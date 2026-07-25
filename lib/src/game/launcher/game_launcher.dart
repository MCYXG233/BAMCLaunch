import 'dart:async';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import '../java/models.dart';
import '../java/java_manager.dart';
import '../../account/account.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../version/models.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
// 注意：config_models.dart 中也定义了 GameConfig 和 FileValidatePolicy，
// 但本文件使用 game/launcher/models.dart 中的本地版本（结构不同），
// 因此不导入 config_models.dart 以避免歧义。
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../di/service_locator.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../instance/instance_manager.dart';
import '../../download/index.dart';
import 'models.dart';
import 'argument_builder.dart';
import 'native_library_manager.dart';
import 'game_file_validator.dart';
import 'game_process_manager.dart';
import 'game_output_monitor.dart';
import 'game_error_detector.dart';
import 'game_ready_detector.dart';

/// 游戏启动器接口
///
/// 定义了游戏启动器的核心功能接口。
abstract class IGameLauncher {
  Future<GameProcessInfo> launch(LaunchArguments args);
  Future<void> stop(String processId);
  Stream<GameLog> getLogStream(String processId);
  Stream<GameProcessStatus> getStatusStream(String processId);
  Map<String, GameProcessInfo> get runningProcesses;
  Future<void> initialize();
  void dispose();
}

/// 游戏启动器实现类（编排层）
///
/// 负责协调整个启动流程，将单一职责委托给 4 个子组件：
/// - [GameProcessManager]：进程启动 / 停止
/// - [GameOutputMonitor]：stdout / stderr 监听
/// - [GameErrorDetector]：错误模式匹配与崩溃诊断
/// - [GameReadyDetector]：游戏就绪判定
///
/// 主类自身保留：
/// - 启动编排（4 步骤）
/// - 共享状态管理（_runningProcesses / _launchingStates）
/// - 进程退出处理与游戏时长记录
class GameLauncher implements IGameLauncher {
  static GameLauncher? _instance;

  factory GameLauncher() {
    _instance ??= GameLauncher._internal();
    return _instance!;
  }

  GameLauncher._internal();

  static GameLauncher get instance =>
      ServiceLocator.instance.tryGet<GameLauncher>() ??
      (_instance ??= GameLauncher._internal());

  static void reset() {
    _instance = null;
  }

  // ==================== 依赖与子组件 ====================

  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final IConfigManager _configManager = ConfigManager();
  final EventBus _eventBus = EventBus();
  final Logger _logger = Logger('GameLauncher');

  final GameProcessManager _processManager = GameProcessManager();
  final GameOutputMonitor _outputMonitor = GameOutputMonitor();
  final GameErrorDetector _errorDetector = GameErrorDetector();
  final GameReadyDetector _readyDetector = GameReadyDetector();

  // ==================== 共享状态 ====================

  final Map<String, GameProcessInfo> _runningProcesses = {};
  final Map<String, Process> _processes = {};
  final Map<String, StreamController<GameLog>> _logControllers = {};
  final Map<String, StreamController<GameProcessStatus>> _statusControllers =
      {};
  final Map<String, LaunchingState> _launchingStates = {};
  int _processIdCounter = 0;
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
    if (!_initialized) await initialize();

    final processId =
        'proc_${DateTime.now().millisecondsSinceEpoch}_${_processIdCounter++}';
    _logger.info(
      'Launching game: ${args.gameVersion} with process ID: $processId',
    );

