import 'platform/platform.dart';
import 'download/download.dart';
import 'http/i_http_client.dart';
import 'http/implementations/http_client.dart';
import 'logger/logger.dart';
import 'config/config.dart';
import 'version/version.dart';
import 'game/game.dart';
import 'content/content_manager.dart';
import 'modpack/modpack.dart';
import 'server/server.dart';
import 'update/update.dart';
import 'auth/auth.dart';

/// 全局平台适配器单例
final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();

/// 全局下载引擎单例
final IDownloadEngine downloadEngine = DownloadEngine();

/// 全局HTTP客户端单例
final IHttpClient httpClient = HttpClient();

/// 全局版本管理器单例
final IVersionManager versionManager = VersionManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
);

/// 全局游戏启动器单例
final IGameLauncher gameLauncher = GameLauncher(
  platformAdapter: platformAdapter,
  logger: logger,
);

/// 全局内容管理器单例
final IContentManager contentManager = ContentManager(
  httpClient: httpClient,
  logger: logger,
  downloadEngine: downloadEngine,
);

/// 全局模组包管理器单例
final IModpackManager modpackManager = ModpackManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
  contentManager: contentManager,
);

/// 全局服务器管理器单例
final IServerManager serverManager = ServerManager(
  configManager: configManager,
  logger: logger,
);

/// 全局更新管理器单例
final IUpdateManager updateManager = UpdateManager(
  platformAdapter: platformAdapter,
  logger: logger,
);

/// 全局账户管理器单例
final AccountManager accountManager = AccountManager(
  configManager,
  logger,
);
