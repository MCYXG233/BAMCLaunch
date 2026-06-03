import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../config/config_manager.dart';
import '../config/config_keys.dart';

/// 备份类型
enum BackupType {
  /// 完整备份（所有内容）
  full,

  /// 仅备份存档
  savesOnly,

  /// 仅备份配置
  configOnly,
}

/// 压缩级别
enum CompressionLevel {
  /// 快速压缩
  fast,

  /// 平衡压缩
  balanced,

  /// 最大压缩
  maximum,
}

/// 备份记录
class BackupRecord {
  /// 备份唯一ID
  final String id;

  /// 实例ID
  final String instanceId;

  /// 实例名称
  final String instanceName;

  /// 备份类型
  final BackupType type;

  /// 创建时间
  final DateTime createdAt;

  /// 备份文件路径
  final String filePath;

  /// 文件大小（字节）
  final int fileSize;

  /// 描述（用户备注）
  final String? description;

  /// 游戏版本
  final String? gameVersion;

  /// 是否已压缩
  final bool isCompressed;

  /// 标签ID列表
  final List<String> tags;

  BackupRecord({
    required this.id,
    required this.instanceId,
    required this.instanceName,
    required this.type,
    required this.createdAt,
    required this.filePath,
    required this.fileSize,
    this.description,
    this.gameVersion,
    this.isCompressed = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceId': instanceId,
      'instanceName': instanceName,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'filePath': filePath,
      'fileSize': fileSize,
      'description': description,
      'gameVersion': gameVersion,
      'isCompressed': isCompressed,
      'tags': tags,
    };
  }

  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as String,
      instanceId: json['instanceId'] as String,
      instanceName: json['instanceName'] as String,
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.full,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      description: json['description'] as String?,
      gameVersion: json['gameVersion'] as String?,
      isCompressed: json['isCompressed'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  BackupRecord copyWith({
    String? id,
    String? instanceId,
    String? instanceName,
    BackupType? type,
    DateTime? createdAt,
    String? filePath,
    int? fileSize,
    String? description,
    String? gameVersion,
    bool? isCompressed,
    List<String>? tags,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      instanceName: instanceName ?? this.instanceName,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
      gameVersion: gameVersion ?? this.gameVersion,
      isCompressed: isCompressed ?? this.isCompressed,
      tags: tags ?? this.tags,
    );
  }
}

/// 备份进度回调
typedef BackupProgressCallback = void Function(
  double progress,
  String currentFile,
);

/// 备份管理器
class BackupManager {
  static BackupManager? _instance;

