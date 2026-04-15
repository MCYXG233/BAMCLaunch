import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'i_download_engine.dart';
import 'i_download_source.dart';
import 'download_task.dart';
import 'download_status.dart';
import '../logger/logger.dart';

/// 下载引擎实现类
/// 提供文件下载、多线程分块下载、断点续传等功能
class DownloadEngine implements IDownloadEngine {
  /// 下载任务映射
  final Map<String, DownloadTask> _downloadTasks = {};

  /// 下载完成器映射
  final Map<String, Completer<void>> _downloadCompleters = {};

  /// 订阅映射
  final Map<String, List<StreamSubscription>> _subscriptions = {};

  /// 取消标志映射
  final Map<String, bool> _cancelFlags = {};

  /// 活跃下载集合
  final Set<String> _activeDownloads = {};

  /// 下载速度映射
  final Map<String, int> _downloadSpeeds = {};

  /// 上次进度更新时间映射
  final Map<String, DateTime> _lastProgressUpdate = {};

  /// 下载单个文件
  /// [url]: 下载URL
  /// [savePath]: 保存路径
  /// [sources]: 下载源列表
  /// [checksum]: 文件校验和
  /// [checksumType]: 校验和类型
  /// [maxRetries]: 最大重试次数
  /// [chunkSize]: 分块大小
  /// [maxThreads]: 最大线程数
  /// [onProgress]: 进度回调
  /// [onError]: 错误回调
  @override
  Future<void> downloadFile(
    String url,
    String savePath, {
    List<IDownloadSource>? sources,
    String? checksum,
    String? checksumType,
    int maxRetries = 3,
    int chunkSize = 1024 * 1024,
    int maxThreads = 4,
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    if (_downloadTasks.containsKey(url)) {
      throw Exception('下载已经在进行中');
    }

    final task = DownloadTask(
      url: url,
      savePath: savePath,
      checksum: checksum,
      checksumType: checksumType,
      maxRetries: maxRetries,
      chunkSize: chunkSize,
      maxThreads: maxThreads,
    );
    _downloadTasks[url] = task;
    _cancelFlags[url] = false;
    _downloadCompleters[url] = Completer<void>();
    _activeDownloads.add(url);
    _downloadSpeeds[url] = 0;
    _lastProgressUpdate[url] = DateTime.now();

    try {
      logger.info('开始下载: $url -> $savePath');
      await _executeDownload(task, sources, onProgress, onError);
      logger.info('下载完成: $url');
      _downloadCompleters[url]?.complete();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      onError?.call(e.toString());
      logger.error('下载失败: $url - $e');
      _downloadCompleters[url]?.completeError(e);
    } finally {
      _cleanupDownload(url);
    }
  }

  /// 下载多个文件
  /// [urls]: 下载URL列表
  /// [savePaths]: 保存路径列表
  /// [sources]: 下载源列表
  /// [checksums]: 文件校验和列表
  /// [checksumTypes]: 校验和类型列表
  /// [maxRetries]: 最大重试次数
  /// [chunkSize]: 分块大小
  /// [maxThreads]: 最大线程数
  /// [onProgress]: 进度回调
  /// [onError]: 错误回调
  @override
  Future<List<bool>> downloadFiles(
    List<String> urls,
    List<String> savePaths, {
    List<IDownloadSource>? sources,
    List<String>? checksums,
    List<String>? checksumTypes,
    int maxRetries = 3,
    int chunkSize = 1024 * 1024,
    int maxThreads = 4,
    Function(int, double)? onProgress,
    Function(int, String)? onError,
  }) async {
    if (urls.length != savePaths.length) {
      throw Exception('URLs 和保存路径长度必须相同');
    }

    final results = <bool>[];
    final futures = <Future<void>>[];

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final savePath = savePaths[i];
      final checksum =
          checksums != null && checksums.length > i ? checksums[i] : null;
      final checksumType = checksumTypes != null && checksumTypes.length > i
          ? checksumTypes[i]
          : null;

      final future = downloadFile(
        url,
        savePath,
        sources: sources,
        checksum: checksum,
        checksumType: checksumType,
        maxRetries: maxRetries,
        chunkSize: chunkSize,
        maxThreads: maxThreads,
        onProgress: (progress) => onProgress?.call(i, progress),
        onError: (error) => onError?.call(i, error),
      ).then((_) => results.add(true)).catchError((_) => results.add(false));

      futures.add(future);
    }

    await Future.wait(futures);
    return results;
  }

