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

  /// 准备好的时间
  DateTime? readyTime;

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
    this.readyTime,
    this.stopTime,
    this.exitCode,
    this.errorMessage,
    List<GameLog>? logs,
  }) : logs = logs ?? [];

  /// 是否正在运行
  bool get isRunning =>
      status == GameProcessStatus.starting ||
      status == GameProcessStatus.running;

  /// 运行时长（从启动到停止）
  Duration get duration {
    final end = stopTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// 精确游戏时长（从游戏就绪到停止，这才是真正的游戏时长）
  Duration get accuratePlayTime {
    if (readyTime == null) return Duration.zero;
    final end = stopTime ?? DateTime.now();
    return end.difference(readyTime!);
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
    DateTime? readyTime,
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
      readyTime: readyTime ?? this.readyTime,
      stopTime: stopTime ?? this.stopTime,
      exitCode: exitCode ?? this.exitCode,
      errorMessage: errorMessage ?? this.errorMessage,
      logs: logs ?? this.logs,
    );
  }
}

enum LaunchError {
  modLoaderNotInstalled,
  noSuitableJava,
  selectedJavaUnavailable,
  gameFilesIncomplete,
  launchingStateNotFound,
  authlibInjectorNotReady,
  authServerNotFound,
  playerValidationFailed,
  launchCommandBuildFailed,
  processStartFailed,
}

class LaunchCommand {
  final List<String> classPaths;
  final List<String> args;

  const LaunchCommand({
    required this.classPaths,
    required this.args,
  });

  String get fullCommand => args.join(' ');
}

class LaunchingState {
  final String id;
  final int currentStep;
  final String? javaPath;
  final int? javaVersion;
  final String gameVersion;
  final String gameDirectory;
  final Map<String, dynamic>? versionJson;
  final String? accountId;
  final String? accountName;
  final String? accountUuid;
  final String? accountToken;
  final String? authServerUrl;
  final String? authServerMeta;
  final int memory;
  final List<String> jvmArgs;
  final String? serverAddress;
  final int? serverPort;
  final String? fullCommand;
  final int? pid;
  final DateTime startTime;
  final DateTime? readyTime;
  final String? errorMessage;

  LaunchingState({
    required this.id,
    required this.currentStep,
    this.javaPath,
    this.javaVersion,
    required this.gameVersion,
    required this.gameDirectory,
    this.versionJson,
    this.accountId,
    this.accountName,
    this.accountUuid,
    this.accountToken,
    this.authServerUrl,
    this.authServerMeta,
    required this.memory,
    required this.jvmArgs,
    this.serverAddress,
    this.serverPort,
    this.fullCommand,
    this.pid,
    required this.startTime,
    this.readyTime,
    this.errorMessage,
  });

