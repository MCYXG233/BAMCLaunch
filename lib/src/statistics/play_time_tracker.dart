import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../game/game_statistics.dart';

/// 实例时长排行榜条目
class PlayTimeEntry {
  final String instanceId;
  final String instanceName;
  final int playTimeSeconds;
  final int launchCount;
  final DateTime? lastPlayed;

  PlayTimeEntry({
    required this.instanceId,
    required this.instanceName,
    required this.playTimeSeconds,
    required this.launchCount,
    this.lastPlayed,
  });

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'instanceName': instanceName,
      'playTimeSeconds': playTimeSeconds,
      'launchCount': launchCount,
      'lastPlayed': lastPlayed?.toIso8601String(),
    };
  }

  factory PlayTimeEntry.fromJson(Map<String, dynamic> json) {
    return PlayTimeEntry(
      instanceId: json['instanceId'] as String,
      instanceName: json['instanceName'] as String,
      playTimeSeconds: json['playTimeSeconds'] as int,
      launchCount: json['launchCount'] as int,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'] as String)
          : null,
    );
  }
}

/// 精确计时器状态
enum PlayTimeTrackerState {
  idle,
  running,
  paused,
}

/// 游戏时长追踪器
/// 提供精确计时功能，支持在实例维度累计游戏时长
class PlayTimeTracker {
  static PlayTimeTracker? _instance;

  final Logger _logger = Logger('PlayTimeTracker');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final GameStatisticsManager _statisticsManager = GameStatisticsManager.instance;

  /// 数据文件
  File? _dataFile;

  /// 实例时长累计数据
  final Map<String, PlayTimeEntry> _instancePlayTimes = {};

  /// 当前正在计时的实例ID
  String? _currentTrackingInstanceId;

  /// 当前会话开始时间
  DateTime? _sessionStartTime;

  /// 当前已累计的时长（秒），用于暂停/恢复
  int _accumulatedSeconds = 0;

  /// 计时器状态
  PlayTimeTrackerState _state = PlayTimeTrackerState.idle;

  /// 计时器
  Timer? _timer;

  /// 是否已初始化
  bool _initialized = false;

  PlayTimeTracker._internal();

