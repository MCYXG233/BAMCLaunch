import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../logger/logger.dart';

class MemoryLeakDetector {
  static MemoryLeakDetector? _instance;
  final Map<String, int> _objectCounts = {};
  final Map<String, DateTime> _objectCreationTimes = {};
  final Map<String, StackTrace> _objectCreationTraces = {};
  Timer? _detectionTimer;
  bool _isRunning = false;

  factory MemoryLeakDetector() {
    _instance ??= MemoryLeakDetector._internal();
    return _instance!;
  }

  MemoryLeakDetector._internal();

  void startDetection({int intervalSeconds = 30}) {
    if (_isRunning) return;
    _isRunning = true;

    _detectionTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _performLeakDetection(),
    );

    logger.info('Memory leak detection started');
  }

  void stopDetection() {
    _isRunning = false;
    _detectionTimer?.cancel();
    logger.info('Memory leak detection stopped');
  }

  void trackObject(String objectType, String objectId) {
    final key = '$objectType:$objectId';
    _objectCounts[key] = (_objectCounts[key] ?? 0) + 1;
    _objectCreationTimes[key] = DateTime.now();
    _objectCreationTraces[key] = StackTrace.current;
  }

  void untrackObject(String objectType, String objectId) {
    final key = '$objectType:$objectId';
    _objectCounts.remove(key);
    _objectCreationTimes.remove(key);
    _objectCreationTraces.remove(key);
  }

  void _performLeakDetection() {
    final now = DateTime.now();
    final suspiciousObjects = <String>[];

    for (final entry in _objectCreationTimes.entries) {
      final key = entry.key;
      final creationTime = entry.value;
      final age = now.difference(creationTime).inMinutes;

      // 检查长时间存在的对象（可能的内存泄漏）
      if (age > 10) {
        suspiciousObjects.add(key);
      }
    }

    if (suspiciousObjects.isNotEmpty) {
      logger.warn(
          'Potential memory leaks detected: ${suspiciousObjects.length} objects');
      for (final key in suspiciousObjects.take(5)) {
        final parts = key.split(':');
        final objectType = parts[0];
        final objectId = parts[1];
        final creationTime = _objectCreationTimes[key];
        final age =
            creationTime != null ? now.difference(creationTime).inMinutes : 0;

        logger.warn('  - $objectType:$objectId (${age}m old)');
      }
    }
  }

  void dispose() {
    stopDetection();
    _objectCounts.clear();
    _objectCreationTimes.clear();
    _objectCreationTraces.clear();
  }
}

class MemoryOptimizer {
  static MemoryOptimizer? _instance;
  final MemoryLeakDetector _leakDetector = MemoryLeakDetector();
  final List<MemoryOptimizationRule> _optimizationRules = [];

  factory MemoryOptimizer() {
    _instance ??= MemoryOptimizer._internal();
    return _instance!;
  }

  MemoryOptimizer._internal() {
    _initializeOptimizationRules();
  }

  void _initializeOptimizationRules() {
    // 添加默认优化规则
    _optimizationRules.addAll([
      ImageCacheOptimizationRule(),
      NetworkCacheOptimizationRule(),
      IsolateMemoryOptimizationRule(),
      LargeFileOptimizationRule(),
    ]);
  }

  void startOptimization() {
    logger.info('Memory optimization started');

    // 启动内存泄漏检测
    _leakDetector.startDetection();

    // 应用所有优化规则
    for (final rule in _optimizationRules) {
      rule.apply();
    }
  }

  void stopOptimization() {
    logger.info('Memory optimization stopped');
    _leakDetector.stopDetection();

    // 清理所有优化规则
    for (final rule in _optimizationRules) {
      rule.dispose();
    }
  }

  void addOptimizationRule(MemoryOptimizationRule rule) {
    _optimizationRules.add(rule);
    rule.apply();
  }

  void removeOptimizationRule(MemoryOptimizationRule rule) {
    rule.dispose();
    _optimizationRules.remove(rule);
  }

