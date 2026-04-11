import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'i_download_engine.dart';
import 'i_download_source.dart';
import 'download_task.dart';
import 'download_status.dart';

class DownloadEngine implements IDownloadEngine {
  final Map<String, DownloadTask> _downloadTasks = {};
  final Map<String, Completer<void>> _downloadCompleters = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  final Map<String, bool> _cancelFlags = {};
  final Set<String> _activeDownloads = {};

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
      throw Exception('Download already in progress');
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

    try {
      await _executeDownload(task, sources, onProgress, onError);
      _downloadCompleters[url]?.complete();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      onError?.call(e.toString());
      _downloadCompleters[url]?.completeError(e);
    } finally {
      _cleanupDownload(url);
    }
  }

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
      throw Exception('URLs and save paths must have the same length');
    }

    final results = <bool>[];
    final futures = <Future<void>>[];

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final savePath = savePaths[i];
      final checksum = checksums != null && checksums.length > i ? checksums[i] : null;
      final checksumType = checksumTypes != null && checksumTypes.length > i ? checksumTypes[i] : null;

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

  Future<void> _executeDownload(
    DownloadTask task,
    List<IDownloadSource>? sources,
    Function(double)? onProgress,
    Function(String)? onError,
  ) async {
    String resolvedUrl = task.url;
    
    if (sources != null && sources.isNotEmpty) {
      resolvedUrl = await _resolveUrlWithSources(task.url, sources);
    }

    task.status = DownloadStatus.downloading;

    final file = File(task.savePath);
    final tempFile = File('${task.savePath}.part');

    // 确保目录存在
    await tempFile.parent.create(recursive: true);

    if (await tempFile.exists()) {
      task.downloadedBytes = await tempFile.length();
    }

    final contentLength = await _getContentLength(resolvedUrl);
    task.totalBytes = contentLength;

    if (task.downloadedBytes >= contentLength) {
      await tempFile.rename(task.savePath);
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      onProgress?.call(1.0);
      return;
    }

    final chunks = _splitIntoChunks(task.downloadedBytes, contentLength, task.chunkSize);
    final semaphore = _Semaphore(task.maxThreads);
    final chunkCompleters = <Completer<void>>[];

    for (final chunk in chunks) {
      if (_cancelFlags[task.url] == true) {
        throw Exception('Download canceled');
      }

      // 检查是否暂停
      await task.waitIfPaused();

      final completer = Completer<void>();
      chunkCompleters.add(completer);

      semaphore.acquire().then((_) async {
        try {
          await _downloadChunk(
            resolvedUrl,
            tempFile,
            chunk.start,
            chunk.end,
            task,
            onProgress,
          );
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        } finally {
          semaphore.release();
        }
      });
    }

    await Future.wait(chunkCompleters.map((completer) => completer.future));

    await tempFile.rename(task.savePath);
    task.status = DownloadStatus.completed;
    task.progress = 1.0;
    onProgress?.call(1.0);

    if (task.checksum != null && task.checksumType != null) {
      final isValid = await verifyFile(task.savePath, task.checksum!, task.checksumType!);
      if (!isValid) {
        throw Exception('Checksum verification failed');
      }
    }
  }

  Future<String> _resolveUrlWithSources(String originalUrl, List<IDownloadSource> sources) async {
    final validSources = sources.where((source) => source.isValid()).toList();
    
    if (validSources.isEmpty) {
      return originalUrl;
    }

    // 并行测试所有源的响应时间
    final sourceResponseTimes = <IDownloadSource, int>{};
    final futures = validSources.map((source) async {
      try {
        final responseTime = await source.getResponseTime();
        sourceResponseTimes[source] = responseTime;
      } catch (_) {
        // 忽略失败的源
      }
    });

    await Future.wait(futures);

    if (sourceResponseTimes.isEmpty) {
      return originalUrl;
    }

    // 选择响应时间最短的源
    final bestSource = sourceResponseTimes.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;

    return await bestSource.resolveUrl(originalUrl);
  }

  Future<int> _getContentLength(String url) async {
    final client = HttpClient();
    
    try {
      final request = await client.getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      request.headers.add('Range', 'bytes=0-');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close()
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 206) {
        final contentRange = response.headers.value('content-range');
        if (contentRange != null) {
          final match = RegExp(r'/(\d+)').firstMatch(contentRange);
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
      
      throw Exception('Failed to get content length, status: ${response.statusCode}');
    } finally {
      client.close();
    }
  }

  List<_Chunk> _splitIntoChunks(int start, int end, int chunkSize) {
    final chunks = <_Chunk>[];
    int current = start;
    
    while (current< end) {
      final chunkEnd = current + chunkSize - 1;
      chunks.add(_Chunk(
        start: current,
        end: chunkEnd >end ? end - 1 : chunkEnd,
      ));
      current += chunkSize;
    }
    
    return chunks;
  }

  Future<void> _downloadChunk(
    String url,
    File file,
    int start,
    int end,
    DownloadTask task,
    Function(double)? onProgress,
  ) async {
    if (_cancelFlags[task.url] == true) {
      throw Exception('Download canceled');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 30);
      
    try {
      final request = await client.getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      request.headers.add('Range', 'bytes=$start-$end');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      request.headers.add('Accept-Encoding', 'identity'); // 禁用压缩以避免额外内存使用
      
      final response = await request.close()
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 206) {
        throw Exception('Failed to download chunk: ${response.statusCode}');
      }

      // 优化流处理：使用固定大小的缓冲区，避免内存峰值
      const bufferSize = 16384; // 16KB buffer - 更大的缓冲区减少系统调用
      final sink = file.openWrite(mode: FileMode.append);
      
      int bytesWritten = 0;
      int progressUpdateCounter = 0;
      const progressUpdateInterval = 4; // 减少进度更新频率，避免频繁回调
      
      await for (final chunk in response) {
        // 检查是否取消
        if (_cancelFlags[task.url] == true) {
          await sink.close();
          throw Exception('Download canceled');
        }
        
        // 检查是否暂停
        await task.waitIfPaused();
        
        sink.add(chunk);
        bytesWritten += chunk.length;
        progressUpdateCounter++;
        
        // 定期更新进度，避免频繁回调
        if ((bytesWritten >= bufferSize || bytesWritten >= (end - start + 1)) && 
            progressUpdateCounter >= progressUpdateInterval) {
          task.downloadedBytes += bytesWritten;
          task.progress = task.totalBytes > 0 
              ? task.downloadedBytes / task.totalBytes 
              : 0.0;
          onProgress?.call(task.progress);
          bytesWritten = 0;
          progressUpdateCounter = 0;
        }
      }
      
      // 确保最后剩余的字节也更新进度
      if (bytesWritten > 0) {
        task.downloadedBytes += bytesWritten;
        task.progress = task.totalBytes > 0 
            ? task.downloadedBytes / task.totalBytes 
            : 0.0;
        onProgress?.call(task.progress);
      }
      
      await sink.close();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<bool> verifyFile(String filePath, String checksum, String checksumType) async {
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
        throw Exception('Unsupported checksum type: $checksumType');
    }

    final input = file.openRead();
    final digest = await input.transform(hash).first;
    
    final calculatedChecksum = digest.toString();

    return calculatedChecksum.toLowerCase() == checksum.toLowerCase();
  }

  @override
  void cancelDownload(String url) {
    _cancelFlags[url] = true;
    _subscriptions[url]?.forEach((sub) => sub.cancel());
    _downloadCompleters[url]?.completeError(Exception('Download canceled'));
    _cleanupDownload(url);
  }
  
  @override
  void pauseDownload(String url) {
    final task = _downloadTasks[url];
    if (task != null) {
      task.pause();
    }
  }
  
  @override
  void resumeDownload(String url) {
    final task = _downloadTasks[url];
    if (task != null) {
      task.resume();
    }
  }

  @override
  bool isDownloading(String url) {
    return _downloadTasks.containsKey(url) && 
           _downloadTasks[url]?.status == DownloadStatus.downloading;
  }
  
  @override
  bool isPaused(String url) {
    return _downloadTasks.containsKey(url) && 
           _downloadTasks[url]?.status == DownloadStatus.paused;
  }

  @override
  double getProgress(String url) {
    return _downloadTasks[url]?.progress ?? 0.0;
  }
  
  @override
  List<String> getPausedDownloads() {
    return _downloadTasks.entries
        .where((entry) => entry.value.status == DownloadStatus.paused)
        .map((entry) => entry.key)
        .toList();
  }
  
  @override
  DownloadStatus getStatus(String url) {
    return _downloadTasks[url]?.status ?? DownloadStatus.pending;
  }

  @override
  void cancelAllDownloads() {
    final urls = List.from(_downloadTasks.keys);
    for (final url in urls) {
      cancelDownload(url);
    }
  }

  @override
  List<String> getActiveDownloads() {
    return List.from(_activeDownloads);
  }

  @override
  Map<String, double> getAllProgress() {
    final progressMap =<String, double>{};
    for (final entry in _downloadTasks.entries) {
      progressMap[entry.key] = entry.value.progress;
    }
    return progressMap;
  }

  void _cleanupDownload(String url) {
    _downloadTasks.remove(url);
    _downloadCompleters.remove(url);
    _subscriptions.remove(url);
    _cancelFlags.remove(url);
    _activeDownloads.remove(url);
  }
}

class _Chunk {
  final int start;
  final int end;

  _Chunk({required this.start, required this.end});
}

class _Semaphore {
  final int _maxPermits;
  int _availablePermits;
  final Queue<Completer<void>> _waiting = Queue();

  _Semaphore(this._maxPermits) : _availablePermits = _maxPermits;

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

  void release() {
    if (_waiting.isNotEmpty) {
      final completer = _waiting.removeFirst();
      completer.complete();
    } else {
      _availablePermits++;
    }
  }
}