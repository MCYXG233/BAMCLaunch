import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/logger.dart';
import 'models.dart';

class ProcessMonitor {
  final Logger _logger;
  final String processId;
  final Process process;
  final String gameDirectory;

  StreamController<GameLog>? _logController;
  StreamController<GameProcessStatus>? _statusController;
  IOSink? _logSink;
  
  DateTime? _readyTime;
  DateTime? _stopTime;
  bool _isReady = false;

  ProcessMonitor({
    required this.processId,
    required this.process,
    required this.gameDirectory,
  }) : _logger = Logger('ProcessMonitor($processId)') {
    _initLogFile();
  }

  Stream<GameLog> get logStream => _logController?.stream ?? const Stream.empty();
  Stream<GameProcessStatus> get statusStream => _statusController?.stream ?? const Stream.empty();

  bool get isReady => _isReady;
  DateTime? get readyTime => _readyTime;

  void start() {
    _logController = StreamController<GameLog>.broadcast();
    _statusController = StreamController<GameProcessStatus>.broadcast();
    
    _listenToOutput();
    _listenToExit();
  }

  void _initLogFile() {
    try {
      final logDir = Directory('$gameDirectory/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      final logFile = File('$gameDirectory/logs/minecraft_${processId}.log');
      _logSink = logFile.openWrite(mode: FileMode.append);
      _logSink?.writeln('=== Process Monitor Log - ${DateTime.now().toIso8601String()} ===');
    } catch (e) {
      _logger.warn('Failed to initialize log file: $e');
    }
  }

  void _listenToOutput() {
    final stdoutSubscription = process.stdout
        .transform(const Utf8Decoder())
        .listen(
          (data) => _handleOutput(data, 'stdout'),
          onError: (e) => _logger.error('Stdout stream error: $e'),
          onDone: () => _logger.debug('Stdout stream closed'),
        );

    final stderrSubscription = process.stderr
        .transform(const Utf8Decoder())
        .listen(
          (data) => _handleOutput(data, 'stderr'),
          onError: (e) => _logger.error('Stderr stream error: $e'),
          onDone: () => _logger.debug('Stderr stream closed'),
        );

    process.exitCode.then((_) {
      stdoutSubscription.cancel();
      stderrSubscription.cancel();
    });
  }

  void _handleOutput(String data, String source) {
    final lines = data.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final log = GameLog(
        timestamp: DateTime.now(),
        level: _parseLogLevel(line),
        message: line,
        source: source,
      );

      _logController?.add(log);
      
      if (_logSink != null) {
        try {
          _logSink?.writeln(log.format());
        } catch (e) {
          _logger.warn('Failed to write to log file: $e');
        }
      }

      _checkGameReady(line);
    }
  }

  void _checkGameReady(String line) {
    if (_isReady) return;

    final lower = line.toLowerCase();
    final readyKeywords = [
      'render thread started',
      'glfw initialized',
      'setting user:',
      'lwjgl version',
      'minecraft main thread',
      'game started',
      'entering game loop',
    ];

    if (readyKeywords.any((keyword) => lower.contains(keyword))) {
      _logger.info('Game is ready');
      _isReady = true;
      _readyTime = DateTime.now();
    }
  }

  GameLogLevel _parseLogLevel(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return GameLogLevel.error;
    } else if (lower.contains('warn') || lower.contains('warning')) {
      return GameLogLevel.warn;
    } else if (lower.contains('debug')) {
      return GameLogLevel.debug;
    }
    return GameLogLevel.info;
  }

  void _listenToExit() async {
    final exitCode = await process.exitCode;
    _stopTime = DateTime.now();

    if (exitCode == 0) {
      _statusController?.add(GameProcessStatus.stopped);
    } else {
      _statusController?.add(GameProcessStatus.crashed);
    }

    _cleanup();
  }

  Future<void> stop() async {
    _logger.info('Stopping monitored process');
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/PID', process.pid.toString()]);
      } else {
        process.kill(ProcessSignal.sigterm);
      }
    } catch (e) {
      _logger.error('Failed to stop process', e, null);
    }
  }

  void _cleanup() {
    _logSink?.writeln('=== Log ended - ${DateTime.now().toIso8601String()} ===');
    _logSink?.close();
    
    _logController?.close();
    _statusController?.close();
  }

  Duration get playTime {
    if (_readyTime == null) return Duration.zero;
    final end = _stopTime ?? DateTime.now();
    return end.difference(_readyTime!);
  }

  void dispose() {
    _cleanup();
  }
}

class ProcessMonitorManager {
  static ProcessMonitorManager? _instance;

  factory ProcessMonitorManager() {
    return _instance ??= ProcessMonitorManager._internal();
  }

  ProcessMonitorManager._internal();

  static ProcessMonitorManager get instance => _instance ??= ProcessMonitorManager._internal();

  final Map<String, ProcessMonitor> _monitors = {};
  final Logger _logger = Logger('ProcessMonitorManager');

  ProcessMonitor createMonitor({
    required String processId,
    required Process process,
    required String gameDirectory,
  }) {
    final monitor = ProcessMonitor(
      processId: processId,
      process: process,
      gameDirectory: gameDirectory,
    );
    _monitors[processId] = monitor;
    _logger.info('Created process monitor for $processId');
    return monitor;
  }

  ProcessMonitor? getMonitor(String processId) {
    return _monitors[processId];
  }

  void removeMonitor(String processId) {
    final monitor = _monitors.remove(processId);
    if (monitor != null) {
      monitor.dispose();
      _logger.info('Removed process monitor for $processId');
    }
  }

  bool hasMonitor(String processId) {
    return _monitors.containsKey(processId);
  }

  int get monitorCount => _monitors.length;

  void disposeAll() {
    for (final monitor in _monitors.values) {
      monitor.dispose();
    }
    _monitors.clear();
    _logger.info('Disposed all process monitors');
  }
}