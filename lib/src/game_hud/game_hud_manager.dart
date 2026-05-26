import 'dart:async';
import '../event/event_bus.dart';
import '../event/event.dart';
import 'fps_monitor.dart';
import 'memory_monitor.dart';

class GameHUDManager {
  static GameHUDManager? _instance;
  
  factory GameHUDManager() {
    _instance ??= GameHUDManager._internal();
    return _instance!;
  }
  
  GameHUDManager._internal();
  
  static GameHUDManager get instance => _instance ??= GameHUDManager._internal();
  
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
  
  final FPSMonitor fpsMonitor = FPSMonitor();
  final MemoryMonitor memoryMonitor = MemoryMonitor();
  
  final EventBus _eventBus = EventBus.instance;
  
  bool _isEnabled = false;
  bool _showFPS = true;
  bool _showMemory = true;
  bool _showPosition = false;
  bool _autoAdjustQuality = false;
  
  int _fpsWarningThreshold = 30;
  int _memoryWarningThreshold = 85;
  
  StreamSubscription<FPSData>? _fpsSubscription;
  StreamSubscription<MemoryData>? _memorySubscription;
  
  bool get isEnabled => _isEnabled;
  bool get showFPS => _showFPS;
  bool get showMemory => _showMemory;
  bool get showPosition => _showPosition;
  bool get autoAdjustQuality => _autoAdjustQuality;
  int get fpsWarningThreshold => _fpsWarningThreshold;
  int get memoryWarningThreshold => _memoryWarningThreshold;
  
  void enable() {
    if (_isEnabled) return;
    _isEnabled = true;
    fpsMonitor.start();
    memoryMonitor.start();
    _subscribeToStreams();
    _eventBus.publish(HUDEnabledEvent());
  }
  
  void disable() {
    if (!_isEnabled) return;
    _isEnabled = false;
    fpsMonitor.stop();
    memoryMonitor.stop();
    _unsubscribeFromStreams();
    _eventBus.publish(HUDDisabledEvent());
  }
  
  void toggle() {
    if (_isEnabled) {
      disable();
    } else {
      enable();
    }
  }
  
  void setShowFPS(bool show) {
    _showFPS = show;
    _eventBus.publish(HUDSettingsChangedEvent(
      showFPS: show,
      showMemory: _showMemory,
      showPosition: _showPosition,
    ));
  }
  
  void setShowMemory(bool show) {
    _showMemory = show;
    _eventBus.publish(HUDSettingsChangedEvent(
      showFPS: _showFPS,
      showMemory: show,
      showPosition: _showPosition,
    ));
  }
  
  void setShowPosition(bool show) {
    _showPosition = show;
    _eventBus.publish(HUDSettingsChangedEvent(
      showFPS: _showFPS,
      showMemory: _showMemory,
      showPosition: show,
    ));
  }
  
  void setAutoAdjustQuality(bool enabled) {
    _autoAdjustQuality = enabled;
  }
  
  void setFPSWarningThreshold(int threshold) {
    _fpsWarningThreshold = threshold.clamp(10, 120);
  }
  
  void setMemoryWarningThreshold(int threshold) {
    _memoryWarningThreshold = threshold.clamp(50, 100);
  }
  
  void _subscribeToStreams() {
    _fpsSubscription = fpsMonitor.fpsStream.listen(_handleFPSData);
    _memorySubscription = memoryMonitor.memoryStream.listen(_handleMemoryData);
  }
  
  void _unsubscribeFromStreams() {
    _fpsSubscription?.cancel();
    _memorySubscription?.cancel();
    _fpsSubscription = null;
    _memorySubscription = null;
  }
  
  void _handleFPSData(FPSData data) {
    if (data.currentFPS < _fpsWarningThreshold) {
      _eventBus.publish(LowFPSWarningEvent(
        currentFPS: data.currentFPS,
        averageFPS: data.averageFPS,
        threshold: _fpsWarningThreshold.toDouble(),
      ));
    }
  }
  
  void _handleMemoryData(MemoryData data) {
    if (data.usagePercentage > _memoryWarningThreshold) {
      _eventBus.publish(HighMemoryWarningEvent(
        usedMemory: data.usedMemory,
        totalMemory: data.totalMemory,
        usagePercentage: data.usagePercentage,
        threshold: _memoryWarningThreshold.toDouble(),
      ));
    }
  }
  
  Map<String, dynamic> getCurrentStats() {
    return {
      'fps': {
        'current': fpsMonitor.currentFPS,
        'min': fpsMonitor.minFPS == double.infinity ? 0.0 : fpsMonitor.minFPS,
        'max': fpsMonitor.maxFPS,
        'average': fpsMonitor.averageFPS,
      },
      'memory': {
        'used': memoryMonitor.currentUsedMemory,
        'total': memoryMonitor.totalMemory,
        'peak': memoryMonitor.peakUsedMemory,
        'average': memoryMonitor.averageUsedMemory,
        'usagePercentage': memoryMonitor.totalMemory > 0 
            ? (memoryMonitor.currentUsedMemory / memoryMonitor.totalMemory * 100)
            : 0.0,
      },
      'settings': {
        'isEnabled': _isEnabled,
        'showFPS': _showFPS,
        'showMemory': _showMemory,
        'showPosition': _showPosition,
        'autoAdjustQuality': _autoAdjustQuality,
        'fpsWarningThreshold': _fpsWarningThreshold,
        'memoryWarningThreshold': _memoryWarningThreshold,
      },
    };
  }
  
  void dispose() {
    disable();
    fpsMonitor.dispose();
    memoryMonitor.dispose();
  }
}

class HUDEnabledEvent extends Event {
  HUDEnabledEvent();
}

class HUDDisabledEvent extends Event {
  HUDDisabledEvent();
}

class HUDSettingsChangedEvent extends Event {
  final bool showFPS;
  final bool showMemory;
  final bool showPosition;
  
  HUDSettingsChangedEvent({
    required this.showFPS,
    required this.showMemory,
    required this.showPosition,
  });
}

class LowFPSWarningEvent extends Event {
  final double currentFPS;
  final double averageFPS;
  final double threshold;
  
  LowFPSWarningEvent({
    required this.currentFPS,
    required this.averageFPS,
    required this.threshold,
  });
}

class HighMemoryWarningEvent extends Event {
  final int usedMemory;
  final int totalMemory;
  final double usagePercentage;
  final double threshold;
  
  HighMemoryWarningEvent({
    required this.usedMemory,
    required this.totalMemory,
    required this.usagePercentage,
    required this.threshold,
  });
}

class HUDStatsSnapshot {
  final FPSData fpsData;
  final MemoryData memoryData;
  final DateTime timestamp;
  
  HUDStatsSnapshot({
    required this.fpsData,
    required this.memoryData,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'fps': fpsData.toJson(),
    'memory': memoryData.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}
