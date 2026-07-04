import 'dart:async';
import '../event/event_bus.dart';
import '../event/event.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';
import 'download_engine.dart';
import 'models.dart';
import 'multi_source_downloader.dart' as msd;

class DownloadQueueManager {
  static DownloadQueueManager? _instance;
  
  factory DownloadQueueManager() {
    _instance ??= DownloadQueueManager._internal();
    return _instance!;
  }
  
  DownloadQueueManager._internal();
  
  static DownloadQueueManager get instance =>
      ServiceLocator.instance.tryGet<DownloadQueueManager>() ??
      (_instance ??= DownloadQueueManager._internal());
  
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
  
  final EventBus _eventBus = EventBus.instance;
  final Logger _logger = Logger();
  final DownloadEngine _downloadEngine = DownloadEngine();
  
  final List<DownloadQueueItem> _queue = [];
  final List<DownloadQueueItem> _downloading = [];
  final List<DownloadQueueItem> _completed = [];
  final List<DownloadQueueItem> _failed = [];
  
  int _maxConcurrent = 3;
  int _maxRetries = 3;
  
  bool _isRunning = false;
  bool _isPaused = false;
  
  StreamSubscription? _downloadSubscription;
  
  int get maxConcurrent => _maxConcurrent;
  int get maxRetries => _maxRetries;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  
  List<DownloadQueueItem> get queue => List.unmodifiable(_queue);
  List<DownloadQueueItem> get downloading => List.unmodifiable(_downloading);
  List<DownloadQueueItem> get completed => List.unmodifiable(_completed);
  List<DownloadQueueItem> get failed => List.unmodifiable(_failed);
  
  int get totalCount => _queue.length + _downloading.length + _completed.length + _failed.length;
  int get pendingCount => _queue.length;
  int get activeCount => _downloading.length;
  int get completedCount => _completed.length;
  int get failedCount => _failed.length;
  
  double get overallProgress {
    if (totalCount == 0) return 0.0;
    double total = 0.0;
    for (final item in _downloading) {
      total += item.progress;
    }
    return total / totalCount;
  }
  
  void setMaxConcurrent(int max) {
    _maxConcurrent = max.clamp(1, 10);
    if (_isRunning && !_isPaused) {
      _processQueue();
    }
  }
  
  void setMaxRetries(int max) {
    _maxRetries = max.clamp(0, 10);
  }
  
  void enqueue(DownloadRequest request) {
    final item = DownloadQueueItem(
      id: 'queue_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      request: request,
      status: QueueItemStatus.pending,
      retryCount: 0,
    );
    
    _queue.add(item);
    _eventBus.publish(QueueItemAddedEvent(item));
    
    if (_isRunning && !_isPaused) {
      _processQueue();
    }
  }
  
