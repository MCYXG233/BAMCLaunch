import '../app_event.dart';

/// 下载进度事件
class DownloadProgressEvent extends AppEvent {
  final String url;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int speed; // bytes per second

  DownloadProgressEvent({
    required this.url,
    required this.progress,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speed = 0,
  });

  @override
  bool get isCancelable => false;
}

/// 下载完成事件
class DownloadCompletedEvent extends AppEvent {
  final String url;
  final String filePath;

  DownloadCompletedEvent({
    required this.url,
    required this.filePath,
  });
}

/// 下载失败事件
class DownloadFailedEvent extends AppEvent {
  final String url;
  final String error;

  DownloadFailedEvent({
    required this.url,
    required this.error,
  });
}

/// 下载取消事件
class DownloadCancelledEvent extends AppEvent {
  final String url;

  DownloadCancelledEvent({required this.url});
}

/// 下载暂停事件
class DownloadPausedEvent extends AppEvent {
  final String url;

  DownloadPausedEvent({required this.url});
}

/// 下载恢复事件
class DownloadResumedEvent extends AppEvent {
  final String url;

  DownloadResumedEvent({required this.url});
}
