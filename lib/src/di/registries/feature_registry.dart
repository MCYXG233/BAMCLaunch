import '../../modpack/modpack_manager.dart';
import '../../extension/extension_manager.dart';
import '../../updater/update_manager.dart';
import '../../features/launch/window_controller.dart';
import '../../features/launch/native_extractor.dart';
import '../../backup/auto_backup_service.dart';
import '../../backup/backup_tag.dart';
import '../../i18n/ba_localization.dart';
import '../../game_hud/game_hud_manager.dart';
import '../../ui/theme/background_manager.dart';
import '../../ui/layout/layout_manager.dart';
import '../service_locator.dart';

/// 功能扩展服务注册
///
/// 注册整合包、扩展、更新、备份、窗口控制、国际化、背景、布局、HUD 等功能服务。
void registerFeatureRegistry(ServiceLocator locator) {
  // ModpackManager - 整合包管理器
  locator.registerLazySingleton<ModpackManager>(
    () => ModpackManager.instance,
  );

  // ExtensionManager - 扩展管理器
  locator.registerLazySingleton<ExtensionManager>(
    () => ExtensionManager.instance,
  );

  // UpdateManager - 更新管理器
  locator.registerLazySingleton<UpdateManager>(() => UpdateManager.instance);

  // WindowManager - 窗口控制器
  locator.registerLazySingleton<WindowController>(
    () => WindowController.instance,
  );

  // NativeExtractor - 原生库提取器
  locator.registerLazySingleton<NativeExtractor>(
    () => NativeExtractor.instance,
  );

  // AutoBackupService - 自动备份服务
  locator.registerLazySingleton<AutoBackupService>(
    () => AutoBackupService.instance,
  );

  // BackupTagManager - 备份标签管理器
  locator.registerLazySingleton<BackupTagManager>(
    () => BackupTagManager.instance,
  );

  // BALocalizations - 国际化
  locator.registerLazySingleton<BALocalizations>(
    () => BALocalizations.instance,
  );

  // BackgroundManager - 背景管理器
  locator.registerLazySingleton<BackgroundManager>(
    () => BackgroundManager.instance,
  );

  // LayoutManager - 布局管理器
  locator.registerLazySingleton<LayoutManager>(() => LayoutManager());

  // GameHUDManager - 游戏 HUD 管理器
  locator.registerLazySingleton<GameHUDManager>(
    () => GameHUDManager.instance,
  );
}
