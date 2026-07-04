import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/utils.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'resource_update_checker.dart';

/// Mod状态
enum ModStatus {
  enabled,
  disabled,
  needsUpdate,
  incompatible,
}

/// Mod元数据
class ModMetadata {
  final String id;
  final String name;
  final String version;
  final String? description;
  final List<String>? authors;
  final String? website;
  final List<String>? gameVersions;
  final List<String>? dependencies;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final ModStatus status;
  final String fileName;
  final String filePath;
  final int fileSize;

  ModMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.authors,
    this.website,
    this.gameVersions,
    this.dependencies,
    this.installedAt,
    this.updatedAt,
    this.status = ModStatus.enabled,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'authors': authors,
      'website': website,
      'gameVersions': gameVersions,
      'dependencies': dependencies,
      'installedAt': installedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
    };
  }

  factory ModMetadata.fromJson(Map<String, dynamic> json) {
    return ModMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
      authors: (json['authors'] as List<dynamic>?)?.cast<String>(),
      website: json['website'] as String?,
      gameVersions: (json['gameVersions'] as List<dynamic>?)?.cast<String>(),
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>(),
      installedAt: json['installedAt'] != null
          ? DateTime.parse(json['installedAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: ModStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ModStatus.enabled,
      ),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
    );
  }

  ModMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    List<String>? authors,
    String? website,
    List<String>? gameVersions,
    List<String>? dependencies,
    DateTime? installedAt,
    DateTime? updatedAt,
    ModStatus? status,
    String? fileName,
    String? filePath,
    int? fileSize,
  }) {
    return ModMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      authors: authors ?? this.authors,
      website: website ?? this.website,
      gameVersions: gameVersions ?? this.gameVersions,
      dependencies: dependencies ?? this.dependencies,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

/// Mod管理器
class ModManager {
  static ModManager? _instance;

  final Logger _logger = Logger('ModManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// Mod缓存
  final Map<String, List<ModMetadata>> _modsCache = {};

  /// Mod元数据缓存文件
  File? _metadataFile;

  /// 是否已初始化
  bool _initialized = false;

  ModManager._internal();

  /// 获取单例实例
  static ModManager get instance {
    return ServiceLocator.instance.tryGet<ModManager>() ??
        (_instance ??= ModManager._internal());
  }

  /// 工厂构造函数
  factory ModManager() => instance;

  /// 初始化Mod管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _metadataFile = File(path.join(supportDir, 'mod_metadata.json'));

      if (await _metadataFile!.exists()) {
        await _loadMetadata();
      }

      _logger.info('Mod manager initialized');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize mod manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载元数据
  Future<void> _loadMetadata() async {
    try {
      final content = await _metadataFile!.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      data.forEach((instanceId, modsData) {
        if (modsData is List) {
          _modsCache[instanceId] = modsData
              .whereType<Map<String, dynamic>>()
              .map((e) => ModMetadata.fromJson(e))
              .toList();
        }
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to load mod metadata', e, stackTrace);
    }
  }

  /// 保存元数据
  Future<void> _saveMetadata() async {
    try {
      final data = <String, dynamic>{};

      _modsCache.forEach((instanceId, mods) {
        data[instanceId] = mods.map((m) => m.toJson()).toList();
      });

      await _metadataFile!.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      _logger.error('Failed to save mod metadata', e, stackTrace);
    }
  }

  /// 扫描实例目录获取所有Mod
  Future<List<ModMetadata>> scanInstanceMods(String instanceId, String instancePath) async {
    final modsDir = Directory(path.join(instancePath, 'mods'));
    final mods = <ModMetadata>[];

    if (!await modsDir.exists()) {
      return mods;
    }

    await for (final file in modsDir.list()) {
      if (file is File &&
          (file.path.endsWith('.jar') ||
              file.path.endsWith('.litemod') ||
              file.path.endsWith('.disabled'))) {
        final mod = await _loadModFromFile(file, instanceId);
        if (mod != null) {
          mods.add(mod);
        }
      }
    }

    // 更新缓存
    _modsCache[instanceId] = mods;
    await _saveMetadata();

    return mods;
  }

  /// 从文件加载Mod
  Future<ModMetadata?> _loadModFromFile(File file, String instanceId) async {
    try {
      final fileName = path.basename(file.path);
      final fileStat = await file.stat();
      final isDisabled = fileName.endsWith('.disabled');

      // 解析文件名
      final cleanName = isDisabled
          ? fileName.substring(0, fileName.length - '.disabled'.length)
          : fileName;

      String name;
      String version = 'unknown';
      String? description;
      List<String>? authors;

      // 优先从 JAR 内读取元数据
      if (cleanName.endsWith('.jar')) {
        final metadata = await _readModMetadataFromJar(file.path);
        if (metadata != null) {
          name = metadata['name'] ?? _parseNameFromFileName(cleanName);
          version = metadata['version'] ?? 'unknown';
          description = metadata['description'];
          authors = metadata['authors'];
        } else {
          // JAR 解析失败，回退到文件名解析
          final parsed = _parseNameAndVersion(cleanName);
          name = parsed['name']!;
          version = parsed['version']!;
        }
      } else {
        // 非 JAR 文件，从文件名解析
        final parsed = _parseNameAndVersion(cleanName);
        name = parsed['name']!;
        version = parsed['version']!;
      }

      return ModMetadata(
        id: '${instanceId}_$fileName',
        name: name,
        version: version,
        description: description,
        authors: authors,
        status: isDisabled ? ModStatus.disabled : ModStatus.enabled,
        fileName: fileName,
        filePath: file.path,
        fileSize: fileStat.size,
        installedAt: fileStat.modified,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load mod from file ${file.path}', e, stackTrace);
      return null;
    }
  }

  /// 从 JAR 文件中读取 Mod 元数据
  Future<Map<String, dynamic>?> _readModMetadataFromJar(String jarPath) async {
    try {
      final bytes = await File(jarPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 尝试 Fabric mod (fabric.mod.json)
      final fabricMod = archive.findFile('fabric.mod.json');
      if (fabricMod != null) {
        final content = utf8.decode(fabricMod.content as List<int>);
        final data = jsonDecode(content) as Map<String, dynamic>;
        return {
          'name': data['name'] as String?,
          'version': data['version'] as String?,
          'description': data['description'] as String?,
          'authors': (data['authors'] as List<dynamic>?)?.map((a) {
            if (a is String) return a;
            if (a is Map) return a['name']?.toString() ?? '';
            return '';
          }).where((s) => s.isNotEmpty).toList(),
        };
      }

      // 尝试 Forge mods.toml (META-INF/mods.toml)
      final forgeToml = archive.findFile('META-INF/mods.toml');
      if (forgeToml != null) {
        final content = utf8.decode(forgeToml.content as List<int>);
        return _parseForgeToml(content);
      }

      // 尝试 Legacy mcmod.info
      final legacyInfo = archive.findFile('mcmod.info');
      if (legacyInfo != null) {
        final content = utf8.decode(legacyInfo.content as List<int>);
        try {
          final data = jsonDecode(content);
          if (data is List && data.isNotEmpty) {
            final mod = data[0] as Map<String, dynamic>;
            return {
              'name': mod['name'] as String?,
              'version': mod['version'] as String?,
              'description': mod['description'] as String?,
              'authors': (mod['authorList'] as List<dynamic>?)?.cast<String>(),
            };
          } else if (data is Map) {
            final modList = data['modList'] as List<dynamic>?;
            if (modList != null && modList.isNotEmpty) {
              final mod = modList[0] as Map<String, dynamic>;
              return {
                'name': mod['name'] as String?,
                'version': mod['version'] as String?,
                'description': mod['description'] as String?,
                'authors': (mod['authorList'] as List<dynamic>?)?.cast<String>(),
              };
            }
          }
        } catch (_) {
          // JSON 解析失败
        }
      }
    } catch (e) {
      _logger.warning('Failed to read mod metadata from JAR: $jarPath: $e');
    }
    return null;
  }

  /// 解析 Forge mods.toml 格式
  Map<String, dynamic>? _parseForgeToml(String content) {
    String? name;
    String? version;
    String? description;
    List<String>? authors;

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('displayName')) {
        name = _extractTomlValue(trimmed);
      } else if (trimmed.startsWith('version')) {
        version = _extractTomlValue(trimmed);
      } else if (trimmed.startsWith('description')) {
        description = _extractTomlValue(trimmed);
      } else if (trimmed.startsWith('authors')) {
        authors = _extractTomlValue(trimmed)?.split(',').map((s) => s.trim()).toList();
      }
    }

    if (name == null && version == null) return null;
    return {
      'name': name,
      'version': version,
      'description': description,
      'authors': authors,
    };
  }

  /// 提取 TOML 键值对的值
  String? _extractTomlValue(String line) {
    final eqIndex = line.indexOf('=');
    if (eqIndex < 0) return null;
    var value = line.substring(eqIndex + 1).trim();
    // 移除引号
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }

  /// 从文件名解析名称（不带版本）
  String _parseNameFromFileName(String fileName) {
    final clean = fileName.replaceAll('.jar', '').replaceAll('.litemod', '');
    final parts = clean.split('-');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('-');
    }
    return parts.first;
  }

  /// 从文件名解析名称和版本
  Map<String, String> _parseNameAndVersion(String fileName) {
    final clean = fileName.replaceAll('.jar', '').replaceAll('.litemod', '');
    final nameParts = clean.split('-');
    String name = nameParts.first;
    String version = 'unknown';

    if (nameParts.length > 1) {
      version = nameParts.last;
      if (nameParts.length > 2) {
        name = nameParts.sublist(0, nameParts.length - 1).join('-');
      }
    }
    return {'name': name, 'version': version};
  }

  /// 获取实例的Mod列表
  List<ModMetadata> getInstanceMods(String instanceId) {
    return _modsCache[instanceId] ?? [];
  }

  /// 启用Mod
  Future<bool> enableMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (!await file.exists()) return false;

      if (mod.status == ModStatus.enabled) return true;

      // 移除 .disabled 后缀
      final newPath = mod.filePath.replaceAll('.disabled', '');
      await file.rename(newPath);

      // 更新元数据
      final updatedMod = mod.copyWith(
        status: ModStatus.enabled,
        filePath: newPath,
        fileName: path.basename(newPath),
      );

      _updateModInCache(updatedMod);
      await _saveMetadata();

      _logger.info('Enabled mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to enable mod', e, stackTrace);
      return false;
    }
  }

  /// 禁用Mod
  Future<bool> disableMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (!await file.exists()) return false;

      if (mod.status == ModStatus.disabled) return true;

      // 添加 .disabled 后缀
      final newPath = '${mod.filePath}.disabled';
      await file.rename(newPath);

      // 更新元数据
      final updatedMod = mod.copyWith(
        status: ModStatus.disabled,
        filePath: newPath,
        fileName: path.basename(newPath),
      );

      _updateModInCache(updatedMod);
      await _saveMetadata();

      _logger.info('Disabled mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to disable mod', e, stackTrace);
      return false;
    }
  }

  /// 删除Mod
  Future<bool> deleteMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 从缓存中移除
      final instanceId = mod.id.split('_').first;
      final mods = _modsCache[instanceId];
      if (mods != null) {
        mods.removeWhere((m) => m.id == mod.id);
      }

      await _saveMetadata();

      _logger.info('Deleted mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete mod', e, stackTrace);
      return false;
    }
  }

  /// 更新缓存中的Mod
  void _updateModInCache(ModMetadata mod) {
    final instanceId = mod.id.split('_').first;
    final mods = _modsCache[instanceId];
    if (mods != null) {
      final index = mods.indexWhere((m) => m.id == mod.id);
      if (index >= 0) {
        mods[index] = mod;
      }
    }
  }

  /// 批量启用/禁用Mod
  Future<void> toggleMods(List<ModMetadata> mods, bool enable) async {
    for (final mod in mods) {
      if (enable) {
        await enableMod(mod);
      } else {
        await disableMod(mod);
      }
    }
  }

  /// 获取启用的Mod
  List<ModMetadata> getEnabledMods(String instanceId) {
    return getInstanceMods(instanceId)
        .where((m) => m.status == ModStatus.enabled)
        .toList();
  }

  /// 获取禁用的Mod
  List<ModMetadata> getDisabledMods(String instanceId) {
    return getInstanceMods(instanceId)
        .where((m) => m.status == ModStatus.disabled)
        .toList();
  }

  /// 搜索Mod
  List<ModMetadata> searchMods(String instanceId, String query) {
    final lowerQuery = query.toLowerCase();
    return getInstanceMods(instanceId)
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.id.toLowerCase().contains(lowerQuery) ||
            m.fileName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 清空缓存
  void clearCache() {
    _modsCache.clear();
  }
}
