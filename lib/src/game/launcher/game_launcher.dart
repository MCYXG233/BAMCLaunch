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
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
import '../../instance/instance_manager.dart';
import '../../download/index.dart';
import 'models.dart';
import 'argument_builder.dart';
import 'native_library_manager.dart';
import 'game_file_validator.dart';

abstract class IGameLauncher {
  Future<GameProcessInfo> launch(LaunchArguments args);

  Future<void> stop(String processId);

  Stream<GameLog> getLogStream(String processId);

  Stream<GameProcessStatus> getStatusStream(String processId);

  Map<String, GameProcessInfo> get runningProcesses;

  Future<void> initialize();

  void dispose();
}

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

  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();
  final IConfigManager _configManager = ConfigManager();
  final EventBus _eventBus = EventBus();
  final Logger _logger = Logger('GameLauncher');
  final Map<String, GameProcessInfo> _runningProcesses = {};
  final Map<String, Process> _processes = {};
  final Map<String, StreamController<GameLog>> _logControllers = {};
  final Map<String, StreamController<GameProcessStatus>> _statusControllers = {};
  final Map<String, LaunchingState> _launchingStates = {};
  int _processIdCounter = 0;
  bool _initialized = false;

  @override
  Map<String, GameProcessInfo> get runningProcesses => Map.unmodifiable(_runningProcesses);

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

    final processId = 'proc_${DateTime.now().millisecondsSinceEpoch}_${_processIdCounter++}';
    _logger.info('Launching game: ${args.gameVersion} with process ID: $processId');

    final gcStrategy = _configManager.getString(ConfigKeys.gcStrategy, defaultValue: 'auto')!;
    final fileValidatePolicyStr = _configManager.getString(ConfigKeys.fileValidatePolicy, defaultValue: 'normal')!;
    final launcherVisibility = _configManager.getString(ConfigKeys.launcherVisibility, defaultValue: 'always')!;
    
    FileValidatePolicy fileValidatePolicy = FileValidatePolicy.normal;
    if (fileValidatePolicyStr == 'disable') {
      fileValidatePolicy = FileValidatePolicy.disable;
    } else if (fileValidatePolicyStr == 'full') {
      fileValidatePolicy = FileValidatePolicy.full;
    }

    final gameConfig = GameConfig(
      memory: args.memory,
      jvmArgs: args.jvmArguments,
      gcStrategy: gcStrategy,
      fileValidatePolicy: fileValidatePolicy,
      autoJoinServer: args.serverAddress != null,
      serverAddress: args.serverAddress ?? '',
      serverPort: args.serverPort ?? 25565,
      launcherVisibility: launcherVisibility,
    );

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
    _statusControllers[processId] = StreamController<GameProcessStatus>.broadcast();
    _statusControllers[processId]!.add(GameProcessStatus.starting);

    try {
      await _step1SelectJava(processId, args, gameConfig);
      await _step2ValidateFiles(processId, args, gameConfig);
      await _step3ValidatePlayer(processId, args, gameConfig);
      await _step4LaunchGame(processId, args, gameConfig);
      return processInfo;
    } catch (e, stackTrace) {
      _handleLaunchError(processId, e, stackTrace);
      rethrow;
    }
  }

  Future<void> _step1SelectJava(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 1);
    _logger.info('Step 1: Selecting Java runtime');

    JavaInstallation java;
    if (args.javaPath.isNotEmpty) {
      final foundJava = await JavaManager.instance.getJavaInfo(args.javaPath);
      if (foundJava == null) {
        throw LaunchError.selectedJavaUnavailable;
      }
      java = foundJava;
    } else {
      final foundJava = await JavaManager.instance.getJavaForGameVersion(args.gameVersion);
      if (foundJava == null) {
        throw LaunchError.noSuitableJava;
      }
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

    _updateLaunchingState(processId, (state) => state.copyWith(
      javaPath: java.path,
      javaVersion: java.majorVersion,
    ));
  }

  Future<void> _step2ValidateFiles(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 2);
    _logger.info('Step 2: Validating game files');

    final versionJson = await _getVersionJson(args.gameVersion);

    final invalidFiles = await GameFileValidator.instance.validateAll(
      versionJson, args.gameDirectory, gameConfig.fileValidatePolicy);

    if (invalidFiles.isNotEmpty) {
      _logger.warn('Found ${invalidFiles.length} invalid files, triggering patch');
      await _patchFiles(processId, invalidFiles);
    }

    await NativeLibraryManager.instance.extractNativeLibraries(
      versionJson,
      '${args.gameDirectory}/libraries',
      '${args.gameDirectory}/versions/${args.gameVersion}/natives',
    );

    _updateLaunchingState(processId, (state) => state.copyWith(
      versionJson: versionJson.toJson(),
    ));
  }

  Future<void> _patchFiles(String processId, List<InvalidFile> invalidFiles) async {
    _logger.info('Patching ${invalidFiles.length} files');
    for (final file in invalidFiles) {
      _logger.debug('Downloading missing file: ${file.path}');
      if (file.url != null) {
        await DownloadEngine.instance.download(file.url!, file.path);
      }
    }
    _logger.info('All files patched successfully');
  }

  Future<void> _step3ValidatePlayer(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 3);
    _logger.info('Step 3: Validating player authentication');

    final account = args.account;

    if (account.type != AccountType.offline) {
      _logger.debug('Validating token for account: ${account.id}');
      final isTokenValid = await AccountManager.instance.isTokenValid(account);

      if (!isTokenValid) {
        _logger.warn('Token validation failed, attempting to refresh');
        final refreshed = await AccountManager.instance.refreshToken(account);

        if (!refreshed) {
          throw LaunchError.playerValidationFailed;
        }
      }
    }

    if (account.accessToken == null && account.uuid == null) {
      _logger.warn('No valid authentication, using offline mode');
    }

    _updateLaunchingState(processId, (state) => state.copyWith(
      accountId: account.id,
      accountName: account.username,
      accountUuid: account.uuid,
      accountToken: account.accessToken,
    ));
  }

  Future<void> _step4LaunchGame(String processId, LaunchArguments args, GameConfig gameConfig) async {
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

    final fullCommandStr = argumentBuilder.exportFullLaunchCommand(command: command);
    _logger.debug('Launch command: $fullCommandStr');

    Process? process;
    try {
      process = await Process.start(
        command.args.first,
        command.args.sublist(1),
        workingDirectory: args.gameDirectory,
        mode: ProcessStartMode.normal,
      );
      _logger.info('Process started with PID: ${process.pid}');
    } catch (e, stackTrace) {
      _logger.error('Failed to start game process', e, stackTrace);
      throw LaunchError.processStartFailed;
    }

    _processes[processId] = process!;
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) throw LaunchError.launchingStateNotFound;

    processInfo.pid = process!.pid;
    processInfo.status = GameProcessStatus.running;
    _statusControllers[processId]!.add(GameProcessStatus.running);

    _updateLaunchingState(processId, (state) => state.copyWith(
      fullCommand: fullCommandStr,
      pid: process!.pid,
    ));

    _eventBus.publish(GameLaunchedEvent(
      processId: processId,
      version: args.gameVersion,
      username: args.account.username,
    ));

    await _handleLauncherVisibility(gameConfig.launcherVisibility);

    _listenToProcessOutput(processId, process);
    _listenToProcessExit(processId, process);
  }

  Future<void> _handleLauncherVisibility(String visibility) async {
    switch (visibility) {
      case 'runningHidden':
        await windowManager.hide();
        break;
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

    if (Platform.isWindows) {
      unawaited(Process.run('taskkill', ['/F', '/PID', process.pid.toString()]));
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
    _launchingStates.clear();
    _initialized = false;
  }

  Future<VersionJson> _getVersionJson(String versionId) async {
    final versionManager = VersionManager();
    return await versionManager.fetchVersionJson(versionId);
  }

  void _listenToProcessOutput(String processId, Process process) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    IOSink? logSink;

    try {
      final logDir = Directory('${processInfo.arguments.gameDirectory}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      final logFile = File('${processInfo.arguments.gameDirectory}/logs/launcher_${processId}.log');
      logSink = logFile.openWrite(mode: FileMode.append);
      logSink.writeln('=== Launcher Log - Process $processId - ${DateTime.now().toIso8601String()} ===');
    } catch (e) {
      _logger.warn('Failed to open log file: $e');
    }

    final stdoutSubscription = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(processId, data, 'stdout', logSink),
          onError: (e) => _logger.error('Stdout stream error: $e'),
          onDone: () => _logger.debug('Stdout stream closed'),
        );

    final stderrSubscription = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(processId, data, 'stderr', logSink),
          onError: (e) => _logger.error('Stderr stream error: $e'),
          onDone: () => _logger.debug('Stderr stream closed'),
        );

    process.exitCode.then((_) {
      stdoutSubscription.cancel();
      stderrSubscription.cancel();
      logSink?.writeln('=== Log ended - ${DateTime.now().toIso8601String()} ===');
      logSink?.close();
    });
  }

  void _handleOutput(String processId, String data, String source, [IOSink? logSink]) {
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

      if (logSink != null) {
        try {
          logSink.writeln(log.format());
        } catch (e) {
          _logger.warn('Failed to write to log file: $e');
        }
      }

      _checkGameReady(processId, line);
      _checkForErrors(processId, line);
    }
  }

  void _checkForErrors(String processId, String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || 
        lower.contains('exception') || 
        lower.contains('crash') ||
        lower.contains('failed') ||
        lower.contains('fatal')) {
      _logger.warn('Potential error detected in game output: $line');
    }
  }

  void _checkGameReady(String processId, String line) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;
    final state = _launchingStates[processId];
    if (state == null) return;

    if (processInfo.readyTime != null) return;

    final lower = line.toLowerCase();
    final readyKeywords = ['render thread', 'glfw', 'setting user', 'lwjgl'];

    if (readyKeywords.any((keyword) => lower.contains(keyword))) {
      _logger.info('Game is ready');
      processInfo.readyTime = DateTime.now();
      _updateLaunchingState(processId, (state) => state.copyWith(readyTime: DateTime.now()));
      _eventBus.publish(GameReadyEvent(
        processId: processId,
        version: processInfo.arguments.gameVersion,
        username: processInfo.arguments.account.username,
      ));
    }
  }

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

  void _listenToProcessExit(String processId, Process process) async {
    final exitCode = await process.exitCode;

    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    processInfo.stopTime = DateTime.now();
    processInfo.exitCode = exitCode;

    if (exitCode == 0) {
      processInfo.status = GameProcessStatus.stopped;
      _statusControllers[processId]?.add(GameProcessStatus.stopped);
      _eventBus.publish(GameStoppedEvent(processId: processId, exitCode: exitCode));
      await _restoreLauncherVisibility();
      await _recordPlayTime(processId);
    } else {
      processInfo.status = GameProcessStatus.crashed;
      processInfo.errorMessage = 'Exit code: $exitCode';
      _statusControllers[processId]?.add(GameProcessStatus.crashed);
      _eventBus.publish(GameCrashedEvent(
        processId: processId,
        error: 'Exit code: $exitCode',
        logs: processInfo.getRecentLogs(50).map((log) => log.format()).toList(),
      ));
    }

    _cleanupProcess(processId);
  }

  Future<void> _recordPlayTime(String processId) async {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    if (processInfo.readyTime != null && processInfo.stopTime != null) {
      final playTime = processInfo.stopTime!.difference(processInfo.readyTime!);
      _logger.info('Recorded play time: ${playTime.inSeconds} seconds');
      _eventBus.publish(PlayTimeRecordedEvent(
        version: processInfo.arguments.gameVersion,
        playTime: playTime,
      ));

      try {
        final instanceManager = InstanceManager();
        final instances = instanceManager.instances;
        try {
          final instance = instances.firstWhere(
            (i) => i.version == processInfo.arguments.gameVersion,
          );
          await instanceManager.updateInstance(
            id: instance.id,
            playTimeSeconds: (instance.playTimeSeconds ?? 0) + playTime.inSeconds,
          );
        } catch (e) {
          // Instance not found, that's okay
        }
      } catch (e) {
        _logger.warn('Failed to update play time: $e');
      }
    }
  }

  void _handleLaunchError(String processId, Object error, StackTrace stackTrace) {
    _logger.error('Failed to launch game', error, stackTrace);
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    processInfo.status = GameProcessStatus.crashed;
    processInfo.errorMessage = error.toString();
    processInfo.stopTime = DateTime.now();
    _statusControllers[processId]?.add(GameProcessStatus.crashed);
    _eventBus.publish(GameCrashedEvent(
      processId: processId,
      error: error.toString(),
    ));

    _cleanupProcess(processId);
  }

  void _updateLaunchingStep(String processId, int step) {
    _updateLaunchingState(processId, (state) => state.copyWith(currentStep: step));
  }

  void _updateLaunchingState(String processId, LaunchingState Function(LaunchingState) updater) {
    final state = _launchingStates[processId];
    if (state == null) return;
    _launchingStates[processId] = updater(state);
  }

  void _cleanupProcess(String processId) {
    _processes.remove(processId);
    _runningProcesses.remove(processId);
    _launchingStates.remove(processId);

    Future.delayed(const Duration(seconds: 10), () {
      _logControllers[processId]?.close();
      _statusControllers[processId]?.close();
      _logControllers.remove(processId);
      _statusControllers.remove(processId);
    });
  }
}
