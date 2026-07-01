import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:bamclaunch/src/download/resume_manager.dart' as resume;
import 'package:crypto/crypto.dart' as crypto;
import '../core/network_client.dart';
import '../core/error_codes.dart';

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
    void Function(double progress, int downloaded, int total)? onProgress,
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
      final downloadedBytes = await _downloadWithProgress(
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
        final isValid = await _verifyHash(tempFile.path, expectedHash, hashType);
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
  
  Future<int> _downloadWithProgress({
    required String url,
    required File tempFile,
    required int totalSize,
    required int startByte,
    required int chunkSize,
    required int threadCount,
    void Function(double progress, int downloaded, int total)? onProgress,
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
    
    final raf = await tempFile.open(mode: FileMode.append);
    try {
      if (startByte == 0) {
        await raf.truncate(0);
      }
      await raf.setPosition(startByte);
      
      final totalChunks = ((totalSize - currentDownloaded) + chunkSize - 1) ~/ chunkSize;
      final chunksPerThread = (totalChunks + threadCount - 1) ~/ threadCount;
      
      final completers = <Completer<void>>[];
      final receivePorts = <ReceivePort>[];
      
      for (int i = 0; i < threadCount; i++) {
        final startChunk = i * chunksPerThread;
        final endChunk = (i + 1) * chunksPerThread;
        final threadStart = currentDownloaded + startChunk * chunkSize;
        final threadEnd = currentDownloaded + endChunk * chunkSize;
        final actualEnd = threadEnd > totalSize ? totalSize : threadEnd;
        
        if (threadStart >= actualEnd) continue;
        
        final receivePort = ReceivePort();
        receivePorts.add(receivePort);
        
        final completer = Completer<void>();
        completers.add(completer);
        
        final isolate = await Isolate.spawn(
          _downloadChunkIsolate,
          _DownloadChunkParams(
            url: url,
            startByte: threadStart,
            endByte: actualEnd,
            chunkSize: chunkSize,
            sendPort: receivePort.sendPort,
          ),
        );
        
        receivePort.listen((message) {
          if (cancellationToken?.isCancelled ?? false) {
            isolate.kill();
            completer.complete();
            return;
          }
          
          if (message is int) {
            currentDownloaded = message;
            final progress = currentDownloaded / totalSize;
            onProgress?.call(progress, currentDownloaded, totalSize);
          } else if (message == 'done') {
            completer.complete();
          } else if (message is Exception) {
            completer.completeError(message);
          }
        });
      }
      
      await Future.wait(completers.map((c) => c.future));
      for (final port in receivePorts) {
        port.close();
      }
      
      return currentDownloaded;
    } finally {
      await raf.close();
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
  
  Future<bool> _verifyHash(String filePath, String expectedHash, HashType hashType) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    crypto.Digest digest;
    if (hashType == HashType.sha1) {
      digest = crypto.sha1.convert(bytes);
    } else if (hashType == HashType.sha256) {
      digest = crypto.sha256.convert(bytes);
    } else {
      digest = crypto.md5.convert(bytes);
    }
    
    final actualHash = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return actualHash.toLowerCase() == expectedHash.toLowerCase();
  }
  
  static Future<void> _downloadChunkIsolate(_DownloadChunkParams params) async {
    try {
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        params.url,
        headers: {'Range': 'bytes=${params.startByte}-${params.endByte - 1}'},
      );
      if (response.statusCode != 206) {
        throw AppException.fromCode(ErrorCodes.networkUnsupportedDownload);
      }

      // 报告已下载的字节数
      params.sendPort.send(response.bodyBytes.length);
      params.sendPort.send('done');
    } catch (e) {
      params.sendPort.send(e is Exception ? e : Exception(e.toString()));
    }
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

class _DownloadChunkParams {
  final String url;
  final int startByte;
  final int endByte;
  final int chunkSize;
  final SendPort sendPort;
  
  _DownloadChunkParams({
    required this.url,
    required this.startByte,
    required this.endByte,
    required this.chunkSize,
    required this.sendPort,
  });
}
