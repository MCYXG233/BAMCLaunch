import 'dart:async';
import 'task_status.dart';
import 'task_progress.dart';
import 'task_context.dart';
import 'task_listener.dart';

/// 任务基类
///
/// 参考 HMCL 的 Task<T> 设计，支持：
/// - 依赖图（dependents/dependencies）
/// - 进度汇报
/// - 结果链式传递（Monadic 链式操作）
/// - 取消支持
///
/// 使用示例：
/// ```dart
/// final task = DownloadTask(url: '...', savePath: '...');
/// final result = await task.run(
///   onProgress: (p) => print(p),
///   isCancelled: () => userPressedCancel,
/// );
/// ```
abstract class Task<T> {
  TaskStatus _status = TaskStatus.waiting;
  final List<TaskListener<T>> _listeners = [];

  /// 当前任务状态
  TaskStatus get status => _status;

  /// 执行任务（子类实现）
  ///
  /// 此方法包含任务的核心逻辑
  Future<T> execute(TaskContext context);

  /// 依赖的任务（在本任务之前执行）
  List<Task<dynamic>> get dependents => [];

  /// 后续任务（本任务成功后执行）
  List<Task<dynamic>> get dependencies => [];

  /// 添加监听器
  void addListener(TaskListener<T> listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(TaskListener<T> listener) {
    _listeners.remove(listener);
  }

  /// 执行整个任务图
  ///
  /// 1. 执行依赖任务（dependents）
  /// 2. 执行当前任务
  /// 3. 执行后续任务（dependencies）
  Future<T> run({
    void Function(TaskProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final context = TaskContext(
      onProgress: onProgress ?? (_) {},
      isCancelled: isCancelled ?? () => false,
    );

    try {
      _status = TaskStatus.running;
      _notifyStart();

      // 1. 执行依赖任务
      for (final dep in dependents) {
        await dep.run(onProgress: onProgress, isCancelled: isCancelled);
      }

      // 2. 执行当前任务
      final result = await execute(context);
      _status = TaskStatus.success;
      _notifyFinished(result);

      // 3. 执行后续任务
      for (final dep in dependencies) {
        await dep.run(onProgress: onProgress, isCancelled: isCancelled);
      }

      return result;
    } catch (e) {
      _status = TaskStatus.failed;
      _notifyFailed(e);
      rethrow;
    } finally {
      _notifyStopped();
    }
  }

  /// 取消任务
  void cancel() {
    _status = TaskStatus.cancelled;
  }

  /// 链式转换（类似 Future.then）
  ///
  /// 示例：downloadTask.thenApply((path) => File(path).lengthSync())
  Task<R> thenApply<R>(R Function(T result) fn) {
    return _ApplyTask<T, R>(this, fn);
  }

  /// 链式组合（返回新任务）
  ///
  /// 示例：versionTask.thenCompose((version) => InstallModTask(version))
  Task<R> thenCompose<R>(Task<R> Function(T result) fn) {
    return _ComposeTask<T, R>(this, fn);
  }

  /// 链式消费（不返回值）
  ///
  /// 示例：task.thenAccept((result) => print(result))
  Task<void> thenAccept(void Function(T result) fn) {
    return _AcceptTask<T>(this, fn);
  }

  /// 链式执行（不依赖结果）
  ///
  /// 示例：task.thenRun(() => print('完成'))
  Task<void> thenRun(void Function() fn) {
    return _RunTask(fn);
  }

  /// 并行执行多个任务
  ///
  /// 示例：Task.all([downloadMod1, downloadMod2, downloadMod3])
  static Future<List<T>> all<T>(
    List<Task<T>> tasks, {
    void Function(TaskProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    return Future.wait(tasks.map((t) => t.run(
          onProgress: onProgress,
          isCancelled: isCancelled,
        )));
  }

  /// 顺序执行多个任务
  ///
  /// 示例：Task.sequentially([checkJava, downloadGame, installForge, launch])
  static Future<List<T>> sequentially<T>(
    List<Task<T>> tasks, {
    void Function(TaskProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final results = <T>[];
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final result = await task.run(
        onProgress: onProgress != null
            ? (p) => onProgress(TaskProgress.of(
                  (i + p.progress) / tasks.length,
                  stage: p.stage,
                  detail: p.detail,
                ))
            : null,
        isCancelled: isCancelled,
      );
      results.add(result);
    }
    return results;
  }

  /// 创建一个简单的任务
  ///
  /// 示例：Task.of(() async => 42)
  static Task<T> of<T>(Future<T> Function() fn) {
    return _SimpleTask(fn);
  }

  /// 创建一个已完成的任务
  ///
  /// 示例：Task.value(42)
  static Task<T> value<T>(T value) {
    return _ValueTask(value);
  }

  /// 创建一个失败的任务
  ///
  /// 示例：Task.error(Exception('失败'))
  static Task<T> error<T>(Object error) {
    return _ErrorTask(error);
  }

  void _notifyStart() {
    for (final listener in _listeners) {
      listener.onStart(this);
    }
  }

  void _notifyFinished(T result) {
    for (final listener in _listeners) {
      listener.onFinished(this, result);
    }
  }

  void _notifyFailed(Object error) {
    for (final listener in _listeners) {
      listener.onFailed(this, error);
    }
  }

  void _notifyStopped() {
    for (final listener in _listeners) {
      listener.onStopped(this);
    }
  }
}

/// 转换任务（thenApply 实现）
class _ApplyTask<T, R> extends Task<R> {
  final Task<T> parent;
  final R Function(T) transform;

  _ApplyTask(this.parent, this.transform);

  @override
  List<Task<dynamic>> get dependents => [parent];

  @override
  Future<R> execute(TaskContext context) async {
    // 等待父任务完成并获取结果
    final parentResult = await parent.run();
    return transform(parentResult);
  }
}

/// 组合任务（thenCompose 实现）
class _ComposeTask<T, R> extends Task<R> {
  final Task<T> parent;
  final Task<R> Function(T) transform;

  _ComposeTask(this.parent, this.transform);

  @override
  List<Task<dynamic>> get dependents => [parent];

  @override
  Future<R> execute(TaskContext context) async {
    final parentResult = await parent.run();
    return await transform(parentResult).run();
  }
}

/// 消费任务（thenAccept 实现）
class _AcceptTask<T> extends Task<void> {
  final Task<T> parent;
  final void Function(T) action;

  _AcceptTask(this.parent, this.action);

  @override
  List<Task<dynamic>> get dependents => [parent];

  @override
  Future<void> execute(TaskContext context) async {
    final parentResult = await parent.run();
    action(parentResult);
  }
}

/// 运行任务（thenRun 实现）
class _RunTask extends Task<void> {
  final void Function() action;

  _RunTask(this.action);

  @override
  Future<void> execute(TaskContext context) async {
    action();
  }
}

/// 简单任务
class _SimpleTask<T> extends Task<T> {
  final Future<T> Function() fn;

  _SimpleTask(this.fn);

  @override
  Future<T> execute(TaskContext context) async {
    return await fn();
  }
}

/// 已完成任务
class _ValueTask<T> extends Task<T> {
  final T value;

  _ValueTask(this.value);

  @override
  Future<T> execute(TaskContext context) async {
    return value;
  }
}

/// 失败任务
class _ErrorTask<T> extends Task<T> {
  final Object error;

  _ErrorTask(this.error);

  @override
  Future<T> execute(TaskContext context) async {
    throw error;
  }
}
