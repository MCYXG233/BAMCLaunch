import 'package:flutter/foundation.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../config/config_manager.dart';
import '../event/event_bus.dart';
import '../core/logger.dart';
import '../download/download_engine.dart';
import '../version/version_manager.dart';
import '../instance/instance_manager.dart';
import '../account/account_manager.dart';
import '../game/launcher/game_launcher.dart';
import '../auth/auth_manager.dart';
import '../theme/theme_manager.dart';
import '../background/background_manager.dart';
import '../skin/skin_manager.dart';
import '../backup/backup_manager.dart';
import '../mod/mod_manager.dart';
import '../resource/resource_center.dart';
import '../statistics/statistics_manager.dart';

/// 依赖注入容器
/// 
/// **重要**：此容器不是单例，应通过 Provider 注入到 Widget 树中。
/// 每个测试应创建独立的 ServiceLocator 实例以实现隔离。
/// 
/// 提供轻量级的依赖管理功能，支持：
/// - 服务注册（单例模式）
/// - 工厂注册（每次调用创建新实例）
/// - 延迟注册（首次访问时创建）
/// - 服务查找和注入
/// 
/// 使用方式：
/// ```dart
/// // 创建容器（应用启动时）
/// final locator = ServiceLocator();
/// 
/// // 注册服务
/// locator.register<Logger>(() => Logger(locator.get<IPlatformAdapter>()));
/// locator.registerSingleton<ConfigManager>(ConfigManager());
/// 
/// // 获取服务
/// final logger = locator.get<Logger>();
/// final configManager = locator.get<ConfigManager>();
/// 
/// // 注册工厂（每次获取都创建新实例）
/// locator.registerFactory<ApiClient>((loc) => ApiClient(loc.get<HttpClient>()));
/// ```
class ServiceLocator {
  /// 存储已注册的服务
  final Map<Type, _ServiceEntry> _services = {};

  /// 存储已创建的单例实例
  final Map<Type, Object> _singletons = {};

  /// 公开构造函数
  /// 
  /// 推荐通过 [ServiceLocator.createAndRegister] 创建并注册核心服务
  ServiceLocator();

  /// 工厂方法：创建并注册所有核心服务
  /// 
  /// 这是推荐的应用启动方式：
  /// ```dart
  /// final locator = ServiceLocator.createAndRegister();
  /// runApp(
  ///   Provider<ServiceLocator>.value(
  ///     value: locator,
  ///     child: const BAMCApp(),
  ///   ),
  /// );
  /// ```
  static ServiceLocator createAndRegister() {
    final locator = ServiceLocator();
    ServiceRegistry.registerCoreServices(locator);
    return locator;
  }

  /// 注册单例服务
  /// 
  /// [instance] 已创建的服务实例
  void registerSingleton<T>(T instance) {
    _services[T] = _ServiceEntry(
      type: _ServiceType.singleton,
      creator: (_) => instance,
    );
    _singletons[T] = instance;
  }

  /// 注册延迟单例服务
  /// 
  /// [creator] 创建服务的工厂函数，首次获取时调用
  void register<T>(T Function(ServiceLocator) creator) {
    _services[T] = _ServiceEntry(
      type: _ServiceType.lazy,
      creator: creator,
    );
  }

  /// 注册工厂服务（每次获取都创建新实例）
  /// 
  /// [creator] 创建服务的工厂函数，每次获取时调用
  void registerFactory<T>(T Function(ServiceLocator) creator) {
    _services[T] = _ServiceEntry(
      type: _ServiceType.factory,
      creator: creator,
    );
  }

  /// 获取服务实例
  /// 
  /// 如果服务未注册，会抛出 [ServiceNotFoundException]
  T get<T>() {
    final entry = _services[T];
    if (entry == null) {
      throw ServiceNotFoundException(T);
    }

    switch (entry.type) {
      case _ServiceType.singleton:
        return _singletons[T] as T;
      case _ServiceType.lazy:
        if (!_singletons.containsKey(T)) {
          _singletons[T] = entry.creator(this);
        }
        return _singletons[T] as T;
      case _ServiceType.factory:
        return entry.creator(this) as T;
    }
  }

  /// 尝试获取服务实例，不存在则返回 null
  T? tryGet<T>() {
    try {
      return get<T>();
    } catch (_) {
      return null;
    }
  }

  /// 检查服务是否已注册
  bool isRegistered<T>() => _services.containsKey(T);

  /// 注销服务
  void unregister<T>() {
    _services.remove(T);
    _singletons.remove(T);
  }

  /// 重置所有服务（主要用于测试）
  void reset() {
    _services.clear();
    _singletons.clear();
  }

  /// 获取注册的服务类型列表（主要用于调试）
  List<Type> get registeredTypes => _services.keys.toList();
}

/// 服务类型枚举
enum _ServiceType {
  singleton,
  lazy,
  factory,
}

/// 服务条目
class _ServiceEntry {
  final _ServiceType type;
  final Object Function(ServiceLocator) creator;

  _ServiceEntry({
    required this.type,
    required this.creator,
  });
}

/// 服务未找到异常
class ServiceNotFoundException implements Exception {
  final Type type;

  ServiceNotFoundException(this.type);

  @override
  String toString() {
    return 'ServiceNotFoundException: Service of type $type not registered';
  }
}

/// 服务定位器扩展方法
extension ServiceLocatorExtension on ServiceLocator {
  /// 安全获取服务，如果未注册则使用默认值
  T getOrCreate<T>(T Function() defaultCreator) {
    if (isRegistered<T>()) {
      return get<T>();
    }
    final instance = defaultCreator();
    registerSingleton(instance);
    return instance;
  }
}

