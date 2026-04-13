import '../platform/platform.dart';
import '../logger/logger.dart';
import '../download/download.dart';
import '../version/implementations/version_manager.dart';
import 'interfaces/i_game_launcher.dart';
import 'implementations/game_launcher.dart';

export 'interfaces/i_game_launcher.dart';
export 'implementations/game_launcher.dart';
export 'implementations/java_manager.dart';
export 'implementations/launch_arguments_builder.dart';
export 'implementations/game_launch_process_manager.dart';
export 'models/game_launch_models.dart';
export 'game_launcher_example.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IVersionManager versionManager = VersionManager(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
);
final IGameLauncher gameLauncher = GameLauncher(
  platformAdapter: platformAdapter,
  logger: logger,
  downloadEngine: downloadEngine,
  versionManager: versionManager,
);
