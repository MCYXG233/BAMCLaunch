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
    );
  }
}

enum ProcessSignal {
  started,
  exited,
  error,
}
