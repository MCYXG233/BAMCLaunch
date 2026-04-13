import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../config/config.dart';
import 'interfaces/i_update_manager.dart';
import 'implementations/update_manager.dart';

/// 导出更新相关的接口和实现
export 'interfaces/i_update_manager.dart';
export 'implementations/update_manager.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局更新管理器单例
/// 用于检查和安装应用更新
final IUpdateManager updateManager = UpdateManager(
  platformAdapter: platformAdapter,  // 平台适配器，提供跨平台操作
  configManager: configManager,      // 配置管理器，用于存储更新设置
  downloadEngine: downloadEngine,    // 下载引擎，用于下载更新文件
  logger: logger,                  // 日志记录器，用于记录更新过程
);