/// 服务注册器
/// 
/// 用于在应用启动时批量注册所有服务
class ServiceRegistry {
  /// 注册核心服务
  /// 
  /// [locator] 服务定位器实例
  static void registerCoreServices(ServiceLocator locator) {
    
    // 注册平台适配器（延迟加载）
    locator.register<IPlatformAdapter>((_) => PlatformAdapterFactory.create());
    
    // 注册配置管理器（延迟加载）
    locator.register<IConfigManager>((_) => ConfigManagerImpl());
    
    // 注册事件总线（单例）
    locator.registerSingleton(EventBus());
    
    // 注册日志系统（延迟加载）
    locator.register<Logger>((locator) => Logger(
      platformAdapter: locator.get<IPlatformAdapter>(),
      eventBus: locator.get<EventBus>(),
    ));
    
    // 注册下载引擎（延迟加载）
    locator.register<IDownloadEngine>((_) => DownloadEngine());
    
    // 注册版本管理器（延迟加载）
    locator.register<IVersionManager>((locator) => VersionManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      downloadEngine: locator.get<IDownloadEngine>(),
    ));
    
    // 注册实例管理器（延迟加载）
    locator.register<InstanceManager>((locator) => InstanceManager(
      logger: locator.get<Logger>(),
      config: locator.get<IConfigManager>(),
      platformAdapter: locator.get<IPlatformAdapter>(),
    ));
    
    // 注册账户管理器（延迟加载）
    locator.register<AccountManager>((locator) => AccountManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
    ));
    
    // 注册认证管理器（延迟加载）
    locator.register<AuthManager>((locator) => AuthManager(
      configManager: locator.get<IConfigManager>(),
      logger: locator.get<Logger>(),
    ));
    
    // 注册游戏启动器（延迟加载）
    locator.register<IGameLauncher>((locator) => GameLauncher(
      platformAdapter: locator.get<IPlatformAdapter>(),
      configManager: locator.get<IConfigManager>(),
      eventBus: locator.get<EventBus>(),
      logger: locator.get<Logger>(),
    ));
    
    // 注册主题管理器（延迟加载）
    locator.register<ThemeManager>((locator) => ThemeManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      backgroundManager: locator.get<BackgroundManager>(),
    ));
    
    // 注册后台管理器（延迟加载）
    locator.register<BackgroundManager>((locator) => BackgroundManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      platformAdapter: locator.get<IPlatformAdapter>(),
    ));
    
    // 注册皮肤管理器（延迟加载）
    locator.register<SkinManager>((locator) => SkinManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      downloadEngine: locator.get<IDownloadEngine>(),
    ));
    
    // 注册备份管理器（延迟加载）
    locator.register<BackupManager>((locator) => BackupManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      platformAdapter: locator.get<IPlatformAdapter>(),
      instanceManager: locator.get<InstanceManager>(),
    ));
    
    // 注册模组管理器（延迟加载）
    locator.register<ModManager>((locator) => ModManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      downloadEngine: locator.get<IDownloadEngine>(),
    ));
    
    // 注册资源中心（延迟加载）
    locator.register<ResourceCenter>((locator) => ResourceCenter(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
      downloadEngine: locator.get<IDownloadEngine>(),
    ));
    
    // 注册统计管理器（延迟加载）
    locator.register<StatisticsManager>((locator) => StatisticsManager(
      logger: locator.get<Logger>(),
      configManager: locator.get<IConfigManager>(),
    ));
  }

  /// 初始化所有已注册的服务
  /// 
  /// [locator] 服务定位器实例
  static Future<void> initializeServices(ServiceLocator locator) async {
    
    // 初始化配置管理器
    final configManager = locator.get<IConfigManager>();
    await configManager.initialize();
    
    // 初始化日志系统
    final logger = locator.get<Logger>();
    await logger.initialize();
    
    // 初始化实例管理器
    final instanceManager = locator.get<InstanceManager>();
    await instanceManager.initialize();
    
    // 初始化版本管理器（不需要显式初始化，延迟加载时会自动处理）
    
    // 初始化主题管理器
    final themeManager = locator.get<ThemeManager>();
    await themeManager.initialize();
    
    // 初始化后台管理器
    final backgroundManager = locator.get<BackgroundManager>();
    await backgroundManager.initialize();
    
    // 初始化账户管理器
    final accountManager = locator.get<AccountManager>();
    await accountManager.initialize();
    
    // 初始化认证管理器
    final authManager = locator.get<AuthManager>();
    // AuthManager 不需要显式初始化
    
    // 初始化游戏启动器
    final gameLauncher = locator.get<IGameLauncher>();
    await gameLauncher.initialize();
    
    // 初始化下载引擎
    final downloadEngine = locator.get<IDownloadEngine>();
    // DownloadEngine 不需要显式初始化
    
    // 初始化皮肤管理器
    final skinManager = locator.get<SkinManager>();
    // SkinManager 不需要显式初始化
    
    // 初始化备份管理器
    final backupManager = locator.get<BackupManager>();
    // BackupManager 不需要显式初始化
    
    // 初始化模组管理器
    final modManager = locator.get<ModManager>();
    // ModManager 不需要显式初始化
    
    // 初始化资源中心
    final resourceCenter = locator.get<ResourceCenter>();
    // ResourceCenter 不需要显式初始化
    
    // 初始化统计管理器
    final statisticsManager = locator.get<StatisticsManager>();
    // StatisticsManager 不需要显式初始化
  }
}