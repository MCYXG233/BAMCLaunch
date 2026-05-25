import 'task_progress.dart';

/// 任务取消异常
///
/// 当任务被取消时抛出此异常
class TaskCancelledException implements Exception {
  /// 异常消息
  final String message;

  TaskCancelledException([this.message = '任务已取消']);

  @override
  String toString() => 'TaskCancelledException: $message';
}

/// 任务上下文
///
/// 提供任务执行时的上下文信息和操作
class TaskContext {
  /// 进度更新回调函数
  final void Function(TaskProgress progress)? _onProgress;

  /// 是否已取消
  bool _isCancelled = false;

  /// 创建任务上下文
  ///
  /// [onProgress] 进度更新回调函数
  TaskContext({void Function(TaskProgress progress)? onProgress})
    : _onProgress = onProgress;

  /// 报告进度
  ///
  /// [progress] 进度信息
  void onProgress(TaskProgress progress) {
    _onProgress?.call(progress);
  }

  /// 检查任务是否已取消
  ///
  /// 如果任务已取消，会抛出 [TaskCancelledException]
  void checkCancelled() {
    if (_isCancelled) {
      throw TaskCancelledException();
    }
  }

  /// 获取任务是否已取消
  bool get isCancelled => _isCancelled;

  /// 标记任务为已取消
  void cancel() {
    _isCancelled = true;
  }
}
