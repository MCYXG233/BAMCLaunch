import 'dart:async';
import 'dart:convert';
import '../core/logger.dart';
import '../core/error_codes.dart';
import '../config/config_manager.dart';
import '../di/service_locator.dart';
import '../event/event_bus.dart';
import '../event/event.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';
import '../game/backup_manager.dart' deferred as backup_manager;

/// 自动备份调度类型
enum AutoBackupSchedule {
  /// 每天
  daily,

  /// 每周
  weekly,

  /// 每次启动前
  beforeLaunch,
}

/// 自动备份事件基类
abstract class AutoBackupEvent extends Event {}

/// 自动备份开始事件
class AutoBackupStartedEvent extends AutoBackupEvent {
  final String instanceId;
  final String instanceName;
  final AutoBackupSchedule schedule;

  AutoBackupStartedEvent({
    required this.instanceId,
    required this.instanceName,
    required this.schedule,
  });
}

/// 自动备份完成事件
class AutoBackupCompletedEvent extends AutoBackupEvent {
  final String instanceId;
  final String instanceName;
  final String backupId;
  final Duration duration;

  AutoBackupCompletedEvent({
    required this.instanceId,
    required this.instanceName,
    required this.backupId,
    required this.duration,
  });
}

/// 自动备份失败事件
class AutoBackupFailedEvent extends AutoBackupEvent {
  final String instanceId;
  final String instanceName;
  final String error;
  final AutoBackupSchedule schedule;

  AutoBackupFailedEvent({
    required this.instanceId,
    required this.instanceName,
    required this.error,
    required this.schedule,
  });
}

/// 自动备份配置
class AutoBackupConfig {
  /// 是否启用自动备份
  final bool enabled;

  /// 调度类型
  final AutoBackupSchedule schedule;

  /// 保留备份数量
  final int keepCount;

  /// 是否启用压缩
  final bool compress;

  AutoBackupConfig({
    this.enabled = false,
    this.schedule = AutoBackupSchedule.daily,
    this.keepCount = 5,
    this.compress = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'schedule': schedule.name,
    'keepCount': keepCount,
    'compress': compress,
  };

  factory AutoBackupConfig.fromJson(Map<String, dynamic> json) {
    return AutoBackupConfig(
      enabled: json['enabled'] as bool? ?? false,
      schedule: AutoBackupSchedule.values.firstWhere(
        (e) => e.name == json['schedule'],
        orElse: () => AutoBackupSchedule.daily,
      ),
      keepCount: json['keepCount'] as int? ?? 5,
      compress: json['compress'] as bool? ?? true,
    );
  }

  AutoBackupConfig copyWith({
    bool? enabled,
    AutoBackupSchedule? schedule,
    int? keepCount,
    bool? compress,
  }) {
    return AutoBackupConfig(
      enabled: enabled ?? this.enabled,
      schedule: schedule ?? this.schedule,
      keepCount: keepCount ?? this.keepCount,
      compress: compress ?? this.compress,
    );
  }
}

/// 自动备份服务
class AutoBackupService {
  static AutoBackupService? _instance;

  final Logger _logger = Logger('AutoBackupService');
  final EventBus _eventBus = EventBus.instance;
  final ConfigManager _configManager = ConfigManager();

  Timer? _dailyTimer;
  Timer? _weeklyTimer;
  DateTime? _lastDailyBackup;
  DateTime? _lastWeeklyBackup;

  AutoBackupConfig _config = AutoBackupConfig();
  bool _initialized = false;

  AutoBackupService._internal();

  factory AutoBackupService() {
    _instance ??= AutoBackupService._internal();
    return _instance!;
  }

  /// 获取单例实例
  static AutoBackupService get instance =>
      ServiceLocator.instance.tryGet<AutoBackupService>() ??
      (_instance ??= AutoBackupService._internal());

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadConfig();
    _initialized = true;
    _logger.info('Auto backup service initialized');

    if (_config.enabled) {
      _startScheduledBackups();
    }
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final configJson = _configManager.getString('autoBackupConfig');
    if (configJson != null) {
      try {
        _config = AutoBackupConfig.fromJson(jsonDecode(configJson));
      } catch (e) {
        _logger.error('Failed to parse auto backup config', e);
        _config = AutoBackupConfig();
      }
    }

