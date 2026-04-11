import '../platform/platform.dart';
import '../download/download.dart';
import 'interfaces/i_content_manager.dart';
import 'implementations/content_manager.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IContentManager contentManager = ContentManager(
  platformAdapter: platformAdapter,
  downloadEngine: downloadEngine,
);