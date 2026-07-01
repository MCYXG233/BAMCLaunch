import 'dart:async';
import 'event.dart';
import '../di/service_locator.dart';

/// 事件回调函数类型定义
///
/// 定义了事件处理回调函数的签名。
/// 泛型参数 [T] 必须继承自 [Event] 类，确保类型安全。
///
/// ## 使用示例
/// ```dart
/// void myEventHandler(MyEvent event) {
///   print('收到事件: ${event.data}');
/// }
/// ```
typedef EventCallback<T extends Event> = void Function(T event);

/// 事件订阅器
///
/// 用于管理单个事件订阅的生命周期。
/// 当不再需要接收事件时，可以调用 [unsubscribe] 方法取消订阅。
///
/// ## 职责
/// - 封装订阅的元数据（事件类型和订阅ID）
/// - 提供取消订阅的能力
///
/// ## 使用示例
/// ```dart
/// final subscription = EventBus.instance.subscribe<MyEvent>(myHandler);
/// // 不再需要时取消订阅
/// subscription.unsubscribe();
/// ```
///
/// ## 注意事项
/// - 取消订阅后，该订阅器将不再有效
/// - 不需要重复调用 unsubscribe，多次调用是安全的
class EventSubscription {
  /// 订阅的事件类型
  ///
  /// 用于标识此订阅器关联的事件类型，
  /// 在取消订阅时用于定位对应的订阅者列表。
  final Type _eventType;

  /// 订阅的唯一标识符
  ///
  /// 由 [EventBus] 分配的唯一ID，
  /// 用于在订阅者列表中精确定位此订阅。
  final int _id;

  /// 关联的事件总线实例
  ///
  /// 保存对事件总线的引用，
  /// 用于在取消订阅时调用事件总线的内部方法。
  final EventBus _eventBus;

  /// 私有构造函数
  ///
  /// 由 [EventBus.subscribe] 方法内部调用，
  /// 外部代码不应直接创建此类的实例。
  ///
  /// 参数：
  /// - [_eventBus] 关联的事件总线实例
  /// - [_eventType] 订阅的事件类型
  /// - [_id] 订阅的唯一标识符
  EventSubscription._(this._eventBus, this._eventType, this._id);

  /// 取消订阅
  ///
  /// 从事件总线中移除此订阅，之后将不再收到对应类型的事件。
  ///
  /// ## 行为说明
  /// - 调用此方法后，订阅器将不再有效
  /// - 多次调用此方法是安全的，不会产生副作用
  /// - 取消订阅是即时生效的
  ///
  /// ## 使用示例
  /// ```dart
  /// final subscription = EventBus().on<LoginEvent>((event) {
  ///   // 处理登录事件
  /// });
  ///
  /// // 用户登出时取消订阅
  /// subscription.unsubscribe();
  /// ```
  void unsubscribe() {
    _eventBus._unsubscribe(_eventType, _id);
  }
}

/// 弱引用回调包装器
///
/// 内部类，用于包装事件回调函数，实现弱引用订阅机制。
/// 当订阅者（回调函数的持有者）被垃圾回收后，
/// 包装器会自动检测到并允许事件总线清理这些无效订阅。
///
/// ## 设计目的
/// - 避免内存泄漏：当订阅者被销毁后，不需要显式取消订阅
/// - 自动清理：事件发布时会自动清理已失效的订阅
/// - 性能优化：减少手动管理订阅的负担
///
/// ## 实现细节
/// 使用 [WeakReference] 包装回调函数，
/// 当回调函数的外部引用被释放后，[isAlive] 将返回 false。
class _WeakCallbackWrapper {
  /// 订阅的唯一标识符
  ///
  /// 由 [EventBus] 分配，用于在取消订阅时精确定位此包装器。
  final int id;

  /// 回调函数的弱引用
  ///
  /// 使用 [WeakReference] 包装回调函数，
  /// 允许回调函数在没有外部强引用时被垃圾回收。
  ///
  /// ## 注意
  /// 如果回调函数是匿名函数且没有其他引用持有它，
  /// 可能会被立即回收，导致订阅失效。
  final WeakReference<Function> callbackRef;