  /// 获取单例实例
  static PlayTimeTracker get instance {
    _instance ??= PlayTimeTracker._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory PlayTimeTracker() => instance;

  /// 初始化追踪器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      final dataPath = path.join(supportDir, 'statistics');
      final dataDir = Directory(dataPath);

      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      _dataFile = File(path.join(dataPath, 'play_time_tracker.json'));

      if (await _dataFile!.exists()) {
        await _loadData();
      }

      _logger.info('Play time tracker initialized, ${_instancePlayTimes.length} entries loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize play time tracker', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载数据
  Future<void> _loadData() async {
    if (_dataFile == null) return;

    try {
      final content = await _dataFile!.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final entries = data['entries'] as Map<String, dynamic>?;
      if (entries != null) {
        _instancePlayTimes.clear();
        entries.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _instancePlayTimes[key] = PlayTimeEntry.fromJson(value);
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load play time data', e, stackTrace);
    }
  }

  /// 保存数据
  Future<void> _saveData() async {
    if (_dataFile == null) return;

    try {
      final data = {
        'entries': _instancePlayTimes.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _dataFile!.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      _logger.error('Failed to save play time data', e, stackTrace);
    }
  }

  /// 开始计时
  /// 在游戏就绪后开始计时
  Future<void> startTracking(String instanceId, String instanceName) async {
    if (_state == PlayTimeTrackerState.running) {
      _logger.warning('Already tracking instance: $_currentTrackingInstanceId');
      return;
    }

    await initialize();

    _currentTrackingInstanceId = instanceId;
    _sessionStartTime = DateTime.now();
    _accumulatedSeconds = 0;
    _state = PlayTimeTrackerState.running;

    _startTimer();

    _logger.info('Started tracking play time for instance: $instanceName ($instanceId)');
  }

  /// 暂停计时
  void pauseTracking() {
    if (_state != PlayTimeTrackerState.running) return;

    _stopTimer();
    _state = PlayTimeTrackerState.paused;

    _logger.info('Paused tracking for instance: $_currentTrackingInstanceId');
  }

  /// 恢复计时
  void resumeTracking() {
    if (_state != PlayTimeTrackerState.paused) return;

    _state = PlayTimeTrackerState.running;
    _startTimer();

    _logger.info('Resumed tracking for instance: $_currentTrackingInstanceId');
  }

  /// 停止计时并保存
  /// [exitCode] 游戏退出代码
  Future<void> stopTracking({int? exitCode}) async {
    if (_state == PlayTimeTrackerState.idle) return;

    _stopTimer();

    if (_currentTrackingInstanceId != null && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      final totalDuration = _accumulatedSeconds + sessionDuration;

      // 更新实例累计时长
      await _updateInstancePlayTime(_currentTrackingInstanceId!, totalDuration);

      // 同时通知GameStatisticsManager
      final entry = _instancePlayTimes[_currentTrackingInstanceId];
      if (entry != null) {
        _statisticsManager.startSession(
          instanceName: entry.instanceName,
          instanceId: _currentTrackingInstanceId!,
          gameVersion: '',
        );
        await _statisticsManager.endSession(exitCode: exitCode);
      }
    }

    _currentTrackingInstanceId = null;
    _sessionStartTime = null;
    _accumulatedSeconds = 0;
    _state = PlayTimeTrackerState.idle;

    _logger.info('Stopped tracking');
  }

  /// 更新实例累计时长
  Future<void> _updateInstancePlayTime(String instanceId, int additionalSeconds) async {
    final existing = _instancePlayTimes[instanceId];

    if (existing != null) {
      _instancePlayTimes[instanceId] = PlayTimeEntry(
        instanceId: instanceId,
        instanceName: existing.instanceName,
        playTimeSeconds: existing.playTimeSeconds + additionalSeconds,
        launchCount: existing.launchCount + 1,
        lastPlayed: DateTime.now(),
      );
    } else {
      _instancePlayTimes[instanceId] = PlayTimeEntry(
        instanceId: instanceId,
        instanceName: existing?.instanceName ?? 'Unknown',
        playTimeSeconds: additionalSeconds,
        launchCount: 1,
        lastPlayed: DateTime.now(),
      );
    }

    await _saveData();
  }

  /// 获取指定实例的累计时长
  PlayTimeEntry? getInstancePlayTime(String instanceId) {
    return _instancePlayTimes[instanceId];
  }

  /// 获取所有实例的累计时长列表
  List<PlayTimeEntry> getAllInstancePlayTimes() {
    return _instancePlayTimes.values.toList();
  }

  /// 获取时长排行榜（Top N）
  List<PlayTimeEntry> getTopPlayTimeEntries({int limit = 10}) {
    final entries = _instancePlayTimes.values.toList()
      ..sort((a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds));

    return entries.take(limit).toList();
  }

  /// 获取当前正在计时的实例ID
  String? get currentTrackingInstanceId => _currentTrackingInstanceId;

  /// 获取当前状态
  PlayTimeTrackerState get state => _state;

  /// 获取当前会话已累计的时长（秒）
  int get currentSessionSeconds {
    if (_state == PlayTimeTrackerState.running && _sessionStartTime != null) {
      return _accumulatedSeconds + DateTime.now().difference(_sessionStartTime!).inSeconds;
    }
    return _accumulatedSeconds;
  }

  /// 格式化时长
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}小时${minutes}分钟${secs}秒';
    } else if (minutes > 0) {
      return '${minutes}分钟${secs}秒';
    } else {
      return '${secs}秒';
    }
  }

  /// 启动计时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 计时器运行中，每秒触发一次更新
      // 可以在这里通知UI更新
    });
  }

  /// 停止计时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 获取总游戏时长
  Duration getTotalPlayTime() {
    int total = 0;
    for (final entry in _instancePlayTimes.values) {
      total += entry.playTimeSeconds;
    }
    return Duration(seconds: total);
  }

  /// 获取今日游戏时长
  Duration getTodayPlayTime() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int total = 0;
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      if (session.startTime.isAfter(todayStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取本周游戏时长
  Duration getWeekPlayTime() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int total = 0;
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      if (session.startTime.isAfter(weekStartDate)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取本月游戏时长
  Duration getMonthPlayTime() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    int total = 0;
    final sessions = _statisticsManager.getAllSessions();
    for (final session in sessions) {
      if (session.startTime.isAfter(monthStart)) {
        total += session.playTimeSeconds;
      }
    }
    return Duration(seconds: total);
  }

  /// 获取每日游戏时长数据（用于图表）
  Map<DateTime, int> getDailyPlayTimeData({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (var i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[date] = 0;
    }

    final sessions = _statisticsManager.getAllSessions(limit: 1000);
    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (result.containsKey(sessionDate)) {
        result[sessionDate] = result[sessionDate]! + session.playTimeSeconds;
      }
    }

    return result;
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    _instancePlayTimes.clear();
    await _saveData();
    _logger.info('Cleared all play time data');
  }

  /// 释放资源
  void dispose() {
    _stopTimer();
  }
}
