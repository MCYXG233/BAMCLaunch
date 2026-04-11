import 'dart:async';
import 'i_download_source.dart';
import 'download_status.dart';

abstract class IDownloadEngine {
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
  });

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
  });

  Future<bool> verifyFile(String filePath, String checksum, String checksumType);

  void cancelDownload(String url);
  
  void cancelAllDownloads();
  
  void pauseDownload(String url);
  
  void resumeDownload(String url);

  bool isDownloading(String url);
  
  bool isPaused(String url);
  
  List<String> getActiveDownloads();
  
  List<String> getPausedDownloads();

  double getProgress(String url);
  
  Map<String, double> getAllProgress();
  
  DownloadStatus getStatus(String url);
}