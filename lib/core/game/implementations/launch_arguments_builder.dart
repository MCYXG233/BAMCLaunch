import '../../version/models/version_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import 'dart:io';

class LaunchArgumentsBuilder {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;

  LaunchArgumentsBuilder({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
  })  : _platformAdapter = platformAdapter,
        _logger = logger;

  Future<List<String>> buildJvmArguments(
    Version version,
    String javaPath,
    int memoryMb,
    String gameDir,
  ) async {
    final List<String> args = [];

    args.add('-Xms${memoryMb}M');
    args.add('-Xmx${memoryMb}M');

    args.add('-XX:+UseG1GC');
    args.add('-XX:MaxGCPauseMillis=200');
    args.add('-XX:ParallelGCThreads=${Platform.numberOfProcessors}');
    args.add('-XX:+UnlockExperimentalVMOptions');
    args.add('-XX:+DisableExplicitGC');
    args.add('-XX:+AlwaysPreTouch');
    args.add('-XX:+OptimizeStringConcat');
    args.add('-XX:+FastAccessToStaticFields');
    args.add('-XX:+UseCompressedOops');

    if (Platform.isWindows) {
      args.add('-Dsun.java2d.d3d=true');
      args.add('-Dfml.ignoreInvalidMinecraftCertificates=true');
      args.add('-Dfml.ignorePatchDiscrepancies=true');
    }

    args.add('-Djava.library.path=$gameDir/natives');
    args.add('-Dminecraft.launcher.brand=bamclauncher');
    args.add('-Dminecraft.launcher.version=1.0.0');

    if (version.jvmArguments.isNotEmpty) {
      args.addAll(version.jvmArguments);
    }

    return args;
  }

  Future<List<String>> buildGameArguments(
    Version version,
    String username,
    String uuid,
    String accessToken,
    String gameDir,
    String assetsDir,
    String assetIndex,
    String gameVersion,
  ) async {
    final List<String> args = [];

    args.add('--username');
    args.add(username);
    args.add('--version');
    args.add(gameVersion);
    args.add('--gameDir');
    args.add(gameDir);
    args.add('--assetsDir');
    args.add(assetsDir);
    args.add('--assetIndex');
    args.add(assetIndex);
    args.add('--uuid');
    args.add(uuid);
    args.add('--accessToken');
    args.add(accessToken);
    args.add('--userType');
    args.add('mojang');
    args.add('--versionType');
    args.add(version.type.toString().split('.').last);

    if (version.arguments.isNotEmpty) {
      args.addAll(version.arguments);
    }

    return args;
  }

  String buildClasspath(String librariesDir, String gameVersion) {
    final List<String> classpath = [];

    final libDir = Directory(librariesDir);
    if (libDir.existsSync()) {
      libDir.listSync(recursive: true).forEach((entity) {
        if (entity is File && entity.path.endsWith('.jar')) {
          classpath.add(entity.path);
        }
      });
    }

    classpath.add('$librariesDir/versions/$gameVersion/$gameVersion.jar');

    return classpath.join(Platform.isWindows ? ';' : ':');
  }
}
