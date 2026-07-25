import '../../version/version_manager.dart';
import '../../version/optifine_installer.dart';
import '../../version/quilt_installer.dart';
import '../service_locator.dart';

/// 版本与安装器服务注册
void registerVersionRegistry(ServiceLocator locator) {
  // VersionManager - 版本管理器
  locator.registerLazySingleton<VersionManager>(
    () => VersionManager.instance,
  );

  // OptiFineInstaller - OptiFine 安装器
  locator.registerLazySingleton<OptiFineInstaller>(() => OptiFineInstaller());

  // QuiltInstaller - Quilt 安装器
  locator.registerLazySingleton<QuiltInstaller>(
    () => QuiltInstaller.instance,
  );
}
