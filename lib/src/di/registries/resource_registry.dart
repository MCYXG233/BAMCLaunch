import '../../resource_center/resource_manager.dart' as online_res;
import '../../resource_center/download_manager.dart';
import '../../resource_center/download_service.dart';
import '../../resource_center/favorite_manager.dart';
import '../../resource_center/search_service.dart';
import '../service_locator.dart';

/// 在线资源中心服务注册
///
/// 注册资源管理、下载、收藏、搜索等服务。
/// 注意：与 instance/resource_manager.dart 的 ResourceManager 同名，通过 alias 区分。
void registerResourceRegistry(ServiceLocator locator) {
  // ResourceManager (resource_center/) - 在线资源管理器
  locator.registerLazySingleton<online_res.ResourceManager>(
    () => online_res.ResourceManager.instance,
  );

  // DownloadManager (resource_center/) - 资源下载管理器
  locator.registerLazySingleton<DownloadManager>(
    () => DownloadManager.instance,
  );

  // DownloadService (resource_center/) - 资源下载服务
  locator.registerLazySingleton<DownloadService>(
    () => DownloadService.instance,
  );

  // FavoriteManager - 收藏管理器
  locator.registerLazySingleton<FavoriteManager>(
    () => FavoriteManager.instance,
  );

  // SearchService - 搜索服务
  locator.registerLazySingleton<SearchService>(() => SearchService.instance);
}