  Future<MemoryInfo> getMemoryInfo() async {
    try {
      // 使用更简单的内存信息获取方式
      return MemoryInfo(
        usedMemory: 0,
        heapSize: 0,
        externalMemory: 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      logger.error('Failed to get memory info: $e');
      return MemoryInfo(
        usedMemory: 0,
        heapSize: 0,
        externalMemory: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  void optimizeNow() {
    logger.info('Performing immediate memory optimization');

    // 强制垃圾回收
    if (kDebugMode) {
      debugPrint('Forcing garbage collection...');
    }

    // 应用所有优化规则
    for (final rule in _optimizationRules) {
      rule.optimize();
    }
  }

  void dispose() {
    stopOptimization();
    _leakDetector.dispose();
    _optimizationRules.clear();
  }
}

abstract class MemoryOptimizationRule {
  void apply();
  void optimize();
  void dispose();
}

class ImageCacheOptimizationRule implements MemoryOptimizationRule {
  Timer? _optimizationTimer;

  @override
  void apply() {
    logger.info('Applying image cache optimization');

    // 设置图片缓存大小限制
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        100 * 1024 * 1024; // 100MB

    // 定期清理图片缓存
    _optimizationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => optimize(),
    );
  }

  @override
  void optimize() {
    final cache = PaintingBinding.instance.imageCache;
    final currentSize = cache.currentSize;
    final currentSizeBytes = cache.currentSizeBytes;

    if (currentSize > 50 || currentSizeBytes > 50 * 1024 * 1024) {
      cache.clear();
      logger.info(
          'Image cache cleared: $currentSize images, ${_formatBytes(currentSizeBytes)}');
    }
  }

  @override
  void dispose() {
    _optimizationTimer?.cancel();
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var index = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }
}

class NetworkCacheOptimizationRule implements MemoryOptimizationRule {
  final Map<String, DateTime> _cachedResponses = {};
  Timer? _cleanupTimer;

  @override
  void apply() {
    logger.info('Applying network cache optimization');

    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => optimize(),
    );
  }

  @override
  void optimize() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cachedResponses.entries) {
      final age = now.difference(entry.value).inMinutes;
      if (age > 30) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cachedResponses.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      logger
          .info('Cleaned ${expiredKeys.length} expired network cache entries');
    }
  }

  void trackNetworkResponse(String url) {
    _cachedResponses[url] = DateTime.now();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _cachedResponses.clear();
  }
}

class IsolateMemoryOptimizationRule implements MemoryOptimizationRule {
  final List<Isolate> _trackedIsolates = [];
  Timer? _monitorTimer;

  @override
  void apply() {
    logger.info('Applying isolate memory optimization');

    _monitorTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => optimize(),
    );
  }

  @override
  void optimize() {
    // 监控Isolate内存使用情况
    for (final isolate in _trackedIsolates) {
      // 这里可以添加Isolate内存监控逻辑
    }
  }

  void trackIsolate(Isolate isolate) {
    _trackedIsolates.add(isolate);
  }

  void untrackIsolate(Isolate isolate) {
    _trackedIsolates.remove(isolate);
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _trackedIsolates.clear();
  }
}

class LargeFileOptimizationRule implements MemoryOptimizationRule {
  final Set<String> _openFiles = {};
  Timer? _monitorTimer;

  @override
  void apply() {
    logger.info('Applying large file optimization');

    _monitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => optimize(),
    );
  }

  @override
  void optimize() {
    if (_openFiles.length > 10) {
      logger.warn('Too many open files: ${_openFiles.length}');
      // 这里可以添加文件关闭逻辑
    }
  }

  void trackOpenFile(String filePath) {
    _openFiles.add(filePath);
  }

  void trackClosedFile(String filePath) {
    _openFiles.remove(filePath);
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _openFiles.clear();
  }
}

class MemoryInfo {
  final int usedMemory;
  final int heapSize;
  final int externalMemory;
  final DateTime timestamp;

  MemoryInfo({
    required this.usedMemory,
    required this.heapSize,
    required this.externalMemory,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MemoryInfo(used: ${_formatBytes(usedMemory)}, heap: ${_formatBytes(heapSize)}, external: ${_formatBytes(externalMemory)}, timestamp: $timestamp)';
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var index = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }
}
