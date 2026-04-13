import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../content/content_manager.dart';
import 'interfaces/i_server_manager.dart';
import 'implementations/server_manager.dart';

/// 导出服务器相关的接口和实现
export 'interfaces/i_server_manager.dart';
export 'implementations/server_manager.dart';
export 'models/server_models.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局服务器管理器单例
/// 用于管理游戏服务器的创建和启动
final IServerManager serverManager = ServerManager(
  platformAdapter: platformAdapter,  // 平台适配器，提供跨平台操作
  logger: logger,                  // 日志记录器，用于记录服务器管理过程
  downloadEngine: downloadEngine,    // 下载引擎，用于下载服务器文件
  contentManager: contentManager,    // 内容管理器，用于处理服务器内容
);