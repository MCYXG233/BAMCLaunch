import 'service_locator.dart';
import 'registries/core_registry.dart';
import 'registries/config_registry.dart';
import 'registries/platform_registry.dart';
import 'registries/auth_registry.dart';
import 'registries/account_registry.dart';
import 'registries/instance_registry.dart';
import 'registries/game_registry.dart';
import 'registries/version_registry.dart';
import 'registries/download_registry.dart';
import 'registries/resource_registry.dart';
import 'registries/mod_registry.dart';
import 'registries/loader_registry.dart';
import 'registries/network_registry.dart';
import 'registries/system_registry.dart';
import 'registries/feature_registry.dart';

/// 统一服务注册表（薄壳）
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
/// ## 架构说明
///
/// 本类仅作为调度入口，按业务域将实际注册工作委托给
/// `registries/` 目录下的 15 个分组文件。每个分组文件
/// 只 import 自己域的模块，便于按需加载与测试 mock。
///
/// 注册顺序遵循依赖关系：
/// 1. 核心基础设施（无依赖）
/// 2. 平台适配（依赖核心）
/// 3. 配置管理（依赖平台）
/// 4. 认证与账户
/// 5. 实例与游戏管理
/// 6. 下载与资源
/// 7. 系统、网络与功能扩展
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
    registerCoreRegistry(locator);

    // ━━━ Phase 2：平台适配层（依赖核心）━━━
    registerPlatformRegistry(locator);

    // ━━━ Phase 3：配置管理（依赖平台）━━━
    registerConfigRegistry(locator);

    // ━━━ Phase 4：认证与账户 ━━━
    registerAuthRegistry(locator);
    registerAccountRegistry(locator);

    // ━━━ Phase 5：实例与游戏管理 ━━━
    registerInstanceRegistry(locator);
    registerGameRegistry(locator);
    registerVersionRegistry(locator);

    // ━━━ Phase 6：下载与资源 ━━━
    registerDownloadRegistry(locator);
    registerResourceRegistry(locator);
    registerModRegistry(locator);
    registerLoaderRegistry(locator);

    // ━━━ Phase 7：系统、网络与功能扩展 ━━━
    registerNetworkRegistry(locator);
    registerSystemRegistry(locator);
    registerFeatureRegistry(locator);

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
}
