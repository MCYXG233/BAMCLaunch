import '../../account/account_manager.dart';
import '../../account/account_store.dart';
import '../../account/skin_manager.dart';
import '../../features/skin/cape_manager.dart';
import '../../features/skin/skin_preview_3d.dart';
import '../service_locator.dart';

/// 账户与皮肤服务注册
///
/// 注册账户持久化存储、账户管理、皮肤与披风管理等服务。
void registerAccountRegistry(ServiceLocator locator) {
  // AccountStore - 账户持久化存储（统一 AuthManager 和 AccountManager 的存储路径）
  locator.registerLazySingleton<AccountStore>(() => AccountStore.instance);

  // AccountManager - 账户管理器
  locator.registerLazySingleton<AccountManager>(() => AccountManager.instance);

  // SkinManager - 皮肤管理器
  locator.registerLazySingleton<SkinManager>(() => SkinManager.instance);

  // CapeManager - 披风管理器
  locator.registerLazySingleton<CapeManager>(() => CapeManager.instance);

  // SkinPreviewManager - 皮肤预览管理器
  locator.registerLazySingleton<SkinPreviewManager>(
    () => SkinPreviewManager.instance,
  );
}
