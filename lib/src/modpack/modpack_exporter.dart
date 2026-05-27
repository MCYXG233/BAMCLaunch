import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart' as archive;
import '../core/error_codes.dart';
import '../core/logger.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';

typedef ExportProgressCallback = void Function(
  int completed,
  int total,
  String? currentTask,
);

enum ModpackExportFormat {
  curseforge,
  modrinth,
  bamc,
}

class ModpackExportOptions {
  final String name;
  final String? description;
  final String? version;
  final String? author;
  final ModpackExportFormat format;
  final bool includeMods;
  final bool includeConfig;
  final bool includeSaves;
  final bool includeResourcePacks;
  final bool includeShaderPacks;
  final bool includeScreenshots;

  const ModpackExportOptions({
    required this.name,
    this.description,
    this.version,
    this.author,
    this.format = ModpackExportFormat.bamc,
    this.includeMods = true,
    this.includeConfig = true,
    this.includeSaves = true,
    this.includeResourcePacks = true,
    this.includeShaderPacks = true,
    this.includeScreenshots = true,
  });
}

class ModpackExporter {
  static final Logger _logger = Logger('ModpackExporter');

  static Future<String> exportModpack({
    required String instanceId,
    required String outputPath,
    required ModpackExportOptions options,
    ExportProgressCallback? onProgress,
  }) async {
    try {
      _logger.info('Starting modpack export for instance: $instanceId');

      final manager = InstanceManager.instance;
      if (!manager.isInitialized) {
        await manager.initialize();
      }

      final instance = manager.instances.firstWhere(
        (i) => i.id == instanceId,
        orElse: () => throw AppException.fromCode(
          ErrorCodes.instanceNotFound,
          detail: instanceId,
        ),
      );

      final instancePath = manager.getInstancePath(instanceId);

      onProgress?.call(0, 1, '正在收集文件...');

      final zipArchive = await _collectFiles(instancePath, options, onProgress);

      final manifest = _generateManifest(instance, options);
      final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
      final manifestBytes = utf8.encode(manifestJson);

      String manifestName;
      switch (options.format) {
        case ModpackExportFormat.curseforge:
          manifestName = 'manifest.json';
        case ModpackExportFormat.modrinth:
          manifestName = 'modrinth.index.json';
        case ModpackExportFormat.bamc:
          manifestName = 'instance.json';
      }

      zipArchive.addFile(archive.ArchiveFile(
        manifestName,
        manifestBytes.length,
        manifestBytes,
      ));

      onProgress?.call(0, 1, '正在压缩文件...');

      final encodedArchive = archive.ZipEncoder().encode(zipArchive);
      if (encodedArchive == null) {
        throw AppException.fromCode(
          ErrorCodes.fileNotFound,
          detail: 'ZIP编码失败',
        );
      }

      final outputFile = File(outputPath);
      final outputDir = Directory(path.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      await outputFile.writeAsBytes(encodedArchive);

      _logger.info('Modpack exported successfully to: $outputPath');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to export modpack', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.modpackParseFailed,
        detail: '导出整合包失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<archive.Archive> _collectFiles(
    String instancePath,
    ModpackExportOptions options,
    ExportProgressCallback? onProgress,
  ) async {
    final zipArchive = archive.Archive();
    int collected = 0;

    final Map<String, bool> foldersToCollect = {
      'mods': options.includeMods,
      'config': options.includeConfig,
      'saves': options.includeSaves,
      'resourcepacks': options.includeResourcePacks,
      'shaderpacks': options.includeShaderPacks,
      'screenshots': options.includeScreenshots,
    };

    int totalFolders = foldersToCollect.values.where((v) => v).length;
    int processedFolders = 0;

    for (final entry in foldersToCollect.entries) {
      if (!entry.value) continue;

      final dirPath = path.join(instancePath, entry.key);
      final dir = Directory(dirPath);

      if (await dir.exists()) {
        int fileCount = 0;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = path.relative(entity.path, from: instancePath);
            final archivePath = relativePath.replaceAll('\\', '/');
            final content = await entity.readAsBytes();
            zipArchive.addFile(archive.ArchiveFile(
              archivePath,
              content.length,
              content,
            ));
            collected++;
            fileCount++;
          }
        }
        _logger.info('Collected $fileCount files from ${entry.key}');
      }

      processedFolders++;
      onProgress?.call(
        processedFolders,
        totalFolders,
        '正在收集 ${entry.key}...',
      );
    }

    _logger.info('Total files collected: $collected');
    return zipArchive;
  }

  static Map<String, dynamic> _generateManifest(
    GameInstance instance,
    ModpackExportOptions options,
  ) {
    switch (options.format) {
      case ModpackExportFormat.curseforge:
        return _generateCurseForgeManifest(instance, options);
      case ModpackExportFormat.modrinth:
        return _generateModrinthIndex(instance, options);
      case ModpackExportFormat.bamc:
        return _generateBamcManifest(instance, options);
    }
  }

  static Map<String, dynamic> _generateCurseForgeManifest(
    GameInstance instance,
    ModpackExportOptions options,
  ) {
    final String? loaderId;
    if (instance.loader != null && instance.loaderVersion != null) {
      loaderId = '${instance.loader}-${instance.loaderVersion}';
    } else if (instance.loader != null) {
      loaderId = instance.loader;
    } else {
      loaderId = null;
    }

    return {
      'minecraft': {
        'version': instance.version,
        'modLoaders': [
          {
            'id': loaderId ?? '',
            'primary': true,
          },
        ],
      },
      'manifestType': 'minecraftModpack',
      'manifestVersion': 1,
      'name': options.name,
      'version': options.version ?? '1.0.0',
      'author': options.author ?? '',
      'description': options.description ?? '',
      'files': <Map<String, dynamic>>[],
      'overrides': 'overrides',
    };
  }

  static Map<String, dynamic> _generateModrinthIndex(
    GameInstance instance,
    ModpackExportOptions options,
  ) {
    final Map<String, dynamic> dependencies = {
      'minecraft': instance.version,
    };

    if (instance.loader != null) {
      switch (instance.loader!.toLowerCase()) {
        case 'forge':
          dependencies['forge'] = instance.loaderVersion ?? '';
        case 'fabric':
          dependencies['fabric-loader'] = instance.loaderVersion ?? '';
        case 'quilt':
          dependencies['quilt-loader'] = instance.loaderVersion ?? '';
        case 'neoforge':
          dependencies['neoforge'] = instance.loaderVersion ?? '';
      }
    }

    return {
      'formatVersion': 1,
      'game': 'minecraft',
      'versionId': options.version ?? '1.0.0',
      'name': options.name,
      'summary': options.description ?? '',
      'dependencies': dependencies,
      'files': <Map<String, dynamic>>[],
    };
  }

  static Map<String, dynamic> _generateBamcManifest(
    GameInstance instance,
    ModpackExportOptions options,
  ) {
    return {
      'name': options.name,
      'version': options.version ?? '1.0.0',
      'minecraftVersion': instance.version,
      'modLoader': instance.loader,
      'modLoaderVersion': instance.loaderVersion,
      'author': options.author,
      'description': options.description,
      'createdAt': DateTime.now().toIso8601String(),
      'format': 'bamc',
      'formatVersion': 1,
    };
  }
}
