import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../content/content_manager.dart';
import 'interfaces/i_modpack_manager.dart';
import 'implementations/modpack_manager.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IModpackManager modpackManager = ModpackManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
  contentManager: contentManager,
);