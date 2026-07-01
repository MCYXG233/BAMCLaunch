import 'service_locator.dart';

// Core 基础设施
import '../core/logger.dart';
import '../core/error_handler.dart';
import '../core/privacy_manager.dart';
import '../event/event_bus.dart';

// 配置
import '../config/config_manager.dart';
import '../config/config_manager_impl.dart';

// 平台
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';

// 认证
import '../auth/auth_manager.dart';
import '../auth/authlib_injector.dart';
import '../auth/authlib_login.dart';
import '../auth/local_yggdrasil_server.dart';
import '../auth/oauth_service.dart';

// 账户 & 皮肤
import '../account/account_manager.dart';
import '../account/skin_manager.dart';
import '../features/skin/cape_manager.dart';
import '../features/skin/skin_preview_3d.dart';

// 实例管理
import '../instance/instance_manager.dart';
import '../instance/resource_manager.dart' as inst_res;

// 游戏启动 & Java
import '../game/launcher/game_launcher.dart';
import '../game/launcher/game_file_validator.dart';
import '../game/launcher/native_library_manager.dart';
import '../game/launcher/process_monitor.dart';
import '../game/java/java_manager.dart';
import '../game/java/java_downloader.dart';
import '../game/backup_manager.dart';
import '../game/game_statistics.dart';

// 版本 & 安装器
import '../version/version_manager.dart';
import '../version/optifine_installer.dart';
import '../version/quilt_installer.dart';

// 下载
import '../download/download_engine.dart';
import '../download/download_source.dart';
import '../download/mirror_manager.dart';
import '../download/queue_manager.dart';

// 资源中心
import '../resource_center/resource_manager.dart';
import '../resource_center/download_manager.dart';
import '../resource_center/download_service.dart';
import '../resource_center/favorite_manager.dart';
import '../resource_center/search_service.dart';

// Mod 管理
import '../mod/mod_manager.dart' as mod;
import '../resource/mod_manager.dart' as res_mod;
import '../resource/resource_update_checker.dart';
import '../mod/mod_loader_manager.dart';

// 加载器
import '../loader/loader_download_service.dart';
import '../loader/java_download_service.dart';

// 网络
import '../network/terracotta_manager.dart';

// 系统
import '../system/log_manager.dart';
import '../system/system_diagnostics.dart';
import '../statistics/play_time_tracker.dart';

// 功能模块
import '../features/launch/window_controller.dart';
import '../features/launch/native_extractor.dart';
import '../backup/auto_backup_service.dart';
import '../backup/backup_tag.dart';
import '../extension/extension_manager.dart';
import '../modpack/modpack_manager.dart';
import '../updater/update_manager.dart';
import '../i18n/ba_localization.dart';
import '../game_hud/game_hud_manager.dart';
import '../ui/theme/background_manager.dart';
import '../ui/layout/layout_manager.dart';

/// 统一服务注册表
///
/// 在应用启动时调用 [initialize] 注册所有管理器服务。
/// 后续通过 [get] 获取服务实例，替代直接访问 `XxxManager.instance`。
///
/// ## 使用示例
/// ```dart
/// // main.dart 启动时
/// await ServiceRegistry.initialize();
///
/// // 任意位置获取服务
/// final logger = ServiceRegistry.get<Logger>();
/// ```
///
/// ## 迁移指南
///
/// ### Phase 1（已完成）：注册所有现有单例
/// 本类注册所有管理器的懒加载工厂，工厂内部调用各管理器的 `.instance` getter。
/// 现有代码中的 `XxxManager.instance` 调用无需修改，完全兼容。
///
/// ### Phase 2（逐步进行）：新代码统一使用 ServiceRegistry
/// 新代码应使用 `ServiceRegistry.get<T>()` 获取服务实例。
///
/// ### Phase 3（未来）：移除手动单例
/// 当所有消费者迁移到 ServiceRegistry 后，各管理器可移除自身的 `_instance` 字段
/// 和 `static get instance` getter。
class ServiceRegistry {
  ServiceRegistry._();