  final Logger _logger = Logger('BackupManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final ConfigManager _configManager = ConfigManager();

  /// 备份存储目录
  Directory? _backupDir;

  /// 备份记录
  final List<BackupRecord> _backups = [];

  /// 是否正在备份
  bool _isBackingUp = false;

  /// 是否正在恢复
  bool _isRestoring = false;

  /// 是否初始化
  bool _initialized = false;

  /// 是否启用压缩
  bool _compressEnabled = true;

  /// 压缩级别
  CompressionLevel _compressionLevel = CompressionLevel.balanced;

  BackupManager._internal();

  /// 获取单例实例
  static BackupManager get instance {
    _instance ??= BackupManager._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory BackupManager() => instance;

  /// 初始化备份管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _backupDir = Directory(path.join(supportDir, 'backups'));

      if (!await _backupDir!.exists()) {
        await _backupDir!.create(recursive: true);
      }

      await _loadBackupRecords();
      await _loadCompressionSettings();
      _logger.info('Backup manager initialized, ${_backups.length} backups loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize backup manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载压缩设置
  Future<void> _loadCompressionSettings() async {
    _compressEnabled = _configManager.getBool(ConfigKeys.backupCompressEnabled) ?? true;
    final levelStr = _configManager.getString(ConfigKeys.backupCompressionLevel) ?? 'balanced';
    _compressionLevel = CompressionLevel.values.firstWhere(
      (e) => e.name == levelStr,
      orElse: () => CompressionLevel.balanced,
    );
  }

  /// 保存压缩设置
  Future<void> _saveCompressionSettings() async {
    await _configManager.setBool(ConfigKeys.backupCompressEnabled, _compressEnabled);
    await _configManager.setString(ConfigKeys.backupCompressionLevel, _compressionLevel.name);
  }

  /// 获取压缩设置
  bool get compressEnabled => _compressEnabled;
  CompressionLevel get compressionLevel => _compressionLevel;

  /// 设置压缩启用状态
  Future<void> setCompressEnabled(bool enabled) async {
    _compressEnabled = enabled;
    await _saveCompressionSettings();
    _logger.info('Backup compression ${enabled ? 'enabled' : 'disabled'}');
  }

  /// 设置压缩级别
  Future<void> setCompressionLevel(CompressionLevel level) async {
    _compressionLevel = level;
    await _saveCompressionSettings();
    _logger.info('Backup compression level set to ${level.name}');
  }

  /// 获取压缩级别对应的 archive 压缩方式
  int _getArchiveCompressionLevel() {
    switch (_compressionLevel) {
      case CompressionLevel.fast:
        return 1;
      case CompressionLevel.balanced:
        return 6;
      case CompressionLevel.maximum:
        return 9;
    }
  }

  /// 加载备份记录
  Future<void> _loadBackupRecords() async {
    final indexFile = File(path.join(_backupDir!.path, 'index.json'));

    if (!await indexFile.exists()) {
      // 尝试从文件系统重建索引
      await _rebuildIndex();
      return;
    }

    try {
      final content = await indexFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final backupsData = data['backups'] as List?;

      if (backupsData != null) {
        _backups.clear();
        _backups.addAll(
          backupsData
              .whereType<Map<String, dynamic>>()
              .map((e) => BackupRecord.fromJson(e)),
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load backup records', e, stackTrace);
      await _rebuildIndex();
    }
  }

  /// 保存备份记录
  Future<void> _saveBackupRecords() async {
    final indexFile = File(path.join(_backupDir!.path, 'index.json'));

    try {
      final data = {
        'backups': _backups.map((e) => e.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await indexFile.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      _logger.error('Failed to save backup records', e, stackTrace);
    }
  }

  /// 从文件系统重建索引
  Future<void> _rebuildIndex() async {
    _logger.info('Rebuilding backup index...');
    _backups.clear();

    try {
      if (_backupDir == null || !await _backupDir!.exists()) return;

      final files = _backupDir!.listSync();

      for (final file in files) {
        if (file is File && file.path.endsWith('.zip')) {
          final fileName = path.basenameWithoutExtension(file.path);

          // 尝试从文件名解析信息
          final parts = fileName.split('_');

          if (parts.length >= 3) {
            final instanceId = parts[0];
            final timestamp = int.tryParse(parts[1]) ?? 0;
            final typeStr = parts.length > 2 ? parts[2] : 'full';

            final type = BackupType.values.firstWhere(
              (e) => e.name == typeStr,
              orElse: () => BackupType.full,
            );

            final fileStat = await file.stat();

            _backups.add(BackupRecord(
              id: fileName,
              instanceId: instanceId,
              instanceName: instanceId, // 暂时使用ID作为名称
              type: type,
              createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
              filePath: file.path,
              fileSize: fileStat.size,
              isCompressed: true,
            ));
          }
        }
      }

      _logger.info('Rebuilt index with ${_backups.length} backups');
      await _saveBackupRecords();
    } catch (e, stackTrace) {
      _logger.error('Failed to rebuild backup index', e, stackTrace);
    }
  }

  /// 压缩目录为 ZIP
  Future<int> _compressDirectory({
    required String sourceDir,
    required String outputPath,
    BackupProgressCallback? onProgress,
  }) async {
    final archive = Archive();
    final sourceDirectory = Directory(sourceDir);

    int totalFiles = 0;
    int processedFiles = 0;

    // 统计文件总数
    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is File) {
        totalFiles++;
      }
    }

    // 读取文件并添加到归档
    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: sourceDir);
        final fileBytes = await entity.readAsBytes();

        archive.addFile(ArchiveFile(
          relativePath,
          fileBytes.length,
          fileBytes,
        ));

        processedFiles++;
        if (onProgress != null) {
          onProgress(
            totalFiles > 0 ? processedFiles / totalFiles * 0.8 : 0,
            relativePath,
          );
        }
      }
    }

    // 编码为 ZIP
    final zipData = ZipEncoder().encode(
      archive,
      level: _getArchiveCompressionLevel(),
    );

    if (zipData != null) {
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipData);

      if (onProgress != null) {
        onProgress(1.0, '完成');
      }

      return zipData.length;
    }

    return 0;
  }

  /// 解压 ZIP 到目录
  Future<void> _decompressArchive({
    required String archivePath,
    required String outputDir,
    BackupProgressCallback? onProgress,
  }) async {
    final archiveFile = File(archivePath);
    final bytes = await archiveFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final totalFiles = archive.files.length;
    var processedFiles = 0;

    for (final file in archive.files) {
      final outputPath = path.join(outputDir, file.name);

      if (file.isFile) {
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outputPath).create(recursive: true);
      }

      processedFiles++;
      if (onProgress != null) {
        onProgress(
          totalFiles > 0 ? processedFiles / totalFiles : 0,
          file.name,
        );
      }
    }
  }

