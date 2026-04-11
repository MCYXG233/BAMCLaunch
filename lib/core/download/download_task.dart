import 'dart:async';
import 'download_status.dart';

class DownloadTask {
  final String url;
  final String savePath;
  final String? checksum;
  final String? checksumType;
  final int maxRetries;
  final int chunkSize;
  final int maxThreads;
  
  DownloadStatus status;
  double progress;
  int downloadedBytes;
  int totalBytes;
  String? errorMessage;
  
  // 用于暂停/恢复的控制
  bool isPaused = false;
  Completer<void>? pauseCompleter;
  
  DownloadTask({
    required this.url,
    required this.savePath,
    this.checksum,
    this.checksumType,
    required this.maxRetries,
    required this.chunkSize,
    required this.maxThreads,
  }) : status = DownloadStatus.pending,
       progress = 0.0,
       downloadedBytes = 0,
       totalBytes = 0;
  
  void pause() {
    if (status == DownloadStatus.downloading && !isPaused) {
      isPaused = true;
      pauseCompleter = Completer<void>();
      status = DownloadStatus.paused;
    }
  }
  
  void resume() {
    if (status == DownloadStatus.paused && isPaused) {
      isPaused = false;
      pauseCompleter?.complete();
      pauseCompleter = null;
      status = DownloadStatus.downloading;
    }
  }
  
  Future<void> waitIfPaused() async {
    if (isPaused && pauseCompleter != null) {
      await pauseCompleter?.future;
    }
  }
}