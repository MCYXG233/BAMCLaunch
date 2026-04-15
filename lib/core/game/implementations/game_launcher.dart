import '../interfaces/i_game_launcher.dart';
import '../models/game_launch_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../version/interfaces/i_version_manager.dart';
import '../../download/i_download_engine.dart';
import '../../download/download_engine.dart';
import 'java_manager.dart';
import 'launch_arguments_builder.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// 游戏启动器实现类
/// 负责游戏的启动、Java检测、崩溃分析等功能
class GameLauncher implements IGameLauncher {
  /// 平台适配器
  final IPlatformAdapter _platformAdapter;
  /// 日志记录器
  final ILogger _logger;
  /// 版本管理器
  final IVersionManager _versionManager;
  /// 下载引擎
  final IDownloadEngine _downloadEngine;
  /// Java管理器
  final JavaManager _javaManager;
  /// 启动参数构建器
  final LaunchArgumentsBuilder _argumentsBuilder;
  /// 游戏进程
  Process? _gameProcess;
  /// 输出流控制器
  final StreamController<String> _outputController =
      StreamController.broadcast();
  /// 信号流控制器
  final StreamController<ProcessSignal> _signalController =
      StreamController.broadcast();
  /// 启动状态流控制器
  final StreamController<GameLaunchStatus> _statusController =
      StreamController.broadcast();
  /// 最后一次崩溃日志
  String? _lastCrashLog;