  /// 构造函数
  ///
  /// 创建一个弱引用包装器。
  ///
  /// 参数：
  /// - [id] 订阅的唯一标识符
  /// - [callback] 要包装的回调函数
  ///
  /// ## 注意事项
  /// 传入的 [callback] 应该是一个有稳定引用的方法或函数，
  /// 避免使用可能被立即回收的临时匿名函数。
  _WeakCallbackWrapper(this.id, Function callback)
      : callbackRef = WeakReference(callback);

  /// 检查回调是否仍然有效
  ///
  /// 返回 true 表示回调函数仍然存在（未被垃圾回收），
  /// 返回 false 表示回调函数已被回收，此订阅应该被清理。
  ///
  /// ## 返回值
  /// - `true`: 回调函数仍然存活，可以正常调用
  /// - `false`: 回调函数已被垃圾回收，订阅无效
  bool get isAlive => callbackRef.target != null;

  /// 获取回调函数
  ///
  /// 如果回调函数仍然存活，返回该函数；否则返回 null。
  ///
  /// ## 返回值
  /// - 非 null: 回调函数的引用
  /// - null: 回调函数已被垃圾回收
  ///
  /// ## 使用注意
  /// 调用方应该先检查 [isAlive] 或判断返回值是否为 null，
  /// 避免在回调已失效时调用。
  Function? get callback => callbackRef.target;
}

/// 事件总线
///
/// 实现发布-订阅模式的核心组件，用于在应用程序内部进行松耦合的事件通信。
/// 采用单例模式确保全局唯一的事件总线实例。
///
/// ## 核心功能
/// - **订阅事件**：通过 [subscribe] 或 [on] 方法订阅特定类型的事件
/// - **发布事件**：通过 [publish] 方法发布事件，通知所有订阅者
/// - **取消订阅**：通过 [EventSubscription.unsubscribe] 取消特定订阅
/// - **自动清理**：使用弱引用机制，自动清理失效的订阅
///
/// ## 设计特点
/// - **单例模式**：全局唯一实例，确保事件通信的一致性
/// - **弱引用订阅**：避免内存泄漏，订阅者被销毁后自动清理
/// - **类型安全**：使用泛型确保事件类型的正确性
/// - **异常隔离**：单个订阅者的异常不会影响其他订阅者
///
/// ## 使用示例
/// ```dart
/// // 定义事件类
/// class UserLoginEvent extends Event {
///   final String userId;
///   UserLoginEvent(this.userId);
/// }
///
/// // 订阅事件
/// final subscription = EventBus.instance.on<UserLoginEvent>((event) {
///   print('用户登录: ${event.userId}');
/// });
///
/// // 发布事件
/// EventBus.instance.publish(UserLoginEvent('user123'));
///
/// // 取消订阅
/// subscription.unsubscribe();
/// ```
///
/// ## 线程安全
/// 注意：此实现不是线程安全的。在 Dart 的单线程模型中使用是安全的，
/// 但如果涉及 Isolate 通信，需要额外的同步机制。
///
/// ## 性能考虑
/// - 订阅和取消订阅的时间复杂度为 O(n)，n 为该事件类型的订阅者数量
/// - 发布事件时会清理失效的订阅，可能有轻微的性能开销
/// - 建议在适当时机调用 [cleanup] 方法主动清理失效订阅
class EventBus {
  /// 单例实例
  ///
  /// 使用可空类型存储单例实例，
  /// 允许通过 [reset] 方法重置（主要用于测试场景）。
  static EventBus? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例，如果实例不存在则创建新实例。
  /// 这是获取 [EventBus] 实例的推荐方式之一。
  ///
  /// ## 返回值
  /// [EventBus] 的全局唯一实例
  factory EventBus() => _instance ??= EventBus._internal();

  /// 内部私有构造函数
  ///
  /// 用于创建单例实例，外部代码不应直接调用。
  /// 请使用 [EventBus()] 工厂构造函数或 [instance] 静态属性获取实例。
  EventBus._internal();

  /// 获取单例实例
  ///
  /// 静态属性，提供访问单例实例的便捷方式。
  /// 如果实例不存在，会自动创建。
  ///
  /// ## 返回值
  /// [EventBus] 的全局唯一实例
  ///
  /// ## 使用示例
  /// ```dart
  /// EventBus.instance.publish(MyEvent());
  /// ```
  static EventBus get instance =>
      ServiceLocator.instance.tryGet<EventBus>() ??
      (_instance ??= EventBus._internal());