  static bool _initialized = false;

  /// 是否已初始化
  static bool get isInitialized => _initialized;

  /// 初始化服务注册表
  ///
  /// 按依赖顺序注册所有服务。使用懒加载模式，
  /// 服务仅在首次被访问时才真正创建。
  static Future<void> initialize() async {
    if (_initialized) return;

    final locator = ServiceLocator.instance;

    // ━━━ Phase 1：核心基础设施（无外部依赖）━━━
    _registerCore(locator);

    // ━━━ Phase 2：平台适配层（依赖核心）━━━
    _registerPlatform(locator);

    // ━━━ Phase 3：配置管理（依赖平台）━━━
    _registerConfig(locator);

    // ━━━ Phase 4：认证与账户 ━━━
    _registerAuth(locator);

    // ━━━ Phase 5：实例与游戏管理 ━━━
    _registerInstanceAndGame(locator);

    // ━━━ Phase 6：下载与资源 ━━━
    _registerDownloadAndResource(locator);

    // ━━━ Phase 7：其他管理器 ━━━
    _registerMisc(locator);

    _initialized = true;
  }

  /// 获取服务实例
  ///
  /// 等价于 `ServiceLocator.instance.get<T>()`。
  static T get<T>() => ServiceLocator.instance.get<T>();

  /// 尝试获取服务实例，未注册时返回 null
  static T? tryGet<T>() => ServiceLocator.instance.tryGet<T>();

  /// 检查服务是否已注册
  static bool isRegistered<T>() => ServiceLocator.instance.isRegistered<T>();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 分组注册
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static void _registerCore(ServiceLocator locator) {
    // EventBus - 全局事件总线，几乎所有模块都依赖
    locator.registerLazySingleton<EventBus>(() => EventBus.instance);

    // Logger - 日志系统
    locator.registerLazySingleton<Logger>(() => Logger.instance);

    // ErrorHandler - 全局异常处理（依赖 Logger, EventBus）
    locator.registerLazySingleton<ErrorHandler>(() => ErrorHandler.instance);

    // PrivacyManager - 隐私管理
    locator.registerLazySingleton<PrivacyManager>(() => PrivacyManager());
  }

  static void _registerPlatform(ServiceLocator locator) {
    // PlatformAdapterFactory - 平台适配器
    locator.registerLazySingleton<IPlatformAdapter>(
      () => PlatformAdapterFactory.instance,
    );
  }

  static void _registerConfig(ServiceLocator locator) {
    // ConfigManager - 配置管理器
    locator.registerLazySingleton<ConfigManager>(() => ConfigManager.instance);

    // ConfigManagerImpl - 配置管理器实现
    locator.registerLazySingleton<ConfigManagerImpl>(() => ConfigManagerImpl());
  }

  static void _registerAuth(ServiceLocator locator) {
    // AuthManager - 认证管理器
    locator.registerLazySingleton<AuthManager>(() => AuthManager.instance);

    // AccountManager - 账户管理器
    locator.registerLazySingleton<AccountManager>(() => AccountManager.instance);

    // SkinManager - 皮肤管理器
    locator.registerLazySingleton<SkinManager>(() => SkinManager.instance);

    // CapeManager - 披风管理器
    locator.registerLazySingleton<CapeManager>(() => CapeManager.instance);

    // OAuthService - OAuth 服务
    locator.registerLazySingleton<OAuthService>(() => OAuthService.instance);

    // AuthlibInjector - Authlib 注入器
    locator.registerLazySingleton<AuthlibInjector>(() => AuthlibInjector.instance);

    // AuthlibLoginManager - Authlib 登录管理器
    locator.registerLazySingleton<AuthlibLoginManager>(
      () => AuthlibLoginManager.instance,
    );

    // LocalYggdrasilServer - 本地 Yggdrasil 服务器
    locator.registerLazySingleton<LocalYggdrasilServer>(
      () => LocalYggdrasilServer.instance,
    );
  }

