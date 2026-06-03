import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:path/path.dart' as path;
import '../core/error_codes.dart';
import '../core/logger.dart';
import 'instance_manager.dart';
import 'models.dart';

/// 导入进度回调
typedef ImportProgressCallback = void Function(
  int completed,
  int total,
  String? currentTask,
);

/// 冲突处理选项
enum ConflictResolution {
  /// 覆盖现有文件
  overwrite,
  /// 重命名导入的文件
  rename,
  /// 取消导入
  cancel,
}

/// 文件冲突信息
class FileConflict {
  final String path;
  final String existingFile;
  final String incomingFile;
  final int existingSize;
  final int incomingSize;
  final DateTime existingModified;
  final DateTime incomingModified;

  FileConflict({
    required this.path,
    required this.existingFile,
    required this.incomingFile,
    required this.existingSize,
    required this.incomingSize,
    required this.existingModified,
    required this.incomingModified,
  });
}

/// 导入选项
class InstanceImportOptions {
  final String? targetDirectoryId;
  final String? customName;
  final bool showConflictDialog;
  final ConflictResolution defaultConflictResolution;

  const InstanceImportOptions({
    this.targetDirectoryId,
    this.customName,
    this.showConflictDialog = true,
    this.defaultConflictResolution = ConflictResolution.rename,
  });
}

/// 导入结果
class InstanceImportResult {
  final GameInstance instance;
  final List<String> importedFiles;
  final List<String> skippedFiles;
  final List<FileConflict> conflicts;

  InstanceImportResult({
    required this.instance,
    required this.importedFiles,
    required this.skippedFiles,
    required this.conflicts,
  });
}

/// 实例导入器
class InstanceImporter {
  static final Logger _logger = Logger('InstanceImporter');

