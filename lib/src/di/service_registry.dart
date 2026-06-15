import 'service_locator.dart';
import '../account/account_manager.dart';
import '../instance/instance_manager.dart';
import '../download/download_engine.dart';
import '../auth/auth_manager.dart';
import '../platform/platform_adapter.dart';
import '../config/config_manager.dart';
import '../mod/mod_manager.dart';
import '../game/game_launcher.dart';
import '../resource_center/resource_center.dart';

import '../core/logger.dart';
import '../event/event_bus.dart';

/// 服务注册器
/// 
/// 负责注册所有服务到 ServiceLocator
class ServiceRegistry {
  ServiceRegistry._();

  /// 注册所有服务
  static Future<void> registerAllServices(ServiceLocator locator) async {
    // 平台适配器（单例）
    final platformAdapter = PlatformAdapterFactory.createAdapter();
    locator.registerSingleton<IPlatformAdapter>(platformAdapter);

    // 配置管理器（单例）
    final configManager = ConfigManagerImpl();
    await configManager.initialize();
    locator.registerSingleton<IConfigManager>(configManager);

    // 事件总线（单例）
    final eventBus = EventBus();
    locator.registerSingleton<EventBus>(eventBus);
    // 设置静态实例以兼容旧代码
    EventBus.setInstance(eventBus);

    // 日志系统（单例）
    final logger = Logger(
      platformAdapter: platformAdapter,
      eventBus: eventBus,
    );
    await logger.initialize();
    locator.registerSingleton<Logger>(logger);
    // 设置静态实例以兼容旧代码
    Logger.setInstance(logger);

    // 账户管理器（单例）
    final accountManager = AccountManager(
      platformAdapter: platformAdapter,
      configManager: configManager,
    );
    await accountManager.initialize();
    locator.registerSingleton<AccountManager>(accountManager);

    // 实例管理器（单例）
    final instanceManager = InstanceManager(
      platformAdapter: platformAdapter,
      configManager: configManager,
    );
    await instanceManager.initialize();
    locator.registerSingleton<InstanceManager>(instanceManager);
    // 设置静态实例以兼容旧代码
    InstanceManager.setInstance(instanceManager);

    // 下载引擎（单例）
    final downloadEngine = DownloadEngine(
      platformAdapter: platformAdapter,
      configManager: configManager,
    );
    await downloadEngine.initialize();
    locator.registerSingleton<DownloadEngine>(downloadEngine);

    // 认证管理器（单例）
    final authManager = AuthManager(
      platformAdapter: platformAdapter,
      configManager: configManager,
      accountManager: accountManager,
    );
    await authManager.initialize();
    locator.registerSingleton<AuthManager>(authManager);
    // 设置静态实例以兼容旧代码
    AuthManager.setInstance(authManager);

    // Mod 管理器（单例）
    final modManager = ModManager(
      platformAdapter: platformAdapter,
    );
    locator.registerSingleton<ModManager>(modManager);

    // 游戏启动器（单例）
    final gameLauncher = GameLauncher(
      platformAdapter: platformAdapter,
      configManager: configManager,
      accountManager: accountManager,
      instanceManager: instanceManager,
    );
    locator.registerSingleton<GameLauncher>(gameLauncher);
    // 设置静态实例以兼容旧代码
    GameLauncher.setInstance(gameLauncher);

    // 资源中心（单例）
    final resourceCenter = ResourceCenter(
      downloadEngine: downloadEngine,
    );
    locator.registerSingleton<ResourceCenter>(resourceCenter);
  }
}
