import 'logger.dart';

/// 通用任务基类
///
/// 所有长时间运行的操作都应继承此类。
/// 支持进度上报、取消、重试、依赖声明。
abstract class Task<T> {
  final String name;

  Task({required this.name});

  /// 执行任务
  Future<T> execute(TaskContext context);

  /// 取消任务
  void cancel() {}

  /// 是否可重试
  bool get retryable => false;

  /// 依赖的任务类型列表
  List<Type> get dependencies => [];
}

/// 任务执行上下文
class TaskContext {
  final void Function(double progress, String? message)? onProgress;
  final bool Function() isCancelled;
  final Logger logger;

  TaskContext({
    this.onProgress,
    required this.isCancelled,
    required this.logger,
  });

  void reportProgress(double progress, [String? message]) {
    if (isCancelled()) throw TaskCancelledException();
    onProgress?.call(progress, message);
  }
}

/// 任务取消异常
class TaskCancelledException implements Exception {
  @override
  String toString() => '任务已取消';
}

/// 任务链 — 串行执行多个任务
class TaskChain<T> extends Task<T> {
  final List<Task> tasks;

  TaskChain({required String name, required this.tasks}) : super(name: name);

  @override
  Future<T> execute(TaskContext context) async {
    dynamic result;
    for (int i = 0; i < tasks.length; i++) {
      if (context.isCancelled()) throw TaskCancelledException();
      context.reportProgress(i / tasks.length, tasks[i].name);
      result = await tasks[i].execute(context);
    }
    return result as T;
  }
}

/// 并行任务组 — 并发执行多个任务
class TaskGroup<T> extends Task<List<T>> {
  final List<Task<T>> tasks;
  final int maxConcurrency;

  TaskGroup({required String name, required this.tasks, this.maxConcurrency = 3})
      : super(name: name);

  @override
  Future<List<T>> execute(TaskContext context) async {
    final semaphore = _Semaphore(maxConcurrency);
    final futures = tasks.map((task) async {
      if (context.isCancelled()) throw TaskCancelledException();
      await semaphore.acquire();
      try {
        return await task.execute(context);
      } finally {
        semaphore.release();
      }
    }).toList();
    return Future.wait(futures);
  }
}

class _Semaphore {
  int _permits;
  _Semaphore(this._permits);

  Future<void> acquire() async {
    while (_permits <= 0) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _permits--;
  }

  void release() => _permits++;
}
