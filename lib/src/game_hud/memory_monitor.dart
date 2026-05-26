import 'dart:async';
import 'dart:collection';
import 'dart:io';

class MemoryMonitor {
  static const int _sampleSize = 60;
  
  final Queue<MemorySnapshot> _snapshots = Queue<MemorySnapshot>();
  Timer? _monitorTimer;
  
  final _memoryController = StreamController<MemoryData>.broadcast();
  
  int _currentUsedMemory = 0;
  int _peakUsedMemory = 0;
  int _averageUsedMemory = 0;
  int _totalMemory = 0;
  
  Stream<MemoryData> get memoryStream => _memoryController.stream;
  
  int get currentUsedMemory => _currentUsedMemory;
  int get peakUsedMemory => _peakUsedMemory;
  int get averageUsedMemory => _averageUsedMemory;
  int get totalMemory => _totalMemory;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  
  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _updateMemoryInfo();
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateMemoryInfo();
      _emitMemoryData();
    });
  }
  
  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
  }
  
  void _updateMemoryInfo() {
    try {
      final snapshot = _getMemorySnapshot();
      _snapshots.add(snapshot);
      
      if (_snapshots.length > _sampleSize) {
        _snapshots.removeFirst();
      }
      
      _currentUsedMemory = snapshot.usedMemory;
      if (snapshot.usedMemory > _peakUsedMemory) {
        _peakUsedMemory = snapshot.usedMemory;
      }
      _totalMemory = snapshot.totalMemory;
      
      int totalUsed = 0;
      for (final s in _snapshots) {
        totalUsed += s.usedMemory;
      }
      _averageUsedMemory = _snapshots.isNotEmpty 
          ? (totalUsed / _snapshots.length).round() 
          : 0;
    } catch (e) {
      _currentUsedMemory = 0;
      _totalMemory = 0;
    }
  }
  
  MemorySnapshot _getMemorySnapshot() {
    int totalMemory = 0;
    int usedMemory = 0;
    
    try {
      final process = ProcessResultEx.run('wmic', ['OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/value']);
      if (process.exitCode == 0) {
        final lines = process.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.startsWith('TotalVisibleMemorySize=')) {
            totalMemory = int.tryParse(line.split('=').last.trim()) ?? 0;
          } else if (line.startsWith('FreePhysicalMemory=')) {
            final freeMemory = int.tryParse(line.split('=').last.trim()) ?? 0;
            usedMemory = totalMemory - freeMemory;
          }
        }
      }
    } catch (e) {
      totalMemory = 8192 * 1024;
      usedMemory = (totalMemory * 0.6).round();
    }
    
    return MemorySnapshot(
      usedMemory: usedMemory,
      totalMemory: totalMemory,
      timestamp: DateTime.now(),
    );
  }
  
  void _emitMemoryData() {
    _memoryController.add(MemoryData(
      usedMemory: _currentUsedMemory,
      totalMemory: _totalMemory,
      peakUsedMemory: _peakUsedMemory,
      averageUsedMemory: _averageUsedMemory,
      usagePercentage: _totalMemory > 0 
          ? (_currentUsedMemory / _totalMemory * 100) 
          : 0.0,
      timestamp: DateTime.now(),
    ));
  }
  
  void dispose() {
    stop();
    _memoryController.close();
  }
}

class MemorySnapshot {
  final int usedMemory;
  final int totalMemory;
  final DateTime timestamp;
  
  MemorySnapshot({
    required this.usedMemory,
    required this.totalMemory,
    required this.timestamp,
  });
}

class MemoryData {
  final int usedMemory;
  final int totalMemory;
  final int peakUsedMemory;
  final int averageUsedMemory;
  final double usagePercentage;
  final DateTime timestamp;
  
  MemoryData({
    required this.usedMemory,
    required this.totalMemory,
    required this.peakUsedMemory,
    required this.averageUsedMemory,
    required this.usagePercentage,
    required this.timestamp,
  });
  
  String get usedMemoryFormatted => _formatBytes(usedMemory);
  String get totalMemoryFormatted => _formatBytes(totalMemory);
  String get peakUsedMemoryFormatted => _formatBytes(peakUsedMemory);
  String get averageUsedMemoryFormatted => _formatBytes(averageUsedMemory);
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  Map<String, dynamic> toJson() => {
    'usedMemory': usedMemory,
    'totalMemory': totalMemory,
    'peakUsedMemory': peakUsedMemory,
    'averageUsedMemory': averageUsedMemory,
    'usagePercentage': usagePercentage,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ProcessResultEx {
  static ProcessResult run(String executable, List<String> arguments) {
    return Process.runSync(executable, arguments);
  }
}
