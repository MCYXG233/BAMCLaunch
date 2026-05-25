import 'dart:async';
import 'task_status.dart';
import 'task_progress.dart';
import 'task_context.dart';

/// 任务抽象基类
///
/// 所有自定义任务都应该继承此类并实现 execute 方法
abstract class Task<T> {
  /// 任务ID
  final String id;

  /// 依赖的任务列表
  final List<Task> _dependencies = [];

  /// 依赖此任务的任务列表
  final List<Task> _dependents = [];

  /// 任务状态
  TaskStatus _status = TaskStatus.waiting;

  /// 任务结果
  T? _result;

  /// 任务错误
  Object? _error;

  /// 堆栈跟踪
  StackTrace? _stackTrace;

  /// 完成回调
  final Completer<T> _completer = Completer<T>();

  /// 任务上下文
  TaskContext? _context;

  /// 创建任务
  ///
  /// [id] 任务ID，如果不提供则自动生成
  Task({String? id}) : id = id ?? _generateId();

  /// 生成唯一ID
  static String _generateId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  /// ID计数器
  static int _idCounter = 0;

  /// 执行任务的核心逻辑
  ///
  /// 子类必须实现此方法
  /// [context] 任务上下文
  Future<T> execute(TaskContext context);

  /// 获取依赖的任务列表
  List<Task> get dependencies => List.unmodifiable(_dependencies);

  /// 获取依赖此任务的任务列表
  List<Task> get dependents => List.unmodifiable(_dependents);

  /// 获取任务状态
  TaskStatus get status => _status;

  /// 获取任务结果
  T? get result => _result;

  /// 获取任务错误
  Object? get error => _error;

  /// 获取堆栈跟踪
  StackTrace? get stackTrace => _stackTrace;

  /// 获取任务是否已完成
  bool get isCompleted =>
      _status == TaskStatus.success ||
      _status == TaskStatus.failed ||
      _status == TaskStatus.cancelled;

  /// 获取任务是否成功
  bool get isSuccess => _status == TaskStatus.success;

  /// 获取任务是否失败
  bool get isFailed => _status == TaskStatus.failed;

  /// 获取任务是否已取消
  bool get isCancelled => _status == TaskStatus.cancelled;

  /// 添加依赖任务
  ///
  /// [task] 要依赖的任务
  void addDependency(Task task) {
    if (!_dependencies.contains(task)) {
      _dependencies.add(task);
      task._dependents.add(this);
    }
  }

  /// 移除依赖任务
  ///
  /// [task] 要移除的依赖任务
  void removeDependency(Task task) {
    _dependencies.remove(task);
    task._dependents.remove(this);
  }

  /// 运行任务
  ///
  /// [context] 任务上下文，如果不提供则自动创建
  Future<T> run([TaskContext? context]) async {
    if (_status != TaskStatus.waiting) {
      throw StateError('任务已经在执行或已完成');
    }

    _context = context ?? TaskContext();
    _status = TaskStatus.running;

    try {
      // 先运行所有依赖任务
      for (final dep in _dependencies) {
        if (!dep.isCompleted) {
          await dep.run(_context);
        }
      }

      // 检查依赖任务是否有失败或取消的
      for (final dep in _dependencies) {
        if (dep.isFailed) {
          throw StateError('依赖任务失败: ${dep.id}');
        }
        if (dep.isCancelled) {
          throw TaskCancelledException('依赖任务已取消: ${dep.id}');
        }
      }

      // 检查当前任务是否已被取消
      _context!.checkCancelled();

      // 执行任务
      _result = await execute(_context!);
      _status = TaskStatus.success;
      _completer.complete(_result);
      return _result!;
    } on TaskCancelledException catch (e) {
      _status = TaskStatus.cancelled;
      _error = e;
      if (!_completer.isCompleted) {
        _completer.completeError(e);
      }
      rethrow;
    } catch (e, stackTrace) {
      _status = TaskStatus.failed;
      _error = e;
      _stackTrace = stackTrace;
      if (!_completer.isCompleted) {
        _completer.completeError(e, stackTrace);
      }
      rethrow;
    }
  }

  /// 取消任务
  void cancel() {
    if (isCompleted) return;
    _context?.cancel();
    _status = TaskStatus.cancelled;
  }

  /// 等待任务完成
  Future<T> get future => _completer.future;

  /// 链式操作 - 转换结果
  ///
  /// [fn] 转换函数
  Task<U> thenApply<U>(FutureOr<U> Function(T value) fn) {
    return _ApplyTask(this, fn);
  }

  /// 链式操作 - 组合任务
  ///
  /// [fn] 组合函数，返回新的任务
  Task<U> thenCompose<U>(Task<U> Function(T value) fn) {
    return _ComposeTask(this, fn);
  }

  /// 并行执行多个任务
  ///
  /// [tasks] 要并行执行的任务列表
  static Task<List<T>> all<T>(List<Task<T>> tasks) {
    return _AllTask(tasks);
  }

  /// 顺序执行多个任务
  ///
  /// [tasks] 要顺序执行的任务列表
  static Task<List<T>> sequentially<T>(List<Task<T>> tasks) {
    return _SequentialTask(tasks);
  }
}

/// Apply 任务实现
class _ApplyTask<T, U> extends Task<U> {
  final Task<T> _task;
  final FutureOr<U> Function(T value) _fn;

  _ApplyTask(this._task, this._fn) {
    addDependency(_task);
  }

  @override
  Future<U> execute(TaskContext context) async {
    final result = await _task.future;
    return await _fn(result);
  }
}

/// Compose 任务实现
class _ComposeTask<T, U> extends Task<U> {
  final Task<T> _task;
  final Task<U> Function(T value) _fn;

  _ComposeTask(this._task, this._fn) {
    addDependency(_task);
  }

  @override
  Future<U> execute(TaskContext context) async {
    final result = await _task.future;
    final nextTask = _fn(result);
    return await nextTask.run(context);
  }
}

/// All 任务实现 - 并行执行
class _AllTask<T> extends Task<List<T>> {
  final List<Task<T>> _tasks;

  _AllTask(this._tasks);

  @override
  Future<List<T>> execute(TaskContext context) async {
    // 并行运行所有任务
    final futures = _tasks.map((task) => task.run(context)).toList();
    return await Future.wait(futures);
  }
}

/// Sequential 任务实现 - 顺序执行
class _SequentialTask<T> extends Task<List<T>> {
  final List<Task<T>> _tasks;

  _SequentialTask(this._tasks);

  @override
  Future<List<T>> execute(TaskContext context) async {
    final results = <T>[];
    for (final task in _tasks) {
      results.add(await task.run(context));
    }
    return results;
  }
}
