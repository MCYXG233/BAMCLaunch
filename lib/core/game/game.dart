import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../version/version.dart';
import 'interfaces/i_game_launcher.dart';
import 'implementations/game_launcher.dart';

/// 导出游戏相关的接口和实现
export 'interfaces/i_game_launcher.dart';
export 'implementations/game_launcher.dart';
export 'implementations/java_manager.dart';
export 'implementations/launch_arguments_builder.dart';
export 'implementations/game_launch_process_manager.dart';
export 'models/game_launch_models.dart';
export 'game_launcher_example.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局游戏启动器单例
/// 用于启动和管理游戏进程
final IGameLauncher gameLauncher = GameLauncher(
  platformAdapter: platformAdapter,  // 平台适配器，提供跨平台操作
  logger: logger,                  // 日志记录器，用于记录启动过程
  downloadEngine: downloadEngine,    // 下载引擎，用于下载游戏文件
  versionManager: versionManager,    // 版本管理器，用于管理游戏版本
);
