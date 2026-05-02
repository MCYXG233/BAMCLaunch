/// 任务进度信息
///
/// 用于向 UI 层汇报任务执行进度
class TaskProgress {
  /// 进度值（0.0 - 1.0）
  final double progress;

  /// 当前阶段名称
  final String? stage;

  /// 详细信息
  final String? detail;

  const TaskProgress({
    this.progress = 0.0,
    this.stage,
    this.detail,
  });

  /// 创建一个带进度的 TaskProgress
  factory TaskProgress.of(double progress, {String? stage, String? detail}) {
    return TaskProgress(
      progress: progress.clamp(0.0, 1.0),
      stage: stage,
      detail: detail,
    );
  }

  /// 创建一个完成的 TaskProgress
  factory TaskProgress.completed({String? detail}) {
    return TaskProgress(
      progress: 1.0,
      stage: '完成',
      detail: detail,
    );
  }

  @override
  String toString() {
    final percent = (progress * 100).toStringAsFixed(1);
    if (stage != null) {
      return '$stage: $percent%';
    }
    return '$percent%';
  }
}
