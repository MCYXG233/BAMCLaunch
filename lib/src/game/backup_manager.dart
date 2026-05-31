import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';

/// 备份类型
enum BackupType {
  /// 完整备份（所有内容）
  full,

  /// 仅备份存档
  savesOnly,

  /// 仅备份配置
  configOnly,
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
      _logger.info('Backup manager initialized, ${_backups.length} backups loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize backup manager', e, stackTrace);
      _initialized = true;
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

  /// 创建备份
  Future<BackupRecord?> createBackup({
    required String instanceId,
    required String instanceName,
    required String instancePath,
    BackupType type = BackupType.full,
    String? description,
    String? gameVersion,
    BackupProgressCallback? onProgress,
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

      // 简单实现：复制目录（实际应该用zip压缩）
      // 这里使用简单的目录复制作为示例
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

      // 创建记录（实际应该是zip文件）
      // 这里为了简化，我们记录临时目录
      final backupRecord = BackupRecord(
        id: id,
        instanceId: instanceId,
        instanceName: instanceName,
        type: type,
        createdAt: timestamp,
        filePath: tempDir.path, // 实际应该是zip文件路径
        fileSize: await _calculateDirectorySize(tempDir),
        description: description,
        gameVersion: gameVersion,
      );

      _backups.add(backupRecord);
      await _saveBackupRecords();

      _logger.info('Backup completed: $id');
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

      // 从备份复制（实际应该从zip解压）
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

  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    final index = _backups.indexWhere((b) => b.id == backupId);
    if (index < 0) return;

    final backup = _backups[index];

    try {
      final file = File(backup.filePath);
      if (await file.exists()) {
        if (file is Directory) {
          await file.delete(recursive: true);
        } else {
          await file.delete();
        }
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