    final gameConfig = _buildGameConfig(args);
    final launchingState = LaunchingState(
      id: processId,
      currentStep: 1,
      gameVersion: args.gameVersion,
      gameDirectory: args.gameDirectory,
      memory: args.memory,
      jvmArgs: args.jvmArguments,
      serverAddress: args.serverAddress,
      serverPort: args.serverPort,
      startTime: DateTime.now(),
    );
    _launchingStates[processId] = launchingState;

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
      await _step1SelectJava(processId, args);
      await _step2ValidateFiles(processId, args, gameConfig);
      await _step3ValidatePlayer(processId, args);
      await _step4LaunchGame(processId, args, gameConfig);
      return processInfo;
    } catch (e, stackTrace) {
      _handleLaunchError(processId, e, stackTrace);
      rethrow;
    }
  }

  GameConfig _buildGameConfig(LaunchArguments args) {
    final gcStrategy = _configManager.getString(
      ConfigKeys.gcStrategy,
      defaultValue: 'auto',
    )!;
    final fileValidatePolicyStr = _configManager.getString(
      ConfigKeys.fileValidatePolicy,
      defaultValue: 'normal',
    )!;
    final launcherVisibility = _configManager.getString(
      ConfigKeys.launcherVisibility,
      defaultValue: 'always',
    )!;

    FileValidatePolicy fileValidatePolicy = FileValidatePolicy.normal;
    if (fileValidatePolicyStr == 'disable') {
      fileValidatePolicy = FileValidatePolicy.disable;
    } else if (fileValidatePolicyStr == 'full') {
      fileValidatePolicy = FileValidatePolicy.full;
    }

    return GameConfig(
      memory: args.memory,
      jvmArgs: args.jvmArguments,
      gcStrategy: gcStrategy,
      fileValidatePolicy: fileValidatePolicy,
      autoJoinServer: args.serverAddress != null,
      serverAddress: args.serverAddress ?? '',
      serverPort: args.serverPort ?? BAMCConstants.defaultMinecraftPort,
      launcherVisibility: launcherVisibility,
    );
  }

  Future<void> _step1SelectJava(String processId, LaunchArguments args) async {
    _updateLaunchingStep(processId, 1);
    _logger.info('Step 1: Selecting Java runtime');

    JavaInstallation java;
    if (args.javaPath.isNotEmpty) {
      final foundJava = await JavaManager.instance.getJavaInfo(args.javaPath);
      if (foundJava == null) throw LaunchError.selectedJavaUnavailable;
      java = foundJava;
    } else {
      final foundJava = await JavaManager.instance.getJavaForGameVersion(
        args.gameVersion,
      );
      if (foundJava == null) throw LaunchError.noSuitableJava;
      java = foundJava;
    }

    _logger.info('Selected Java: ${java.version} at ${java.path}');

    final isCompatible = JavaManager.instance.isJavaCompatibleWithGame(
      java.version,
      args.gameVersion,
    );
    if (!isCompatible) {
      _logger.warn(
        'Java ${java.version} may not be compatible with game version ${args.gameVersion}',
      );
    }

    _updateLaunchingState(
      processId,
      (state) =>
          state.copyWith(javaPath: java.path, javaVersion: java.majorVersion),
    );
  }

  Future<void> _step2ValidateFiles(
    String processId,
    LaunchArguments args,
    GameConfig gameConfig,
  ) async {
    _updateLaunchingStep(processId, 2);
    _logger.info('Step 2: Validating game files');

    final versionJson = await _getVersionJson(args.gameVersion);
    final invalidFiles = await GameFileValidator.instance.validateAll(
      versionJson,
      args.gameDirectory,
      gameConfig.fileValidatePolicy,
    );

    if (invalidFiles.isNotEmpty) {
      _logger.warn(
        'Found ${invalidFiles.length} invalid files, triggering patch',
      );
      await _patchFiles(invalidFiles);
    }

    await NativeLibraryManager.instance.extractNativeLibraries(
      versionJson,
      '${args.gameDirectory}/libraries',
      '${args.gameDirectory}/versions/${args.gameVersion}/natives',
    );

    _updateLaunchingState(
      processId,
      (state) => state.copyWith(versionJson: versionJson.toJson()),
    );
  }

  Future<void> _patchFiles(List<InvalidFile> invalidFiles) async {
    _logger.info('Patching ${invalidFiles.length} files');
    for (final file in invalidFiles) {
      _logger.debug('Downloading missing file: ${file.path}');
      if (file.url != null) {
        await DownloadEngine.instance.download(file.url!, file.path);
      }
    }
    _logger.info('All files patched successfully');
  }

  Future<void> _step3ValidatePlayer(
    String processId,
    LaunchArguments args,
  ) async {
    _updateLaunchingStep(processId, 3);
    _logger.info('Step 3: Validating player authentication');

    final account = args.account;
    if (account.type != AccountType.offline) {
      _logger.debug('Validating token for account: ${account.id}');
      final isTokenValid = await AccountManager.instance.isTokenValid(account);

      if (!isTokenValid) {
        _logger.warn('Token validation failed, attempting to refresh');
        final refreshed = await AccountManager.instance.refreshToken(account);
        if (!refreshed) throw LaunchError.playerValidationFailed;
      }
    }

    if (account.accessToken == null && account.uuid == null) {
      _logger.warn('No valid authentication, using offline mode');
    }

    _updateLaunchingState(
      processId,
      (state) => state.copyWith(
        accountId: account.id,
        accountName: account.username,
        accountUuid: account.uuid,
        accountToken: account.accessToken,
      ),
    );
  }

  Future<void> _step4LaunchGame(
    String processId,
    LaunchArguments args,
    GameConfig gameConfig,
  ) async {
    _updateLaunchingStep(processId, 4);
    _logger.info('Step 4: Launching game');

    final state = _launchingStates[processId];
    if (state == null) throw LaunchError.launchingStateNotFound;

    final versionJson = VersionJson.fromJson(state.versionJson!);
    final argumentBuilder = ArgumentBuilder(
      gameDirectory: args.gameDirectory,
      versionJson: versionJson,
      isWindows: _platformAdapter.isWindows,
    );

    final command = await argumentBuilder.buildLaunchCommand(
      javaPath: state.javaPath!,
      gameConfig: gameConfig,
      account: args.account,
      javaMajorVersion: state.javaVersion!,
    );

    final fullCommandStr = argumentBuilder.exportFullLaunchCommand(
      command: command,
    );
    _logger.debug('Launch command: $fullCommandStr');

    // 委托 GameProcessManager 启动进程
    final process = await _processManager.startProcess(
      command: command.args,
      workingDirectory: args.gameDirectory,
    );

    final processInfo = _runningProcesses[processId];
    if (processInfo == null) throw LaunchError.launchingStateNotFound;

    _processes[processId] = process;
    processInfo.pid = process.pid;
    processInfo.status = GameProcessStatus.running;
    _statusControllers[processId]!.add(GameProcessStatus.running);

    _updateLaunchingState(
      processId,
      (state) => state.copyWith(fullCommand: fullCommandStr, pid: process.pid),
    );

    _eventBus.publish(
      GameLaunchedEvent(
        processId: processId,
        version: args.gameVersion,
        username: args.account.username,
      ),
    );

    await _handleLauncherVisibility(gameConfig.launcherVisibility);

    // 委托 GameOutputMonitor 监听输出，每行日志触发错误检测和就绪检测
    _outputMonitor.startMonitoring(
      process: process,
      processId: processId,
      gameDirectory: processInfo.arguments.gameDirectory,
      logController: _logControllers[processId]!,
      onLog: (log) => _onProcessLog(processId, log),
    );

    _listenToProcessExit(processId, process);
  }

  /// 处理每行日志：触发错误检测和就绪检测
  void _onProcessLog(String processId, GameLog log) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    processInfo.addLog(log);

    _errorDetector.checkForErrors(processId, log.message);

    _readyDetector.checkGameReady(
      processId: processId,
      line: log.message,
      processInfo: processInfo,
      eventBus: _eventBus,
      onReady: (readyTime) {
        _updateLaunchingState(
          processId,
          (state) => state.copyWith(readyTime: readyTime),
        );
      },
    );
  }

  Future<void> _handleLauncherVisibility(String visibility) async {
    switch (visibility) {
      case 'runningHidden':
      case 'startHidden':
        await windowManager.hide();
        break;
      case 'always':
      default:
        break;
    }
  }

  Future<void> _restoreLauncherVisibility() async {
    await windowManager.show();
    await windowManager.focus();
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
    _processManager.stop(process);
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
    _launchingStates.clear();
    _initialized = false;
  }

  Future<VersionJson> _getVersionJson(String versionId) async {
    final versionManager = VersionManager();
    return await versionManager.fetchVersionJson(versionId);
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
      await _restoreLauncherVisibility();
      await _recordPlayTime(processId);
    } else {
      processInfo.status = GameProcessStatus.crashed;
      processInfo.errorMessage = 'Exit code: $exitCode';
      _statusControllers[processId]?.add(GameProcessStatus.crashed);

      // 委托 GameErrorDetector 生成崩溃诊断报告
      await _errorDetector.analyzeCrashLog(
        processId: processId,
        processInfo: processInfo,
        eventBus: _eventBus,
      );

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

  Future<void> _recordPlayTime(String processId) async {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    if (processInfo.readyTime != null && processInfo.stopTime != null) {
      final playTime = processInfo.stopTime!.difference(processInfo.readyTime!);
      _logger.info('Recorded play time: ${playTime.inSeconds} seconds');

      _eventBus.publish(
        PlayTimeRecordedEvent(
          version: processInfo.arguments.gameVersion,
          playTime: playTime,
        ),
      );

      try {
        final instanceManager = InstanceManager();
        final instances = instanceManager.instances;
        try {
          final instance = instances.firstWhere(
            (i) => i.version == processInfo.arguments.gameVersion,
          );
          await instanceManager.updateInstance(
            id: instance.id,
            playTimeSeconds:
                (instance.playTimeSeconds ?? 0) + playTime.inSeconds,
          );
        } catch (e) {
          // 实例未找到，这是正常情况
        }
      } catch (e) {
        _logger.warn('Failed to update play time: $e');
      }
    }
  }

  void _handleLaunchError(
    String processId,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.error('Failed to launch game', error, stackTrace);
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    processInfo.status = GameProcessStatus.crashed;
    processInfo.errorMessage = error.toString();
    processInfo.stopTime = DateTime.now();
    _statusControllers[processId]?.add(GameProcessStatus.crashed);

    _eventBus.publish(
      GameCrashedEvent(processId: processId, error: error.toString()),
    );

    _cleanupProcess(processId);
  }

  void _updateLaunchingStep(String processId, int step) {
    _updateLaunchingState(
      processId,
      (state) => state.copyWith(currentStep: step),
    );
  }

  void _updateLaunchingState(
    String processId,
    LaunchingState Function(LaunchingState) updater,
  ) {
    final state = _launchingStates[processId];
    if (state == null) return;
    _launchingStates[processId] = updater(state);
  }

  void _cleanupProcess(String processId) {
    _processes.remove(processId);
    _runningProcesses.remove(processId);
    _launchingStates.remove(processId);
    _errorDetector.clear(processId);

    Future.delayed(const Duration(seconds: 10), () {
      _logControllers[processId]?.close();
      _statusControllers[processId]?.close();
      _logControllers.remove(processId);
      _statusControllers.remove(processId);
    });
  }
}
