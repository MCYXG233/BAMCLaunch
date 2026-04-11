import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bamclauncher/core/logger/logger.dart';

class PerformanceMetrics {
  final double fps;
  final int memoryUsage;
  final double cpuUsage;
  final int networkBytesSent;
  final int networkBytesReceived;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.fps,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkBytesSent,
    required this.networkBytesReceived,
    required this.timestamp,
  });
}

class PerformanceAlert {
  final String type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  PerformanceAlert({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.details,
  });
}

class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  bool _isMonitoring = false;
  Timer? _fpsTimer;
  Timer? _metricsTimer;
  int _frameCount = 0;
  int _lastFrameTime = 0;
  double _currentFps = 0.0;
  int _currentMemory = 0;
  double _currentCpu = 0.0;
  int _networkBytesSent = 0;
  int _networkBytesReceived = 0;
  final List<double> _fpsHistory = [];
  final List<int> _memoryHistory = [];
  final List<double> _cpuHistory = [];
  final List<PerformanceMetrics> _metricsHistory = [];
  final List<PerformanceAlert> _alerts = [];
  final int _historySize = 300;

  // 性能阈值配置
  final double _fpsWarningThreshold = 45.0;
  final double _fpsCriticalThreshold = 30.0;
  final int _memoryWarningThreshold = 512 * 1024 * 1024; // 512MB
  final int _memoryCriticalThreshold = 1024 * 1024 * 1024; // 1GB
  final double _cpuWarningThreshold = 70.0;
  final double _cpuCriticalThreshold = 90.0;

  // 回调函数
  Function(double)? onFpsUpdated;
  Function(int)? onMemoryUpdated;
  Function(double)? onCpuUpdated;
  Function(PerformanceMetrics)? onMetricsUpdated;
  Function(PerformanceAlert)? onAlert;

  factory PerformanceMonitor() {
    _instance ??= PerformanceMonitor._internal();
    return _instance!;
  }

  PerformanceMonitor._internal();

  void startMonitoring({
    int fpsInterval = 1000,
    int metricsInterval = 3000,
  }) {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;

    _fpsTimer = Timer.periodic(Duration(milliseconds: fpsInterval), (timer) {
      _calculateFps();
    });

    _metricsTimer =
        Timer.periodic(Duration(milliseconds: metricsInterval), (timer) {
      _collectAllMetrics();
    });

    logger.info('Performance monitoring started');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _fpsTimer?.cancel();
    _metricsTimer?.cancel();
    logger.info('Performance monitoring stopped');
  }

  void onFrameRendered() {
    _frameCount++;
  }

  // 获取当前性能数据
  double get currentFps => _currentFps;
  int get currentMemory => _currentMemory;
  double get currentCpu => _currentCpu;
  int get networkBytesSent => _networkBytesSent;
  int get networkBytesReceived => _networkBytesReceived;

  // 获取历史数据
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  List<int> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<double> get cpuHistory => List.unmodifiable(_cpuHistory);
  List<PerformanceMetrics> get metricsHistory =>
      List.unmodifiable(_metricsHistory);
  List<PerformanceAlert> get alerts => List.unmodifiable(_alerts);

  // 性能分析方法
  PerformanceAnalysisResult analyzePerformance() {
    return PerformanceAnalysisResult(
      averageFps: _calculateAverage(_fpsHistory),
      minFps: _fpsHistory.isNotEmpty
          ? _fpsHistory.reduce((a, b) => a < b ? a : b)
          : 0.0,
      maxFps: _fpsHistory.isNotEmpty
          ? _fpsHistory.reduce((a, b) => a > b ? a : b)
          : 0.0,
      averageMemory:
          _calculateAverage(_memoryHistory.map((m) => m.toDouble()).toList()),
      peakMemory: _memoryHistory.isNotEmpty
          ? _memoryHistory.reduce((a, b) => a > b ? a : b)
          : 0,
      averageCpu: _calculateAverage(_cpuHistory),
      peakCpu: _cpuHistory.isNotEmpty
          ? _cpuHistory.reduce((a, b) => a > b ? a : b)
          : 0.0,
      alertCount: _alerts.length,
      monitoringDuration: _metricsHistory.isNotEmpty
          ? _metricsHistory.last.timestamp
              .difference(_metricsHistory.first.timestamp)
          : Duration.zero,
    );
  }

  // 导出性能报告
  String exportPerformanceReport() {
    final analysis = analyzePerformance();
    final buffer = StringBuffer();

    buffer.writeln('=== BAMCLauncher 性能报告 ===');
    buffer.writeln('生成时间: ${DateTime.now().toString()}');
    buffer.writeln('监控时长: ${analysis.monitoringDuration.inMinutes}分钟');
    buffer.writeln('');
    buffer.writeln('FPS统计:');
    buffer.writeln('  平均FPS: ${analysis.averageFps.toStringAsFixed(1)}');
    buffer.writeln('  最低FPS: ${analysis.minFps.toStringAsFixed(1)}');
    buffer.writeln('  最高FPS: ${analysis.maxFps.toStringAsFixed(1)}');
    buffer.writeln('');
    buffer.writeln('内存统计:');
    buffer.writeln('  平均内存: ${_formatBytes(analysis.averageMemory.toInt())}');
    buffer.writeln('  峰值内存: ${_formatBytes(analysis.peakMemory)}');
    buffer.writeln('');
    buffer.writeln('CPU统计:');
    buffer.writeln('  平均CPU: ${analysis.averageCpu.toStringAsFixed(1)}%');
    buffer.writeln('  峰值CPU: ${analysis.peakCpu.toStringAsFixed(1)}%');
    buffer.writeln('');
    buffer.writeln('性能告警: ${analysis.alertCount}个');

    if (_alerts.isNotEmpty) {
      buffer.writeln('告警详情:');
      for (final alert in _alerts.take(5)) {
        buffer
            .writeln('  ${alert.timestamp}: [${alert.type}] ${alert.message}');
      }
      if (_alerts.length > 5) {
        buffer.writeln('  ... 还有 ${_alerts.length - 5} 个告警');
      }
    }

    return buffer.toString();
  }

  // 重置性能数据
  void reset() {
    _fpsHistory.clear();
    _memoryHistory.clear();
    _cpuHistory.clear();
    _metricsHistory.clear();
    _alerts.clear();
    _currentFps = 0.0;
    _currentMemory = 0;
    _currentCpu = 0.0;
    _networkBytesSent = 0;
    _networkBytesReceived = 0;
    logger.info('Performance data reset');
  }

  // 内部方法：计算FPS
  void _calculateFps() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastFrameTime;

    if (elapsed > 0) {
      _currentFps = (_frameCount * 1000) / elapsed;
      _fpsHistory.add(_currentFps);

      if (_fpsHistory.length > _historySize) {
        _fpsHistory.removeAt(0);
      }

      onFpsUpdated?.call(_currentFps);
      _checkFpsThreshold(_currentFps);
    }

    _frameCount = 0;
    _lastFrameTime = now;
  }

  // 内部方法：收集所有性能指标
  Future<void> _collectAllMetrics() async {
    await _calculateMemoryUsage();
    await _calculateCpuUsage();
    await _calculateNetworkUsage();

    final metrics = PerformanceMetrics(
      fps: _currentFps,
      memoryUsage: _currentMemory,
      cpuUsage: _currentCpu,
      networkBytesSent: _networkBytesSent,
      networkBytesReceived: _networkBytesReceived,
      timestamp: DateTime.now(),
    );

    _metricsHistory.add(metrics);

    if (_metricsHistory.length > _historySize) {
      _metricsHistory.removeAt(0);
    }

    onMetricsUpdated?.call(metrics);
  }

  // 内部方法：计算内存使用
  Future<void> _calculateMemoryUsage() async {
    try {
      if (Platform.isWindows) {
        _currentMemory = await _getWindowsProcessMemory();
      } else if (Platform.isMacOS) {
        _currentMemory = await _getMacOSProcessMemory();
      } else if (Platform.isLinux) {
        _currentMemory = await _getLinuxProcessMemory();
      } else {
        _currentMemory = await _getDartMemoryUsage();
      }

      _memoryHistory.add(_currentMemory);

      if (_memoryHistory.length > _historySize) {
        _memoryHistory.removeAt(0);
      }

      onMemoryUpdated?.call(_currentMemory);
      _checkMemoryThreshold(_currentMemory);
    } catch (e) {
      logger.error('Failed to calculate memory usage: $e');
      _currentMemory = await _getDartMemoryUsage();
    }
  }

  // 内部方法：计算CPU使用
  Future<void> _calculateCpuUsage() async {
    try {
      if (Platform.isWindows) {
        _currentCpu = await _getWindowsCpuUsage();
      } else if (Platform.isMacOS) {
        _currentCpu = await _getMacOSCpuUsage();
      } else if (Platform.isLinux) {
        _currentCpu = await _getLinuxCpuUsage();
      } else {
        _currentCpu = 0.0;
      }

      _cpuHistory.add(_currentCpu);

      if (_cpuHistory.length > _historySize) {
        _cpuHistory.removeAt(0);
      }

      onCpuUpdated?.call(_currentCpu);
      _checkCpuThreshold(_currentCpu);
    } catch (e) {
      logger.error('Failed to calculate CPU usage: $e');
      _currentCpu = 0.0;
    }
  }

  // 内部方法：计算网络使用（占位实现）
  Future<void> _calculateNetworkUsage() async {
    // 这里应该实现网络流量监控
    // 暂时使用模拟数据
    _networkBytesSent += 1024;
    _networkBytesReceived += 2048;
  }

  // 内部方法：获取Dart内存使用
  Future<int> _getDartMemoryUsage() async {
    try {
      // 使用更简单的内存信息获取方式
      return 0;
    } catch (_) {}
    return 0;
  }

  // Windows平台内存获取（改进版）
  Future<int> _getWindowsProcessMemory() async {
    try {
      final processId = pid.toString();
      final process = await Process.run(
        'wmic',
        ['process', 'where', 'ProcessId=$processId', 'get', 'WorkingSetSize'],
      );
      final output = process.stdout.toString();
      final match = RegExp(r'(\d+)').firstMatch(output);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (_) {}
    return await _getDartMemoryUsage();
  }

  // Windows平台CPU获取
  Future<double> _getWindowsCpuUsage() async {
    try {
      final processId = pid.toString();
      final process = await Process.run(
        'wmic',
        [
          'process',
          'where',
          'ProcessId=$processId',
          'get',
          'PercentProcessorTime'
        ],
      );
      final output = process.stdout.toString();
      final match = RegExp(r'(\d+)').firstMatch(output);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    } catch (_) {}
    return 0.0;
  }

  // macOS平台内存获取
  Future<int> _getMacOSProcessMemory() async {
    try {
      final process = await Process.run(
        'ps',
        ['-o', 'rss=', '-p', pid.toString()],
      );
      final output = process.stdout.toString().trim();
      return int.parse(output) * 1024; // 转换为字节
    } catch (_) {}
    return await _getDartMemoryUsage();
  }

  // macOS平台CPU获取
  Future<double> _getMacOSCpuUsage() async {
    try {
      final process = await Process.run(
        'ps',
        ['-o', '%cpu=', '-p', pid.toString()],
      );
      final output = process.stdout.toString().trim();
      return double.parse(output);
    } catch (_) {}
    return 0.0;
  }

  // Linux平台内存获取
  Future<int> _getLinuxProcessMemory() async {
    try {
      final file = File('/proc/$pid/statm');
      final content = await file.readAsString();
      final parts = content.split(' ');
      if (parts.length > 1) {
        return int.parse(parts[1]) * 4096; // 转换为字节（假设页面大小为4KB）
      }
    } catch (_) {}
    return await _getDartMemoryUsage();
  }

  // Linux平台CPU获取
  Future<double> _getLinuxCpuUsage() async {
    try {
      final file = File('/proc/$pid/stat');
      final content = await file.readAsString();
      final parts = content.split(' ');
      if (parts.length >= 14) {
        final utime = int.parse(parts[13]);
        final stime = int.parse(parts[14]);
        final totalTime = utime + stime;
        return (totalTime / 100.0); // 简化计算
      }
    } catch (_) {}
    return 0.0;
  }

  // 检查FPS阈值
  void _checkFpsThreshold(double fps) {
    if (fps < _fpsCriticalThreshold) {
      _addAlert('CRITICAL', 'FPS过低: ${fps.toStringAsFixed(1)}', {'fps': fps});
    } else if (fps < _fpsWarningThreshold) {
      _addAlert('WARNING', 'FPS偏低: ${fps.toStringAsFixed(1)}', {'fps': fps});
    }
  }

  // 检查内存阈值
  void _checkMemoryThreshold(int memory) {
    if (memory > _memoryCriticalThreshold) {
      _addAlert(
          'CRITICAL', '内存占用过高: ${_formatBytes(memory)}', {'memory': memory});
    } else if (memory > _memoryWarningThreshold) {
      _addAlert(
          'WARNING', '内存占用偏高: ${_formatBytes(memory)}', {'memory': memory});
    }
  }

  // 检查CPU阈值
  void _checkCpuThreshold(double cpu) {
    if (cpu > _cpuCriticalThreshold) {
      _addAlert(
          'CRITICAL', 'CPU占用过高: ${cpu.toStringAsFixed(1)}%', {'cpu': cpu});
    } else if (cpu > _cpuWarningThreshold) {
      _addAlert('WARNING', 'CPU占用偏高: ${cpu.toStringAsFixed(1)}%', {'cpu': cpu});
    }
  }

  // 添加告警
  void _addAlert(String type, String message, Map<String, dynamic> details) {
    final alert = PerformanceAlert(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      details: details,
    );
    _alerts.add(alert);
    logger.warn('Performance Alert: [$type] $message');
    onAlert?.call(alert);
  }

  // 计算平均值
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var index = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }

  void dispose() {
    stopMonitoring();
    _fpsTimer?.cancel();
    _metricsTimer?.cancel();
  }
}

