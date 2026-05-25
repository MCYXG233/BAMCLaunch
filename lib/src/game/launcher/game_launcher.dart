import 'dart:async';
import 'dart:io';
import '../java/models.dart';
import '../../account/account.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../version/models.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
import 'models.dart';
import 'argument_builder.dart';

/// 游戏启动器接口
abstract class IGameLauncher {
  /// 启动游戏
  Future<GameProcessInfo> launch(LaunchArguments args);

  /// 停止游戏
  Future<void> stop(String processId);

  /// 获取日志流
  Stream<GameLog> getLogStream(String processId);

  /// 获取状态流
  Stream<GameProcessStatus> getStatusStream(String processId);

  /// 获取运行中的进程
  Map<String, GameProcessInfo> get runningProcesses;

  /// 初始化
  Future<void> initialize();

  /// 清理资源
  void dispose();
}

/// 游戏启动器实现（单例）
class GameLauncher implements IGameLauncher {
  static GameLauncher? _instance;

  factory GameLauncher() {
    _instance ??= GameLauncher._internal();
    return _instance!;
  }

  GameLauncher._internal();

  static GameLauncher get instance => _instance ?? GameLauncher._internal();

  static void reset() {
    _instance = null;
  }

  /// 平台适配器
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线
  final EventBus _eventBus = EventBus();

  /// 日志记录器
  final Logger _logger = Logger();

  /// 运行中的进程
  final Map<String, GameProcessInfo> _runningProcesses = {};

  /// 实际的Process对象
  final Map<String, Process> _processes = {};

  /// 日志流控制器
  final Map<String, StreamController<GameLog>> _logControllers = {};

  /// 状态流控制器
  final Map<String, StreamController<GameProcessStatus>> _statusControllers =
      {};

  /// 进程ID计数器
  int _processIdCounter = 0;

  /// 是否已初始化
  bool _initialized = false;

