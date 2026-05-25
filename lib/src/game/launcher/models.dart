import '../../account/account.dart';

/// 游戏进程状态枚举
enum GameProcessStatus {
  /// 启动中
  starting,

  /// 运行中
  running,

  /// 已停止
  stopped,

  /// 已崩溃
  crashed,
}

/// 游戏日志级别
enum GameLogLevel {
  /// 调试
  debug,

  /// 信息
  info,

  /// 警告
  warn,

  /// 错误
  error,
}

/// 游戏日志
class GameLog {
  /// 时间戳
  final DateTime timestamp;

  /// 日志级别
  final GameLogLevel level;

  /// 日志消息
  final String message;

  /// 日志来源（stdout/stderr）
  final String source;

  GameLog({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.source,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'source': source,
    };
  }

  /// 从JSON创建
  factory GameLog.fromJson(Map<String, dynamic> json) {
    return GameLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: GameLogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => GameLogLevel.info,
      ),
      message: json['message'] as String,
      source: json['source'] as String,
    );
  }

  /// 格式化日志
  String format() {
    final levelStr = level.name.toUpperCase().padRight(5);
    return '[${timestamp.toLocal().toString().substring(0, 23)}] [$levelStr] [$source] $message';
  }
}

/// 启动参数
class LaunchArguments {
  /// Java路径
  final String javaPath;

  /// 游戏版本
  final String gameVersion;

  /// 账户
  final Account account;

  /// 游戏目录
  final String gameDirectory;

  /// 内存大小（MB）
  final int memory;

  /// JVM参数
  final List<String> jvmArguments;

  /// 游戏参数
  final List<String> gameArguments;

  /// 服务器地址（可选）
  final String? serverAddress;

  /// 服务器端口（可选）
  final int? serverPort;

  LaunchArguments({
    required this.javaPath,
    required this.gameVersion,
    required this.account,
    required this.gameDirectory,
    required this.memory,
    required this.jvmArguments,
    required this.gameArguments,
    this.serverAddress,
    this.serverPort,
  });

  /// 创建副本
  LaunchArguments copyWith({
    String? javaPath,
    String? gameVersion,
    Account? account,
    String? gameDirectory,
    int? memory,
    List<String>? jvmArguments,
    List<String>? gameArguments,
    String? serverAddress,
    int? serverPort,
  }) {
    return LaunchArguments(
      javaPath: javaPath ?? this.javaPath,
      gameVersion: gameVersion ?? this.gameVersion,
      account: account ?? this.account,
      gameDirectory: gameDirectory ?? this.gameDirectory,
      memory: memory ?? this.memory,
      jvmArguments: jvmArguments ?? this.jvmArguments,
      gameArguments: gameArguments ?? this.gameArguments,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'javaPath': javaPath,
      'gameVersion': gameVersion,
      'account': account.toJson(),
      'gameDirectory': gameDirectory,
      'memory': memory,
      'jvmArguments': jvmArguments,
      'gameArguments': gameArguments,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
    };
  }
}

/// 游戏进程信息
class GameProcessInfo {
  /// 进程ID（内部唯一标识）
  final String processId;

  /// 启动参数
  final LaunchArguments arguments;

  /// 进程状态
  GameProcessStatus status;

  /// 进程PID
  int? pid;

  /// 启动时间
  final DateTime startTime;

  /// 停止时间
  DateTime? stopTime;

  /// 退出代码
  int? exitCode;

  /// 错误信息
  String? errorMessage;

  /// 日志列表
  final List<GameLog> logs;

  GameProcessInfo({
    required this.processId,
    required this.arguments,
    required this.status,
    this.pid,
    required this.startTime,
    this.stopTime,
    this.exitCode,
    this.errorMessage,
    List<GameLog>? logs,
  }) : logs = logs ?? [];

  /// 是否正在运行
  bool get isRunning =>
      status == GameProcessStatus.starting ||
      status == GameProcessStatus.running;

  /// 运行时长
  Duration get duration {
    final end = stopTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// 添加日志
  void addLog(GameLog log) {
    logs.add(log);
    if (logs.length > 1000) {
      logs.removeAt(0);
    }
  }

  /// 获取最近的日志
  List<GameLog> getRecentLogs(int count) {
    if (logs.length <= count) return List.from(logs);
    return logs.sublist(logs.length - count);
  }

  /// 创建副本
  GameProcessInfo copyWith({
    String? processId,
    LaunchArguments? arguments,
    GameProcessStatus? status,
    int? pid,
    DateTime? startTime,
    DateTime? stopTime,
    int? exitCode,
    String? errorMessage,
    List<GameLog>? logs,
  }) {
    return GameProcessInfo(
      processId: processId ?? this.processId,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      pid: pid ?? this.pid,
      startTime: startTime ?? this.startTime,
      stopTime: stopTime ?? this.stopTime,
      exitCode: exitCode ?? this.exitCode,
      errorMessage: errorMessage ?? this.errorMessage,
      logs: logs ?? this.logs,
    );
  }
}
