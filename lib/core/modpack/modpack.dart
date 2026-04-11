import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../version/implementations/version_manager.dart';
import '../version/interfaces/i_version_manager.dart';
import 'interfaces/i_modpack_manager.dart';
import 'implementations/modpack_manager.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IVersionManager versionManager = VersionManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
);
final IModpackManager modpackManager = ModpackManager(
  platformAdapter: platformAdapter,
  logger: logger,
  versionManager: versionManager,
  downloadEngine: downloadEngine,
);