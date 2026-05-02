/// 事件基类
///
/// 所有事件继承此类，支持取消和时间戳
abstract class AppEvent {
  /// 事件触发时间
  final DateTime timestamp = DateTime.now();

  bool _cancelled = false;

  /// 是否已取消
  bool get isCancelled => _cancelled;

  /// 取消事件（仅可取消的事件有效）
  void cancel() {
    if (isCancelable) {
      _cancelled = true;
    }
  }

  /// 是否支持取消
  bool get isCancelable => false;

  @override
  String toString() => '$runtimeType(${timestamp.toIso8601String()})';
}