  /// 重置单例实例
  ///
  /// 将单例实例设置为 null，下次获取时会创建新实例。
  ///
  /// ## 用途
  /// - 单元测试中重置测试环境
  /// - 清理所有订阅状态
  ///
  /// ## 注意
  /// 此方法会清除所有现有的订阅，生产环境应谨慎使用。
  ///
  /// ## 使用示例
  /// ```dart
  /// tearDown(() {
  ///   EventBus.reset(); // 每个测试后重置
  /// });
  /// ```
  static void reset() {
    _instance = null;
  }

  /// 存储订阅者的映射表
  ///
  /// 键为事件类型（[Type]），值为该事件类型的订阅者列表。
  /// 每个订阅者使用 [_WeakCallbackWrapper] 包装，实现弱引用机制。
  ///
  /// ## 数据结构
  /// ```
  /// {
  ///   EventTypeA: [wrapper1, wrapper2, ...],
  ///   EventTypeB: [wrapper3, wrapper4, ...],
  /// }
  /// ```
  final Map<Type, List<_WeakCallbackWrapper>> _subscribers = {};

  /// 订阅ID生成器
  ///
  /// 自增计数器，用于为每个新订阅分配唯一标识符。
  /// 从 0 开始，每次订阅递增 1。
  ///
  /// ## 注意
  /// 这是一个简单的递增ID，在应用生命周期内不会重置。
  /// 如果订阅数量极大（超过 int 最大值），可能会溢出。
  int _nextId = 0;

  /// 订阅事件
  ///
  /// 注册一个回调函数来监听指定类型的事件。
  /// 当该类型的事件被发布时，回调函数会被调用。
  ///
  /// ## 类型参数
  /// - [T]: 要订阅的事件类型，必须继承自 [Event]
  ///
  /// ## 参数
  /// - [callback]: 事件回调函数，当事件发布时被调用
  ///   - 类型: [EventCallback<T>]
  ///   - 参数: T event - 发布的事件实例
  ///   - 返回值: void
  ///
  /// ## 返回值
  /// 返回 [EventSubscription] 实例，可用于取消订阅。
  ///
  /// ## 使用示例
  /// ```dart
  /// // 订阅用户登录事件
  /// final subscription = EventBus.instance.subscribe<UserLoginEvent>((event) {
  ///   print('用户 ${event.userId} 已登录');
  /// });
  ///
  /// // 稍后取消订阅
  /// subscription.unsubscribe();
  /// ```
  ///
  /// ## 注意事项
  /// - 回调函数使用弱引用存储，如果回调函数没有其他引用持有，可能会被垃圾回收
  /// - 建议使用命名方法而非匿名函数，以确保引用稳定
  /// - 回调函数中的异常不会影响其他订阅者，但会被记录到当前 Zone
  ///
  /// ## 可能的问题
  /// 如果使用临时匿名函数作为回调，可能会因为弱引用特性导致订阅立即失效：
  /// ```dart
  /// // 错误示例 - 匿名函数可能被立即回收
  /// EventBus().subscribe<MyEvent>((e) => print(e)); // 可能失效
  ///
  /// // 正确示例 - 使用有稳定引用的方法
  /// void myHandler(MyEvent e) => print(e);
  /// EventBus().subscribe(myHandler); // 稳定
  /// ```
  EventSubscription subscribe<T extends Event>(EventCallback<T> callback) {
    // 获取事件类型，用于作为订阅者映射表的键
    final eventType = T;
    // 生成唯一的订阅ID
    final id = _nextId++;
    // 创建弱引用包装器
    final wrapper = _WeakCallbackWrapper(id, callback);

    // 如果该事件类型还没有订阅者列表，创建一个空列表
    if (!_subscribers.containsKey(eventType)) {
      _subscribers[eventType] = [];
    }

    // 将包装器添加到订阅者列表
    _subscribers[eventType]!.add(wrapper);
    // 返回订阅器实例，允许调用方管理订阅生命周期
    return EventSubscription._(this, eventType, id);
  }

