import '../platform/i_platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../logger/i_logger.dart';
import '../logger/logger_impl.dart';
import '../version/interfaces/i_version_manager.dart';
import '../version/implementations/version_manager.dart';
import '../download/download_engine.dart';
import '../download/i_download_engine.dart';
import 'game.dart';

class GameLauncherExample {
  static Future<void> runExample() async {
    final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
    final ILogger logger = LoggerImpl();
    final IDownloadEngine downloadEngine = DownloadEngine();
    final IVersionManager versionManager = VersionManager(
      platformAdapter: platformAdapter,
      logger: logger,
      downloadEngine: downloadEngine,
    );

    final GameLauncher launcher = GameLauncher(
      platformAdapter: platformAdapter,
      logger: logger,
      versionManager: versionManager,
    );

    try {
      logger.info('=== BAMCLauncher 游戏启动示例 ===');

      logger.info('1. 检测Java环境...');
      final javaResult = await launcher.detectJava();
      if (javaResult.found) {
        logger.info('✓ 找到Java: ${javaResult.version}');
      } else {
        logger.error('✗ 未找到Java: ${javaResult.error}');
        return;
      }

      logger.info('2. 优化JVM参数...');
      final jvmArgs = await launcher.optimizeJvmParameters('1.20.1', 4096);
      logger.info('JVM参数: $jvmArgs');

      logger.info('3. 构建启动配置...');
      final config = await launcher.buildLaunchConfig(
        gameVersion: '1.20.1',
        username: 'Player',
        uuid: '00000000-0000-0000-0000-000000000000',
        accessToken: 'dummy_token',
        memoryMb: 4096,
      );

      logger.info('启动配置准备完成');
      logger.info('游戏版本: ${config.gameVersion}');
      logger.info('Java路径: ${config.javaPath}');
      logger.info('内存分配: ${config.memoryMb}MB');

      logger.info('4. 启动游戏...');
      final process = await launcher.launchGame(config);
      
      logger.info('游戏进程已启动, PID: ${process.pid}');

      launcher.getGameOutput().listen((output) {
        logger.info('[游戏输出] $output');
      });

      launcher.getProcessSignals().listen((signal) {
        switch (signal) {
          case ProcessSignal.started:
            logger.info('游戏进程已启动');
            break;
          case ProcessSignal.exited:
            logger.info('游戏进程已退出');
            break;
          case ProcessSignal.error:
            logger.error('游戏进程启动失败');
            break;
        }
      });

      await process.exitCode;
      logger.info('游戏已结束');

    } catch (e) {
      logger.error('启动失败: $e');
    }
  }
}
