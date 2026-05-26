import 'dart:async';
import 'dart:collection';

class FPSMonitor {
  static const int _sampleSize = 60;
  
  final Queue<double> _frameTimes = Queue<double>();
  DateTime? _lastFrameTime;
  Timer? _monitorTimer;
  
  final _fpsController = StreamController<FPSData>.broadcast();
  
  double _currentFPS = 0.0;
  double _minFPS = double.infinity;
  double _maxFPS = 0.0;
  double _averageFPS = 0.0;
  
  Stream<FPSData> get fpsStream => _fpsController.stream;
  
  double get currentFPS => _currentFPS;
  double get minFPS => _minFPS;
  double get maxFPS => _maxFPS;
  double get averageFPS => _averageFPS;
  
  void start() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFPS();
      _emitFPSData();
    });
  }
  
  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _reset();
  }
  
  void recordFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final deltaTime = now.difference(_lastFrameTime!).inMicroseconds / 1000000.0;
      _frameTimes.add(deltaTime);
      
      if (_frameTimes.length > _sampleSize) {
        _frameTimes.removeFirst();
      }
      
      if (deltaTime > 0) {
        _currentFPS = 1.0 / deltaTime;
      }
    }
    _lastFrameTime = now;
  }
  
  void _calculateFPS() {
    if (_frameTimes.isEmpty) {
      _currentFPS = 0.0;
      return;
    }
    
    double totalTime = 0;
    double minTime = double.infinity;
    double maxTime = 0.0;
    
    for (final frameTime in _frameTimes) {
      totalTime += frameTime;
      if (frameTime < minTime) minTime = frameTime;
      if (frameTime > maxTime) maxTime = frameTime;
    }
    
    final avgFrameTime = totalTime / _frameTimes.length;
    _averageFPS = avgFrameTime > 0 ? 1.0 / avgFrameTime : 0.0;
    
    if (minTime > 0) {
      _maxFPS = 1.0 / minTime;
    }
    if (maxTime > 0) {
      _minFPS = 1.0 / maxTime;
    }
    
    _currentFPS = _averageFPS;
  }
  
  void _emitFPSData() {
    _fpsController.add(FPSData(
      currentFPS: _currentFPS,
      minFPS: _minFPS == double.infinity ? 0.0 : _minFPS,
      maxFPS: _maxFPS,
      averageFPS: _averageFPS,
      frameCount: _frameTimes.length,
      timestamp: DateTime.now(),
    ));
  }
  
  void _reset() {
    _frameTimes.clear();
    _currentFPS = 0.0;
    _minFPS = double.infinity;
    _maxFPS = 0.0;
    _averageFPS = 0.0;
    _lastFrameTime = null;
  }
  
  void dispose() {
    stop();
    _fpsController.close();
  }
}

class FPSData {
  final double currentFPS;
  final double minFPS;
  final double maxFPS;
  final double averageFPS;
  final int frameCount;
  final DateTime timestamp;
  
  FPSData({
    required this.currentFPS,
    required this.minFPS,
    required this.maxFPS,
    required this.averageFPS,
    required this.frameCount,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'currentFPS': currentFPS,
    'minFPS': minFPS,
    'maxFPS': maxFPS,
    'averageFPS': averageFPS,
    'frameCount': frameCount,
    'timestamp': timestamp.toIso8601String(),
  };
}
