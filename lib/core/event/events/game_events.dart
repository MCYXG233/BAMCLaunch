import '../app_event.dart';

/// 游戏状态枚举
enum GameState {
  idle,
  preparing,
  downloading,
  launching,
  running,
  crashed,
  stopped,
}

/// 游戏状态变更事件
class GameStateChangedEvent extends AppEvent {
  final String versionId;
  final GameState oldState;
  final GameState newState;

  GameStateChangedEvent({
    required this.versionId,
    required this.oldState,
    required this.newState,
  });
}

/// 游戏启动事件
class GameLaunchedEvent extends AppEvent {
  final String versionId;
  final int pid;

  GameLaunchedEvent({
    required this.versionId,
    required this.pid,
  });
}

/// 游戏退出事件
class GameExitedEvent extends AppEvent {
  final String versionId;
  final int exitCode;

  GameExitedEvent({
    required this.versionId,
    required this.exitCode,
  });
}

/// 游戏崩溃事件
class GameCrashedEvent extends AppEvent {
  final String versionId;
  final int exitCode;
  final String? crashReport;
  final List<String> possibleCauses;

  GameCrashedEvent({
    required this.versionId,
    required this.exitCode,
    this.crashReport,
    required this.possibleCauses,
  });

  @override
  bool get isCancelable => false;
}

/// 游戏日志输出事件
class GameLogEvent extends AppEvent {
  final String versionId;
  final String logLine;
  final bool isError;

  GameLogEvent({
    required this.versionId,
    required this.logLine,
    this.isError = false,
  });
}
