import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart' as archive;
import '../core/error_codes.dart';
import '../core/logger.dart';

/// 整合包资源类型
enum ModpackResourceType {
  mod,
  resourcePack,
  shaderPack,
  dataPack,
  config,
  other,
}

/// 解析资源类型
ModpackResourceType _parseResourceType(String? type) {
  switch (type?.toLowerCase()) {
    case 'mod':
    case 'mods':
      return ModpackResourceType.mod;
    case 'resourcepack':
    case 'resourcepacks':
    case 'resource-pack':
    case 'resource_pack':
      return ModpackResourceType.resourcePack;
    case 'shaderpack':
    case 'shaderpacks':
    case 'shader-pack':
    case 'shader_pack':
      return ModpackResourceType.shaderPack;
    case 'datapack':
    case 'datapacks':
    case 'data-pack':
    case 'data_pack':
      return ModpackResourceType.dataPack;
    case 'config':
    case 'configs':
      return ModpackResourceType.config;
    default:
      return ModpackResourceType.other;
  }
}

/// 资源类型转字符串
String _resourceTypeToString(ModpackResourceType type) {
  switch (type) {
    case ModpackResourceType.mod:
      return 'mod';
    case ModpackResourceType.resourcePack:
      return 'resourcePack';
    case ModpackResourceType.shaderPack:
      return 'shaderPack';
    case ModpackResourceType.dataPack:
      return 'dataPack';
    case ModpackResourceType.config:
      return 'config';
    case ModpackResourceType.other:
      return 'other';
  }
}

/// 整合包资源信息
class ModpackResource {
  final String name;
  final ModpackResourceType type;
  final String? projectId;
  final String? fileId;
  final String? downloadUrl;
  final String? fileHash;
  final int? fileSize;
  final List<String>? requiredDependencies;

  ModpackResource({
    required this.name,
    required this.type,
    this.projectId,
    this.fileId,
    this.downloadUrl,
    this.fileHash,
    this.fileSize,
    this.requiredDependencies,
  });

  factory ModpackResource.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final resourceType = _parseResourceType(type);

    return ModpackResource(
      name: json['name'] as String? ?? 'unknown',
      type: resourceType,
      projectId: json['projectId']?.toString(),
      fileId: json['fileId']?.toString(),
      downloadUrl: json['downloadUrl'] as String?,
      fileHash: json['sha1'] as String? ?? json['fileHash'] as String?,
      fileSize: json['fileSize'] as int? ?? json['size'] as int?,
      requiredDependencies: (json['requiredDependencies'] as List<dynamic>?)
          ?.map((d) => d.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': _resourceTypeToString(type),
      if (projectId != null) 'projectId': projectId,
      if (fileId != null) 'fileId': fileId,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (fileHash != null) 'fileHash': fileHash,
      if (fileSize != null) 'fileSize': fileSize,
      if (requiredDependencies != null) 'requiredDependencies': requiredDependencies,
    };
  }
}

/// 整合包信息
class ModpackInfo {
  final String name;
  final String version;
  final String minecraftVersion;
  final String? modLoader;
  final String? modLoaderVersion;
  final String? author;
  final String? description;
  final List<ModpackResource> mods;
  final List<ModpackResource> resourcePacks;
  final List<ModpackResource> shaderPacks;
  final List<ModpackResource> dataPacks;
  final List<ModpackResource> otherResources;
  final Map<String, dynamic>? configs;
  final String? iconUrl;
  final DateTime? createdAt;

  ModpackInfo({
    required this.name,
    required this.version,
    required this.minecraftVersion,
    this.modLoader,
    this.modLoaderVersion,
    this.author,
    this.description,
    this.mods = const [],
    this.resourcePacks = const [],
    this.shaderPacks = const [],
    this.dataPacks = const [],
    this.otherResources = const [],
    this.configs,
    this.iconUrl,
    this.createdAt,
  });

  /// 获取所有资源
  List<ModpackResource> get allResources => [
        ...mods,
        ...resourcePacks,
        ...shaderPacks,
        ...dataPacks,
        ...otherResources,
      ];
}

/// 整合包解析器
class ModpackParser {
  static final Logger _logger = Logger('ModpackParser');

