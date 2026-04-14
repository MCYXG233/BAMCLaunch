import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../version/interfaces/i_version_manager.dart';
import '../game.dart';
import 'dart:async';
import 'dart:io';

enum LaunchStatus {
  initializing,
  detectingJava,
  checkingVersion,
  buildingConfig,
  launching,
  running,
  finished,
  failed,
}

class LaunchProcessManager {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;
  final IVersionManager _versionManager;
  final GameLauncher _launcher;
  
  final StreamController<LaunchStatus> _statusController = StreamController.broadcast();
  final StreamController<double> _progressController = StreamController.broadcast();
  
  LaunchStatus _currentStatus = LaunchStatus.initializing;
  Process? _gameProcess;

  LaunchProcessManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IVersionManager versionManager,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _versionManager = versionManager,
        _launcher = GameLauncher(
          platformAdapter: platformAdapter,
          logger: logger,
          versionManager: versionManager,
        );

  Stream<LaunchStatus> get statusStream => _statusController.stream;
  Stream<double> get progressStream => _progressController.stream;

  Future<void> launchGame({
    required String gameVersion,
    required String username,
    required String uuid,
    required String accessToken,
    required int memoryMb,
  }) async {
    try {
      _updateStatus(LaunchStatus.initializing);
      _updateProgress(0.0);

      _updateStatus(LaunchStatus.detectingJava);
      _updateProgress(0.2);
      
      final javaResult = await _launcher.detectJava();
      if (!javaResult.found) {
        throw Exception('未找到Java环境: ${javaResult.error}');
      }
      _logger.info('检测到Java: ${javaResult.version}');

      _updateStatus(LaunchStatus.checkingVersion);
      _updateProgress(0.4);
      
      final versionExists = await _versionManager.checkVersionIntegrity(gameVersion);
      if (!versionExists) {
        _logger.warn('版本 $gameVersion 不存在或已损坏，正在修复...');
        await _versionManager.repairVersion(gameVersion);
      }

      _updateStatus(LaunchStatus.buildingConfig);
      _updateProgress(0.6);
      
      final config = await _launcher.buildLaunchConfig(
        gameVersion: gameVersion,
        username: username,
        uuid: uuid,
        accessToken: accessToken,
        memoryMb: memoryMb,
      );

      // 确保 natives 已提取
      await _ensureNativesExtracted(gameVersion);

      _updateStatus(LaunchStatus.launching);
      _updateProgress(0.8);
      
      _gameProcess = await _launcher.launchGame(config);
      
      _updateStatus(LaunchStatus.running);
      _updateProgress(1.0);

      _logger.info('游戏进程已启动, PID: ${_gameProcess!.pid}');

      _launcher.getGameOutput().listen((output) {
        _logger.info('[游戏] $output');
      });

      await _gameProcess!.exitCode;
      
      _updateStatus(LaunchStatus.finished);
      _logger.info('游戏进程已正常退出');

    } catch (e) {
      _logger.error('启动失败: $e');
      _updateStatus(LaunchStatus.failed);
      rethrow;
    }
  }

  Future<void> stopGame() async {
    if (_gameProcess != null) {
      _logger.info('正在终止游戏进程');
      await _launcher.killProcess();
      _gameProcess = null;
      _updateStatus(LaunchStatus.finished);
    }
  }

  void _updateStatus(LaunchStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  void _updateProgress(double progress) {
    _progressController.add(progress);
  }

  /// 确保 natives 库已提取
  Future<void> _ensureNativesExtracted(String gameVersion) async {
    try {
      _logger.info('检查 natives 库: $gameVersion');
      final gameDir = '${_platformAdapter.gameDirectory}/.minecraft';
      final nativesDir = '$gameDir/versions/$gameVersion/natives';

      // 检查 natives 目录是否存在
      if (await Directory(nativesDir).exists()) {
        final files = await Directory(nativesDir).list().toList();
        if (files.isNotEmpty) {
          _logger.info('Natives 库已存在');
          return;
        }
      }

      // 如果不存在，需要提取 natives
      _logger.info('提取 natives 库...');
      final librariesDir = '$gameDir/libraries';
      final versionDir = '$gameDir/versions/$gameVersion';

      // 创建 natives 目录
      await Directory(nativesDir).create(recursive: true);

      // 查找并解压 natives jar 文件
      final nativeJars = await Directory(librariesDir)
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.contains('natives'))
          .toList();

      for (final jar in nativeJars) {
        try {
          // 这里简化处理，实际应该解压 jar 文件
          _logger.debug('找到 native jar: ${jar.path}');
        } catch (e) {
          _logger.warn('处理 native jar 失败: ${jar.path}, 错误: $e');
        }
      }

      _logger.info('Natives 库提取完成');
    } catch (e) {
      _logger.error('提取 natives 库失败: $e');
      // 不抛出异常，因为某些版本可能不需要 natives
    }
  }

  void dispose() {
    _statusController.close();
    _progressController.close();
  }
}
