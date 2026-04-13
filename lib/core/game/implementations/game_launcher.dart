import '../interfaces/i_game_launcher.dart';
import '../models/game_launch_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../version/interfaces/i_version_manager.dart';
import 'java_manager.dart';
import 'launch_arguments_builder.dart';
import 'dart:io';
import 'dart:async';

class GameLauncher implements IGameLauncher {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;
  final IVersionManager _versionManager;
  final JavaManager _javaManager;
  final LaunchArgumentsBuilder _argumentsBuilder;
  Process? _gameProcess;
  final StreamController<String> _outputController =
      StreamController.broadcast();
  final StreamController<ProcessSignal> _signalController =
      StreamController.broadcast();

  GameLauncher({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IVersionManager versionManager,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _versionManager = versionManager,
        _javaManager = JavaManager(
          platformAdapter: platformAdapter,
          logger: logger,
        ),
        _argumentsBuilder = LaunchArgumentsBuilder(
          platformAdapter: platformAdapter,
          logger: logger,
        );

  @override
  Future<JavaDetectionResult> detectJava() async {
    try {
      _logger.info('开始检测Java环境');

      // 首先尝试通过平台适配器查找Java
      String? javaPath = await _platformAdapter.findJava();
      if (javaPath != null) {
        ProcessResult result = await Process.run(javaPath, ['-version']);
        if (result.exitCode == 0) {
          String errorOutput = result.stderr.toString();
          String version = _parseJavaVersion(errorOutput);
          _logger.info('检测到Java: $version, 路径: $javaPath');
          return JavaDetectionResult(
            found: true,
            javaPath: javaPath,
            version: version,
          );
        }
      }

      // 尝试通过环境变量查找Java
      String? envJavaPath = Platform.environment['JAVA_HOME'];
      if (envJavaPath != null) {
        String javaExecPath = Platform.isWindows 
            ? '$envJavaPath\\bin\\java.exe' 
            : '$envJavaPath/bin/java';
        if (await File(javaExecPath).exists()) {
          ProcessResult result = await Process.run(javaExecPath, ['-version']);
          if (result.exitCode == 0) {
            String errorOutput = result.stderr.toString();
            String version = _parseJavaVersion(errorOutput);
            _logger.info('通过JAVA_HOME检测到Java: $version, 路径: $javaExecPath');
            return JavaDetectionResult(
              found: true,
              javaPath: javaExecPath,
              version: version,
            );
          }
        }
      }

      // 尝试常见的Java安装路径
      List<String> commonJavaPaths = Platform.isWindows
          ? [
              'C:\\Program Files\\Java\\jdk-17\\bin\\java.exe',
              'C:\\Program Files\\Java\\jdk-16\\bin\\java.exe',
              'C:\\Program Files\\Java\\jdk-15\\bin\\java.exe',
              'C:\\Program Files (x86)\\Java\\jdk-17\\bin\\java.exe',
              'C:\\Program Files (x86)\\Java\\jdk-16\\bin\\java.exe',
            ]
          : Platform.isMacOS
              ? [
                  '/usr/bin/java',
                  '/usr/local/bin/java',
                  '/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java',
                ]
              : [
                  '/usr/bin/java',
                  '/usr/local/bin/java',
                  '/opt/java/bin/java',
                ];

      for (String path in commonJavaPaths) {
        if (await File(path).exists()) {
          try {
            ProcessResult result = await Process.run(path, ['-version']);
            if (result.exitCode == 0) {
              String errorOutput = result.stderr.toString();
              String version = _parseJavaVersion(errorOutput);
              _logger.info('通过常见路径检测到Java: $version, 路径: $path');
              return JavaDetectionResult(
                found: true,
                javaPath: path,
                version: version,
              );
            }
          } catch (e) {
            _logger.warn('尝试路径 $path 失败: $e');
          }
        }
      }

      return JavaDetectionResult(
        found: false,
        error: '未找到Java环境，请手动安装Java 17或更高版本',
      );
    } catch (e) {
      _logger.error('Java检测异常: $e');
      return JavaDetectionResult(
        found: false,
        error: '检测异常: $e',
      );
    }
  }

  String _parseJavaVersion(String output) {
    RegExp versionRegex = RegExp(r'version "(\d+(?:\.\d+)*)"');
    Match? match = versionRegex.firstMatch(output);
    return match?.group(1) ?? 'Unknown';
  }

  @override
  Future<String> optimizeJvmParameters(String gameVersion, int memoryMb) async {
    try {
      final version = await _versionManager.getVersionInfo(gameVersion);
      final jvmArgs = await _argumentsBuilder.buildJvmArguments(
        version,
        '',
        memoryMb,
        '${_platformAdapter.gameDirectory}/.minecraft',
      );
      return jvmArgs.join(' ');
    } catch (e) {
      _logger.warn('Failed to optimize JVM parameters: $e, using default');
      List<String> args = [];

      args.add('-Xms${memoryMb}M');
      args.add('-Xmx${memoryMb}M');

      args.add('-XX:+UseG1GC');
      args.add('-XX:MaxGCPauseMillis=200');
      args.add('-XX:ParallelGCThreads=${Platform.numberOfProcessors}');
      args.add('-XX:+UnlockExperimentalVMOptions');
      args.add('-XX:+DisableExplicitGC');
      args.add('-XX:+AlwaysPreTouch');

      if (Platform.isWindows) {
        args.add('-Dsun.java2d.d3d=true');
      }

      args.add('-Dfml.ignoreInvalidMinecraftCertificates=true');
      args.add('-Dfml.ignorePatchDiscrepancies=true');

      return args.join(' ');
    }
  }

  Future<GameLaunchConfig> buildLaunchConfig({
    required String gameVersion,
    required String username,
    required String uuid,
    required String accessToken,
    required int memoryMb,
  }) async {
    _logger.info('构建游戏启动配置: $gameVersion');

    final version = await _versionManager.getVersionInfo(gameVersion);
    final javaResult = await _javaManager.findRecommendedJava(gameVersion);

    if (javaResult == null || !javaResult.found) {
      throw Exception('未找到合适的Java环境，检测结果: ${javaResult?.error ?? "未知错误"}');
    }

    final gameDir = '${_platformAdapter.gameDirectory}/.minecraft';
    final assetsDir = '$gameDir/assets';
    final librariesDir = '$gameDir/libraries';

    final jvmArgs = await _argumentsBuilder.buildJvmArguments(
      version,
      javaResult.javaPath!,
      memoryMb,
      gameDir,
    );

    final gameArgs = await _argumentsBuilder.buildGameArguments(
      version,
      username,
      uuid,
      accessToken,
      gameDir,
      assetsDir,
      version.assetIndex?.id ?? gameVersion,
      gameVersion,
    );

    return GameLaunchConfig(
      gameDir: gameDir,
      gameVersion: gameVersion,
      javaPath: javaResult.javaPath!,
      memoryMb: memoryMb,
      username: username,
      uuid: uuid,
      accessToken: accessToken,
      assetIndex: version.assetIndex?.id ?? gameVersion,
      assetsDir: assetsDir,
      librariesDir: librariesDir,
      mainClass: version.mainClass,
      jvmArgs: jvmArgs,
      gameArgs: gameArgs,
    );
  }

  @override
  Future<Process> launchGame(GameLaunchConfig config) async {
    try {
      final classpath = _argumentsBuilder.buildClasspath(
        config.librariesDir,
        config.gameVersion,
      );

      List<String> command = [
        config.javaPath,
        ...config.jvmArgs,
        '-cp',
        classpath,
        config.mainClass,
        ...config.gameArgs,
      ];

      _logger.info('启动游戏进程: ${command.join(' ')}');
      _logger.debug('完整启动命令: ${command.join(' ')}');

      _gameProcess = await Process.start(
        command.first,
        command.sublist(1),
        workingDirectory: config.gameDir,
      );

      _signalController.add(ProcessSignal.started);

      _gameProcess!.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) {
        _outputController.add(data);
        _logger.info('[Game] $data');
      });

      _gameProcess!.stderr
          .transform(const SystemEncoding().decoder)
          .listen((data) {
        _outputController.add(data);
        _logger.error('[Game] $data');
      });

      _gameProcess!.exitCode.then((code) {
        _logger.info('游戏进程退出, 退出码: $code');
        _signalController.add(ProcessSignal.exited);
        _gameProcess = null;
      });

      return _gameProcess!;
    } catch (e) {
      _logger.error('启动游戏失败: $e');
      _signalController.add(ProcessSignal.error);
      rethrow;
    }
  }

  Future<void> ensureNativesExtracted(String gameVersion) async {
    final gameDir = '${_platformAdapter.gameDirectory}/.minecraft';
    final nativesDir = '$gameDir/natives';

    if (!await Directory(nativesDir).exists()) {
      await Directory(nativesDir).create(recursive: true);
      _logger.info('创建natives目录: $nativesDir');
    }
  }

  @override
  Stream<String> getGameOutput() {
    return _outputController.stream;
  }

  @override
  Stream<ProcessSignal> getProcessSignals() {
    return _signalController.stream;
  }

  @override
  Future<void> killProcess() async {
    if (_gameProcess != null) {
      _logger.info('终止游戏进程');
      _gameProcess!.kill();
      await _gameProcess!.exitCode;
      _gameProcess = null;
    }
  }

  @override
  bool get isProcessRunning {
    return _gameProcess != null;
  }
}
