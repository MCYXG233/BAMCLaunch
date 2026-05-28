import 'dart:async';
import '../event/event_bus.dart';
import '../event/event.dart';
import '../core/logger.dart';
import 'download_source.dart';
import 'multi_source_downloader.dart' as msd;
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

  /// 活跃的下载任务取消令牌
  final List<msd.CancellationToken> _activeCancellationTokens = [];

  /// 进度流控制器
  final _progressController = StreamController<DownloadProgress>.broadcast();

  /// 事件总线
  final EventBus _eventBus = EventBus.instance;

  /// 日志记录器
  final Logger _logger = Logger();

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
    _logger.info('开始下载: $url -> $savePath');
    int attemptCount = 0;
    int maxAttempts = _mirrorManager.allMirrorSources.length;
    Exception? lastError;

    while (attemptCount < maxAttempts) {
      try {
        final sources = _buildDownloadSources();
        final downloader = msd.MultiSourceDownloader(sources: sources);
        final cancellationToken = msd.CancellationToken();
        _activeCancellationTokens.add(cancellationToken);
        final taskId = DateTime.now().millisecondsSinceEpoch.toString();

        _eventBus.publish(
          DownloadStartedEvent(taskId: taskId, url: url, savePath: savePath),
        );

        try {
          final result = await downloader.download(
            url: url,
            savePath: savePath,
            expectedHash: hash,
            hashType: hashType != null ? msd.HashType.values[hashType.index] : null,
            onProgress: (progress, downloaded, total) {
              _progressController.add(
                DownloadProgress(
                  downloadedBytes: downloaded,
                  totalBytes: total,
                  progress: progress,
                ),
              );
            },
            onSourceSwitch: (sourceName) {
              _eventBus.publish(
                DownloadInfoEvent(message: '切换到下载源: $sourceName'),
              );
            },
            cancellationToken: cancellationToken,
          );

          _eventBus.publish(
            DownloadCompletedEvent(
              taskId: taskId,
              url: url,
              savePath: savePath,
            ),
          );
          _logger.info('下载完成: $savePath');
          return result;
        } finally {
          _activeCancellationTokens.remove(cancellationToken);
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        _logger.warn('下载尝试失败: ${lastError.toString()}');
        attemptCount++;

        if (_autoSwitchMirror && attemptCount < maxAttempts) {
          _downloadSource = _mirrorManager.switchToNextMirror();
          _eventBus.publish(
            DownloadInfoEvent(message: '镜像源不可用，正在切换到 ${_downloadSource.name}...'),
          );
        }
      }
    }

    throw DownloadException(
      '下载失败，所有镜像源均不可用。最后一个错误: ${lastError?.toString() ?? '未知错误'}',
      lastError,
    );
  }

  List<msd.DownloadSource> _buildDownloadSources() {
    final sources = <msd.DownloadSource>[];
    for (final mirror in _mirrorManager.allMirrorSources) {
      sources.add(
        msd.DownloadSource(
          name: mirror.name,
          urlResolver: (path) async => await mirror.getUrl(path),
          availabilityChecker: () async => await mirror.isAvailable(),
        ),
      );
    }
    return sources;
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
    _logger.info('取消所有下载任务');
    for (final token in _activeCancellationTokens) {
      token.cancel();
    }
    _activeCancellationTokens.clear();
    _eventBus.publish(DownloadCancelledEvent(taskId: 'all'));
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
class DownloadInfoEvent extends Event {
  final String message;

  DownloadInfoEvent({required this.message});
}
