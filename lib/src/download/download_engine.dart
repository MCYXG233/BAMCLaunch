import 'dart:async';
import '../event/event_bus.dart';
import '../event/event.dart';
import 'download_source.dart';
import 'download_task.dart';
import 'models.dart';

/// 下载引擎接口
abstract class IDownloadEngine {
  /// 下载单个文件
  Future<String> download(
    String url,
    String savePath, {
    String? hash,
    HashType? hashType,
  });

  /// 批量下载文件
  Future<List<String>> downloadBatch(List<DownloadRequest> requests);

  /// 取消所有下载任务
  Future<void> cancelAll();

  /// 下载进度流
  Stream<DownloadProgress> get progressStream;

  /// 设置下载源
  void setDownloadSource(IDownloadSource source);

  /// 获取当前镜像源管理器
  MirrorSourceManager get mirrorManager;

  /// 设置是否启用自动切换镜像源
  void setAutoSwitchMirror(bool enabled);
}

/// 下载引擎实现（单例）
class DownloadEngine implements IDownloadEngine {
  static DownloadEngine? _instance;

  factory DownloadEngine() {
    return _instance ??= DownloadEngine._internal();
  }

  DownloadEngine._internal();

  /// 获取单例实例
  static DownloadEngine get instance =>
      _instance ??= DownloadEngine._internal();

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// 镜像源管理器
  final MirrorSourceManager _mirrorManager = MirrorSourceManager();

  /// 当前下载源
  IDownloadSource _downloadSource = MirrorSourceManager().currentMirrorSource;

  /// 是否启用自动切换镜像源
  bool _autoSwitchMirror = true;

  /// 活跃的下载任务
  final List<DownloadTask> _activeTasks = [];

  /// 进度流控制器
  final _progressController = StreamController<DownloadProgress>.broadcast();

  /// 事件总线
  final EventBus _eventBus = EventBus.instance;

  @override
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  @override
  void setDownloadSource(IDownloadSource source) {
    _downloadSource = source;
  }

  @override
  MirrorSourceManager get mirrorManager => _mirrorManager;

  @override
  void setAutoSwitchMirror(bool enabled) {
    _autoSwitchMirror = enabled;
  }

  @override
  Future<String> download(
    String url,
    String savePath, {
    String? hash,
    HashType? hashType,
  }) async {
    int attemptCount = 0;
    int maxAttempts = _mirrorManager.allMirrorSources.length;
    Exception? lastError;

    while (attemptCount < maxAttempts) {
      try {
        final actualUrl = await _downloadSource.getUrl(url);

        final task = DownloadTask(
          url: actualUrl,
          savePath: savePath,
          hash: hash,
          hashType: hashType,
        );

        _activeTasks.add(task);
        _eventBus.publish(
          DownloadStartedEvent(taskId: task.id, url: actualUrl, savePath: savePath),
        );

        try {
          final result = await task.run();
          _eventBus.publish(
            DownloadCompletedEvent(
              taskId: task.id,
              url: actualUrl,
              savePath: savePath,
            ),
          );
          return result;
        } finally {
          _activeTasks.remove(task);
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attemptCount++;

        // 如果启用了自动切换且还有其他镜像源，尝试切换
        if (_autoSwitchMirror && attemptCount < maxAttempts) {
          _downloadSource = _mirrorManager.switchToNextMirror();
          _eventBus.publish(
            DownloadInfoEvent(
              message: '镜像源不可用，正在切换到 ${_downloadSource.name}...',
            ),
          );
        }
      }
    }

    // 如果所有尝试都失败了，抛出友好的错误信息
    throw DownloadException(
      '下载失败，所有镜像源均不可用。最后一个错误: ${lastError?.message ?? lastError.toString()}',
      lastError,
    );
  }

  @override
  Future<List<String>> downloadBatch(List<DownloadRequest> requests) async {
    final results = <String>[];
    for (final request in requests) {
      final result = await download(
        request.url,
        request.savePath,
        hash: request.hash,
        hashType: request.hashType,
      );
      results.add(result);
    }
    return results;
  }

  @override
  Future<void> cancelAll() async {
    for (final task in _activeTasks) {
      task.cancel();
      _eventBus.publish(DownloadCancelledEvent(taskId: task.id));
    }
    _activeTasks.clear();
  }
}

/// 下载异常类
class DownloadException implements Exception {
  final String message;
  final Exception? innerException;

  DownloadException(this.message, [this.innerException]);

  @override
  String toString() {
    if (innerException != null) {
      return '$message\n原因: ${innerException.toString()}';
    }
    return message;
  }
}

/// 下载信息事件
class DownloadInfoEvent {
  final String message;

  DownloadInfoEvent({required this.message});
}