  /// 订阅事件（[subscribe] 的别名）
  ///
  /// 提供更简洁的语法糖，语义上更符合 Dart 的事件订阅习惯。
  /// 功能与 [subscribe] 完全相同。
  ///
  /// ## 类型参数
  /// - [T]: 要订阅的事件类型，必须继承自 [Event]
  ///
  /// ## 参数
  /// - [callback]: 事件回调函数
  ///
  /// ## 返回值
  /// 返回 [EventSubscription] 实例
  ///
  /// ## 使用示例
  /// ```dart
  /// // 使用 on 方法，语法更简洁
  /// EventBus.instance.on<DataUpdateEvent>((event) {
  ///   refreshUI();
  /// });
  /// ```
  EventSubscription on<T extends Event>(EventCallback<T> callback) =>
      subscribe(callback);

  /// 发布事件
  ///
  /// 将事件发布到事件总线，通知所有订阅该事件类型的订阅者。
  /// 每个订阅者的回调函数会被依次调用。
  ///
  /// ## 类型参数
  /// - [T]: 事件类型，必须继承自 [Event]
  ///
  /// ## 参数
  /// - [event]: 要发布的事件实例
  ///   - 类型: T
  ///   - 包含事件相关的数据
  ///
  /// ## 行为说明
  /// - 如果该事件类型没有订阅者，方法直接返回，不执行任何操作
  /// - 发布过程中会自动清理已失效的订阅（回调已被垃圾回收）
  /// - 单个订阅者的异常不会影响其他订阅者的事件处理
  /// - 异常会被传递到当前 Zone 的错误处理器
  ///
  /// ## 使用示例
  /// ```dart
  /// // 发布用户登录事件
  /// EventBus.instance.publish(UserLoginEvent('user123'));
  ///
  /// // 发布数据更新事件
  /// EventBus.instance.publish(DataUpdateEvent(
  ///   type: 'user',
  ///   data: {'name': 'John'},
  /// ));
  /// ```
  ///
  /// ## 异常处理
  /// 回调函数中的异常会被捕获并传递给当前 Zone 的错误处理器：
  /// ```dart
  /// runZoned(() {
  ///   EventBus.instance.subscribe<MyEvent>((e) {
  ///     throw Exception('处理失败');
  ///   });
  ///   EventBus.instance.publish(MyEvent()); // 异常被捕获，不影响其他订阅者
  /// }, onError: (error, stackTrace) {
  ///   print('事件处理异常: $error');
  /// });
  /// ```
  void publish<T extends Event>(T event) {
    // 获取事件类型
    final eventType = T;
    // 获取该事件类型的订阅者列表
    final subscribers = _subscribers[eventType];

    // 如果没有订阅者，直接返回
    if (subscribers == null) return;

    // 用于存储仍然有效的订阅者
    final aliveSubscribers = <_WeakCallbackWrapper>[];

    // 遍历所有订阅者
    for (final wrapper in subscribers) {
      // 检查订阅者是否仍然有效（回调是否被垃圾回收）
      if (wrapper.isAlive) {
        // 保留有效的订阅者
        aliveSubscribers.add(wrapper);
        // 获取回调函数
        final callback = wrapper.callback;
        if (callback != null) {
          try {
            // 调用回调函数，传递事件实例
            callback(event);
          } catch (e, stackTrace) {
            // 捕获异常，防止单个订阅者的异常影响其他订阅者
            // 将异常传递给当前 Zone 的错误处理器
            Zone.current.handleUncaughtError(e, stackTrace);
          }
        }
      }
      // 如果订阅者已失效（isAlive 为 false），不添加到 aliveSubscribers，
      // 实现自动清理
    }

    // 更新订阅者列表，移除已失效的订阅
    _subscribers[eventType] = aliveSubscribers;
  }

