import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../content/content_manager.dart';
import 'interfaces/i_server_manager.dart';
import 'implementations/server_manager.dart';

export 'interfaces/i_server_manager.dart';
export 'implementations/server_manager.dart';
export 'models/server_models.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IServerManager serverManager = ServerManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
  contentManager: contentManager,
);