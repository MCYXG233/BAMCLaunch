import 'dart:async';
import 'task.dart';
import 'task_status.dart';
import 'task_progress.dart';
import 'task_listener.dart';

/// 任务执行器
///
/// 管理任务的异步执行，支持取消和进度汇报
class TaskExecutor<T> {
  final Task<T> _task;
  final StreamController<TaskProgress> _progressController =
      StreamController<TaskProgress>.broadcast();

  Completer<T>? _completer;
  bool _cancelled = false;

  TaskExecutor(this._task);

  /// 进度流
  Stream<TaskProgress> get progressStream => _progressController.stream;

  /// 是否已取消
  bool get isCancelled => _cancelled;

  /// 任务状态
  TaskStatus get status => _task.status;

  /// 开始执行任务
  Future<T> start({
    void Function(TaskProgress)? onProgress,
    TaskListener<T>? listener,
  }) async {
    if (_completer != null) {
      throw StateError('任务已经启动');
    }

    _completer = Completer<T>();

    if (listener != null) {
      _task.addListener(listener);
    }

    try {
      final result = await _task.run(
        onProgress: (progress) {
          _progressController.add(progress);
          onProgress?.call(progress);
        },
        isCancelled: () => _cancelled,
      );
      _completer!.complete(result);
      return result;
    } catch (e) {
      _completer!.completeError(e);
      rethrow;
    } finally {
      if (listener != null) {
        _task.removeListener(listener);
      }
    }
  }

  /// 取消任务
  void cancel() {
    _cancelled = true;
    _task.cancel();
  }

  /// 释放资源
  void dispose() {
    _progressController.close();
  }
}

/// 批量任务执行器
///
/// 管理多个任务的执行，支持并行和顺序执行
class BatchTaskExecutor {
  final List<Task<dynamic>> _tasks;
  final StreamController<BatchTaskProgress> _progressController =
      StreamController<BatchTaskProgress>.broadcast();

  bool _cancelled = false;
  int _completedCount = 0;

  BatchTaskExecutor(this._tasks);

  /// 进度流
  Stream<BatchTaskProgress> get progressStream => _progressController.stream;

  /// 是否已取消
  bool get isCancelled => _cancelled;

  /// 并行执行所有任务
  Future<List<dynamic>> executeParallel({
    void Function(BatchTaskProgress)? onProgress,
    int? maxConcurrency,
  }) async {
    _completedCount = 0;
    final results = <dynamic>[];

    if (maxConcurrency != null && maxConcurrency > 0) {
      // 使用信号量控制并发
      final semaphore = _Semaphore(maxConcurrency);
      final futures = _tasks.map((task) async {
        await semaphore.acquire();
        try {
          if (_cancelled) throw Exception('批量任务已取消');
          final result = await task.run(
            isCancelled: () => _cancelled,
            onProgress: (p) => _updateProgress(onProgress),
          );
          results.add(result);
          _completedCount++;
          _updateProgress(onProgress);
          return result;
        } finally {
          semaphore.release();
        }
      }).toList();

      await Future.wait(futures);
    } else {
      // 无限制并发
      final futures = _tasks.map((task) async {
        if (_cancelled) throw Exception('批量任务已取消');
        final result = await task.run(
          isCancelled: () => _cancelled,
          onProgress: (p) => _updateProgress(onProgress),
        );
        results.add(result);
        _completedCount++;
        _updateProgress(onProgress);
        return result;
      }).toList();

      await Future.wait(futures);
    }

    return results;
  }

  /// 顺序执行所有任务
  Future<List<dynamic>> executeSequential({
    void Function(BatchTaskProgress)? onProgress,
  }) async {
    _completedCount = 0;
    final results = <dynamic>[];

    for (final task in _tasks) {
      if (_cancelled) throw Exception('批量任务已取消');

      final result = await task.run(
        isCancelled: () => _cancelled,
        onProgress: (p) => _updateProgress(onProgress),
      );
      results.add(result);
      _completedCount++;
      _updateProgress(onProgress);
    }

    return results;
  }

  /// 取消所有任务
  void cancelAll() {
    _cancelled = true;
    for (final task in _tasks) {
      task.cancel();
    }
  }

  void _updateProgress(void Function(BatchTaskProgress)? onProgress) {
    final progress = BatchTaskProgress(
      totalTasks: _tasks.length,
      completedTasks: _completedCount,
      progress: _tasks.isNotEmpty ? _completedCount / _tasks.length : 0.0,
    );
    _progressController.add(progress);
    onProgress?.call(progress);
  }

  /// 释放资源
  void dispose() {
    _progressController.close();
  }
}

/// 批量任务进度
class BatchTaskProgress {
  /// 总任务数
  final int totalTasks;

  /// 已完成任务数
  final int completedTasks;

  /// 整体进度（0.0 - 1.0）
  final double progress;

  const BatchTaskProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.progress,
  });

  @override
  String toString() {
    return '$completedTasks/$totalTasks (${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// 信号量（用于并发控制）
class _Semaphore {
  final int _maxPermits;
  int _availablePermits;
  final List<Completer<void>> _waitQueue = [];

  _Semaphore(int maxPermits)
      : _maxPermits = maxPermits,
        _availablePermits = maxPermits;

  Future<void> acquire() async {
    if (_availablePermits > 0) {
      _availablePermits--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _availablePermits++;
    }
  }
}
