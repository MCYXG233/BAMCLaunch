/// 全局常量
class BAMCConstants {
  BAMCConstants._();

  /// Minecraft 默认服务器端口
  static const int defaultMinecraftPort = 25565;

  /// 默认最大内存 (MB)
  static const int defaultMaxMemoryMB = 2048;

  /// 推荐最大内存 (MB)
  static const int recommendedMaxMemoryMB = 4096;

  /// 最小内存 (MB)
  static const int minMemoryMB = 512;

  /// 默认动画时长 (ms)
  static const int defaultAnimationDurationMs = 300;

  /// 下载分块大小 (4MB)
  static const int defaultChunkSize = 4 * 1024 * 1024;

  /// 最大日志文件大小 (5MB)
  static const int maxLogFileSize = 5 * 1024 * 1024;

  /// 最大日志文件数
  static const int maxLogFileCount = 10;

  /// 版本清单缓存时间 (1小时)
  static const Duration versionManifestCacheDuration = Duration(hours: 1);
}
