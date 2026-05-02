import 'task_progress.dart';

/// 任务上下文
///
/// 提供取消检查和进度报告功能
class TaskContext {
  /// 进度回调
  final void Function(TaskProgress) onProgress;

  /// 取消检查函数
  final bool Function() isCancelled;

  TaskContext({
    required this.onProgress,
    required this.isCancelled,
  });

  /// 检查任务是否已取消
  ///
  /// 如果已取消，抛出 [TaskCancelledException]
  void checkCancelled() {
    if (isCancelled()) {
      throw TaskCancelledException();
    }
  }

  /// 报告进度
  void reportProgress(TaskProgress progress) {
    onProgress(progress);
  }

  /// 报告进度（简化版）
  void report(double progress, {String? stage, String? detail}) {
    onProgress(TaskProgress.of(progress, stage: stage, detail: detail));
  }
}

/// 任务取消异常
class TaskCancelledException implements Exception {
  final String message;

  TaskCancelledException([this.message = '任务已取消']);

  @override
  String toString() => 'TaskCancelledException: $message';
}