  @override
  Map<String, GameProcessInfo> get runningProcesses =>
      Map.unmodifiable(_runningProcesses);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _logger.info('GameLauncher initialized');
  }

  @override
  Future<GameProcessInfo> launch(LaunchArguments args) async {
    if (!_initialized) {
      await initialize();
    }

    final processId =
        'proc_${DateTime.now().millisecondsSinceEpoch}_${_processIdCounter++}';
    _logger.info(
      'Launching game: ${args.gameVersion} with process ID: $processId',
    );

    final processInfo = GameProcessInfo(
      processId: processId,
      arguments: args,
      status: GameProcessStatus.starting,
      startTime: DateTime.now(),
    );

    _runningProcesses[processId] = processInfo;
    _logControllers[processId] = StreamController<GameLog>.broadcast();
    _statusControllers[processId] =
        StreamController<GameProcessStatus>.broadcast();

    _statusControllers[processId]!.add(GameProcessStatus.starting);

    try {
      final versionJson = await _getVersionJson(args.gameVersion);

      final argumentBuilder = ArgumentBuilder(
        gameDirectory: args.gameDirectory,
        versionJson: versionJson,
        isWindows: _platformAdapter.isWindows,
      );

      final command = await argumentBuilder.buildFullCommand(
        javaPath: args.javaPath,
        memory: args.memory,
        jvmArgs: args.jvmArguments,
        account: args.account,
        serverAddress: args.serverAddress,
        serverPort: args.serverPort,
        gameArgs: args.gameArguments,
      );

      _logger.debug('Launch command: ${command.join(' ')}');

      final process = await Process.start(
        command.first,
        command.sublist(1),
        workingDirectory: args.gameDirectory,
      );

      _processes[processId] = process;
      processInfo.pid = process.pid;
      processInfo.status = GameProcessStatus.running;
      _statusControllers[processId]!.add(GameProcessStatus.running);

      _eventBus.publish(
        GameLaunchedEvent(
          processId: processId,
          version: args.gameVersion,
          username: args.account.username,
        ),
      );

      _listenToProcessOutput(processId, process);
      _listenToProcessExit(processId, process);

      return processInfo;
    } catch (e, stackTrace) {
      _logger.error('Failed to launch game', e, stackTrace);
      processInfo.status = GameProcessStatus.crashed;
      processInfo.errorMessage = e.toString();
      processInfo.stopTime = DateTime.now();
      _statusControllers[processId]?.add(GameProcessStatus.crashed);
      _eventBus.publish(
        GameCrashedEvent(processId: processId, error: e.toString()),
      );
      rethrow;
    }
  }

  @override
  Future<void> stop(String processId) async {
    final process = _processes[processId];
    final processInfo = _runningProcesses[processId];

    if (process == null || processInfo == null) {
      _logger.warn('Process not found: $processId');
      return;
    }

    _logger.info('Stopping game process: $processId');

    if (Platform.isWindows) {
      unawaited(
        Process.run('taskkill', ['/F', '/PID', process.pid.toString()]),
      );
    } else {
      process.kill(ProcessSignal.sigterm);
    }
  }

  @override
  Stream<GameLog> getLogStream(String processId) {
    return _logControllers[processId]?.stream ?? const Stream.empty();
  }

  @override
  Stream<GameProcessStatus> getStatusStream(String processId) {
    return _statusControllers[processId]?.stream ?? const Stream.empty();
  }

  @override
  void dispose() {
    for (final processId in _processes.keys.toList()) {
      stop(processId);
    }

    for (final controller in _logControllers.values) {
      controller.close();
    }
    for (final controller in _statusControllers.values) {
      controller.close();
    }

    _logControllers.clear();
    _statusControllers.clear();
    _processes.clear();
    _runningProcesses.clear();
    _initialized = false;
  }

  /// 获取版本JSON
  Future<VersionJson> _getVersionJson(String versionId) async {
    final versionManager = VersionManager();
    return await versionManager.fetchVersionJson(versionId);
  }

  /// 监听进程输出
  void _listenToProcessOutput(String processId, Process process) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    process.stdout.transform(const SystemEncoding().decoder).listen((data) {
      _handleOutput(processId, data, 'stdout');
    });

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      _handleOutput(processId, data, 'stderr');
    });
  }

  /// 处理输出
  void _handleOutput(String processId, String data, String source) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    final lines = data.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final log = GameLog(
        timestamp: DateTime.now(),
        level: _parseLogLevel(line),
        message: line,
        source: source,
      );

      processInfo.addLog(log);
      _logControllers[processId]?.add(log);
    }
  }

  /// 解析日志级别
  GameLogLevel _parseLogLevel(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return GameLogLevel.error;
    } else if (lower.contains('warn') || lower.contains('warning')) {
      return GameLogLevel.warn;
    } else if (lower.contains('debug')) {
      return GameLogLevel.debug;
    }
    return GameLogLevel.info;
  }

  /// 监听进程退出
  void _listenToProcessExit(String processId, Process process) async {
    final exitCode = await process.exitCode;

    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    processInfo.stopTime = DateTime.now();
    processInfo.exitCode = exitCode;

    if (exitCode == 0) {
      processInfo.status = GameProcessStatus.stopped;
      _statusControllers[processId]?.add(GameProcessStatus.stopped);
      _eventBus.publish(
        GameStoppedEvent(processId: processId, exitCode: exitCode),
      );
    } else {
      processInfo.status = GameProcessStatus.crashed;
      processInfo.errorMessage = 'Exit code: $exitCode';
      _statusControllers[processId]?.add(GameProcessStatus.crashed);
      _eventBus.publish(
        GameCrashedEvent(
          processId: processId,
          error: 'Exit code: $exitCode',
          logs: processInfo
              .getRecentLogs(50)
              .map((log) => log.format())
              .toList(),
        ),
      );
    }

    _cleanupProcess(processId);
  }

  /// 清理进程资源
  void _cleanupProcess(String processId) {
    _processes.remove(processId);
    _runningProcesses.remove(processId);

    Future.delayed(const Duration(seconds: 10), () {
      _logControllers[processId]?.close();
      _statusControllers[processId]?.close();
      _logControllers.remove(processId);
      _statusControllers.remove(processId);
    });
  }
}
