/// 任务进度信息
///
/// 用于表示任务执行过程中的进度状态
class TaskProgress {
  /// 进度值（0.0 - 1.0）
  final double progress;

  /// 当前阶段描述
  final String? stage;

  /// 详细信息
  final String? detail;

  /// 描述 (description 是 stage 的别名，用于向后兼容)
  final String? description;

  /// 创建任务进度
  ///
  /// [progress] 进度值，必须在 0.0 到 1.0 之间
  /// [stage] 当前阶段描述
  /// [detail] 详细信息
  TaskProgress({
    required this.progress,
    this.stage,
    this.detail,
    this.description,
  }) : assert(progress >= 0.0 && progress <= 1.0, '进度值必须在 0.0 到 1.0 之间');
}
