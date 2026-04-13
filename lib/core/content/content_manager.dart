import '../platform/platform.dart';
import '../download/download.dart';
import '../http/implementations/http_client.dart';
import '../logger/logger.dart';
import 'interfaces/i_content_manager.dart';
import 'implementations/content_manager.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IDownloadEngine downloadEngine = DownloadEngine();
final IHttpClient httpClient = HttpClient();
final IContentManager contentManager = ContentManager(
  httpClient: httpClient,
  logger: logger,
  downloadEngine: downloadEngine,
);