    _lastDailyBackup = _configManager.getString('lastDailyBackup') != null
        ? DateTime.tryParse(_configManager.getString('lastDailyBackup')!)
        : null;
    _lastWeeklyBackup = _configManager.getString('lastWeeklyBackup') != null
        ? DateTime.tryParse(_configManager.getString('lastWeeklyBackup')!)
        : null;
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    await _configManager.setString('autoBackupConfig', jsonEncode(_config.toJson()));
  }

  /// 获取当前配置
  AutoBackupConfig get config => _config;

  /// 更新配置
  Future<void> updateConfig(AutoBackupConfig newConfig) async {
    final oldEnabled = _config.enabled;
    _config = newConfig;
    await _saveConfig();

    if (oldEnabled && !newConfig.enabled) {
      _stopScheduledBackups();
      _logger.info('Auto backup disabled');
    } else if (!oldEnabled && newConfig.enabled) {
      _startScheduledBackups();
      _logger.info('Auto backup enabled');
    } else if (newConfig.enabled) {
      _restartScheduledBackups();
      _logger.info('Auto backup config updated');
    }
  }

  /// 启动定时备份
  void _startScheduledBackups() {
    _stopScheduledBackups();

    switch (_config.schedule) {
      case AutoBackupSchedule.daily:
        _scheduleDailyBackup();
        break;
      case AutoBackupSchedule.weekly:
        _scheduleWeeklyBackup();
        break;
      case AutoBackupSchedule.beforeLaunch:
        break;
    }

    _logger.info('Scheduled backups started: ${_config.schedule}');
  }