  /// 取消订阅（内部方法）
  ///
  /// 根据事件类型和订阅ID移除特定的订阅。
  /// 此方法由 [EventSubscription.unsubscribe] 内部调用，
  /// 外部代码应通过订阅器实例取消订阅。
  ///
  /// ## 参数
  /// - [eventType]: 事件类型，用于定位订阅者列表
  /// - [id]: 订阅的唯一标识符，用于定位具体的订阅
  ///
  /// ## 行为说明
  /// - 如果事件类型没有订阅者列表，方法直接返回
  /// - 移除指定ID的订阅后，如果订阅者列表为空，会移除整个事件类型的条目
  /// - 此方法是幂等的，多次调用相同的参数是安全的
  ///
  /// ## 时间复杂度
  /// O(n)，其中 n 为该事件类型的订阅者数量
  void _unsubscribe(Type eventType, int id) {
    // 获取该事件类型的订阅者列表
    final subscribers = _subscribers[eventType];
    // 如果没有订阅者，直接返回
    if (subscribers == null) return;

    // 移除指定ID的订阅
    subscribers.removeWhere((wrapper) => wrapper.id == id);

    // 如果订阅者列表为空，移除整个事件类型的条目，释放内存
    if (subscribers.isEmpty) {
      _subscribers.remove(eventType);
    }
  }

  /// 清理所有已失效的订阅者
  ///
  /// 遍历所有事件类型的订阅者，移除已被垃圾回收的订阅。
  /// 通常在事件发布时会自动清理，但也可以手动调用此方法进行主动清理。
  ///
  /// ## 使用场景
  /// - 应用进入后台时，释放不必要的资源引用
  /// - 定期维护，清理积累的失效订阅
  /// - 内存紧张时，主动释放资源
  ///
  /// ## 行为说明
  /// - 遍历所有事件类型的订阅者列表
  /// - 移除所有失效的订阅（回调已被垃圾回收）
  /// - 如果某个事件类型的订阅者列表为空，移除该条目
  ///
  /// ## 使用示例
  /// ```dart
  /// // 在应用进入后台时清理
  /// void onAppPaused() {
  ///   EventBus.instance.cleanup();
  /// }
  ///
  /// // 定期清理（如每分钟）
  /// Timer.periodic(Duration(minutes: 1), (_) {
  ///   EventBus.instance.cleanup();
  /// });
  /// ```
  void cleanup() {
    // 记录需要完全移除的事件类型
    final typesToRemove = <Type>[];

    // 遍历所有订阅者列表
    for (final entry in _subscribers.entries) {
      // 过滤出仍然有效的订阅者
      final aliveSubscribers = entry.value.where((w) => w.isAlive).toList();

      if (aliveSubscribers.isEmpty) {
        // 如果没有有效的订阅者，标记此事件类型待移除
        typesToRemove.add(entry.key);
      } else {
        // 更新为有效的订阅者列表
        _subscribers[entry.key] = aliveSubscribers;
      }
    }

    // 移除没有订阅者的事件类型条目
    for (final type in typesToRemove) {
      _subscribers.remove(type);
    }
  }

  /// 获取当前订阅者数量
  ///
  /// 统计事件总线中活跃的订阅者数量。
  /// 可用于监控和调试事件订阅状态。
  ///
  /// ## 参数
  /// - [eventType]: 可选参数，指定要统计的事件类型
  ///   - 如果提供，只统计该事件类型的订阅者数量
  ///   - 如果为 null（默认），统计所有事件类型的订阅者总数
  ///
  /// ## 返回值
  /// - `int`: 订阅者数量
  ///   - 如果指定了事件类型且该类型没有订阅者，返回 0
  ///   - 如果没有指定事件类型，返回所有订阅者的总数
  ///
  /// ## 使用示例
  /// ```dart
  /// // 获取所有订阅者数量
  /// final totalCount = EventBus.instance.subscriberCount();
  /// print('总订阅数: $totalCount');
  ///
  /// // 获取特定事件类型的订阅者数量
  /// final loginEventCount = EventBus.instance.subscriberCount(UserLoginEvent);
  /// print('登录事件订阅数: $loginEventCount');
  /// ```
  ///
  /// ## 注意事项
  /// - 返回的数量包括所有订阅者，包括可能已失效但尚未清理的订阅
  /// - 如果需要准确的数量，建议先调用 [cleanup] 方法
  int subscriberCount([Type? eventType]) {
    if (eventType != null) {
      // 如果指定了事件类型，返回该类型的订阅者数量
      return _subscribers[eventType]?.length ?? 0;
    }

    // 统计所有事件类型的订阅者总数
    var count = 0;
    for (final list in _subscribers.values) {
      count += list.length;
    }
    return count;
  }
}