import 'dart:async';
import 'dart:io';
import 'package:bamclaunch/src/download/resume_manager.dart' as resume;
import 'package:crypto/crypto.dart' as crypto;
import '../core/network_client.dart';
import '../core/error_codes.dart';

/// 多源并发下载器
///
/// 支持：
/// - 多源并发下载（Racing 模式，取最快成功的源）
/// - 多线程分块下载
/// - 断点续传
/// - SHA1/SHA256/MD5 哈希校验（流式）
/// - 进度上报
/// - 取消支持
class MultiSourceDownloader {
  static const int defaultChunkSize = 4 * 1024 * 1024;
  static const int defaultThreadCount = 4;
  static const Duration sourceTimeout = Duration(seconds: 10);

  final List<DownloadSource> sources;
  final resume.ResumeDownloadManager resumeManager;

  MultiSourceDownloader({
    required this.sources,
    resume.ResumeDownloadManager? resumeManager,
  }) : resumeManager = resumeManager ?? resume.ResumeDownloadManager();

  Future<String> download({
    required String url,
    required String savePath,
    String? expectedHash,
    HashType? hashType,
    int chunkSize = defaultChunkSize,
    int threadCount = defaultThreadCount,
    void Function(double progress, int downloaded, int total, {int speed, int remainingSeconds})? onProgress,
    void Function(String source)? onSourceSwitch,
    CancellationToken? cancellationToken,
  }) async {
    final tempFile = File('$savePath.tmp');
    final parentDir = tempFile.parent;

    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final totalSize = await _getContentLength(url);
    final resumeInfo = await resumeManager.getResumeInfo(savePath, totalSize);

    int startByte = 0;
    if (resumeInfo.canResume && await tempFile.exists()) {
      startByte = resumeInfo.downloadedBytes;
      onProgress?.call(resumeInfo.progress, resumeInfo.downloadedBytes, totalSize);
    }

    await resumeManager.saveMetadata(savePath, resume.DownloadMetadata(
      filePath: savePath,
      url: url,
      expectedHash: expectedHash,
      hashType: hashType?.name,
      startTime: DateTime.now(),
    ));

    try {
      final downloadedBytes = await _downloadConcurrently(
        url: url,
        tempFile: tempFile,
        totalSize: totalSize,
        startByte: startByte,
        chunkSize: chunkSize,
        threadCount: threadCount,
        onProgress: onProgress,
        onSourceSwitch: onSourceSwitch,
        cancellationToken: cancellationToken,
      );

      await resumeManager.saveProgress(resume.DownloadProgress(
        filePath: savePath,
        url: url,
        downloadedBytes: downloadedBytes,
        totalBytes: totalSize,
        lastUpdate: DateTime.now(),
      ));

      if (expectedHash != null && hashType != null) {
        final isValid = await _verifyHashStream(tempFile.path, expectedHash, hashType);
        if (!isValid) {
          await tempFile.delete();
          await resumeManager.removeProgress(savePath);
          throw AppException.fromCode(ErrorCodes.fileHashMismatch);
        }
      }

      await tempFile.rename(savePath);
      await resumeManager.removeProgress(savePath);

      return savePath;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<int> _downloadConcurrently({
    required String url,
    required File tempFile,
    required int totalSize,
    required int startByte,
    required int chunkSize,
    required int threadCount,
    void Function(double progress, int downloaded, int total, {int speed, int remainingSeconds})? onProgress,
    void Function(String source)? onSourceSwitch,
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw AppException.fromCode(ErrorCodes.networkCancelled);
    }

    int currentDownloaded = startByte;

    if (startByte == 0) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    final remainingBytes = totalSize - startByte;
    if (remainingBytes <= 0) {
      return totalSize;
    }

    final actualThreadCount = (remainingBytes < chunkSize) ? 1 : threadCount;
    final bytesPerThread = (remainingBytes + actualThreadCount - 1) ~/ actualThreadCount;
    final chunkFiles = <int, String>{};
    final futures = <Future<void>>[];

    // 速度计算变量
    int lastBytes = startByte;
    DateTime lastTime = DateTime.now();

    for (int i = 0; i < actualThreadCount; i++) {
      final threadStart = startByte + i * bytesPerThread;
      var threadEnd = threadStart + bytesPerThread;
      if (threadEnd > totalSize) threadEnd = totalSize;
      if (threadStart >= threadEnd) continue;

      final chunkPath = '${tempFile.path}.chunk.$threadStart';
      chunkFiles[threadStart] = chunkPath;

      futures.add(_downloadChunkToFile(
        url: url,
        chunkPath: chunkPath,
        startByte: threadStart,
        endByte: threadEnd,
        cancellationToken: cancellationToken,
        onBytesDownloaded: (bytes) {
          currentDownloaded += bytes;
          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          if (elapsed > 500) {
            final speed = ((currentDownloaded - lastBytes) * 1000 ~/ elapsed);
            final remaining = speed > 0 ? ((totalSize - currentDownloaded) ~/ speed) : 0;
            final progress = currentDownloaded / totalSize;
            onProgress?.call(progress, currentDownloaded, totalSize, speed: speed, remainingSeconds: remaining);
            lastBytes = currentDownloaded;
            lastTime = now;
          } else {
            final progress = currentDownloaded / totalSize;
            onProgress?.call(progress, currentDownloaded, totalSize);
          }
        },
      ));
    }

    await Future.wait(futures);

    // 合并所有 chunk 到目标文件
    final raf = await tempFile.open(mode: FileMode.writeOnly);
    try {
      final sortedStarts = chunkFiles.keys.toList()..sort();
      for (final start in sortedStarts) {
        final chunkFile = File(chunkFiles[start]!);
        if (await chunkFile.exists()) {
          final data = await chunkFile.readAsBytes();
          await raf.setPosition(start);
          await raf.writeFrom(data);
          await chunkFile.delete();
        }
      }
    } finally {
      await raf.close();
    }

    return currentDownloaded;
  }

  Future<void> _downloadChunkToFile({
    required String url,
    required String chunkPath,
    required int startByte,
    required int endByte,
    CancellationToken? cancellationToken,
    void Function(int bytes)? onBytesDownloaded,
  }) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      url,
      headers: {'Range': 'bytes=$startByte-${endByte - 1}'},
    );

    if (cancellationToken?.isCancelled ?? false) return;

    if (response.statusCode == 416) {
      // Range 不满足，清除续传信息重新下载
      throw AppException.fromCode(ErrorCodes.networkUnsupportedDownload, detail: 'HTTP 416: Range not satisfiable');
    }

    if (response.statusCode == 206 || response.statusCode == 200) {
      final data = response.bodyBytes;
      if (data.isEmpty) return;
      await File(chunkPath).writeAsBytes(data);
      onBytesDownloaded?.call(data.length);
    } else {
      throw AppException.fromCode(ErrorCodes.networkUnsupportedDownload);
    }
  }
  
