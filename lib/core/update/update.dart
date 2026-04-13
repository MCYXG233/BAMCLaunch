import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../config/config.dart';
import 'interfaces/i_update_manager.dart';
import 'implementations/update_manager.dart';

export 'interfaces/i_update_manager.dart';
export 'implementations/update_manager.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IUpdateManager updateManager = UpdateManager(
  platformAdapter: platformAdapter,
  configManager: configManager,
  downloadEngine: downloadEngine,
  logger: logger,
);