import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import 'interfaces/i_version_manager.dart';
import 'implementations/version_manager.dart';

export 'interfaces/i_version_manager.dart';
export 'models/version_models.dart';
export 'implementations/version_manager.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局版本管理器单例
/// 用于管理游戏版本的下载和安装
final IVersionManager versionManager = VersionManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
);