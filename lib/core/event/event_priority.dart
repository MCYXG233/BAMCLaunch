/// 事件优先级
///
/// 参考 HMCL 的 EventPriority，5 级优先级
enum EventPriority {
  /// 最高优先级
  highest,

  /// 高优先级
  high,

  /// 普通优先级（默认）
  normal,

  /// 低优先级
  low,

  /// 最低优先级
  lowest,
}