  /// 构造函数
  /// [platformAdapter]: 平台适配器实例
  /// [logger]: 日志记录器实例
  /// [versionManager]: 版本管理器实例
  /// [downloadEngine]: 下载引擎实例
  GameLauncher({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IVersionManager versionManager,
    IDownloadEngine? downloadEngine,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _versionManager = versionManager,
        _downloadEngine = downloadEngine ?? DownloadEngine(),
        _javaManager = JavaManager(
          platformAdapter: platformAdapter,
          logger: logger,
        ),
        _argumentsBuilder = LaunchArgumentsBuilder(
          platformAdapter: platformAdapter,
          logger: logger,
        );

  /// 检测Java环境
  /// 返回Java检测结果
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

  /// 解析Java版本
  /// [output]: Java版本输出
  /// 返回解析后的版本字符串
  String _parseJavaVersion(String output) {
    RegExp versionRegex = RegExp(r'version "(\d+(?:\.\d+)*)"');
    Match? match = versionRegex.firstMatch(output);
    return match?.group(1) ?? 'Unknown';
  }

  /// 优化JVM参数
  /// [gameVersion]: 游戏版本
  /// [memoryMb]: 内存大小（MB）
  /// 返回优化后的JVM参数字符串
  @override
  Future<String> optimizeJvmParameters(String gameVersion, int memoryMb) async {
    try {
      _logger.info('优化JVM参数: $gameVersion, 内存: ${memoryMb}MB');
      final version = await _versionManager.getVersionInfo(gameVersion);
      final jvmArgs = await _argumentsBuilder.buildJvmArguments(
        version,
        '',
        memoryMb,
        '${_platformAdapter.gameDirectory}/.minecraft',
      );
      _logger.debug('生成的JVM参数: ${jvmArgs.join(' ')}');
      return jvmArgs.join(' ');
    } catch (e) {
      _logger.warn('优化JVM参数失败: $e, 使用默认参数');
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

      _logger.debug('使用默认JVM参数: ${args.join(' ')}');
      return args.join(' ');
    }
  }

  /// 构建游戏启动配置
  /// [gameVersion]: 游戏版本
  /// [username]: 用户名
  /// [uuid]: 用户UUID
  /// [accessToken]: 访问令牌
  /// [memoryMb]: 内存大小（MB）
  /// [customEnvironment]: 自定义环境变量
  /// 返回游戏启动配置
  @override
  Future<GameLaunchConfig> buildLaunchConfig({
    required String gameVersion,
    required String username,
    required String uuid,
    required String accessToken,
    required int memoryMb,
    Map<String, String>? customEnvironment,
  }) async {
    _logger.info('构建游戏启动配置: $gameVersion');
    _statusController.add(GameLaunchStatus.preparing);

    try {
      final version = await _versionManager.getVersionInfo(gameVersion);
      _statusController.add(GameLaunchStatus.checkingJava);
      
      final javaResult = await _javaManager.findRecommendedJava(gameVersion);

      if (javaResult == null || !javaResult.found) {
        throw Exception('未找到合适的Java环境，检测结果: ${javaResult?.error ?? "未知错误"}');
      }

      _statusController.add(GameLaunchStatus.resolvingDependencies);
      final gameDir = '${_platformAdapter.gameDirectory}/.minecraft';
      final assetsDir = '$gameDir/assets';
      final librariesDir = '$gameDir/libraries';

      // 确保必要的目录存在
      await _ensureDirectories(gameDir, assetsDir, librariesDir);

      _statusController.add(GameLaunchStatus.buildingArguments);
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

      _statusController.add(GameLaunchStatus.ready);
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
        customEnvironment: customEnvironment,
      );
    } catch (e) {
      _logger.error('构建启动配置失败: $e');
      _statusController.add(GameLaunchStatus.error);
      rethrow;
    }
  }

  /// 启动游戏
  /// [config]: 游戏启动配置
  /// 返回游戏进程
  @override
  Future<Process> launchGame(GameLaunchConfig config) async {
    try {
      _statusController.add(GameLaunchStatus.launching);
      _logger.info('启动游戏: ${config.gameVersion}');

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

      _logger.info('启动命令: ${command.join(' ')}');
      _logger.debug('完整启动命令: ${command.join(' ')}');

      // 准备环境变量
      Map<String, String> environment = Map.from(Platform.environment);
      if (config.customEnvironment != null) {
        environment.addAll(config.customEnvironment!);
      }

      _gameProcess = await Process.start(
        command.first,
        command.sublist(1),
        workingDirectory: config.gameDir,
        environment: environment,
      );

      _signalController.add(ProcessSignal.started);
      _statusController.add(GameLaunchStatus.running);

      // 捕获标准输出
      _gameProcess!.stdout
          .transform(utf8.decoder)
          .listen((data) {
        _outputController.add(data);
        _logger.info('[Game] $data');
        // 检测崩溃信息
        _detectCrash(data);
      });

      // 捕获错误输出
      _gameProcess!.stderr
          .transform(utf8.decoder)
          .listen((data) {
        _outputController.add(data);
        _logger.error('[Game] $data');
        // 检测崩溃信息
        _detectCrash(data);
      });

      // 处理进程退出
      _gameProcess!.exitCode.then((code) {
        _logger.info('游戏进程退出, 退出码: $code');
        _signalController.add(ProcessSignal.exited);
        _statusController.add(GameLaunchStatus.exited);
        _gameProcess = null;
        
        // 分析崩溃日志
        if (_lastCrashLog != null) {
          _analyzeCrashLog(_lastCrashLog!);
        }
      });

      return _gameProcess!;
    } catch (e) {
      _logger.error('启动游戏失败: $e');
      _signalController.add(ProcessSignal.error);
      _statusController.add(GameLaunchStatus.error);
      rethrow;
    }
  }

  /// 确保必要的目录存在
  /// [gameDir]: 游戏目录
  /// [assetsDir]: 资源目录
  /// [librariesDir]: 库目录
  Future<void> _ensureDirectories(String gameDir, String assetsDir, String librariesDir) async {
    final dirs = [gameDir, assetsDir, librariesDir, '$gameDir/natives', '$gameDir/logs'];
    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        _logger.info('创建目录: $dir');
      }
    }
  }

  /// 检测崩溃信息
  /// [output]: 游戏输出
  void _detectCrash(String output) {
    // 检测常见的崩溃关键词
    final crashKeywords = [
      'Exception in thread',
      'Error:',
      'Crash',
      'Java.lang',
      'OutOfMemoryError',
      'StackOverflowError',
    ];

    for (final keyword in crashKeywords) {
      if (output.contains(keyword)) {
        _lastCrashLog ??= '';
        _lastCrashLog = (_lastCrashLog ?? '') + output;
        _logger.warn('检测到可能的崩溃: $keyword');
        break;
      }
    }
  }

  /// 分析崩溃日志
  /// [crashLog]: 崩溃日志
  void _analyzeCrashLog(String crashLog) {
    _logger.info('分析崩溃日志...');
    
    if (crashLog.contains('OutOfMemoryError')) {
      _logger.error('崩溃原因: 内存不足，请增加分配的内存');
    } else if (crashLog.contains('NoClassDefFoundError') || crashLog.contains('ClassNotFoundException')) {
      _logger.error('崩溃原因: 缺少依赖库，请重新安装游戏版本');
    } else if (crashLog.contains('UnsatisfiedLinkError')) {
      _logger.error('崩溃原因: 本地库加载失败，请检查natives目录');
    } else if (crashLog.contains('IllegalArgumentException') || crashLog.contains('NullPointerException')) {
      _logger.error('崩溃原因: 游戏代码错误，可能是模组冲突');
    } else {
      _logger.error('崩溃原因: 未知错误，请检查完整日志');
    }

    // 保存崩溃日志
    final logDir = '${_platformAdapter.gameDirectory}/.minecraft/logs';
    final logFile = File('$logDir/crash_${DateTime.now().millisecondsSinceEpoch}.txt');
    logFile.writeAsString(crashLog).catchError((e) {
      _logger.error('保存崩溃日志失败: $e');
    });
  }

  /// 获取游戏输出流
  @override
  Stream<String> getGameOutput() {
    return _outputController.stream;
  }

  /// 获取进程信号流
  @override
  Stream<ProcessSignal> getProcessSignals() {
    return _signalController.stream;
  }

  /// 获取启动状态流
  @override
  Stream<GameLaunchStatus> getLaunchStatus() {
    return _statusController.stream;
  }

  /// 终止游戏进程
  @override
  Future<void> killProcess() async {
    if (_gameProcess != null) {
      _logger.info('终止游戏进程');
      _gameProcess!.kill();
      await _gameProcess!.exitCode;
      _gameProcess = null;
      _statusController.add(GameLaunchStatus.exited);
    }
  }

  /// 检查游戏进程是否运行
  @override
  bool get isProcessRunning {
    return _gameProcess != null;
  }

  /// 分析最后一次崩溃
  /// 返回崩溃分析结果
  @override
  Future<CrashAnalysis> analyzeLastCrash() async {
    if (_lastCrashLog != null) {
      return CrashAnalysis(
        hasCrash: true,
        crashLog: _lastCrashLog!,
        analysis: _analyzeCrashLogText(_lastCrashLog!),
      );
    }
    
    // 检查最新的崩溃日志文件
    final logDir = '${_platformAdapter.gameDirectory}/.minecraft/logs';
    final logDirExists = await Directory(logDir).exists();
    
    if (logDirExists) {
      final crashFiles = await Directory(logDir)
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.txt') && entity.path.contains('crash_'))
          .toList();
      
      if (crashFiles.isNotEmpty) {
        // 按修改时间排序，获取最新的崩溃日志
        crashFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        final latestCrashFile = crashFiles.first as File;
        final crashLog = await latestCrashFile.readAsString();
        
        return CrashAnalysis(
          hasCrash: true,
          crashLog: crashLog,
          analysis: _analyzeCrashLogText(crashLog),
        );
      }
    }
    
    return CrashAnalysis(
      hasCrash: false,
      analysis: '没有检测到崩溃日志',
    );
  }

  /// 分析崩溃日志文本
  /// [crashLog]: 崩溃日志文本
  /// 返回分析结果
  String _analyzeCrashLogText(String crashLog) {
    if (crashLog.contains('OutOfMemoryError')) {
      return '内存不足，请增加分配的内存';
    } else if (crashLog.contains('NoClassDefFoundError') || crashLog.contains('ClassNotFoundException')) {
      return '缺少依赖库，请重新安装游戏版本';
    } else if (crashLog.contains('UnsatisfiedLinkError')) {
      return '本地库加载失败，请检查natives目录';
    } else if (crashLog.contains('IllegalArgumentException') || crashLog.contains('NullPointerException')) {
      return '游戏代码错误，可能是模组冲突';
    } else {
      return '未知错误，请检查完整日志';
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _outputController.close();
    _signalController.close();
    _statusController.close();
    if (_gameProcess != null) {
      _gameProcess!.kill();
    }
  }
}
