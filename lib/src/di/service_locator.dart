/// 轻量级依赖注入容器
///
/// 支持三种注册方式：
/// - [registerSingleton]：注册已创建的实例
/// - [registerLazySingleton]：注册懒加载工厂，首次 get 时创建并缓存
/// - [registerFactory]：每次 get 都创建新实例
///
/// ## 使用示例
/// ```dart
/// final locator = ServiceLocator.instance;
/// locator.registerLazySingleton<Logger>(() => Logger._internal());
/// final logger = locator.get<Logger>();
/// ```
class ServiceLocator {
  ServiceLocator._();

  static ServiceLocator? _singleton;

  /// 获取全局唯一的 ServiceLocator 实例
  static ServiceLocator get instance => _singleton ??= ServiceLocator._();

  /// 已注册的单例实例缓存
  final Map<Type, Object> _singletons = <Type, Object>{};

  /// 懒加载工厂（首次 get 时调用并缓存结果）
  final Map<Type, Object Function()> _lazyFactories = <Type, Object Function()>{};

  /// 工厂（每次 get 都创建新实例）
  final Map<Type, Object Function()> _factories = <Type, Object Function()>{};

  /// 注册单例服务
  ///
  /// 将已创建的实例注册为单例，后续 [get] 始终返回同一实例。
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance as Object;
    _lazyFactories.remove(T);
    _factories.remove(T);
  }

  /// 注册懒加载单例服务
  ///
  /// [factory] 在首次调用 [get] 时执行，结果被缓存为单例。
  void registerLazySingleton<T>(T Function() factory) {
    _lazyFactories[T] = () => factory() as Object;
    _factories.remove(T);
  }

  /// 注册工厂服务
  ///
  /// 每次调用 [get] 都会执行 [factory] 创建新实例。
  void registerFactory<T>(T Function() factory) {
    _factories[T] = () => factory() as Object;
    _lazyFactories.remove(T);
  }

  /// 获取服务实例
  ///
  /// 按优先级查找：已缓存单例 → 懒加载工厂 → 工厂。
  /// 未注册时抛出 [StateError]。
  T get<T>() {
    // 1. 已缓存的单例
    final cached = _singletons[T];
    if (cached is T) return cached;

    // 2. 懒加载工厂 → 创建并缓存
    final lazyFactory = _lazyFactories[T];
    if (lazyFactory != null) {
      final instance = lazyFactory() as T;
      _singletons[T] = instance as Object;
      return instance;
    }

    // 3. 工厂 → 每次新建
    final factory = _factories[T];
    if (factory != null) {
      return factory() as T;
    }

    throw StateError(
      'Service of type $T is not registered. '
      'Did you forget to call ServiceRegistry.initialize()?',
    );
  }

  /// 尝试获取服务实例，未注册或未缓存时返回 null
  ///
  /// 注意：此方法不会触发懒加载工厂，仅返回已缓存的单例。
  /// 这是为了避免循环依赖（如 Logger.instance → tryGet → lazyFactory → Logger.instance）。
  /// 懒加载工厂仅在 [get] 方法中触发。
  T? tryGet<T>() {
    final cached = _singletons[T];
    if (cached is T) return cached;
    return null;
  }

  /// 检查服务是否已注册（包括单例、懒加载、工厂）
  bool isRegistered<T>() {
    return _singletons.containsKey(T) ||
        _lazyFactories.containsKey(T) ||
        _factories.containsKey(T);
  }

  /// 注销服务
  void unregister<T>() {
    _singletons.remove(T);
    _lazyFactories.remove(T);
    _factories.remove(T);
  }

  /// 重置所有注册（主要用于测试）
  void reset() {
    _singletons.clear();
    _lazyFactories.clear();
    _factories.clear();
  }

  /// 获取所有已注册的类型列表
  List<Type> get registeredTypes {
    return <Type>{
      ..._singletons.keys,
      ..._lazyFactories.keys,
      ..._factories.keys,
    }.toList();
  }

  /// 已实例化的单例数量
  int get activeSingletonCount => _singletons.length;

  /// 总注册服务数量（包括尚未实例化的懒加载）
  int get totalRegisteredCount => registeredTypes.length;

  /// 重置全局单例（仅用于测试）
  static void resetInstance() {
    _singleton?.reset();
    _singleton = null;
  }
}