  /// 执行下载
  /// [task]: 下载任务
  /// [sources]: 下载源列表
  /// [onProgress]: 进度回调
  /// [onError]: 错误回调
  Future<void> _executeDownload(
    DownloadTask task,
    List<IDownloadSource>? sources,
    Function(double)? onProgress,
    Function(String)? onError,
  ) async {
    String resolvedUrl = task.url;
    List<IDownloadSource> availableSources =
        sources?.where((source) => source.isValid()).toList() ?? [];

    if (availableSources.isNotEmpty) {
      resolvedUrl = await _resolveUrlWithSources(task.url, availableSources);
    }

    task.status = DownloadStatus.downloading;

    final file = File(task.savePath);
    final tempFile = File('${task.savePath}.part');

    // 确保目录存在
    await tempFile.parent.create(recursive: true);

    if (await tempFile.exists()) {
      task.downloadedBytes = await tempFile.length();
      logger.info('恢复下载: ${task.downloadedBytes} 字节已下载');
    }

    int contentLength = 0;
    int retryCount = 0;
    bool success = false;

    // 尝试获取内容长度，支持重试
    while (retryCount < task.maxRetries && !success) {
      try {
        contentLength = await _getContentLength(resolvedUrl);
        success = true;
      } catch (e) {
        retryCount++;
        logger.warn('获取内容长度失败 ($retryCount/${task.maxRetries}): $e');
        if (retryCount < task.maxRetries) {
          await Future.delayed(Duration(seconds: pow(2, retryCount).toInt()));
        } else {
          throw Exception('无法获取文件大小: $e');
        }
      }
    }

    task.totalBytes = contentLength;
    logger.info('文件大小: ${_formatFileSize(contentLength)}');

    if (task.downloadedBytes >= contentLength) {
      await tempFile.rename(task.savePath);
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      onProgress?.call(1.0);
      logger.info('文件已完整下载，无需重复下载');
      return;
    }

    // 动态调整分块大小，根据文件大小
    int adjustedChunkSize = task.chunkSize;
    if (contentLength > 100 * 1024 * 1024) {
      // 大于100MB
      adjustedChunkSize = 4 * 1024 * 1024; // 4MB chunks
    } else if (contentLength > 10 * 1024 * 1024) {
      // 大于10MB
      adjustedChunkSize = 2 * 1024 * 1024; // 2MB chunks
    }

    final chunks = _splitIntoChunks(
        task.downloadedBytes, contentLength, adjustedChunkSize);
    final semaphore = _Semaphore(task.maxThreads);
    final chunkCompleters = <Completer<void>>[];

    // 启动速度监控
    final speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_activeDownloads.contains(task.url)) {
        timer.cancel();
        return;
      }
      // 这里可以添加速度回调
    });

    try {
      for (final chunk in chunks) {
        if (_cancelFlags[task.url] == true) {
          throw Exception('下载已取消');
        }

        // 检查是否暂停
        await task.waitIfPaused();

        final completer = Completer<void>();
        chunkCompleters.add(completer);

        semaphore.acquire().then((_) async {
          int chunkRetryCount = 0;
          bool chunkSuccess = false;

          while (chunkRetryCount < task.maxRetries && !chunkSuccess) {
            try {
              await _downloadChunk(
                resolvedUrl,
                tempFile,
                chunk.start,
                chunk.end,
                task,
                onProgress,
              );
              chunkSuccess = true;
              completer.complete();
            } catch (e) {
              chunkRetryCount++;
              logger.warn('分块下载失败 ($chunkRetryCount/${task.maxRetries}): $e');
              if (chunkRetryCount < task.maxRetries) {
                // 尝试切换到其他源
                if (availableSources.isNotEmpty) {
                  try {
                    resolvedUrl = await _resolveUrlWithSources(
                        task.url, availableSources);
                    logger.info('切换到备用源: $resolvedUrl');
                  } catch (_) {
                    // 忽略源切换失败
                  }
                }
                await Future.delayed(
                    Duration(seconds: pow(2, chunkRetryCount).toInt()));
              } else {
                completer.completeError(e);
              }
            }
          }
          semaphore.release();
        });
      }

      await Future.wait(chunkCompleters.map((completer) => completer.future));

      await tempFile.rename(task.savePath);
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      onProgress?.call(1.0);

      if (task.checksum != null && task.checksumType != null) {
        logger.info('开始校验文件哈希值');
        final isValid =
            await verifyFile(task.savePath, task.checksum!, task.checksumType!);
        if (!isValid) {
          throw Exception('文件校验失败');
        }
        logger.info('文件校验成功');
      }
    } finally {
      speedTimer.cancel();
    }
  }

  /// 使用下载源解析URL
  /// [originalUrl]: 原始URL
  /// [sources]: 下载源列表
  /// 返回解析后的URL
  Future<String> _resolveUrlWithSources(
      String originalUrl, List<IDownloadSource> sources) async {
    // 并行测试所有源的响应时间
    final sourceResponseTimes = <IDownloadSource, int>{};
    final futures = sources.map((source) async {
      try {
        final responseTime = await source.getResponseTime();
        sourceResponseTimes[source] = responseTime;
        logger.debug('源 ${source.getName()} 响应时间: ${responseTime}ms');
      } catch (e) {
        logger.warn('源 ${source.getName()} 测试失败: $e');
      }
    });

    await Future.wait(futures);

    if (sourceResponseTimes.isEmpty) {
      logger.warn('所有源测试失败，使用原始URL');
      return originalUrl;
    }

    // 选择响应时间最短的源
    final bestSource = sourceResponseTimes.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;

    final resolvedUrl = await bestSource.resolveUrl(originalUrl);
    logger.info('选择最佳源: ${bestSource.getName()} -> $resolvedUrl');
    return resolvedUrl;
  }

  /// 获取内容长度
  /// [url]: 文件URL
  /// 返回文件大小
  Future<int> _getContentLength(String url) async {
    final client = HttpClient();

    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      request.headers.add('Range', 'bytes=0-');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      request.headers.add('Accept', '*/*');

      final response =
          await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode == 206) {
        final contentRange = response.headers.value('content-range');
        if (contentRange != null) {
          final match = RegExp(r'/([0-9]+)$').firstMatch(contentRange);
          if (match != null) {
            return int.parse(match.group(1)!);
          }
        }
      } else if (response.statusCode == 200) {
        final contentLength = response.headers.value('content-length');
        if (contentLength != null) {
          return int.parse(contentLength);
        }
      }

      throw Exception('获取内容长度失败，状态码: ${response.statusCode}');
    } finally {
      client.close(force: true);
    }
  }

  /// 将文件分割成分块
  /// [start]: 起始位置
  /// [end]: 结束位置
  /// [chunkSize]: 分块大小
  /// 返回分块列表
  List<_Chunk> _splitIntoChunks(int start, int end, int chunkSize) {
    final chunks = <_Chunk>[];
    int current = start;

    while (current < end) {
      final chunkEnd = current + chunkSize - 1;
      chunks.add(_Chunk(
        start: current,
        end: chunkEnd > end ? end - 1 : chunkEnd,
      ));
      current += chunkSize;
    }

    logger.debug('文件分块: ${chunks.length} 块');
    return chunks;
  }

  /// 下载分块
  /// [url]: 文件URL
  /// [file]: 临时文件
  /// [start]: 分块起始位置
  /// [end]: 分块结束位置
  /// [task]: 下载任务
  /// [onProgress]: 进度回调
  Future<void> _downloadChunk(
    String url,
    File file,
    int start,
    int end,
    DownloadTask task,
    Function(double)? onProgress,
  ) async {
    if (_cancelFlags[task.url] == true) {
      throw Exception('下载已取消');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 60);

    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      request.headers.add('Range', 'bytes=$start-$end');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      request.headers.add('Accept-Encoding', 'identity'); // 禁用压缩以避免额外内存使用
      request.headers.add('Accept', '*/*');

      final response =
          await request.close().timeout(const Duration(seconds: 120));

      if (response.statusCode != 206) {
        throw Exception('分块下载失败: ${response.statusCode}');
      }

      // 优化流处理：使用固定大小的缓冲区，避免内存峰值
      const bufferSize = 16384; // 16KB buffer - 更大的缓冲区减少系统调用
      final sink = file.openWrite(mode: FileMode.append);

      int bytesWritten = 0;
      int progressUpdateCounter = 0;
      const progressUpdateInterval = 4; // 减少进度更新频率，避免频繁回调
      int totalChunkBytes = end - start + 1;
      int chunkBytesWritten = 0;

      final startTime = DateTime.now();

      await for (final chunk in response) {
        // 检查是否取消
        if (_cancelFlags[task.url] == true) {
          await sink.close();
          throw Exception('下载已取消');
        }

        // 检查是否暂停
        await task.waitIfPaused();

        sink.add(chunk);
        bytesWritten += chunk.length;
        chunkBytesWritten += chunk.length;
        progressUpdateCounter++;

        // 定期更新进度，避免频繁回调
        if ((bytesWritten >= bufferSize ||
                chunkBytesWritten >= totalChunkBytes) &&
            progressUpdateCounter >= progressUpdateInterval) {
          task.downloadedBytes += bytesWritten;
          task.progress = task.totalBytes > 0
              ? task.downloadedBytes / task.totalBytes
              : 0.0;

          // 计算下载速度
          final now = DateTime.now();
          final elapsed =
              now.difference(_lastProgressUpdate[task.url]!).inMilliseconds /
                  1000;
          if (elapsed > 0) {
            _downloadSpeeds[task.url] = (bytesWritten / elapsed).round();
          }
          _lastProgressUpdate[task.url] = now;

          onProgress?.call(task.progress);
          bytesWritten = 0;
          progressUpdateCounter = 0;
        }
      }

      // 确保最后剩余的字节也更新进度
      if (bytesWritten > 0) {
        task.downloadedBytes += bytesWritten;
        task.progress =
            task.totalBytes > 0 ? task.downloadedBytes / task.totalBytes : 0.0;

        final now = DateTime.now();
        final elapsed =
            now.difference(_lastProgressUpdate[task.url]!).inMilliseconds /
                1000;
        if (elapsed > 0) {
          _downloadSpeeds[task.url] = (bytesWritten / elapsed).round();
        }
        _lastProgressUpdate[task.url] = now;

        onProgress?.call(task.progress);
      }

      await sink.close();

      final endTime = DateTime.now();
      final chunkTime = endTime.difference(startTime).inMilliseconds / 1000;
      final chunkSpeed =
          chunkTime > 0 ? (totalChunkBytes / chunkTime).round() : 0;
      logger.debug(
          '分块下载完成: ${_formatFileSize(totalChunkBytes)} in ${chunkTime.toStringAsFixed(2)}s (${_formatFileSize(chunkSpeed)}/s)');
    } finally {
      client.close(force: true);
    }
  }

  /// 验证文件
  /// [filePath]: 文件路径
  /// [checksum]: 校验和
  /// [checksumType]: 校验和类型
  /// 返回是否验证成功
  @override
  Future<bool> verifyFile(
      String filePath, String checksum, String checksumType) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    // 使用分块读取方式处理大文件，避免一次性加载到内存
    Hash hash;
    switch (checksumType.toLowerCase()) {
      case 'md5':
        hash = md5;
        break;
      case 'sha1':
        hash = sha1;
        break;
      case 'sha256':
        hash = sha256;
        break;
      default:
        throw Exception('不支持的校验类型: $checksumType');
    }

    try {
      final input = file.openRead();
      final digest = await input.transform(hash).first;

      final calculatedChecksum = digest.toString();
      final isMatch =
          calculatedChecksum.toLowerCase() == checksum.toLowerCase();

      if (!isMatch) {
        logger.error('校验失败: 计算值=$calculatedChecksum, 期望值=$checksum');
      }

      return isMatch;
    } catch (e) {
      logger.error('校验过程出错: $e');
      return false;
    }
  }

  /// 取消下载
  /// [url]: 下载URL
  @override
  void cancelDownload(String url) {
    _cancelFlags[url] = true;
    _subscriptions[url]?.forEach((sub) => sub.cancel());
    _downloadCompleters[url]?.completeError(Exception('下载已取消'));
    logger.info('取消下载: $url');
    _cleanupDownload(url);
  }

  /// 暂停下载
  /// [url]: 下载URL
  @override
  void pauseDownload(String url) {
    final task = _downloadTasks[url];
    if (task != null) {
      task.pause();
      task.status = DownloadStatus.paused;
      logger.info('暂停下载: $url');
    }
  }

  /// 恢复下载
  /// [url]: 下载URL
  @override
  void resumeDownload(String url) {
    final task = _downloadTasks[url];
    if (task != null) {
      task.resume();
      task.status = DownloadStatus.downloading;
      _lastProgressUpdate[url] = DateTime.now();
      logger.info('恢复下载: $url');
    }
  }

  /// 检查是否正在下载
  /// [url]: 下载URL
  /// 返回是否正在下载
  @override
  bool isDownloading(String url) {
    return _downloadTasks.containsKey(url) &&
        _downloadTasks[url]?.status == DownloadStatus.downloading;
  }

  /// 检查是否暂停
  /// [url]: 下载URL
  /// 返回是否暂停
  @override
  bool isPaused(String url) {
    return _downloadTasks.containsKey(url) &&
        _downloadTasks[url]?.status == DownloadStatus.paused;
  }

  /// 获取下载进度
  /// [url]: 下载URL
  /// 返回进度（0-1）
  @override
  double getProgress(String url) {
    return _downloadTasks[url]?.progress ?? 0.0;
  }

  /// 获取暂停的下载列表
  /// 返回暂停的下载URL列表
  @override
  List<String> getPausedDownloads() {
    return _downloadTasks.entries
        .where((entry) => entry.value.status == DownloadStatus.paused)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取下载状态
  /// [url]: 下载URL
  /// 返回下载状态
  @override
  DownloadStatus getStatus(String url) {
    return _downloadTasks[url]?.status ?? DownloadStatus.pending;
  }

  /// 取消所有下载
  @override
  void cancelAllDownloads() {
    final urls = List.from(_downloadTasks.keys);
    for (final url in urls) {
      cancelDownload(url);
    }
  }

  /// 获取活跃下载列表
  /// 返回活跃下载URL列表
  @override
  List<String> getActiveDownloads() {
    return List.from(_activeDownloads);
  }

  /// 获取所有下载进度
  /// 返回下载进度映射
  @override
  Map<String, double> getAllProgress() {
    final progressMap = <String, double>{};
    for (final entry in _downloadTasks.entries) {
      progressMap[entry.key] = entry.value.progress;
    }
    return progressMap;
  }

  /// 获取下载速度
  /// [url]: 下载URL
  /// 返回下载速度（字节/秒）
  int getSpeed(String url) {
    return _downloadSpeeds[url] ?? 0;
  }

  /// 获取所有下载速度
  /// 返回下载速度映射
  Map<String, int> getAllSpeeds() {
    return Map.from(_downloadSpeeds);
  }

  /// 清理下载资源
  /// [url]: 下载URL
  void _cleanupDownload(String url) {
    _downloadTasks.remove(url);
    _downloadCompleters.remove(url);
    _subscriptions.remove(url);
    _cancelFlags.remove(url);
    _activeDownloads.remove(url);
    _downloadSpeeds.remove(url);
    _lastProgressUpdate.remove(url);
  }

  /// 格式化文件大小
  /// [bytes]: 字节数
  /// 返回格式化后的文件大小字符串
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 下载分块类
class _Chunk {
  /// 分块起始位置
  final int start;

  /// 分块结束位置
  final int end;

  /// 构造函数
  _Chunk({required this.start, required this.end});
}

/// 信号量类
class _Semaphore {
  /// 最大许可数
  final int _maxPermits;

  /// 可用许可数
  int _availablePermits;

  /// 等待队列
  final Queue<Completer<void>> _waiting = Queue();

  /// 构造函数
  _Semaphore(this._maxPermits) : _availablePermits = _maxPermits;

  /// 获取许可
  Future<void> acquire() {
    if (_availablePermits > 0) {
      _availablePermits--;
      return Future.value();
    } else {
      final completer = Completer<void>();
      _waiting.add(completer);
      return completer.future;
    }
  }

  /// 释放许可
  void release() {
    if (_waiting.isNotEmpty) {
      final completer = _waiting.removeFirst();
      completer.complete();
    } else {
      _availablePermits++;
    }
  }
}
