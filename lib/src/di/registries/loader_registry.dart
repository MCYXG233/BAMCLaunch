import '../../loader/loader_download_service.dart';
import '../../loader/java_download_service.dart';
import '../service_locator.dart';

/// 加载器下载服务注册
void registerLoaderRegistry(ServiceLocator locator) {
  // LoaderDownloadService - 加载器下载服务
  locator.registerLazySingleton<LoaderDownloadService>(
    () => LoaderDownloadService.instance,
  );

  // JavaDownloadService - Java 下载服务
  locator.registerLazySingleton<JavaDownloadService>(
    () => JavaDownloadService.instance,
  );
}