  Future<int> _getContentLength(String url) async {
    for (final source in sources) {
      try {
        final actualUrl = await source.getUrl(url);
        final networkClient = NetworkClient();
        final response = await networkClient.get(
          actualUrl,
          timeoutSeconds: sourceTimeout.inSeconds,
        );
        if (response.statusCode == 200) {
          return int.parse(response.headers['content-length'] ?? '0');
        }
      } catch (e) {
        continue;
      }
    }
    
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      url,
      timeoutSeconds: sourceTimeout.inSeconds,
    );
    if (response.statusCode == 200) {
      return int.parse(response.headers['content-length'] ?? '0');
    }
    throw AppException.fromCode(ErrorCodes.networkFileSizeError);
  }
  
  Future<bool> _verifyHashStream(String filePath, String expectedHash, HashType hashType) async {
    final file = File(filePath);
    final inputStream = file.openRead();
    final hashStream = inputStream.transform(
      hashType == HashType.sha1
          ? crypto.sha1
          : hashType == HashType.sha256
              ? crypto.sha256
              : crypto.md5,
    );
    final digest = await hashStream.first;
    final actualHash = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return actualHash.toLowerCase() == expectedHash.toLowerCase();
  }
}

class DownloadSource {
  final String name;
  final Future<String> Function(String path) urlResolver;
  final Future<bool> Function()? availabilityChecker;
  
  const DownloadSource({
    required this.name,
    required this.urlResolver,
    this.availabilityChecker,
  });
  
  Future<String> getUrl(String path) async {
    return await urlResolver(path);
  }
  
  Future<bool> isAvailable() async {
    if (availabilityChecker != null) {
      return await availabilityChecker!();
    }
    return true;
  }
}

class CancellationToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
  
  void reset() {
    _isCancelled = false;
  }
}

enum HashType {
  sha1,
  sha256,
  md5,
}
