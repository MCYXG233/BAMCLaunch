import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../core/error_codes.dart';
import '../core/logger.dart';
import 'instance_manager.dart';
import 'models.dart';

/// 导出进度回调
typedef ExportProgressCallback = void Function(
  int completed,
  int total,
  String? currentTask,
);

/// 导出选项
class InstanceExportOptions {
  final String? customName;
  final String? author;
  final String? version;
  final String? description;
  final bool includeMods;
  final bool includeConfig;
  final bool includeSaves;
  final bool includeResourcePacks;
  final bool includeShaderPacks;
  final bool includeScreenshots;
  final bool includeLogs;
  final bool includeOptionsTxt;

  const InstanceExportOptions({
    this.customName,
    this.author,
    this.version,
    this.description,
    this.includeMods = true,
    this.includeConfig = true,
    this.includeSaves = true,
    this.includeResourcePacks = true,
    this.includeShaderPacks = true,
    this.includeScreenshots = false,
    this.includeLogs = false,
    this.includeOptionsTxt = true,
  });
}

/// 导出格式
enum InstanceExportFormat {
  /// BAMC自有格式（ZIP + instance.json）
  bamc,
  /// Modrinth mrpack格式
  modrinth,
  /// 标准ZIP格式（仅包含文件）
  zip,
}

/// 实例导出器
class InstanceExporter {
  static final Logger _logger = Logger('InstanceExporter');

  /// 导出实例
  static Future<String> exportInstance({
    required String instanceId,
    required String outputPath,
    required InstanceExportFormat format,
    required InstanceExportOptions options,
    ExportProgressCallback? onProgress,
  }) async {
    try {
      _logger.info('Starting instance export for: $instanceId');

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

      // 收集文件
      final archive = await _collectFiles(instancePath, options, onProgress);

      // 生成元数据
      final Map<String, dynamic>? metadata;
      switch (format) {
        case InstanceExportFormat.bamc:
          metadata = _generateBamcMetadata(instance, options);
        case InstanceExportFormat.modrinth:
          metadata = _generateModrinthMetadata(instance, options);
        case InstanceExportFormat.zip:
          metadata = null;
      }

      // 添加元数据文件
      if (metadata != null) {
        final metadataJson = const JsonEncoder.withIndent('  ').convert(metadata);
        final metadataName = format == InstanceExportFormat.modrinth
            ? 'modrinth.index.json'
            : 'instance.json';
        archive.addFile(ArchiveFile(
          metadataName,
          metadataJson.length,
          utf8.encode(metadataJson),
        ));
      }

      onProgress?.call(0, 1, '正在压缩文件...');

      // 编码为ZIP
      final encodedArchive = ZipEncoder().encode(archive);
      if (encodedArchive == null) {
        throw AppException.fromCode(
          ErrorCodes.fileNotFound,
          detail: 'ZIP编码失败',
        );
      }

      // 写入文件
      final outputFile = File(outputPath);
      final outputDir = Directory(path.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      await outputFile.writeAsBytes(encodedArchive);

      _logger.info('Instance exported successfully to: $outputPath');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to export instance', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.modpackParseFailed,
        detail: '导出实例失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 收集文件到归档
  static Future<Archive> _collectFiles(
    String instancePath,
    InstanceExportOptions options,
    ExportProgressCallback? onProgress,
  ) async {
    final zipArchive = Archive();
    int collected = 0;

    final Map<String, bool> foldersToCollect = {
      'mods': options.includeMods,
      'config': options.includeConfig,
      'saves': options.includeSaves,
      'resourcepacks': options.includeResourcePacks,
      'shaderpacks': options.includeShaderPacks,
      'screenshots': options.includeScreenshots,
      'logs': options.includeLogs,
    };

    int totalFolders = foldersToCollect.values.where((v) => v).length;
    int processedFolders = 0;

    // 添加options.txt
    if (options.includeOptionsTxt) {
      final optionsFile = File(path.join(instancePath, 'options.txt'));
      if (await optionsFile.exists()) {
        final content = await optionsFile.readAsBytes();
        zipArchive.addFile(ArchiveFile('instances/options.txt', content.length, content));
        collected++;
      }
    }

    for (final entry in foldersToCollect.entries) {
      if (!entry.value) continue;

      final dirPath = path.join(instancePath, entry.key);
      final dir = Directory(dirPath);

      if (await dir.exists()) {
        int fileCount = 0;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = path.relative(entity.path, from: instancePath);
            final archivePath = 'instances/$relativePath'.replaceAll('\\', '/');
            final content = await entity.readAsBytes();
            zipArchive.addFile(ArchiveFile(
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

  /// 生成BAMC格式元数据
  static Map<String, dynamic> _generateBamcMetadata(
    GameInstance instance,
    InstanceExportOptions options,
  ) {
    return {
      'name': options.customName ?? instance.name,
      'version': options.version ?? '1.0.0',
      'minecraftVersion': instance.version,
      'modLoader': instance.loader,
      'modLoaderVersion': instance.loaderVersion,
      'author': options.author,
      'description': options.description ?? instance.description,
      'createdAt': DateTime.now().toIso8601String(),
      'format': 'bamc',
      'formatVersion': 1,
      'instanceId': instance.id,
    };
  }

  /// 生成Modrinth格式元数据
  static Map<String, dynamic> _generateModrinthMetadata(
    GameInstance instance,
    InstanceExportOptions options,
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
      'name': options.customName ?? instance.name,
      'summary': options.description ?? instance.description ?? '',
      'dependencies': dependencies,
      'files': <Map<String, dynamic>>[],
    };
  }

  /// 获取导出文件默认名称
  static String getDefaultExportFileName(GameInstance instance, InstanceExportFormat format) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final safeName = instance.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

    String extension;
    switch (format) {
      case InstanceExportFormat.bamc:
        extension = 'zip';
      case InstanceExportFormat.modrinth:
        extension = 'mrpack';
      case InstanceExportFormat.zip:
        extension = 'zip';
    }

    return '${safeName}_$timestamp.$extension';
  }

  /// 计算实例大小
  static Future<int> calculateInstanceSize(String instancePath) async {
    int totalSize = 0;

    final dir = Directory(instancePath);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }

    return totalSize;
  }
}
