import 'dart:async';
import 'app_event.dart';
import 'event_priority.dart';
import 'event_manager.dart';

/// 全局事件总线
///
/// 参考 HMCL 的 EventBus，使用 Type 作为键的 O(1) 查找
///
/// 使用示例：
/// ```dart
/// final eventBus = EventBus();
///
/// // 注册监听
/// eventBus.on<DownloadProgressEvent>((event) {
///   print('下载进度: ${event.progress}');
/// });
///
/// // 触发事件
/// eventBus.emit(DownloadProgressEvent(progress: 0.5));
/// ```
class EventBus {
  static final EventBus _instance = EventBus._();
  factory EventBus() => _instance;
  EventBus._();

  final Map<Type, EventManager> _channels = {};

  /// 获取事件通道
  EventManager<T> channel<T extends AppEvent>() {
    return _channels.putIfAbsent(T, () => EventManager<T>()) as EventManager<T>;
  }

  /// 注册事件处理器
  void on<T extends AppEvent>(
    FutureOr<void> Function(T) handler, {
    EventPriority priority = EventPriority.normal,
  }) {
    channel<T>().register(handler, priority: priority);
  }

  /// 触发事件
  Future<void> emit<T extends AppEvent>(T event) async {
    await channel<T>().fireEvent(event);
  }

  /// 移除处理器
  void off<T extends AppEvent>(FutureOr<void> Function(T) handler) {
    channel<T>().unregister(handler);
  }

  /// 清除指定类型的所有处理器
  void clear<T extends AppEvent>() {
    channel<T>().clear();
  }

  /// 清除所有处理器
  void clearAll() {
    for (final channel in _channels.values) {
      channel.clear();
    }
    _channels.clear();
  }

  /// 获取指定类型的处理器数量
  int handlerCount<T extends AppEvent>() {
    return channel<T>().handlerCount;
  }
}