  /// 停止定时备份
  void _stopScheduledBackups() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    _weeklyTimer?.cancel();
    _weeklyTimer = null;
  }

  /// 重启定时备份
  void _restartScheduledBackups() {
    _startScheduledBackups();
  }

  /// 调度每日备份
  void _scheduleDailyBackup() {
    _dailyTimer?.cancel();
    
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 3, 0, 0);
    
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    final duration = nextRun.difference(now);
    _dailyTimer = Timer(duration, () {
      _performScheduledBackup(AutoBackupSchedule.daily);
      _dailyTimer = Timer.periodic(const Duration(days: 1), (_) {
        _performScheduledBackup(AutoBackupSchedule.daily);
      });
    });
  }

  /// 调度每周备份（每周一凌晨3点）
  void _scheduleWeeklyBackup() {
    _weeklyTimer?.cancel();

    final now = DateTime.now();
    var nextMonday = now.add(Duration(days: (8 - now.weekday) % 7));
    nextMonday = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 3, 0, 0);

    if (nextMonday.isBefore(now)) {
      nextMonday = nextMonday.add(const Duration(days: 7));
    }

    final duration = nextMonday.difference(now);
    _weeklyTimer = Timer(duration, () {
      _performScheduledBackup(AutoBackupSchedule.weekly);
      _weeklyTimer = Timer.periodic(const Duration(days: 7), (_) {
        _performScheduledBackup(AutoBackupSchedule.weekly);
      });
    });
  }

  /// 执行定时备份
  Future<void> _performScheduledBackup(AutoBackupSchedule schedule) async {
    if (!_config.enabled) return;

    _logger.info('Performing scheduled backup: $schedule');

    try {
      final instanceManager = InstanceManager();
      final instances = instanceManager.instances;

      for (final instance in instances) {
        await _backupInstance(instance, schedule);
      }
    } catch (e, stackTrace) {
      _logger.error('Scheduled backup failed', e, stackTrace);
    }
  }

  /// 启动前备份
  Future<void> backupBeforeLaunch(String instanceId) async {
    if (!_config.enabled || _config.schedule != AutoBackupSchedule.beforeLaunch) {
      return;
    }

    try {
      final instanceManager = InstanceManager();
      final instance = instanceManager.instances.firstWhere(
        (i) => i.id == instanceId,
        orElse: () => throw AppException.fromCode(ErrorCodes.instanceNotFound),
      );

      await _backupInstance(instance, AutoBackupSchedule.beforeLaunch);
    } catch (e, stackTrace) {
      _logger.error('Before launch backup failed for $instanceId', e, stackTrace);
    }
  }

  /// 备份单个实例
  Future<void> _backupInstance(GameInstance instance, AutoBackupSchedule schedule) async {
    final instanceManager = InstanceManager();
    GameDirectory? directory;
    
    try {
      directory = instanceManager.directories.firstWhere(
        (d) => d.id == instance.directoryId,
      );
    } catch (e) {
      _logger.warn('Directory not found for instance: ${instance.id}');
      return;
    }

    _eventBus.publish(AutoBackupStartedEvent(
      instanceId: instance.id,
      instanceName: instance.name,
      schedule: schedule,
    ));

    final startTime = DateTime.now();

    try {
      final backupManager = await _getBackupManager();
      final backup = await backupManager.createBackup(
        instanceId: instance.id,
        instanceName: instance.name,
        instancePath: directory.path,
        type: backup_manager.BackupType.full,
        description: 'Auto backup - ${schedule.name}',
        gameVersion: instance.version,
      );

      if (backup != null) {
        await _enforceKeepCount(instance.id);

        _eventBus.publish(AutoBackupCompletedEvent(
          instanceId: instance.id,
          instanceName: instance.name,
          backupId: backup.id,
          duration: DateTime.now().difference(startTime),
        ));

        await _updateLastBackupTime(schedule);
        _logger.info('Auto backup completed for ${instance.name}');
      } else {
        throw AppException.fromCode(ErrorCodes.backupCreateFailed);
      }
    } catch (e, stackTrace) {
      _eventBus.publish(AutoBackupFailedEvent(
        instanceId: instance.id,
        instanceName: instance.name,
        error: e.toString(),
        schedule: schedule,
      ));
      _logger.error('Auto backup failed for ${instance.name}', e, stackTrace);
    }
  }

  /// 获取备份管理器（延迟导入避免循环依赖）
  Future<dynamic> _getBackupManager() async {
    final backupManager = await _importBackupManager();
    await backupManager.initialize();
    return backupManager;
  }

  Future<dynamic> _importBackupManager() async {
    await backup_manager.loadLibrary();
    return backup_manager.BackupManager.instance;
  }

  /// 执行保留数量限制
  Future<void> _enforceKeepCount(String instanceId) async {
    final backupManager = await _getBackupManager();
    final backups = backupManager.getBackupsForInstance(instanceId);

    if (backups.length > _config.keepCount) {
      final toDelete = backups.skip(_config.keepCount);
      for (final backup in toDelete) {
        await backupManager.deleteBackup(backup.id);
      }
      _logger.info('Cleaned old backups for $instanceId, kept ${_config.keepCount}');
    }
  }

  /// 更新最后备份时间
  Future<void> _updateLastBackupTime(AutoBackupSchedule schedule) async {
    final now = DateTime.now().toIso8601String();
    switch (schedule) {
      case AutoBackupSchedule.daily:
        await _configManager.setString('lastDailyBackup', now);
        _lastDailyBackup = DateTime.now();
        break;
      case AutoBackupSchedule.weekly:
        await _configManager.setString('lastWeeklyBackup', now);
        _lastWeeklyBackup = DateTime.now();
        break;
      case AutoBackupSchedule.beforeLaunch:
        break;
    }
  }

  /// 获取最后备份时间
  DateTime? getLastBackupTime(AutoBackupSchedule schedule) {
    switch (schedule) {
      case AutoBackupSchedule.daily:
        return _lastDailyBackup;
      case AutoBackupSchedule.weekly:
        return _lastWeeklyBackup;
      case AutoBackupSchedule.beforeLaunch:
        return null;
    }
  }

  /// 手动触发备份
  Future<void> triggerManualBackup() async {
    if (_config.enabled) {
      await _performScheduledBackup(_config.schedule);
    }
  }

  /// 释放资源
  void dispose() {
    _stopScheduledBackups();
  }
}