  void enqueueAll(List<DownloadRequest> requests) {
    for (final request in requests) {
      enqueue(request);
    }
  }
  
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    _eventBus.publish(QueueStartedEvent());
    _processQueue();
  }
  
  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _eventBus.publish(QueuePausedEvent());
  }
  
  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _eventBus.publish(QueueResumedEvent());
    _processQueue();
  }
  
  void stop() {
    _isRunning = false;
    _isPaused = false;
    
    for (final item in _downloading.toList()) {
      item.cancel();
      item.status = QueueItemStatus.pending;
      _queue.add(item);
      _downloading.remove(item);
    }
    
    _eventBus.publish(QueueStoppedEvent());
  }
  
  void cancelItem(String itemId) {
    final queueIndex = _queue.indexWhere((item) => item.id == itemId);
    if (queueIndex != -1) {
      final item = _queue.removeAt(queueIndex);
      item.status = QueueItemStatus.cancelled;
      _eventBus.publish(QueueItemRemovedEvent(item));
      return;
    }
    
    final downloadingIndex = _downloading.indexWhere((item) => item.id == itemId);
    if (downloadingIndex != -1) {
      final item = _downloading.removeAt(downloadingIndex);
      item.cancel();
      item.status = QueueItemStatus.cancelled;
      _eventBus.publish(QueueItemRemovedEvent(item));
      _processQueue();
    }
  }
  
  void retryItem(String itemId) {
    final failedIndex = _failed.indexWhere((item) => item.id == itemId);
    if (failedIndex != -1) {
      final item = _failed.removeAt(failedIndex);
      item.status = QueueItemStatus.pending;
      item.retryCount = 0;
      _queue.add(item);
      _eventBus.publish(QueueItemAddedEvent(item));
      
      if (_isRunning && !_isPaused) {
        _processQueue();
      }
    }
  }
  
  void retryAllFailed() {
    final items = _failed.toList();
    _failed.clear();
    
    for (final item in items) {
      item.status = QueueItemStatus.pending;
      item.retryCount = 0;
      _queue.add(item);
      _eventBus.publish(QueueItemAddedEvent(item));
    }
    
    if (_isRunning && !_isPaused) {
      _processQueue();
    }
  }
  
  void clearCompleted() {
    _completed.clear();
    _eventBus.publish(QueueClearedEvent(QueueSection.completed));
  }
  
  void clearFailed() {
    _failed.clear();
    _eventBus.publish(QueueClearedEvent(QueueSection.failed));
  }
  
  void removeItem(String itemId) {
    cancelItem(itemId);
    final completedIndex = _completed.indexWhere((item) => item.id == itemId);
    if (completedIndex != -1) {
      _completed.removeAt(completedIndex);
      _eventBus.publish(QueueItemRemovedEvent(
        _completed.isNotEmpty ? _completed.first : _completed[completedIndex],
      ));
    }
  }
  
  void _processQueue() {
    if (!_isRunning || _isPaused) return;
    
    while (_downloading.length < _maxConcurrent && _queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      _startDownload(item);
    }
    
    _checkCompletion();
  }
  
  void _startDownload(DownloadQueueItem item) {
    item.status = QueueItemStatus.downloading;
    _downloading.add(item);
    _eventBus.publish(QueueItemStartedEvent(item));
    _logger.info('开始下载队列项: ${item.request.url}');

    final cancellationToken = msd.CancellationToken();
    item.bindCancellationToken(cancellationToken);

    item.execute(_downloadEngine, cancellationToken: cancellationToken).then((result) {
      _onDownloadComplete(item, result);
    }).catchError((error) {
      _onDownloadError(item, error);
    });
  }
  
  void _onDownloadComplete(DownloadQueueItem item, String result) {
    _downloading.remove(item);
    item.status = QueueItemStatus.completed;
    item.result = result;
    _completed.add(item);
    
    _eventBus.publish(QueueItemCompletedEvent(item));
    _processQueue();
  }
  
  void _onDownloadError(DownloadQueueItem item, Object error) {
    _downloading.remove(item);
    item.retryCount++;
    
    if (item.retryCount < _maxRetries) {
      item.status = QueueItemStatus.retrying;
      _queue.insert(0, item);
      _eventBus.publish(QueueItemRetryingEvent(item));
      _processQueue();
    } else {
      item.status = QueueItemStatus.failed;
      item.error = error.toString();
      _failed.add(item);
      _eventBus.publish(QueueItemFailedEvent(item));
      _processQueue();
    }
  }
  
  void _checkCompletion() {
    if (_queue.isEmpty && _downloading.isEmpty && _isRunning) {
      _isRunning = false;
      _eventBus.publish(QueueCompletedEvent());
    }
  }
  
  Map<String, dynamic> getQueueStatus() {
    return {
      'isRunning': _isRunning,
      'isPaused': _isPaused,
      'totalCount': totalCount,
      'pendingCount': pendingCount,
      'activeCount': activeCount,
      'completedCount': completedCount,
      'failedCount': failedCount,
      'overallProgress': overallProgress,
      'maxConcurrent': _maxConcurrent,
      'maxRetries': _maxRetries,
    };
  }
  
  void dispose() {
    stop();
    _downloadSubscription?.cancel();
    _queue.clear();
    _downloading.clear();
    _completed.clear();
    _failed.clear();
  }
}

class DownloadQueueItem {
  final String id;
  final DownloadRequest request;
  QueueItemStatus status;
  int retryCount;
  String? result;
  String? error;
  double progress = 0.0;
  msd.CancellationToken? _cancellationToken;

  DownloadQueueItem({
    required this.id,
    required this.request,
    required this.status,
    this.retryCount = 0,
    this.result,
    this.error,
  });

  void bindCancellationToken(msd.CancellationToken token) {
    _cancellationToken = token;
  }

  void cancel() {
    _cancellationToken?.cancel();
    status = QueueItemStatus.cancelled;
  }

  Future<String> execute(DownloadEngine downloadEngine, {msd.CancellationToken? cancellationToken}) async {
    if (cancellationToken != null) {
      bindCancellationToken(cancellationToken);
    }
    return await downloadEngine.download(
      request.url,
      request.savePath,
      hash: request.hash,
      hashType: request.hashType,
      cancellationToken: cancellationToken,
    );
  }
}



enum QueueItemStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
  retrying,
}

enum QueueSection {
  queue,
  downloading,
  completed,
  failed,
}



class QueueStartedEvent extends Event {
  QueueStartedEvent();
}

class QueuePausedEvent extends Event {
  QueuePausedEvent();
}

class QueueResumedEvent extends Event {
  QueueResumedEvent();
}

class QueueStoppedEvent extends Event {
  QueueStoppedEvent();
}

class QueueCompletedEvent extends Event {
  QueueCompletedEvent();
}

class QueueItemAddedEvent extends Event {
  final DownloadQueueItem item;
  QueueItemAddedEvent(this.item);
}

class QueueItemStartedEvent extends Event {
  final DownloadQueueItem item;
  QueueItemStartedEvent(this.item);
}

class QueueItemCompletedEvent extends Event {
  final DownloadQueueItem item;
  QueueItemCompletedEvent(this.item);
}

class QueueItemFailedEvent extends Event {
  final DownloadQueueItem item;
  QueueItemFailedEvent(this.item);
}

class QueueItemRetryingEvent extends Event {
  final DownloadQueueItem item;
  QueueItemRetryingEvent(this.item);
}

class QueueItemRemovedEvent extends Event {
  final DownloadQueueItem item;
  QueueItemRemovedEvent(this.item);
}

class QueueClearedEvent extends Event {
  final QueueSection section;
  QueueClearedEvent(this.section);
}