  static void _registerInstanceAndGame(ServiceLocator locator) {
    // InstanceManager - 实例管理器
    locator.registerLazySingleton<InstanceManager>(
      () => InstanceManager.instance,
    );

    // ResourceManager (instance/) - 实例资源管理器
    locator.registerLazySingleton<inst_res.ResourceManager>(
      () => inst_res.ResourceManager.instance,
    );

    // GameLauncher - 游戏启动器
    locator.registerLazySingleton<GameLauncher>(() => GameLauncher.instance);

    // GameFileValidator - 游戏文件校验器
    locator.registerLazySingleton<GameFileValidator>(
      () => GameFileValidator.instance,
    );

    // NativeLibraryManager - 原生库管理器
    locator.registerLazySingleton<NativeLibraryManager>(
      () => NativeLibraryManager.instance,
    );

    // ProcessMonitorManager - 进程监控管理器
    locator.registerLazySingleton<ProcessMonitorManager>(
      () => ProcessMonitorManager.instance,
    );

    // JavaManager - Java 管理器
    locator.registerLazySingleton<JavaManager>(() => JavaManager.instance);

    // JavaDownloader - Java 下载器
    locator.registerLazySingleton<JavaDownloader>(() => JavaDownloader.instance);

    // VersionManager - 版本管理器
    locator.registerLazySingleton<VersionManager>(() => VersionManager.instance);

    // OptiFineInstaller - OptiFine 安装器
    locator.registerLazySingleton<OptiFineInstaller>(
      () => OptiFineInstaller(),
    );

    // QuiltInstaller - Quilt 安装器
    locator.registerLazySingleton<QuiltInstaller>(() => QuiltInstaller.instance);

    // BackupManager - 备份管理器
    locator.registerLazySingleton<BackupManager>(() => BackupManager.instance);

    // GameStatisticsManager - 游戏统计管理器
    locator.registerLazySingleton<GameStatisticsManager>(
      () => GameStatisticsManager.instance,
    );

    // PlayTimeTracker - 游戏时间追踪
    locator.registerLazySingleton<PlayTimeTracker>(
      () => PlayTimeTracker.instance,
    );
  }

  static void _registerDownloadAndResource(ServiceLocator locator) {
    // DownloadEngine - 下载引擎
    locator.registerLazySingleton<DownloadEngine>(() => DownloadEngine.instance);

    // DownloadQueueManager - 下载队列管理器
    locator.registerLazySingleton<DownloadQueueManager>(
      () => DownloadQueueManager.instance,
    );

    // MirrorSourceManager - 镜像源管理器
    locator.registerLazySingleton<MirrorSourceManager>(
      () => MirrorSourceManager.instance,
    );

    // MirrorManager - 镜像管理器
    locator.registerLazySingleton<MirrorManager>(() => MirrorManager.instance);

    // ResourceManager (resource_center/) - 资源中心管理器
    locator.registerLazySingleton<ResourceManager>(
      () => ResourceManager.instance,
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

    // ModManager (mod/) - Mod 管理器
    locator.registerLazySingleton<mod.ModManager>(() => mod.ModManager.instance);

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

    // LoaderDownloadService - 加载器下载服务
    locator.registerLazySingleton<LoaderDownloadService>(
      () => LoaderDownloadService.instance,
    );

    // JavaDownloadService - Java 下载服务
    locator.registerLazySingleton<JavaDownloadService>(
      () => JavaDownloadService.instance,
    );
  }

  static void _registerMisc(ServiceLocator locator) {
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

    // TerracottaManager - 网络管理器
    locator.registerLazySingleton<TerracottaManager>(
      () => TerracottaManager(),
    );

    // LogManager - 日志管理器
    locator.registerLazySingleton<LogManager>(() => LogManager.instance);

    // SystemDiagnostics - 系统诊断
    locator.registerLazySingleton<SystemDiagnostics>(
      () => SystemDiagnostics.instance,
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

    // SkinPreviewManager - 皮肤预览管理器
    locator.registerLazySingleton<SkinPreviewManager>(
      () => SkinPreviewManager.instance,
    );
  }
}