class PerformanceAnalysisResult {
  final double averageFps;
  final double minFps;
  final double maxFps;
  final double averageMemory;
  final int peakMemory;
  final double averageCpu;
  final double peakCpu;
  final int alertCount;
  final Duration monitoringDuration;

  PerformanceAnalysisResult({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.averageMemory,
    required this.peakMemory,
    required this.averageCpu,
    required this.peakCpu,
    required this.alertCount,
    required this.monitoringDuration,
  });
}

class PerformanceOverlay extends StatelessWidget {
  final PerformanceMonitor monitor;
  final bool showFps;
  final bool showMemory;
  final bool showCpu;
  final bool showNetwork;
  final bool showAlerts;

  const PerformanceOverlay({
    super.key,
    required this.monitor,
    this.showFps = true,
    this.showMemory = true,
    this.showCpu = true,
    this.showNetwork = false,
    this.showAlerts = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'BAMCLauncher Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            if (showFps) _buildFpsRow(),
            if (showMemory) _buildMemoryRow(),
            if (showCpu) _buildCpuRow(),
            if (showNetwork) _buildNetworkRow(),
            if (showAlerts && monitor.alerts.isNotEmpty) _buildAlertRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildFpsRow() {
    Color color;
    if (monitor.currentFps < 30) {
      color = Colors.red;
    } else if (monitor.currentFps < 45) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }

    return Text(
      'FPS: ${monitor.currentFps.toStringAsFixed(1)}',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildMemoryRow() {
    Color color;
    final memoryMB = monitor.currentMemory / (1024 * 1024);
    if (memoryMB > 1024) {
      color = Colors.red;
    } else if (memoryMB > 512) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }

    return Text(
      'Memory: ${_formatBytes(monitor.currentMemory)}',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildCpuRow() {
    Color color;
    if (monitor.currentCpu > 90) {
      color = Colors.red;
    } else if (monitor.currentCpu > 70) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }

    return Text(
      'CPU: ${monitor.currentCpu.toStringAsFixed(1)}%',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildNetworkRow() {
    return Text(
      'Net: ${_formatBytes(monitor.networkBytesSent)}/s | ${_formatBytes(monitor.networkBytesReceived)}/s',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildAlertRow() {
    final latestAlert = monitor.alerts.last;
    Color color;
    if (latestAlert.type == 'CRITICAL') {
      color = Colors.red;
    } else {
      color = Colors.yellow;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '[${latestAlert.type}] ${latestAlert.message}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var index = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }
}
