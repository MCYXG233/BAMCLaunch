import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import '../core/network_client.dart';
import '../task/task.dart';
import '../task/task_context.dart';
import '../task/task_progress.dart';
import 'models.dart';

/// 下载任务
class DownloadTask extends Task<String> {
  /// 文件URL
  final String url;

  /// 保存路径
  final String savePath;

  /// 预期的文件哈希值
  final String? hash;

  /// 哈希类型
  final HashType? hashType;

  /// 最大重试次数
  final int maxRetries;

  /// 分块大小（默认 4MB）
  final int chunkSize;

  /// 并发下载线程数
  final int threadCount;

  /// 创建下载任务
  DownloadTask({
    required this.url,
    required this.savePath,
    this.hash,
    this.hashType,
    this.maxRetries = 3,
    this.chunkSize = 4 * 1024 * 1024,
    this.threadCount = 4,
    String? id,
  }) : super(id: id);

  @override
  Future<String> execute(TaskContext context) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        context.checkCancelled();
        return await _downloadWithProgress(context);
      } catch (e, stackTrace) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1 + attempt));
      }
    }
    throw Exception('下载失败，已超过最大重试次数');
  }

  /// 带进度的下载
  Future<String> _downloadWithProgress(TaskContext context) async {
    final file = File(savePath);
    final tempFile = File('$savePath.tmp');
    final progressFile = File('$savePath.progress');

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    int totalBytes = await _getContentLength(url);
    int downloadedBytes = 0;

    if (await progressFile.exists() && await tempFile.exists()) {
      final progressData = jsonDecode(await progressFile.readAsString());
      downloadedBytes = progressData['downloaded'] as int;
      if (progressData['total'] as int == totalBytes) {
        final tempStat = await tempFile.stat();
        if (tempStat.size == downloadedBytes) {
          downloadedBytes = tempStat.size;
        }
      } else {
        downloadedBytes = 0;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        if (await progressFile.exists()) {
          await progressFile.delete();
        }
      }
    }

    if (downloadedBytes > 0 && downloadedBytes < totalBytes) {
      context.onProgress(
        TaskProgress(
          progress: downloadedBytes / totalBytes,
          description: '继续下载...',
        ),
      );
    }

    final receivePort = ReceivePort();
    final completer = Completer<void>();
    int totalDownloaded = downloadedBytes;

    receivePort.listen((message) {
      if (message is Map) {
        final type = message['type'] as String;
        if (type == 'progress') {
          final bytes = message['bytes'] as int;
          totalDownloaded = bytes;
          final progress = totalDownloaded / totalBytes;
          context.onProgress(
            TaskProgress(
              progress: progress,
              description:
                  '下载中... ${(totalDownloaded / 1024 / 1024).toStringAsFixed(2)} MB / ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
          );
        } else if (type == 'done') {
          completer.complete();
        } else if (type == 'error') {
          completer.completeError(message['error'], message['stackTrace']);
        }
      }
    });

    final isolate = await Isolate.spawn(
      _downloadIsolate,
      _DownloadIsolateData(
        url: url,
        tempPath: tempFile.path,
        progressPath: progressFile.path,
        startByte: downloadedBytes,
        totalBytes: totalBytes,
        sendPort: receivePort.sendPort,
        chunkSize: chunkSize,
        threadCount: threadCount,
      ),
    );

    try {
      await completer.future;
    } finally {
      receivePort.close();
      isolate.kill();
    }

    await tempFile.rename(savePath);
    if (await progressFile.exists()) {
      await progressFile.delete();
    }

    if (hash != null && hashType != null) {
      context.onProgress(TaskProgress(progress: 0.95, description: '校验文件...'));
      final isValid = await _verifyHash(savePath, hash!, hashType!);
      if (!isValid) {
        await file.delete();
        throw Exception('文件哈希校验失败');
      }
    }

    context.onProgress(TaskProgress(progress: 1.0, description: '下载完成'));

    return savePath;
  }

  /// 获取文件大小
  Future<int> _getContentLength(String url) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      url,
      timeoutSeconds: 30,
    );
    
    if (response.statusCode == 200) {
      return int.parse(response.headers['content-length'] ?? '0');
    }
    
    throw Exception('无法获取文件大小，HTTP ${response.statusCode}');
  }

  /// 校验文件哈希
  Future<bool> _verifyHash(
    String filePath,
    String expectedHash,
    HashType hashType,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    Digest digest;

    if (hashType == HashType.sha1) {
      digest = sha1.convert(bytes);
    } else if (hashType == HashType.sha256) {
      digest = sha256.convert(bytes);
    } else {
      digest = md5.convert(bytes);
    }

    final actualHash = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return actualHash.toLowerCase() == expectedHash.toLowerCase();
  }

  /// 隔离区下载函数
  static Future<void> _downloadIsolate(_DownloadIsolateData data) async {
    try {
      final tempFile = File(data.tempPath);
      final progressFile = File(data.progressPath);
      final raf = await tempFile.open(mode: FileMode.append);

      try {
        if (data.startByte == 0) {
          await raf.truncate(0);
        }
        await raf.setPosition(data.startByte);

        int currentDownloaded = data.startByte;
        final chunkSize = data.chunkSize;
        final threads = data.threadCount;

        final totalChunks =
            ((data.totalBytes - currentDownloaded) + chunkSize - 1) ~/
            chunkSize;
        final chunksPerThread = (totalChunks + threads - 1) ~/ threads;

        final completers = <Completer<void>>[];
        final receivePorts = <ReceivePort>[];

        for (int i = 0; i < threads; i++) {
          final startChunk = i * chunksPerThread;
          final endChunk = (i + 1) * chunksPerThread;
          final threadStart = currentDownloaded + startChunk * chunkSize;
          final threadEnd = currentDownloaded + endChunk * chunkSize;
          final actualEnd = threadEnd > data.totalBytes
              ? data.totalBytes
              : threadEnd;

          if (threadStart >= actualEnd) continue;

          final receivePort = ReceivePort();
          receivePorts.add(receivePort);

          final completer = Completer<void>();
          completers.add(completer);

          final isolate = await Isolate.spawn(
            _downloadChunkIsolate,
            _DownloadChunkData(
              url: data.url,
              tempPath: data.tempPath,
              startByte: threadStart,
              endByte: actualEnd,
              chunkSize: chunkSize,
              sendPort: receivePort.sendPort,
            ),
          );

          receivePort.listen((message) {
            if (message is int) {
              data.sendPort.send({'type': 'progress', 'bytes': message});
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

        await progressFile.writeAsString(
          jsonEncode({'downloaded': data.totalBytes, 'total': data.totalBytes}),
        );

        data.sendPort.send({'type': 'done'});
      } finally {
        await raf.close();
      }
    } catch (e, stackTrace) {
      data.sendPort.send({
        'type': 'error',
        'error': e,
        'stackTrace': stackTrace,
      });
    }
  }

  /// 分块下载隔离区
  static Future<void> _downloadChunkIsolate(_DownloadChunkData data) async {
    try {
      final networkClient = NetworkClient();
      final tempFile = File(data.tempPath);
      final raf = await tempFile.open(mode: FileMode.writeOnlyAppend);
      await raf.setPosition(data.startByte);

      int position = data.startByte;

      while (position < data.endByte) {
        final end = position + data.chunkSize - 1;
        final actualEnd = end > data.endByte - 1 ? data.endByte - 1 : end;

        final response = await networkClient.get(
          data.url,
          headers: {
            'Range': 'bytes=$position-$actualEnd',
          },
          timeoutSeconds: 60,
        );

        if (response.statusCode != 206 && response.statusCode != 200) {
          throw Exception('不支持分块下载，HTTP ${response.statusCode}');
        }

        await raf.writeFrom(response.bodyBytes);
        position += response.bodyBytes.length;
        data.sendPort.send(position);
      }

      await raf.close();
      data.sendPort.send('done');
    } catch (e) {
      data.sendPort.send(e is Exception ? e : Exception(e.toString()));
    }
  }
}

/// 下载隔离区数据
class _DownloadIsolateData {
  final String url;
  final String tempPath;
  final String progressPath;
  final int startByte;
  final int totalBytes;
  final SendPort sendPort;
  final int chunkSize;
  final int threadCount;

  _DownloadIsolateData({
    required this.url,
    required this.tempPath,
    required this.progressPath,
    required this.startByte,
    required this.totalBytes,
    required this.sendPort,
    required this.chunkSize,
    required this.threadCount,
  });
}

/// 分块下载数据
class _DownloadChunkData {
  final String url;
  final String tempPath;
  final int startByte;
  final int endByte;
  final int chunkSize;
  final SendPort sendPort;

  _DownloadChunkData({
    required this.url,
    required this.tempPath,
    required this.startByte,
    required this.endByte,
    required this.chunkSize,
    required this.sendPort,
  });
}