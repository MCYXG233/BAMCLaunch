import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../content/content_manager.dart';
import 'interfaces/i_modpack_manager.dart';
import 'implementations/modpack_manager.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局模组包管理器单例
/// 用于管理模组包的安装和更新
final IModpackManager modpackManager = ModpackManager(
  platformAdapter: platformAdapter,  // 平台适配器，提供跨平台操作
  logger: logger,                  // 日志记录器，用于记录模组包管理过程
  downloadEngine: downloadEngine,    // 下载引擎，用于下载模组包文件
  contentManager: contentManager,    // 内容管理器，用于处理模组内容
);