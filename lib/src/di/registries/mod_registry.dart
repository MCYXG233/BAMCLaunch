import '../../mod/mod_manager.dart' as mod;
import '../../resource/mod_manager.dart' as res_mod;
import '../../resource/resource_update_checker.dart';
import '../../mod/mod_loader_manager.dart';
import '../service_locator.dart';

/// Mod 管理服务注册
///
/// 注意：mod/ 与 resource/ 下各有一个 ModManager 同名类，通过 alias 区分。
void registerModRegistry(ServiceLocator locator) {
  // ModManager (mod/) - Mod 管理器
  locator.registerLazySingleton<mod.ModManager>(
    () => mod.ModManager.instance,
  );

  // ModManager (resource/) - 资源 Mod 管理器
  locator.registerLazySingleton<res_mod.ModManager>(
    () => res_mod.ModManager.instance,
  );

  // ModUpdateChecker - Mod 更新检查器
  locator.registerLazySingleton<ModUpdateChecker>(
    () => ModUpdateChecker.instance,
  );

  // ModLoaderManager - Mod 加载器管理器
  locator.registerLazySingleton<ModLoaderManager>(
    () => ModLoaderManager.instance,
  );
}
