import 'task.dart';

/// 任务生命周期监听器
///
/// 参考 HMCL 的 TaskListener，监听任务全生命周期
abstract class TaskListener<T> {
  /// 任务开始
  void onStart(Task<T> task) {}

  /// 任务执行中
  void onRunning(Task<T> task) {}

  /// 任务成功完成
  void onFinished(Task<T> task, T result) {}

  /// 任务失败
  void onFailed(Task<T> task, Object error) {}

  /// 任务停止（完成或失败）
  void onStopped(Task<T> task) {}
}

/// 简单的任务监听器实现
///
/// 提供回调函数方式的监听器
class SimpleTaskListener<T> extends TaskListener<T> {
  final void Function(Task<T>)? onStartCallback;
  final void Function(Task<T>, T)? onFinishedCallback;
  final void Function(Task<T>, Object)? onFailedCallback;

  SimpleTaskListener({
    this.onStartCallback,
    this.onFinishedCallback,
    this.onFailedCallback,
  });

  @override
  void onStart(Task<T> task) {
    onStartCallback?.call(task);
  }

  @override
  void onFinished(Task<T> task, T result) {
    onFinishedCallback?.call(task, result);
  }

  @override
  void onFailed(Task<T> task, Object error) {
    onFailedCallback?.call(task, error);
  }
}