  /// 创建备份
  Future<BackupRecord?> createBackup({
    required String instanceId,
    required String instanceName,
    required String instancePath,
    BackupType type = BackupType.full,
    String? description,
    String? gameVersion,
    BackupProgressCallback? onProgress,
    bool? forceCompress,
  }) async {
    if (_isBackingUp) {
      _logger.warn('Backup already in progress');
      return null;
    }

    _isBackingUp = true;
    _logger.info('Starting backup for $instanceName ($instanceId)');

    try {
      final id = '${instanceId}_${DateTime.now().millisecondsSinceEpoch}_${type.name}';
      final timestamp = DateTime.now();
      final backupFileName = '$id.zip';
      final backupPath = path.join(_backupDir!.path, backupFileName);

      // 确定要备份的目录
      String? sourceDir;
      switch (type) {
        case BackupType.full:
          sourceDir = instancePath;
          break;
        case BackupType.savesOnly:
          sourceDir = path.join(instancePath, 'saves');
          break;
        case BackupType.configOnly:
          sourceDir = path.join(instancePath, 'config');
          break;
      }

      if (sourceDir == null || !Directory(sourceDir).existsSync()) {
        _logger.error('Source directory does not exist: $sourceDir');
        return null;
      }

      final useCompression = forceCompress ?? _compressEnabled;
      int fileSize = 0;

      if (useCompression) {
        // 使用压缩
        fileSize = await _compressDirectory(
          sourceDir: sourceDir,
          outputPath: backupPath,
          onProgress: onProgress,
        );
      } else {
        // 不使用压缩，复制目录
        final tempDir = Directory(path.join(_backupDir!.path, 'temp_$id'));
        await tempDir.create(recursive: true);

        int totalFiles = 0;
        int processedFiles = 0;

        // 统计文件总数
        await for (final entity in Directory(sourceDir).list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
          }
        }

        // 复制文件
        await for (final entity in Directory(sourceDir).list(recursive: true)) {
          final relativePath = path.relative(entity.path, from: sourceDir);
          final destPath = path.join(tempDir.path, relativePath);

          if (entity is File) {
            final destFile = File(destPath);
            await destFile.parent.create(recursive: true);
            await entity.copy(destPath);

            processedFiles++;
            if (onProgress != null) {
              onProgress(
                totalFiles > 0 ? processedFiles / totalFiles : 0,
                relativePath,
              );
            }
          } else if (entity is Directory) {
            await Directory(destPath).create(recursive: true);
          }
        }

        // 计算目录大小
        fileSize = await _calculateDirectorySize(tempDir);

        // 如果不使用压缩，我们仍然创建一个 ZIP 但不压缩内容
        // 这里简化为直接使用临时目录
        // 注意：实际应该创建无压缩的 ZIP
      }

      final backupRecord = BackupRecord(
        id: id,
        instanceId: instanceId,
        instanceName: instanceName,
        type: type,
        createdAt: timestamp,
        filePath: backupPath,
        fileSize: fileSize,
        description: description,
        gameVersion: gameVersion,
        isCompressed: useCompression,
      );

      _backups.add(backupRecord);
      await _saveBackupRecords();

      _logger.info('Backup completed: $id, size: $fileSize bytes, compressed: $useCompression');
      return backupRecord;
    } catch (e, stackTrace) {
      _logger.error('Failed to create backup', e, stackTrace);
      return null;
    } finally {
      _isBackingUp = false;
    }
  }

