import 'dart:async';
import 'i_download_source.dart';
import '../logger/logger.dart';

/// 下载源管理器
/// 参考 HMCL 的下载源管理，提供统一的下载源管理
class DownloadSourceManager {
  /// 下载源列表
  final List<IDownloadSource> _sources = [];

  /// 源优先级映射
  final Map<String, int> _sourcePriorities = {};

  /// 源健康状态映射
  final Map<String, SourceHealth> _sourceHealth = {};

  /// 源响应时间映射
  final Map<String, int> _sourceResponseTimes = {};

  /// 健康检查定时器
  Timer? _healthCheckTimer;

  /// 健康检查间隔
  final Duration healthCheckInterval;

  /// 构造函数
  DownloadSourceManager({
    this.healthCheckInterval = const Duration(minutes: 5),
  });

  /// 添加下载源
  /// [source]: 下载源
  /// [priority]: 优先级（数值越小优先级越高）
  void addSource(IDownloadSource source, {int priority = 100}) {
    _sources.add(source);
    _sourcePriorities[source.getName()] = priority;
    _sourceHealth[source.getName()] = SourceHealth.unknown;
    _sourceResponseTimes[source.getName()] = 0;

    logger.info('添加下载源: ${source.getName()}, 优先级: $priority');
  }

  /// 移除下载源
  /// [sourceName]: 下载源名称
  void removeSource(String sourceName) {
    _sources.removeWhere((source) => source.getName() == sourceName);
    _sourcePriorities.remove(sourceName);
    _sourceHealth.remove(sourceName);
    _sourceResponseTimes.remove(sourceName);

    logger.info('移除下载源: $sourceName');
  }

  /// 获取最佳下载源
  /// [originalUrl]: 原始URL
  /// 返回最佳下载源
  Future<IDownloadSource?> getBestSource(String originalUrl) async {
    if (_sources.isEmpty) {
      return null;
    }

    // 测试所有源的响应时间
    await _testAllSources(originalUrl);

    // 按优先级和健康状态排序
    final sortedSources = List<IDownloadSource>.from(_sources)
      ..sort((a, b) {
        final aHealth = _sourceHealth[a.getName()] ?? SourceHealth.unknown;
        final bHealth = _sourceHealth[b.getName()] ?? SourceHealth.unknown;

        // 健康的源优先
        if (aHealth == SourceHealth.healthy && bHealth != SourceHealth.healthy) {
          return -1;
        }
        if (aHealth != SourceHealth.healthy && bHealth == SourceHealth.healthy) {
          return 1;
        }

        // 按优先级排序
        final aPriority = _sourcePriorities[a.getName()] ?? 100;
        final bPriority = _sourcePriorities[b.getName()] ?? 100;
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // 按响应时间排序
        final aTime = _sourceResponseTimes[a.getName()] ?? 999999;
        final bTime = _sourceResponseTimes[b.getName()] ?? 999999;
        return aTime.compareTo(bTime);
      });

    return sortedSources.first;
  }

  /// 获取所有健康源
  /// 返回健康源列表
  List<IDownloadSource> getHealthySources() {
    return _sources
        .where((source) =>
            _sourceHealth[source.getName()] == SourceHealth.healthy)
        .toList();
  }

  /// 测试所有源
  /// [testUrl]: 测试URL
  Future<void> _testAllSources(String testUrl) async {
    final futures = _sources.map((source) async {
      try {
        final responseTime = await source.getResponseTime();
        _sourceResponseTimes[source.getName()] = responseTime;
        _sourceHealth[source.getName()] = SourceHealth.healthy;

        logger.debug(
            '源 ${source.getName()} 响应时间: ${responseTime}ms');
      } catch (e) {
        _sourceHealth[source.getName()] = SourceHealth.unhealthy;
        logger.warn('源 ${source.getName()} 测试失败: $e');
      }
    });

    await Future.wait(futures);
  }

  /// 启动健康检查
  /// [testUrl]: 测试URL
  void startHealthCheck(String testUrl) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _testAllSources(testUrl);
    });
  }

  /// 停止健康检查
  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// 获取源健康状态
  /// [sourceName]: 源名称
  /// 返回源健康状态
  SourceHealth? getSourceHealth(String sourceName) {
    return _sourceHealth[sourceName];
  }

  /// 获取源响应时间
  /// [sourceName]: 源名称
  /// 返回响应时间（毫秒）
  int? getSourceResponseTime(String sourceName) {
    return _sourceResponseTimes[sourceName];
  }

  /// 获取所有源
  List<IDownloadSource> get sources => List.unmodifiable(_sources);

  /// 获取源数量
  int get sourceCount => _sources.length;

  /// 关闭管理器
  void dispose() {
    stopHealthCheck();
  }
}

/// 源健康状态
enum SourceHealth {
  /// 未知
  unknown,

  /// 健康
  healthy,

  /// 不健康
  unhealthy,

  /// 不可用
  unavailable,
}