  /// 从ZIP文件导入实例
  static Future<InstanceImportResult> importFromZip({
    required String zipPath,
    required InstanceImportOptions options,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      _logger.info('Starting instance import from: $zipPath');

      final manager = InstanceManager.instance;
      if (!manager.isInitialized) {
        await manager.initialize();
      }

      // 确定目标目录
      String directoryId = options.targetDirectoryId ?? manager.selectedDirectoryId ?? manager.directories.first.id;
      if (!manager.directories.any((d) => d.id == directoryId)) {
        throw AppException.fromCode(
          ErrorCodes.instanceNotFound,
          detail: '目标目录不存在',
        );
      }

      onProgress?.call(0, 1, '正在读取ZIP文件...');

      // 读取ZIP文件
      final bytes = await File(zipPath).readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

      // 查找并解析实例配置
      archive.ArchiveFile? configFile;
      for (final file in zipArchive.files) {
        if (file.name == 'instance.json' && file.isFile) {
          configFile = file;
          break;
        }
      }

      if (configFile == null) {
        throw AppException.fromCode(
          ErrorCodes.modpackParseFailed,
          detail: '无效的实例包：缺少instance.json',
        );
      }

      onProgress?.call(1, 3, '正在解析实例配置...');

      // 解析配置
      final configJson = utf8.decode(configFile.content as List<int>);
      final config = jsonDecode(configJson) as Map<String, dynamic>;

      // 生成新ID
      final id = manager.generateId();
      final now = DateTime.now();

      // 创建新实例
      final instance = GameInstance.fromJson(config).copyWith(
        id: id,
        directoryId: directoryId,
        name: options.customName ?? config['name'] as String? ?? 'Imported Instance',
        createdAt: now,
        updatedAt: now,
        lastPlayed: null,
        playTimeSeconds: 0,
      );

      final directory = manager.directories.firstWhere((d) => d.id == directoryId);

      // 检查冲突
      final conflicts = <FileConflict>[];
      final targetDir = Directory('${directory.path}\\instances\\$id');

      onProgress?.call(2, 3, '正在检查文件冲突...');

      for (final file in zipArchive.files) {
        if (file.name.startsWith('instances/') && file.isFile) {
          final subPath = file.name.substring('instances/'.length);
          final destPath = path.join(targetDir.path, subPath.replaceAll('/', path.separator));
          final destFile = File(destPath);

          if (await destFile.exists()) {
            final existingStat = await destFile.stat();
            conflicts.add(FileConflict(
              path: destPath,
              existingFile: destPath,
              incomingFile: file.name,
              existingSize: existingStat.size,
              incomingSize: file.size,
              existingModified: existingStat.modified,
              incomingModified: DateTime.now(),
            ));
          }
        }
      }

      // 确保目标目录存在
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final importedFiles = <String>[];
      final skippedFiles = <String>[];

      int totalFiles = zipArchive.files.where((f) => f.name.startsWith('instances/') && f.isFile).length;
      int processedFiles = 0;

      // 提取文件
      for (final file in zipArchive.files) {
        if (file.name.startsWith('instances/') && file.isFile) {
          final subPath = file.name.substring('instances/'.length);
          final destPath = path.join(targetDir.path, subPath.replaceAll('/', path.separator));

          // 创建目录
          final destDir = Directory(path.dirname(destPath));
          if (!await destDir.exists()) {
            await destDir.create(recursive: true);
          }

          // 检查是否冲突
          final destFile = File(destPath);
          if (await destFile.exists()) {
            bool shouldOverwrite = false;

            switch (options.defaultConflictResolution) {
              case ConflictResolution.overwrite:
                shouldOverwrite = true;
              case ConflictResolution.rename:
                // 重命名：添加时间戳后缀
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final ext = path.extension(destPath);
                final baseName = path.basenameWithoutExtension(destPath);
                final dir = path.dirname(destPath);
                final newPath = path.join(dir, '${baseName}_$timestamp$ext');
                await File(newPath).writeAsBytes(file.content as List<int>);
                importedFiles.add(newPath);
              case ConflictResolution.cancel:
                skippedFiles.add(destPath);
                continue;
            }

            if (shouldOverwrite) {
              await destFile.writeAsBytes(file.content as List<int>);
              importedFiles.add(destPath);
            }
          } else {
            // 无冲突，直接写入
            await File(destPath).writeAsBytes(file.content as List<int>);
            importedFiles.add(destPath);
          }

          processedFiles++;
          onProgress?.call(
            processedFiles,
            totalFiles,
            '正在导入: ${path.basename(subPath)}',
          );
        }
      }

      // 添加实例
      await manager.addInstance(instance);

      _logger.info('Instance imported successfully: ${instance.name}');

      return InstanceImportResult(
        instance: instance,
        importedFiles: importedFiles,
        skippedFiles: skippedFiles,
        conflicts: conflicts,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to import instance', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.modpackParseFailed,
        detail: '导入实例失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 从Modrinth mrpack文件导入实例
  static Future<InstanceImportResult> importFromMrpack({
    required String mrpackPath,
    required InstanceImportOptions options,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      _logger.info('Starting Modrinth modpack import from: $mrpackPath');

      final manager = InstanceManager.instance;
      if (!manager.isInitialized) {
        await manager.initialize();
      }

      // 读取mrpack文件
      final bytes = await File(mrpackPath).readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

      // 查找modrinth.index.json
      archive.ArchiveFile? indexFile;
      for (final file in zipArchive.files) {
        if (file.name == 'modrinth.index.json' && file.isFile) {
          indexFile = file;
          break;
        }
      }

      if (indexFile == null) {
        throw AppException.fromCode(
          ErrorCodes.modpackParseFailed,
          detail: '无效的mrpack文件：缺少modrinth.index.json',
        );
      }

      onProgress?.call(1, 4, '正在解析Modrinth索引...');

      // 解析索引
      final indexJson = utf8.decode(indexFile.content as List<int>);
      final indexData = jsonDecode(indexJson) as Map<String, dynamic>;

      // 确定目标目录
      String directoryId = options.targetDirectoryId ?? manager.selectedDirectoryId ?? manager.directories.first.id;

      // 生成实例信息
      final id = manager.generateId();
      final now = DateTime.now();
      final name = options.customName ?? indexData['name'] as String? ?? 'Modrinth Modpack';

      // 解析依赖获取Minecraft版本
      final dependencies = indexData['dependencies'] as Map<String, dynamic>?;
      final minecraftVersion = dependencies?['minecraft'] as String? ?? '1.20.1';

      // 创建实例
      final instance = GameInstance(
        id: id,
        name: name,
        directoryId: directoryId,
        version: minecraftVersion,
        description: indexData['summary'] as String?,
        config: InstanceConfig(),
        resources: InstanceResources(
          mods: [],
          resourcePacks: [],
          shaderPacks: [],
          worlds: [],
          screenshots: [],
        ),
        createdAt: now,
        updatedAt: now,
      );

      final directory = manager.directories.firstWhere((d) => d.id == directoryId);
      final targetDir = Directory('${directory.path}\\instances\\$id');

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 创建overrides目录
      final overridesDir = Directory(path.join(targetDir.path, 'overrides'));
      if (!await overridesDir.exists()) {
        await overridesDir.create(recursive: true);
      }

      final importedFiles = <String>[];
      int totalFiles = zipArchive.files.where((f) => f.name.startsWith('overrides/') && f.isFile).length;
      int processedFiles = 0;

      // 提取overrides
      for (final file in zipArchive.files) {
        if (file.name.startsWith('overrides/') && file.isFile) {
          final subPath = file.name.substring('overrides/'.length);
          final destPath = path.join(targetDir.path, subPath.replaceAll('/', path.separator));

          final destDir = Directory(path.dirname(destPath));
          if (!await destDir.exists()) {
            await destDir.create(recursive: true);
          }

          await File(destPath).writeAsBytes(file.content as List<int>);
          importedFiles.add(destPath);

          processedFiles++;
          onProgress?.call(
            processedFiles,
            totalFiles > 0 ? totalFiles : 1,
            '正在导入: $subPath',
          );
        }
      }

      // 保存实例
      await manager.addInstance(instance);

      _logger.info('Modrinth modpack imported successfully: $name');

      return InstanceImportResult(
        instance: instance,
        importedFiles: importedFiles,
        skippedFiles: [],
        conflicts: [],
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to import mrpack', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.modpackParseFailed,
        detail: '导入Modrinth整合包失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 检测文件格式
  static Future<InstanceFileFormat> detectFormat(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes, verify: false);

      // 检查是否包含instance.json (BAMC格式)
      bool hasInstanceJson = false;
      bool hasModrinthIndex = false;
      bool hasManifestJson = false;

      for (final file in zipArchive.files) {
        if (file.name == 'instance.json') hasInstanceJson = true;
        if (file.name == 'modrinth.index.json') hasModrinthIndex = true;
        if (file.name == 'manifest.json') hasManifestJson = true;
      }

      if (hasInstanceJson) return InstanceFileFormat.bamc;
      if (hasModrinthIndex) return InstanceFileFormat.modrinth;
      if (hasManifestJson) return InstanceFileFormat.curseforge;

      return InstanceFileFormat.unknown;
    } catch (e) {
      _logger.warning('Failed to detect file format', e);
      return InstanceFileFormat.unknown;
    }
  }
}

/// 实例文件格式
enum InstanceFileFormat {
  /// BAMC格式
  bamc,
  /// Modrinth mrpack格式
  modrinth,
  /// CurseForge格式
  curseforge,
  /// 未知格式
  unknown,
}
