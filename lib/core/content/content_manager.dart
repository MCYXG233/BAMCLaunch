import '../platform/platform.dart';
import '../download/download.dart';
import '../http/i_http_client.dart';
import '../http/implementations/http_client.dart';
import '../logger/logger.dart';
import 'interfaces/i_content_manager.dart';
import 'implementations/content_manager.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局HTTP客户端单例
/// 用于网络请求操作
final IHttpClient httpClient = HttpClient();

/// 全局内容管理器单例
/// 用于管理游戏内容的下载和处理
final IContentManager contentManager = ContentManager(
  httpClient: httpClient,      // HTTP客户端，用于网络请求
  logger: logger,              // 日志记录器，用于记录内容管理过程
  downloadEngine: downloadEngine,  // 下载引擎，用于下载内容文件
);