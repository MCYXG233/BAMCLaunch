import '../../network/terracotta_manager.dart';
import '../service_locator.dart';

/// 网络服务注册
void registerNetworkRegistry(ServiceLocator locator) {
  // TerracottaManager - 网络管理器
  locator.registerLazySingleton<TerracottaManager>(() => TerracottaManager());
}