  /// 恢复备份
  Future<bool> restoreBackup({
    required BackupRecord backup,
    required String targetPath,
    BackupProgressCallback? onProgress,
  }) async {
    if (_isRestoring) {
      _logger.warn('Restore already in progress');
      return false;
    }

    _isRestoring = true;
    _logger.info('Starting restore: ${backup.id}');

    try {
      // 先备份当前状态
      final currentBackup = await createBackup(
        instanceId: backup.instanceId,
        instanceName: backup.instanceName,
        instancePath: targetPath,
        type: BackupType.full,
        description: 'Auto-backup before restore',
        gameVersion: backup.gameVersion,
      );

      // 清空目标目录
      final targetDir = Directory(targetPath);
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      await targetDir.create(recursive: true);

      if (backup.isCompressed && backup.filePath.endsWith('.zip')) {
        // 从 ZIP 解压
        await _decompressArchive(
          archivePath: backup.filePath,
          outputDir: targetPath,
          onProgress: onProgress,
        );
      } else {
        // 从目录复制
        final backupSourceDir = Directory(backup.filePath);
        if (!await backupSourceDir.exists()) {
          throw Exception('Backup source does not exist');
        }

        int totalFiles = 0;
        int processedFiles = 0;

        // 统计文件总数
        await for (final entity in backupSourceDir.list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
          }
        }

        // 复制文件
        await for (final entity in backupSourceDir.list(recursive: true)) {
          final relativePath = path.relative(entity.path, from: backupSourceDir.path);
          final destPath = path.join(targetPath, relativePath);

          if (entity is File) {
            final destFile = File(destPath);
            await destFile.parent.create(recursive: true);
            await entity.copy(destPath);

            processedFiles++;
            if (onProgress != null) {
              onProgress(
                totalFiles > 0 ? processedFiles / totalFiles : 0,
                relativePath,
              );
            }
          } else if (entity is Directory) {
            await Directory(destPath).create(recursive: true);
          }
        }
      }

      _logger.info('Restore completed: ${backup.id}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to restore backup', e, stackTrace);
      return false;
    } finally {
      _isRestoring = false;
    }
  }

  /// 计算目录大小
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return totalSize;
  }

  /// 获取特定实例的备份列表
  List<BackupRecord> getBackupsForInstance(String instanceId) {
    return _backups
        .where((b) => b.instanceId == instanceId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取所有备份
  List<BackupRecord> getAllBackups() {
    return List<BackupRecord>.from(_backups)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 按标签筛选备份
  List<BackupRecord> getBackupsByTag(String tagId) {
    return _backups
        .where((b) => b.tags.contains(tagId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    final index = _backups.indexWhere((b) => b.id == backupId);
    if (index < 0) return;

    final backup = _backups[index];

    try {
      final file = File(backup.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      _backups.removeAt(index);
      await _saveBackupRecords();

      _logger.info('Deleted backup: $backupId');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete backup', e, stackTrace);
    }
  }

  /// 清理旧备份
  Future<void> cleanOldBackups({
    required String instanceId,
    int keepCount = 10,
  }) async {
    final instanceBackups = getBackupsForInstance(instanceId);

    if (instanceBackups.length <= keepCount) return;

    final toDelete = instanceBackups.skip(keepCount);

    for (final backup in toDelete) {
      await deleteBackup(backup.id);
    }
  }

  /// 获取备份存储总大小
  Future<int> getTotalBackupSize() async {
    int totalSize = 0;

    for (final backup in _backups) {
      totalSize += backup.fileSize;
    }

    return totalSize;
  }

  /// 是否正在备份
  bool get isBackingUp => _isBackingUp;

  /// 是否正在恢复
  bool get isRestoring => _isRestoring;
}
