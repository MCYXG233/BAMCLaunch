import '../../instance/instance_manager.dart';
import '../../instance/resource_manager.dart' as inst_res;
import '../service_locator.dart';

/// 实例管理服务注册
void registerInstanceRegistry(ServiceLocator locator) {
  // InstanceManager - 实例管理器
  locator.registerLazySingleton<InstanceManager>(
    () => InstanceManager.instance,
  );

  // ResourceManager (instance/) - 实例资源管理器
  locator.registerLazySingleton<inst_res.ResourceManager>(
    () => inst_res.ResourceManager.instance,
  );
}
