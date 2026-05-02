import 'dart:async';
import 'models/game_launch_models.dart';

/// 游戏启动管理器
/// 参考 HMCL 的任务系统设计，提供统一的游戏启动管理
class GameLaunchManager {
  /// 当前启动配置
  GameLaunchConfig? _currentConfig;

  /// 启动状态流控制器
  final StreamController<GameLaunchEvent> _eventController =
      StreamController<GameLaunchEvent>.broadcast();

  /// 启动历史记录
  final List<LaunchHistoryEntry> _history = [];

  /// 最大历史记录数
  final int maxHistoryCount;

  /// 构造函数
  GameLaunchManager({
    this.maxHistoryCount = 100,
  });

  /// 启动事件流
  Stream<GameLaunchEvent> get eventStream => _eventController.stream;

  /// 获取当前启动配置
  GameLaunchConfig? get currentConfig => _currentConfig;

  /// 获取启动历史
  List<LaunchHistoryEntry> get history => List.unmodifiable(_history);

  /// 记录启动开始
  /// [config]: 启动配置
  void recordLaunchStart(GameLaunchConfig config) {
    _currentConfig = config;

    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.started,
      config: config,
      timestamp: DateTime.now(),
    ));

    _addToHistory(LaunchHistoryEntry(
      gameVersion: config.gameVersion,
      username: config.username,
      startTime: DateTime.now(),
      status: GameLaunchHistoryStatus.running,
    ));
  }

  /// 记录启动成功
  void recordLaunchSuccess() {
    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.success,
      config: _currentConfig,
      timestamp: DateTime.now(),
    ));

    if (_history.isNotEmpty) {
      _history.last.status = GameLaunchHistoryStatus.success;
      _history.last.endTime = DateTime.now();
    }
  }

  /// 记录启动失败
  /// [error]: 错误信息
  void recordLaunchFailure(String error) {
    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.failed,
      config: _currentConfig,
      error: error,
      timestamp: DateTime.now(),
    ));

    if (_history.isNotEmpty) {
      _history.last.status = GameLaunchHistoryStatus.failed;
      _history.last.endTime = DateTime.now();
      _history.last.error = error;
    }
  }

  /// 记录游戏退出
  /// [exitCode]: 退出码
  void recordGameExit(int exitCode) {
    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.exited,
      config: _currentConfig,
      exitCode: exitCode,
      timestamp: DateTime.now(),
    ));

    if (_history.isNotEmpty) {
      _history.last.status = exitCode == 0 ? GameLaunchHistoryStatus.success : GameLaunchHistoryStatus.failed;
      _history.last.endTime = DateTime.now();
      _history.last.exitCode = exitCode;
    }

    _currentConfig = null;
  }

  /// 记录崩溃
  /// [crashLog]: 崩溃日志
  /// [analysis]: 崩溃分析
  void recordCrash(String crashLog, String analysis) {
    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.crashed,
      config: _currentConfig,
      crashLog: crashLog,
      analysis: analysis,
      timestamp: DateTime.now(),
    ));

    if (_history.isNotEmpty) {
      _history.last.status = GameLaunchHistoryStatus.crashed;
      _history.last.endTime = DateTime.now();
      _history.last.crashLog = crashLog;
      _history.last.analysis = analysis;
    }
  }

  /// 记录状态变更
  /// [status]: 新状态
  void recordStatusChange(GameLaunchStatus status) {
    _eventController.add(GameLaunchEvent(
      type: GameLaunchEventType.statusChanged,
      config: _currentConfig,
      status: status,
      timestamp: DateTime.now(),
    ));
  }

  /// 添加到历史记录
  /// [entry]: 历史记录条目
  void _addToHistory(LaunchHistoryEntry entry) {
    _history.insert(0, entry);

    // 限制历史记录数量
    if (_history.length > maxHistoryCount) {
      _history.removeLast();
    }
  }

  /// 获取最近的启动记录
  /// [count]: 记录数量
  /// 返回最近的启动记录列表
  List<LaunchHistoryEntry> getRecentLaunches({int count = 10}) {
    return _history.take(count).toList();
  }

  /// 获取指定版本的启动记录
  /// [gameVersion]: 游戏版本
  /// 返回该版本的启动记录列表
  List<LaunchHistoryEntry> getLaunchesByVersion(String gameVersion) {
    return _history
        .where((entry) => entry.gameVersion == gameVersion)
        .toList();
  }

  /// 获取成功的启动次数
  int get successCount =>
      _history.where((entry) => entry.status == GameLaunchHistoryStatus.success).length;

  /// 获取失败的启动次数
  int get failureCount =>
      _history.where((entry) => entry.status == GameLaunchHistoryStatus.failed).length;

  /// 获取崩溃的启动次数
  int get crashCount =>
      _history.where((entry) => entry.status == GameLaunchHistoryStatus.crashed).length;

  /// 清理历史记录
  void clearHistory() {
    _history.clear();
  }

  /// 关闭管理器
  void dispose() {
    _eventController.close();
  }
}

/// 游戏启动事件
class GameLaunchEvent {
  final GameLaunchEventType type;
  final GameLaunchConfig? config;
  final GameLaunchStatus? status;
  final String? error;
  final String? crashLog;
  final String? analysis;
  final int? exitCode;
  final DateTime timestamp;

  GameLaunchEvent({
    required this.type,
    this.config,
    this.status,
    this.error,
    this.crashLog,
    this.analysis,
    this.exitCode,
    required this.timestamp,
  });
}

/// 游戏启动事件类型
enum GameLaunchEventType {
  /// 启动开始
  started,

  /// 启动成功
  success,

  /// 启动失败
  failed,

  /// 游戏退出
  exited,

  /// 游戏崩溃
  crashed,

  /// 状态变更
  statusChanged,
}

/// 启动历史记录条目
class LaunchHistoryEntry {
  final String gameVersion;
  final String username;
  final DateTime startTime;
  DateTime? endTime;
  GameLaunchHistoryStatus status;
  String? error;
  int? exitCode;
  String? crashLog;
  String? analysis;

  LaunchHistoryEntry({
    required this.gameVersion,
    required this.username,
    required this.startTime,
    this.endTime,
    required this.status,
    this.error,
    this.exitCode,
    this.crashLog,
    this.analysis,
  });

  /// 获取启动时长（秒）
  int? get durationInSeconds {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inSeconds;
  }
}

/// 启动状态
enum GameLaunchHistoryStatus {
  /// 运行中
  running,

  /// 成功
  success,

  /// 失败
  failed,

  /// 崩溃
  crashed,
}
