import 'dart:async';
import 'app_event.dart';
import 'event_priority.dart';
import 'event_handler.dart';

/// 事件管理器 - 单个事件类型的调度器
///
/// 参考 HMCL 的 EventManager<T>，支持优先级排序
class EventManager<T extends AppEvent> {
  final List<EventHandler<T>> _handlers = [];

  /// 注册事件处理器
  void register(
    FutureOr<void> Function(T) handler, {
    EventPriority priority = EventPriority.normal,
  }) {
    _handlers.add(EventHandler(handler, priority: priority));
    _handlers.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  /// 触发事件
  Future<void> fireEvent(T event) async {
    for (final handler in _handlers) {
      if (event.isCancelled) break;
      try {
        await handler.handler(event);
      } catch (e) {
        // 记录错误但继续执行其他处理器
        print('Event handler error: $e');
      }
    }
  }

  /// 移除处理器
  void unregister(FutureOr<void> Function(T) handler) {
    _handlers.removeWhere((h) => h.handler == handler);
  }

  /// 清除所有处理器
  void clear() {
    _handlers.clear();
  }

  /// 获取处理器数量
  int get handlerCount => _handlers.length;
}
