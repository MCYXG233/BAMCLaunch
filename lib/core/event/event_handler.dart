import 'dart:async';
import 'app_event.dart';
import 'event_priority.dart';

/// 事件处理器包装
///
/// 封装事件处理函数，支持优先级和弱引用
class EventHandler<T extends AppEvent> {
  /// 处理函数
  final FutureOr<void> Function(T) handler;

  /// 优先级
  final EventPriority priority;

  /// 是否为弱引用（防止内存泄漏）
  final bool isWeak;

  const EventHandler(
    this.handler, {
    this.priority = EventPriority.normal,
    this.isWeak = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventHandler<T> &&
        other.handler == handler &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(handler, priority);
}