  LaunchingState copyWith({
    String? id,
    int? currentStep,
    String? javaPath,
    int? javaVersion,
    String? gameVersion,
    String? gameDirectory,
    Map<String, dynamic>? versionJson,
    String? accountId,
    String? accountName,
    String? accountUuid,
    String? accountToken,
    String? authServerUrl,
    String? authServerMeta,
    int? memory,
    List<String>? jvmArgs,
    String? serverAddress,
    int? serverPort,
    String? fullCommand,
    int? pid,
    DateTime? startTime,
    DateTime? readyTime,
    String? errorMessage,
  }) {
    return LaunchingState(
      id: id ?? this.id,
      currentStep: currentStep ?? this.currentStep,
      javaPath: javaPath ?? this.javaPath,
      javaVersion: javaVersion ?? this.javaVersion,
      gameVersion: gameVersion ?? this.gameVersion,
      gameDirectory: gameDirectory ?? this.gameDirectory,
      versionJson: versionJson ?? this.versionJson,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      accountUuid: accountUuid ?? this.accountUuid,
      accountToken: accountToken ?? this.accountToken,
      authServerUrl: authServerUrl ?? this.authServerUrl,
      authServerMeta: authServerMeta ?? this.authServerMeta,
      memory: memory ?? this.memory,
      jvmArgs: jvmArgs ?? this.jvmArgs,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
      fullCommand: fullCommand ?? this.fullCommand,
      pid: pid ?? this.pid,
      startTime: startTime ?? this.startTime,
      readyTime: readyTime ?? this.readyTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentStep': currentStep,
      'javaPath': javaPath,
      'javaVersion': javaVersion,
      'gameVersion': gameVersion,
      'gameDirectory': gameDirectory,
      'versionJson': versionJson,
      'accountId': accountId,
      'accountName': accountName,
      'accountUuid': accountUuid,
      'accountToken': accountToken,
      'authServerUrl': authServerUrl,
      'authServerMeta': authServerMeta,
      'memory': memory,
      'jvmArgs': jvmArgs,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
      'fullCommand': fullCommand,
      'pid': pid,
      'startTime': startTime.toIso8601String(),
      'readyTime': readyTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory LaunchingState.fromJson(Map<String, dynamic> json) {
    return LaunchingState(
      id: json['id'] as String,
      currentStep: json['currentStep'] as int,
      javaPath: json['javaPath'] as String?,
      javaVersion: json['javaVersion'] as int?,
      gameVersion: json['gameVersion'] as String,
      gameDirectory: json['gameDirectory'] as String,
      versionJson: json['versionJson'] as Map<String, dynamic>?,
      accountId: json['accountId'] as String?,
      accountName: json['accountName'] as String?,
      accountUuid: json['accountUuid'] as String?,
      accountToken: json['accountToken'] as String?,
      authServerUrl: json['authServerUrl'] as String?,
      authServerMeta: json['authServerMeta'] as String?,
      memory: json['memory'] as int,
      jvmArgs: (json['jvmArgs'] as List<dynamic>).cast<String>(),
      serverAddress: json['serverAddress'] as String?,
      serverPort: json['serverPort'] as int?,
      fullCommand: json['fullCommand'] as String?,
      pid: json['pid'] as int?,
      startTime: DateTime.parse(json['startTime'] as String),
      readyTime: json['readyTime'] != null
          ? DateTime.parse(json['readyTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  bool get isRunning => currentStep > 0 && (pid == null || pid! > 0);

  Duration get totalDuration {
    final end = readyTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get stepDescription {
    switch (currentStep) {
      case 1:
        return '选择Java';
      case 2:
        return '校验文件';
      case 3:
        return '验证账号';
      case 4:
        return '启动游戏';
      default:
        return '未知步骤';
    }
  }
}

enum FileValidatePolicy {
  disable,
  normal,
  full,
}

class GameConfig {
  final int memory;
  final List<String> jvmArgs;
  final String gcStrategy;
  final FileValidatePolicy fileValidatePolicy;
  final bool autoJoinServer;
  final String serverAddress;
  final int serverPort;
  final String launcherVisibility;
  final bool displayGameLog;
  final String customTitle;
  final String customInfo;
  final String wrapperLauncher;
  final String precallCommand;
  final String postExitCommand;
  final String minecraftArgument;
  final bool useNativeGlfw;
  final bool useNativeOpenal;
  final bool noJvmArgs;
  final bool useLwjglUnsafeAgent;
  final bool fullscreen;
  final int resolutionWidth;
  final int resolutionHeight;

  const GameConfig({
    this.memory = 1024,
    this.jvmArgs = const [],
    this.gcStrategy = 'auto',
    this.fileValidatePolicy = FileValidatePolicy.normal,
    this.autoJoinServer = false,
    this.serverAddress = '',
    this.serverPort = 25565,
    this.launcherVisibility = 'always',
    this.displayGameLog = false,
    this.customTitle = '',
    this.customInfo = '',
    this.wrapperLauncher = '',
    this.precallCommand = '',
    this.postExitCommand = '',
    this.minecraftArgument = '',
    this.useNativeGlfw = true,
    this.useNativeOpenal = true,
    this.noJvmArgs = false,
    this.useLwjglUnsafeAgent = false,
    this.fullscreen = false,
    this.resolutionWidth = 854,
    this.resolutionHeight = 480,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      memory: json['memory'] as int? ?? 1024,
      jvmArgs: (json['jvmArgs'] as List<dynamic>?)?.cast<String>() ?? const [],
      gcStrategy: json['gcStrategy'] as String? ?? 'auto',
      fileValidatePolicy: FileValidatePolicy.values.firstWhere(
        (e) => e.name == json['fileValidatePolicy'],
        orElse: () => FileValidatePolicy.normal,
      ),
      autoJoinServer: json['autoJoinServer'] as bool? ?? false,
      serverAddress: json['serverAddress'] as String? ?? '',
      serverPort: json['serverPort'] as int? ?? 25565,
      launcherVisibility: json['launcherVisibility'] as String? ?? 'always',
      displayGameLog: json['displayGameLog'] as bool? ?? false,
      customTitle: json['customTitle'] as String? ?? '',
      customInfo: json['customInfo'] as String? ?? '',
      wrapperLauncher: json['wrapperLauncher'] as String? ?? '',
      precallCommand: json['precallCommand'] as String? ?? '',
      postExitCommand: json['postExitCommand'] as String? ?? '',
      minecraftArgument: json['minecraftArgument'] as String? ?? '',
      useNativeGlfw: json['useNativeGlfw'] as bool? ?? true,
      useNativeOpenal: json['useNativeOpenal'] as bool? ?? true,
      noJvmArgs: json['noJvmArgs'] as bool? ?? false,
      useLwjglUnsafeAgent: json['useLwjglUnsafeAgent'] as bool? ?? false,
      fullscreen: json['fullscreen'] as bool? ?? false,
      resolutionWidth: json['resolutionWidth'] as int? ?? 854,
      resolutionHeight: json['resolutionHeight'] as int? ?? 480,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory': memory,
      'jvmArgs': jvmArgs,
      'gcStrategy': gcStrategy,
      'fileValidatePolicy': fileValidatePolicy.name,
      'autoJoinServer': autoJoinServer,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
      'launcherVisibility': launcherVisibility,
      'displayGameLog': displayGameLog,
      'customTitle': customTitle,
      'customInfo': customInfo,
      'wrapperLauncher': wrapperLauncher,
      'precallCommand': precallCommand,
      'postExitCommand': postExitCommand,
      'minecraftArgument': minecraftArgument,
      'useNativeGlfw': useNativeGlfw,
      'useNativeOpenal': useNativeOpenal,
      'noJvmArgs': noJvmArgs,
      'useLwjglUnsafeAgent': useLwjglUnsafeAgent,
      'fullscreen': fullscreen,
      'resolutionWidth': resolutionWidth,
      'resolutionHeight': resolutionHeight,
    };
  }
}
