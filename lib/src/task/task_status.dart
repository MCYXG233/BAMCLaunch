/// 任务状态枚举
///
/// 表示任务当前的执行状态
enum TaskStatus {
  /// 等待执行
  waiting,

  /// 正在执行
  running,

  /// 执行成功
  success,

  /// 执行失败
  failed,

  /// 已取消
  cancelled,
}
