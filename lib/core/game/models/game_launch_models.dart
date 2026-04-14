class JavaDetectionResult {
  final bool found;
  final String? javaPath;
  final String? version;
  final String? error;

  JavaDetectionResult({
    required this.found,
    this.javaPath,
    this.version,
    this.error,
  });
}

/// 游戏启动状态枚举
enum GameLaunchStatus {
  preparing,
  checkingJava,
  resolvingDependencies,
  buildingArguments,
  ready,
  launching,
  running,
  exited,
  error,
}

/// 崩溃分析结果类
class CrashAnalysis {
  final bool hasCrash;
  final String? crashLog;
  final String analysis;

  CrashAnalysis({
    required this.hasCrash,
    this.crashLog,
    required this.analysis,
  });
}

class GameLaunchConfig {
  final String gameDir;
  final String gameVersion;
  final String javaPath;
  final int memoryMb;
  final String username;
  final String uuid;
  final String accessToken;
  final String assetIndex;
  final String assetsDir;
  final String librariesDir;
  final String mainClass;
  final List<String> jvmArgs;
  final List<String> gameArgs;
  final Map<String, String>? customEnvironment;

  GameLaunchConfig({
    required this.gameDir,
    required this.gameVersion,
    required this.javaPath,
    required this.memoryMb,
    required this.username,
    required this.uuid,
    required this.accessToken,
    required this.assetIndex,
    required this.assetsDir,
    required this.librariesDir,
    required this.mainClass,
    required this.jvmArgs,
    required this.gameArgs,
    this.customEnvironment,
  });

  GameLaunchConfig copyWith({
    String? gameDir,
    String? gameVersion,
    String? javaPath,
    int? memoryMb,
    String? username,
    String? uuid,
    String? accessToken,
    String? assetIndex,
    String? assetsDir,
    String? librariesDir,
    String? mainClass,
    List<String>? jvmArgs,
    List<String>? gameArgs,
    Map<String, String>? customEnvironment,
  }) {
    return GameLaunchConfig(
      gameDir: gameDir ?? this.gameDir,
      gameVersion: gameVersion ?? this.gameVersion,
      javaPath: javaPath ?? this.javaPath,
      memoryMb: memoryMb ?? this.memoryMb,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      accessToken: accessToken ?? this.accessToken,
      assetIndex: assetIndex ?? this.assetIndex,
      assetsDir: assetsDir ?? this.assetsDir,
      librariesDir: librariesDir ?? this.librariesDir,
      mainClass: mainClass ?? this.mainClass,
      jvmArgs: jvmArgs ?? this.jvmArgs,
      gameArgs: gameArgs ?? this.gameArgs,
      customEnvironment: customEnvironment ?? this.customEnvironment,
    );
  }
}

enum ProcessSignal {
  started,
  exited,
  error,
}
