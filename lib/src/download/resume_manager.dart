import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class ResumeDownloadManager {
  static const String _progressExtension = '.download';
  static const String _metaExtension = '.meta';
  
  final String _cacheDirectory;
  
  ResumeDownloadManager({String? cacheDirectory}) 
      : _cacheDirectory = cacheDirectory ?? _getDefaultCacheDirectory();
  
  static String _getDefaultCacheDirectory() {
    if (Platform.isWindows) {
      return '${Platform.environment['LOCALAPPDATA'] ?? '.'}\\BAMCLauncher\\downloads';
    } else {
      return '${Platform.environment['HOME'] ?? '.'}/.bacmlauncher/downloads';
    }
  }
  
  String get cacheDirectory => _cacheDirectory;
  
  Future<void> ensureCacheDirectory() async {
    final dir = Directory(_cacheDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
  
  String getProgressFilePath(String filePath) {
    final fileName = path.basename(filePath);
    return path.join(_cacheDirectory, '$fileName$_progressExtension');
  }
  
  String getMetaFilePath(String filePath) {
    final fileName = path.basename(filePath);
    return path.join(_cacheDirectory, '$fileName$_metaExtension');
  }
  
  Future<DownloadProgress?> loadProgress(String filePath) async {
    final progressFile = File(getProgressFilePath(filePath));
    if (!await progressFile.exists()) {
      return null;
    }
    
    try {
      final content = await progressFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DownloadProgress.fromJson(json);
    } catch (e) {
      await progressFile.delete();
      return null;
    }
  }
  
  Future<void> saveProgress(DownloadProgress progress) async {
    await ensureCacheDirectory();
    final progressFile = File(getProgressFilePath(progress.filePath));
    await progressFile.writeAsString(jsonEncode(progress.toJson()));
  }
  
  Future<void> removeProgress(String filePath) async {
    final progressFile = File(getProgressFilePath(filePath));
    final metaFile = File(getMetaFilePath(filePath));
    
    if (await progressFile.exists()) {
      await progressFile.delete();
    }
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
  }
  
  Future<void> saveMetadata(String filePath, DownloadMetadata metadata) async {
    await ensureCacheDirectory();
    final metaFile = File(getMetaFilePath(filePath));
    await metaFile.writeAsString(jsonEncode(metadata.toJson()));
  }
  
  Future<DownloadMetadata?> loadMetadata(String filePath) async {
    final metaFile = File(getMetaFilePath(filePath));
    if (!await metaFile.exists()) {
      return null;
    }
    
    try {
      final content = await metaFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DownloadMetadata.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  Future<ResumeInfo> getResumeInfo(String filePath, int totalSize) async {
    final progress = await loadProgress(filePath);
    final metadata = await loadMetadata(filePath);
    final tempFile = File('$filePath.tmp');
    
    if (progress == null || metadata == null) {
      return ResumeInfo(
        canResume: false,
        startByte: 0,
        downloadedBytes: 0,
        totalBytes: totalSize,
      );
    }
    
    if (progress.totalBytes != totalSize) {
      await removeProgress(filePath);
      return ResumeInfo(
        canResume: false,
        startByte: 0,
        downloadedBytes: 0,
        totalBytes: totalSize,
      );
    }
    
    if (!await tempFile.exists()) {
      await removeProgress(filePath);
      return ResumeInfo(
        canResume: false,
        startByte: 0,
        downloadedBytes: 0,
        totalBytes: totalSize,
      );
    }
    
    final tempSize = await tempFile.length();
    if (tempSize != progress.downloadedBytes) {
      await tempFile.delete();
      await removeProgress(filePath);
      return ResumeInfo(
        canResume: false,
        startByte: 0,
        downloadedBytes: 0,
        totalBytes: totalSize,
      );
    }
    
    return ResumeInfo(
      canResume: true,
      startByte: progress.downloadedBytes,
      downloadedBytes: progress.downloadedBytes,
      totalBytes: totalSize,
    );
  }
  
  Future<List<DownloadProgress>> getAllProgress() async {
    await ensureCacheDirectory();
    final dir = Directory(_cacheDirectory);
    final progressFiles = await dir
        .list()
        .where((entity) => 
            entity is File && entity.path.endsWith(_progressExtension))
        .cast<File>()
        .toList();
    
    final progressList = <DownloadProgress>[];
    for (final file in progressFiles) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        progressList.add(DownloadProgress.fromJson(json));
      } catch (e) {
        continue;
      }
    }
    
    return progressList;
  }
  
  Future<void> clearAllProgress() async {
    await ensureCacheDirectory();
    final dir = Directory(_cacheDirectory);
    final files = await dir.list().toList();
    
    for (final file in files) {
      if (file is File && 
          (file.path.endsWith(_progressExtension) || 
           file.path.endsWith(_metaExtension))) {
        await file.delete();
      }
    }
  }
}

class DownloadProgress {
  final String filePath;
  final String url;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime lastUpdate;
  final List<DownloadChunk> chunks;
  
  DownloadProgress({
    required this.filePath,
    required this.url,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.lastUpdate,
    this.chunks = const [],
  });
  
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
  
  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'url': url,
    'downloadedBytes': downloadedBytes,
    'totalBytes': totalBytes,
    'lastUpdate': lastUpdate.toIso8601String(),
    'chunks': chunks.map((c) => c.toJson()).toList(),
  };
  
  factory DownloadProgress.fromJson(Map<String, dynamic> json) {
    return DownloadProgress(
      filePath: json['filePath'] as String,
      url: json['url'] as String,
      downloadedBytes: json['downloadedBytes'] as int,
      totalBytes: json['totalBytes'] as int,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      chunks: (json['chunks'] as List<dynamic>?)
          ?.map((c) => DownloadChunk.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class DownloadChunk {
  final int startByte;
  final int endByte;
  final int downloadedBytes;
  final bool isCompleted;
  
  DownloadChunk({
    required this.startByte,
    required this.endByte,
    required this.downloadedBytes,
    this.isCompleted = false,
  });
  
  Map<String, dynamic> toJson() => {
    'startByte': startByte,
    'endByte': endByte,
    'downloadedBytes': downloadedBytes,
    'isCompleted': isCompleted,
  };
  
  factory DownloadChunk.fromJson(Map<String, dynamic> json) {
    return DownloadChunk(
      startByte: json['startByte'] as int,
      endByte: json['endByte'] as int,
      downloadedBytes: json['downloadedBytes'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class DownloadMetadata {
  final String filePath;
  final String url;
  final String? expectedHash;
  final String? hashType;
  final DateTime startTime;
  final String? referer;
  final Map<String, String>? headers;
  
  DownloadMetadata({
    required this.filePath,
    required this.url,
    this.expectedHash,
    this.hashType,
    required this.startTime,
    this.referer,
    this.headers,
  });
  
  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'url': url,
    'expectedHash': expectedHash,
    'hashType': hashType,
    'startTime': startTime.toIso8601String(),
    'referer': referer,
    'headers': headers,
  };
  
  factory DownloadMetadata.fromJson(Map<String, dynamic> json) {
    return DownloadMetadata(
      filePath: json['filePath'] as String,
      url: json['url'] as String,
      expectedHash: json['expectedHash'] as String?,
      hashType: json['hashType'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      referer: json['referer'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

class ResumeInfo {
  final bool canResume;
  final int startByte;
  final int downloadedBytes;
  final int totalBytes;
  
  ResumeInfo({
    required this.canResume,
    required this.startByte,
    required this.downloadedBytes,
    required this.totalBytes,
  });
  
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}
