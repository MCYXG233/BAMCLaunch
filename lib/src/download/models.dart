/// 哈希类型枚举
enum HashType {
  /// SHA-1 哈希
  sha1,

  /// SHA-256 哈希
  sha256,

  /// MD5 哈希
  md5,
}

/// 下载请求
class DownloadRequest {
  /// 文件URL
  final String url;

  /// 保存路径
  final String savePath;

  /// 预期的文件哈希值
  final String? hash;

  /// 哈希类型
  final HashType? hashType;

  /// 创建下载请求
  DownloadRequest({
    required this.url,
    required this.savePath,
    this.hash,
    this.hashType,
  });
}

/// 下载进度
class DownloadProgress {
  /// 已下载字节数
  final int downloadedBytes;

  /// 总字节数
  final int totalBytes;

  /// 进度值（0.0 - 1.0）
  final double progress;

  /// 下载速度（字节/秒）
  final int speed;

  /// 剩余时间（秒）
  final int remainingTime;

  /// 创建下载进度
  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    this.speed = 0,
    this.remainingTime = 0,
  });

  /// 从已下载和总字节数创建进度
  factory DownloadProgress.fromBytes(int downloaded, int total) {
    final progress = total > 0 ? downloaded / total : 0.0;
    return DownloadProgress(
      downloadedBytes: downloaded,
      totalBytes: total,
      progress: progress,
    );
  }
}
