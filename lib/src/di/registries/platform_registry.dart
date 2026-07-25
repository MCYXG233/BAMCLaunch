import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../service_locator.dart';

/// 平台适配层注册
void registerPlatformRegistry(ServiceLocator locator) {
  // PlatformAdapterFactory - 平台适配器
  locator.registerLazySingleton<IPlatformAdapter>(
    () => PlatformAdapterFactory.instance,
  );
}