  /// 解析 zip 文件中的整合包
  static Future<ModpackInfo> parseZip(String zipPath) async {
    try {
      _logger.info('Parsing modpack zip: $zipPath');

      final file = File(zipPath);
      if (!await file.exists()) {
        throw AppException.fromCode(
          ErrorCodes.fileNotFound,
          detail: '整合包文件不存在',
        );
      }

      // 读取并解压 zip
      final bytes = await file.readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

      // 尝试不同格式的解析
      ModpackInfo? result;

      // 尝试 CurseForge 格式 (manifest.json)
      result = await _tryCurseForgeFormat(zipArchive);
      if (result != null) return result;

      // 尝试 Modrinth 格式 (modrinth.index.json)
      result = await _tryModrinthFormat(zipArchive);
      if (result != null) return result;

      // 尝试通用格式 (modpack.json)
      result = await _tryGenericFormat(zipArchive);
      if (result != null) return result;

      // 所有格式都不匹配
      throw AppException.fromCode(
        ErrorCodes.modpackUnsupportedFormat,
        detail: '不支持的整合包格式',
      );
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      _logger.error('Failed to parse modpack', e, stackTrace);
      throw AppException.fromCode(
        ErrorCodes.modpackParseFailed,
        detail: '解析整合包失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 尝试解析 CurseForge 格式
  static Future<ModpackInfo?> _tryCurseForgeFormat(
    archive.Archive zipArchive,
  ) async {
    try {
      final manifestFile = zipArchive.findFile('manifest.json');
      if (manifestFile == null) return null;

      _logger.info('Found CurseForge format manifest');

      final manifestJson = jsonDecode(utf8.decode(manifestFile.content as List<int>));

      // 解析 manifest
      final name = manifestJson['name'] as String?;
      final version = manifestJson['version'] as String?;
      final mcVersion = manifestJson['minecraft']?['version'] as String?;
      final modLoaders = manifestJson['minecraft']?['modLoaders'] as List<dynamic>?;
      final files = manifestJson['files'] as List<dynamic>? ?? [];

      if (name == null || mcVersion == null) {
        return null;
      }

      // 解析 Mod 加载器
      String? modLoader;
      String? modLoaderVersion;
      if (modLoaders != null && modLoaders.isNotEmpty) {
        final loader = modLoaders.first as Map<String, dynamic>;
        final loaderId = loader['id'] as String?;
        if (loaderId != null) {
          final parts = loaderId.split('-');
          if (parts.length >= 2) {
            modLoader = parts[0];
            modLoaderVersion = parts.sublist(1).join('-');
          }
        }
      }

      // 解析资源列表
      final List<ModpackResource> mods = [];
      for (final file in files) {
        final projectId = file['projectID']?.toString();
        final fileId = file['fileID']?.toString();
        if (projectId != null && fileId != null) {
          mods.add(ModpackResource(
            name: 'Mod $projectId',
            type: ModpackResourceType.mod,
            projectId: projectId,
            fileId: fileId,
            requiredDependencies: [],
          ));
        }
      }

      _logger.info('Successfully parsed CurseForge modpack: $name v$version');

      return ModpackInfo(
        name: name,
        version: version ?? '1.0.0',
        minecraftVersion: mcVersion,
        modLoader: modLoader,
        modLoaderVersion: modLoaderVersion,
        author: manifestJson['author'] as String?,
        description: manifestJson['description'] as String?,
        mods: mods,
      );
    } catch (e, stackTrace) {
      _logger.warning('Failed to parse CurseForge format', e, stackTrace);
      return null;
    }
  }

  /// 尝试解析 Modrinth 格式
  static Future<ModpackInfo?> _tryModrinthFormat(
    archive.Archive zipArchive,
  ) async {
    try {
      final indexFile = zipArchive.findFile('modrinth.index.json');
      if (indexFile == null) return null;

      _logger.info('Found Modrinth format index');

      final indexJson = jsonDecode(utf8.decode(indexFile.content as List<int>));

      // 解析 index
      final name = indexJson['name'] as String?;
      final versionId = indexJson['versionId'] as String?;
      final mcVersion = indexJson['gameVersion'] as String?;
      final dependencies = indexJson['dependencies'] as Map<String, dynamic>?;
      final files = indexJson['files'] as List<dynamic>? ?? [];

      if (name == null || mcVersion == null) {
        return null;
      }

      // 解析依赖
      String? modLoader;
      String? modLoaderVersion;
      if (dependencies != null) {
        if (dependencies.containsKey('forge')) {
          modLoader = 'forge';
          modLoaderVersion = dependencies['forge'] as String?;
        } else if (dependencies.containsKey('fabric-loader')) {
          modLoader = 'fabric';
          modLoaderVersion = dependencies['fabric-loader'] as String?;
        } else if (dependencies.containsKey('quilt-loader')) {
          modLoader = 'quilt';
          modLoaderVersion = dependencies['quilt-loader'] as String?;
        }
      }

      // 解析文件列表
      final List<ModpackResource> mods = [];
      final List<ModpackResource> resourcePacks = [];
      final List<ModpackResource> shaderPacks = [];
      final List<ModpackResource> dataPacks = [];
      final List<ModpackResource> otherResources = [];

      for (final file in files) {
        final pathValue = file['path'] as String?;
        final downloads = file['downloads'] as List<dynamic>?;
        final url = downloads?.first as String?;
        final hashes = file['hashes'] as Map<String, dynamic>?;

        if (pathValue != null && url != null) {
          final fileName = path.basename(pathValue);

          // 根据路径判断资源类型
          ModpackResourceType type;
          if (pathValue.startsWith('mods/')) {
            type = ModpackResourceType.mod;
            mods.add(ModpackResource(
              name: fileName,
              type: type,
              downloadUrl: url,
              fileHash: hashes?['sha1'] as String?,
              fileSize: file['fileSize'] as int?,
            ));
          } else if (pathValue.startsWith('resourcepacks/')) {
            type = ModpackResourceType.resourcePack;
            resourcePacks.add(ModpackResource(
              name: fileName,
              type: type,
              downloadUrl: url,
              fileHash: hashes?['sha1'] as String?,
              fileSize: file['fileSize'] as int?,
            ));
          } else if (pathValue.startsWith('shaderpacks/')) {
            type = ModpackResourceType.shaderPack;
            shaderPacks.add(ModpackResource(
              name: fileName,
              type: type,
              downloadUrl: url,
              fileHash: hashes?['sha1'] as String?,
              fileSize: file['fileSize'] as int?,
            ));
          } else if (pathValue.startsWith('datapacks/')) {
            type = ModpackResourceType.dataPack;
            dataPacks.add(ModpackResource(
              name: fileName,
              type: type,
              downloadUrl: url,
              fileHash: hashes?['sha1'] as String?,
              fileSize: file['fileSize'] as int?,
            ));
          } else {
            type = ModpackResourceType.other;
            otherResources.add(ModpackResource(
              name: fileName,
              type: type,
              downloadUrl: url,
              fileHash: hashes?['sha1'] as String?,
              fileSize: file['fileSize'] as int?,
            ));
          }
        }
      }

      _logger.info('Successfully parsed Modrinth modpack: $name v$versionId');

      return ModpackInfo(
        name: name,
        version: versionId ?? '1.0.0',
        minecraftVersion: mcVersion,
        modLoader: modLoader,
        modLoaderVersion: modLoaderVersion,
        mods: mods,
        resourcePacks: resourcePacks,
        shaderPacks: shaderPacks,
        dataPacks: dataPacks,
        otherResources: otherResources,
      );
    } catch (e, stackTrace) {
      _logger.warning('Failed to parse Modrinth format', e, stackTrace);
      return null;
    }
  }

  /// 尝试解析通用格式
  static Future<ModpackInfo?> _tryGenericFormat(
    archive.Archive zipArchive,
  ) async {
    try {
      final modpackFile = zipArchive.findFile('modpack.json');
      if (modpackFile == null) return null;

      _logger.info('Found generic modpack.json');

      final modpackJson = jsonDecode(utf8.decode(modpackFile.content as List<int>));

      final name = modpackJson['name'] as String?;
      final version = modpackJson['version'] as String?;
      final mcVersion = modpackJson['minecraftVersion'] as String?;

      if (name == null || mcVersion == null) {
        return null;
      }

      _logger.info('Successfully parsed generic modpack: $name v$version');

      return ModpackInfo(
        name: name,
        version: version ?? '1.0.0',
        minecraftVersion: mcVersion,
        modLoader: modpackJson['modLoader'] as String?,
        modLoaderVersion: modpackJson['modLoaderVersion'] as String?,
        author: modpackJson['author'] as String?,
        description: modpackJson['description'] as String?,
        mods: [],
      );
    } catch (e, stackTrace) {
      _logger.warning('Failed to parse generic format', e, stackTrace);
      return null;
    }
  }
}
