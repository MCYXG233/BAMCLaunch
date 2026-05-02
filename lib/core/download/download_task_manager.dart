import 'dart:async';

import 'download_task.dart';
import 'download_status.dart';

/// 下载任务管理器
/// 参考 HMCL 的任务系统设计，提供统一的下载任务管理
class DownloadTaskManager {
  /// 下载任务映射
  final Map<String, DownloadTask> _tasks = {};

  /// 任务完成器映射
  final Map<String, Completer<void>> _completers = {};

  /// 任务状态变更流控制器
  final StreamController<TaskStatusEvent> _statusController =
      StreamController<TaskStatusEvent>.broadcast();

  /// 任务进度流控制器
  final StreamController<TaskProgressEvent> _progressController =
      StreamController<TaskProgressEvent>.broadcast();

  /// 任务状态变更流
  Stream<TaskStatusEvent> get statusStream => _statusController.stream;

  /// 任务进度流
  Stream<TaskProgressEvent> get progressStream => _progressController.stream;

  /// 获取所有任务
  List<DownloadTask> get tasks => List.unmodifiable(_tasks.values);

  /// 获取活跃任务
  List<DownloadTask> get activeTasks => _tasks.values
      .where((task) =>
          task.status == DownloadStatus.downloading ||
          task.status == DownloadStatus.paused)
      .toList();

  /// 获取已完成任务
  List<DownloadTask> get completedTasks => _tasks.values
      .where((task) => task.status == DownloadStatus.completed)
      .toList();

  /// 获取失败任务
  List<DownloadTask> get failedTasks => _tasks.values
      .where((task) => task.status == DownloadStatus.failed)
      .toList();

  /// 添加任务
  /// [task]: 下载任务
  /// 返回任务完成的 Future
  Future<void> addTask(DownloadTask task) {
    if (_tasks.containsKey(task.url)) {
      throw Exception('任务已存在: ${task.url}');
    }

    _tasks[task.url] = task;
    _completers[task.url] = Completer<void>();

    _statusController.add(TaskStatusEvent(
      url: task.url,
      status: task.status,
      message: '任务已添加',
    ));

    return _completers[task.url]!.future;
  }

  /// 移除任务
  /// [url]: 下载URL
  void removeTask(String url) {
    final task = _tasks[url];
    if (task != null) {
      if (task.status == DownloadStatus.downloading) {
        throw Exception('不能移除正在下载的任务');
      }

      _tasks.remove(url);
      _completers.remove(url);

      _statusController.add(TaskStatusEvent(
        url: url,
        status: DownloadStatus.canceled,
        message: '任务已移除',
      ));
    }
  }

  /// 更新任务状态
  /// [url]: 下载URL
  /// [status]: 新状态
  /// [message]: 状态消息
  void updateStatus(String url, DownloadStatus status, {String? message}) {
    final task = _tasks[url];
    if (task != null) {
      task.status = status;

      _statusController.add(TaskStatusEvent(
        url: url,
        status: status,
        message: message ?? '状态更新',
      ));

      if (status == DownloadStatus.completed) {
        _completers[url]?.complete();
      } else if (status == DownloadStatus.failed) {
        _completers[url]?.completeError(Exception(message ?? '下载失败'));
      }
    }
  }

  /// 更新任务进度
  /// [url]: 下载URL
  /// [progress]: 进度（0-1）
  /// [downloadedBytes]: 已下载字节数
  /// [totalBytes]: 总字节数
  /// [speed]: 下载速度（字节/秒）
  void updateProgress(
    String url,
    double progress, {
    int? downloadedBytes,
    int? totalBytes,
    int? speed,
  }) {
    final task = _tasks[url];
    if (task != null) {
      task.progress = progress;
      if (downloadedBytes != null) task.downloadedBytes = downloadedBytes;
      if (totalBytes != null) task.totalBytes = totalBytes;

      _progressController.add(TaskProgressEvent(
        url: url,
        progress: progress,
        downloadedBytes: task.downloadedBytes,
        totalBytes: task.totalBytes,
        speed: speed ?? 0,
      ));
    }
  }

  /// 获取任务
  /// [url]: 下载URL
  /// 返回下载任务
  DownloadTask? getTask(String url) {
    return _tasks[url];
  }

  /// 检查任务是否存在
  /// [url]: 下载URL
  /// 返回是否存在
  bool hasTask(String url) {
    return _tasks.containsKey(url);
  }

  /// 获取任务数量
  int get taskCount => _tasks.length;

  /// 获取活跃任务数量
  int get activeTaskCount => activeTasks.length;

  /// 清理已完成任务
  void clearCompletedTasks() {
    final completedUrls = _tasks.entries
        .where((entry) =>
            entry.value.status == DownloadStatus.completed ||
            entry.value.status == DownloadStatus.failed ||
            entry.value.status == DownloadStatus.canceled)
        .map((entry) => entry.key)
        .toList();

    for (final url in completedUrls) {
      _tasks.remove(url);
      _completers.remove(url);
    }
  }

  /// 清理所有任务
  void clearAllTasks() {
    for (final url in _tasks.keys) {
      if (_tasks[url]?.status == DownloadStatus.downloading) {
        _tasks[url]?.status = DownloadStatus.canceled;
      }
      _completers[url]?.completeError(Exception('任务已清理'));
    }

    _tasks.clear();
    _completers.clear();
  }

  /// 关闭管理器
  void dispose() {
    _statusController.close();
    _progressController.close();
  }
}

/// 任务状态事件
class TaskStatusEvent {
  final String url;
  final DownloadStatus status;
  final String? message;

  TaskStatusEvent({
    required this.url,
    required this.status,
    this.message,
  });
}

/// 任务进度事件
class TaskProgressEvent {
  final String url;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int speed;

  TaskProgressEvent({
    required this.url,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
  });
}
