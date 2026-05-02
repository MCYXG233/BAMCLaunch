/// 任务状态枚举
///
/// 参考 HMCL 的 TaskStatus，表示任务生命周期
enum TaskStatus {
  /// 等待执行
  waiting,

  /// 执行中
  running,

  /// 成功完成
  success,

  /// 执行失败
  failed,

  /// 已取消
  cancelled,
}
