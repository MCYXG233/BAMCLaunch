import 'service_locator.dart';

/// 服务注册器
///
/// 注意：此模块是占位实现。实际服务通过各自类的 `.instance`
/// 单例访问（参见各 Manager 类）。该类保留是为了满足旧代码引用。
class ServiceRegistry {
  ServiceRegistry._();

  /// 注册所有服务（占位实现）
  static Future<void> registerAllServices(ServiceLocator locator) async {
    // 各服务通过其自身的单例（如 `ConfigManager.instance`）访问，
    // 此处无需显式注册。
  }
}
