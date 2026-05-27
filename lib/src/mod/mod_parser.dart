import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:crypto/crypto.dart';
import '../core/logger.dart';
import 'mod_info.dart';

class ModParser {
  static final Logger _logger = Logger('ModParser');

  static Future<ModInfo?> parseJarFile(String filePath, bool isEnabled) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

      final stat = await file.stat();
      final fileName = filePath.split(Platform.pathSeparator).last;
      final cleanFileName = fileName.replaceAll('.disabled', '');

      final id = md5.convert(bytes).toString().substring(0, 12);

      ModInfo? modInfo;

      modInfo ??= _tryParseFabric(zipArchive, cleanFileName);
      modInfo ??= _tryParseQuilt(zipArchive, cleanFileName);
      modInfo ??= _tryParseForgeToml(zipArchive, cleanFileName);
      modInfo ??= _tryParseLegacyForge(zipArchive, cleanFileName);

      if (modInfo != null) {
        return modInfo.copyWith(
          id: id,
          filePath: filePath,
          fileName: cleanFileName,
          isEnabled: isEnabled,
          lastModified: stat.modified,
          fileSize: stat.size,
        );
      }

      return ModInfo(
        id: id,
        name: _extractNameFromFileName(cleanFileName),
        fileName: cleanFileName,
        filePath: filePath,
        isEnabled: isEnabled,
        lastModified: stat.modified,
        fileSize: stat.size,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to parse JAR: $filePath', e, stackTrace);
      final fileName = filePath.split(Platform.pathSeparator).last;
      final cleanFileName = fileName.replaceAll('.disabled', '');
      return ModInfo(
        id: cleanFileName,
        name: _extractNameFromFileName(cleanFileName),
        fileName: cleanFileName,
        filePath: filePath,
        isEnabled: isEnabled,
        fileSize: 0,
      );
    }
  }

  static ModInfo? _tryParseFabric(archive.Archive zipArchive, String fileName) {
    try {
      final fabricMod = zipArchive.findFile('fabric.mod.json');
      if (fabricMod == null) return null;

      final content = utf8.decode(fabricMod.content as List<int>);
      final json = jsonDecode(content) as Map<String, dynamic>;

      final modId = json['id'] as String?;
      final name = json['name'] as String? ?? modId ?? fileName;
      final version = json['version'] as String?;
      final description = json['description'] as String?;
      final contact = json['contact'] as Map<String, dynamic>?;
      final authors = json['authors'] as List<dynamic>?;
      final String? author = _extractAuthor(authors, contact);

      final depends = json['depends'] as Map<String, dynamic>?;
      final dependencies = depends?.keys.toList() ?? <String>[];

      return ModInfo(
        id: '',
        name: name,
        version: version,
        author: author,
        description: description,
        fileName: fileName,
        filePath: '',
        modLoader: 'fabric',
        modId: modId,
        dependencies: dependencies.cast<String>(),
      );
    } catch (e) {
      return null;
    }
  }

  static ModInfo? _tryParseQuilt(archive.Archive zipArchive, String fileName) {
    try {
      final quiltMod = zipArchive.findFile('quilt.mod.json');
      if (quiltMod == null) return null;

      final content = utf8.decode(quiltMod.content as List<int>);
      final json = jsonDecode(content) as Map<String, dynamic>;

      final loader = json['quilt_loader'] as Map<String, dynamic>?;
      if (loader == null) return null;

      final modId = loader['id'] as String?;
      final version = loader['version'] as String?;
      final metadata = loader['metadata'] as Map<String, dynamic>?;
      final name = metadata?['name'] as String? ?? modId ?? fileName;
      final description = metadata?['description'] as String?;
      final contributors = metadata?['contributors'] as Map<String, dynamic>?;
      final String? author = contributors?.keys.firstOrNull;

      final depends = loader['depends'] as List<dynamic>?;
      final dependencies = depends
              ?.map((d) {
                if (d is Map<String, dynamic>) {
                  return d['id'] as String?;
                }
                return d as String?;
              })
              .whereType<String>()
              .toList() ??
          <String>[];

      return ModInfo(
        id: '',
        name: name,
        version: version,
        author: author,
        description: description,
        fileName: fileName,
        filePath: '',
        modLoader: 'quilt',
        modId: modId,
        dependencies: dependencies,
      );
    } catch (e) {
      return null;
    }
  }

  static ModInfo? _tryParseForgeToml(archive.Archive zipArchive, String fileName) {
    try {
      final modsToml = zipArchive.findFile('META-INF/mods.toml');
      if (modsToml == null) return null;

      final content = utf8.decode(modsToml.content as List<int>);
      final parsed = _parseSimpleToml(content);

      final mods = parsed['mods'] as List<dynamic>?;
      if (mods == null || mods.isEmpty) return null;

      final mod = mods.first as Map<String, dynamic>;
      final modId = mod['modId'] as String?;
      final modName = mod['displayName'] as String?;
      final version = mod['version'] as String?;
      final description = mod['description'] as String?;
      final author = mod['authors'] as String?;

      final loader = parsed['loader'] as Map<String, dynamic>?;
      final loaderType = loader?['modLoader'] as String?;
      String? modLoader;
      if (loaderType == 'javafml') {
        modLoader = 'forge';
      } else if (loaderType == 'neoforge') {
        modLoader = 'neoforge';
      } else {
        modLoader = 'forge';
      }

      return ModInfo(
        id: '',
        name: modName ?? modId ?? fileName,
        version: version,
        author: author,
        description: description,
        fileName: fileName,
        filePath: '',
        modLoader: modLoader,
        modId: modId,
        dependencies: <String>[],
      );
    } catch (e) {
      return null;
    }
  }

  static ModInfo? _tryParseLegacyForge(archive.Archive zipArchive, String fileName) {
    try {
      final mcmod = zipArchive.findFile('mcmod.info');
      if (mcmod == null) return null;

      final content = utf8.decode(mcmod.content as List<int>);
      final json = jsonDecode(content);

      Map<String, dynamic> mod;
      if (json is List && json.isNotEmpty) {
        mod = json.first as Map<String, dynamic>;
      } else if (json is Map && json['modList'] is List) {
        final modList = json['modList'] as List;
        if (modList.isEmpty) return null;
        mod = modList.first as Map<String, dynamic>;
      } else {
        return null;
      }

      final modId = mod['modid'] as String?;
      final name = mod['name'] as String? ?? modId ?? fileName;
      final version = mod['version'] as String?;
      final description = mod['description'] as String?;
      final authorList = mod['authorList'] as List<dynamic>?;
      final String? author =
          authorList?.isNotEmpty == true ? authorList!.first as String? : null;

      return ModInfo(
        id: '',
        name: name,
        version: version,
        author: author,
        description: description,
        fileName: fileName,
        filePath: '',
        modLoader: 'forge',
        modId: modId,
        dependencies: <String>[],
      );
    } catch (e) {
      return null;
    }
  }

  static String? _extractAuthor(List<dynamic>? authors, Map<String, dynamic>? contact) {
    if (authors != null && authors.isNotEmpty) {
      final first = authors.first;
      if (first is String) return first;
      if (first is Map<String, dynamic>) return first['name'] as String?;
    }
    return null;
  }

  static String _extractNameFromFileName(String fileName) {
    var name = fileName;
    if (name.endsWith('.jar')) {
      name = name.substring(0, name.length - 4);
    }
    return name;
  }

  static Map<String, dynamic> _parseSimpleToml(String content) {
    final result = <String, dynamic>{};
    final regex = RegExp(r'(\w+)\s*=\s*"([^"]*)"');
    final arrayRegex = RegExp(r'\[\[(\w+\.?)*\]\]');
    final lines = content.split('\n');

    String? currentArrayKey;
    Map<String, dynamic>? currentSection;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final arrayMatch = arrayRegex.firstMatch(trimmed);
      if (arrayMatch != null) {
        final fullKey = trimmed.substring(2, trimmed.length - 2);
        final lastDot = fullKey.lastIndexOf('.');
        if (lastDot > 0) {
          final parentKey = fullKey.substring(0, lastDot);
          currentArrayKey = parentKey;
          if (result.containsKey(parentKey)) {
            final existing = result[parentKey];
            if (existing is List) {
              currentSection = <String, dynamic>{};
              existing.add(currentSection);
            }
          } else {
            currentSection = <String, dynamic>{};
            result[parentKey] = <Map<String, dynamic>>[currentSection];
          }
        }
        continue;
      }

      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        currentArrayKey = null;
        currentSection = null;
        continue;
      }

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final key = match.group(1)!;
        final value = match.group(2)!;

        if (currentSection != null) {
          currentSection[key] = value;
        } else {
          result[key] = value;
        }
        continue;
      }

      final kvRegex = RegExp(r'(\w+)\s*=\s*(.+)$');
      final kvMatch = kvRegex.firstMatch(trimmed);
      if (kvMatch != null) {
        final key = kvMatch.group(1)!;
        var value = kvMatch.group(2)!.trim();

        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value == 'true') {
          if (currentSection != null) {
            currentSection[key] = true;
          } else {
            result[key] = true;
          }
          continue;
        } else if (value == 'false') {
          if (currentSection != null) {
            currentSection[key] = false;
          } else {
            result[key] = false;
          }
          continue;
        }

        if (currentSection != null) {
          currentSection[key] = value;
        } else {
          result[key] = value;
        }
      }
    }

    return result;
  }
}
