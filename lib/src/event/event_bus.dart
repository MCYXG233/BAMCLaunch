import 'dart:async';
import 'event.dart';

/// 事件回调函数类型
typedef EventCallback<T extends Event> = void Function(T event);

/// 事件订阅器
///
/// 用于取消事件订阅
class EventSubscription {
  final Type _eventType;
  final int _id;
  final EventBus _eventBus;

  EventSubscription._(this._eventBus, this._eventType, this._id);

  /// 取消订阅
  void unsubscribe() {
    _eventBus._unsubscribe(_eventType, _id);
  }
}

/// 弱引用包装器
class _WeakCallbackWrapper {
  final int id;
  final WeakReference<Function> callbackRef;

  _WeakCallbackWrapper(this.id, Function callback)
    : callbackRef = WeakReference(callback);

  bool get isAlive => callbackRef.target != null;

  Function? get callback => callbackRef.target;
}

/// 事件总线
///
/// 单例模式，用于在应用程序内部发布和订阅事件
class EventBus {
  static EventBus? _instance;

  factory EventBus() => _instance ??= EventBus._internal();

  EventBus._internal();

  /// 获取单例实例
  static EventBus get instance => _instance ??= EventBus._internal();

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// 存储订阅者的映射
  final Map<Type, List<_WeakCallbackWrapper>> _subscribers = {};

  /// 订阅ID生成器
  int _nextId = 0;

  /// 订阅事件
  ///
  /// [T] 事件类型
  /// [callback] 事件回调函数
  /// 返回订阅器，用于取消订阅
  EventSubscription subscribe<T extends Event>(EventCallback<T> callback) {
    final eventType = T;
    final id = _nextId++;
    final wrapper = _WeakCallbackWrapper(id, callback);

    if (!_subscribers.containsKey(eventType)) {
      _subscribers[eventType] = [];
    }

    _subscribers[eventType]!.add(wrapper);
    return EventSubscription._(this, eventType, id);
  }

  /// 订阅事件（subscribe 的别名，用于更符合 Dart 习惯的写法）
  EventSubscription on<T extends Event>(EventCallback<T> callback) =>
      subscribe(callback);

  /// 发布事件
  ///
  /// [event] 要发布的事件
  void publish<T extends Event>(T event) {
    final eventType = T;
    final subscribers = _subscribers[eventType];

    if (subscribers == null) return;

    final aliveSubscribers = <_WeakCallbackWrapper>[];

    for (final wrapper in subscribers) {
      if (wrapper.isAlive) {
        aliveSubscribers.add(wrapper);
        final callback = wrapper.callback;
        if (callback != null) {
          try {
            callback(event);
          } catch (e, stackTrace) {
            Zone.current.handleUncaughtError(e, stackTrace);
          }
        }
      }
    }

    _subscribers[eventType] = aliveSubscribers;
  }

  /// 取消订阅
  ///
  /// [eventType] 事件类型
  /// [id] 订阅ID
  void _unsubscribe(Type eventType, int id) {
    final subscribers = _subscribers[eventType];
    if (subscribers == null) return;

    subscribers.removeWhere((wrapper) => wrapper.id == id);

    if (subscribers.isEmpty) {
      _subscribers.remove(eventType);
    }
  }

  /// 清理所有已失效的订阅者
  ///
  /// 手动清理所有已被垃圾回收的订阅者
  void cleanup() {
    final typesToRemove = <Type>[];

    for (final entry in _subscribers.entries) {
      final aliveSubscribers = entry.value.where((w) => w.isAlive).toList();

      if (aliveSubscribers.isEmpty) {
        typesToRemove.add(entry.key);
      } else {
        _subscribers[entry.key] = aliveSubscribers;
      }
    }

    for (final type in typesToRemove) {
      _subscribers.remove(type);
    }
  }

  /// 获取当前订阅者数量
  ///
  /// [eventType] 事件类型，如果为 null 则统计所有类型
  int subscriberCount([Type? eventType]) {
    if (eventType != null) {
      return _subscribers[eventType]?.length ?? 0;
    }

    var count = 0;
    for (final list in _subscribers.values) {
      count += list.length;
    }
    return count;
  }
}
