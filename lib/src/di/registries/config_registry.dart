import '../../config/config_manager.dart';
import '../../config/config_manager_impl.dart';
import '../service_locator.dart';

/// 配置管理注册
void registerConfigRegistry(ServiceLocator locator) {
  // IConfigManager - 配置管理器（唯一注册，ConfigManagerImpl 为实现类）
  locator.registerLazySingleton<IConfigManager>(() => ConfigManagerImpl());
}
