/// 依赖注入容器
///
/// **重要**：此容器是轻量级占位实现。
/// 实际服务通过各自类的 `.instance` 单例访问（如 `ConfigManager.instance`）。
/// 该类保留是为了满足旧代码中 `ServiceLocator` 类型引用的编译需要。
class ServiceLocator {
  /// 创建一个新的 ServiceLocator 实例
  ServiceLocator();

  /// 存储已注册的服务
  final Map<Type, Object> _services = <Type, Object>{};

  /// 注册单例服务
  void registerSingleton<T>(T instance) {
    _services[T] = instance as Object;
  }

  /// 注册延迟单例服务
  void register<T>(T Function(ServiceLocator) creator) {
    _services[T] = creator(this) as Object;
  }

  /// 注册工厂服务
  void registerFactory<T>(T Function(ServiceLocator) creator) {
    _services[T] = creator(this) as Object;
  }

  /// 获取服务实例
  T get<T>() {
    final value = _services[T];
    if (value is T) return value;
    throw StateError('Service of type $T not registered');
  }

  /// 尝试获取服务实例，不存在则返回 null
  T? tryGet<T>() {
    final value = _services[T];
    return value is T ? value : null;
  }

  /// 检查服务是否已注册
  bool isRegistered<T>() => _services.containsKey(T);

  /// 注销服务
  void unregister<T>() {
    _services.remove(T);
  }

  /// 重置所有服务
  void reset() {
    _services.clear();
  }

  /// 获取注册的服务类型列表
  List<Type> get registeredTypes => _services.keys.toList();
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
