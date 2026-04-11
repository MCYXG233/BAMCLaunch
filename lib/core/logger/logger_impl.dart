import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'i_logger.dart';

class LoggerImpl implements ILogger {
  static final LoggerImpl _instance = LoggerImpl._internal();

  late File _logFile;
  late IOSink _logSink;
  bool _isInitialized = false;
  LogLevel _logLevel = LogLevel.debug;
  final Queue<String> _logQueue = Queue();
  final StreamController<String> _logStreamController =
      StreamController.broadcast();
  late StreamSubscription<String> _logSubscription;
  static const int _maxLogFiles = 10;
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB

  factory LoggerImpl() => _instance;

  LoggerImpl._internal();

  Future<void> initialize(String logFilePath) async {
    if (_isInitialized) return;

    try {
      final logDirectory = Directory(logFilePath).parent;
      if (!logDirectory.existsSync()) {
        await logDirectory.create(recursive: true);
      }

      // 执行日志轮转
      await _rotateLogs(logDirectory.path);

      _logFile = File(logFilePath);
      _logSink = _logFile.openWrite(mode: FileMode.append);
      _isInitialized = true;

      // 启动异步日志写入
      _startAsyncLogProcessing();

      info('Logger initialized', {'logFile': logFilePath});
    } catch (e) {
      print('Failed to initialize logger: $e');
    }
  }

  @override
  void debug(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.debug)) {
      _log('DEBUG', message, context);
    }
  }

  @override
  void info(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.info)) {
      _log('INFO', message, context);
    }
  }

  @override
  void warn(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.warn)) {
      _log('WARN', message, context);
    }
  }

  @override
  void error(String message, [Map<String, dynamic>? context, dynamic error]) {
    if (_shouldLog(LogLevel.error)) {
      _log('ERROR', message, context, error);
    }
  }

  @override
  void setLogLevel(LogLevel level) {
    _logLevel = level;
    info('Log level changed', {'level': level.name});
  }

  @override
  LogLevel getLogLevel() {
    return _logLevel;
  }

  @override
  Future<void> flush() async {
    if (_isInitialized) {
      await _logSink.flush();
    }
  }

  @override
  void close() {
    if (_isInitialized) {
      _logSubscription.cancel();
      _logStreamController.close();
      _logSink.close();
      _isInitialized = false;
    }
  }

  bool _shouldLog(LogLevel level) {
    return level.index >= _logLevel.index;
  }

  void _log(String level, String message, Map<String, dynamic>? context,
      [dynamic error]) {
    final timestamp = DateTime.now().toIso8601String();

    String logLine = '[$timestamp] [$level] [APP] $message';

    if (context != null && context.isNotEmpty) {
      logLine += ' | Context: ${_formatContext(context)}';
    }

    if (error != null) {
      logLine += '\nError: $error';
      if (error is Error && error.stackTrace != null) {
        logLine += '\nStack Trace:\n${error.stackTrace}';
      } else if (error is Exception) {
        logLine += '\nException: ${error.toString()}';
      }
    }

    // 输出到控制台
    print(logLine);

    // 添加到日志队列
    if (_isInitialized) {
      _logStreamController.add(logLine);
    }
  }

  void _startAsyncLogProcessing() {
    _logSubscription = _logStreamController.stream.listen((logLine) async {
      try {
        // 检查文件大小，超过限制则轮转
        if (_logFile.existsSync() && _logFile.lengthSync() > _maxLogFileSize) {
          await _rotateLogs(_logFile.parent.path);
        }

        _logSink.writeln(logLine);
      } catch (e) {
        print('Failed to write to log file: $e');
      }
    });
  }

  Future<void> _rotateLogs(String logDirectory) async {
    final logFiles = Directory(logDirectory)
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .cast<File>()
        .toList();

    if (logFiles.length >= _maxLogFiles) {
      // 按创建时间排序，删除最旧的文件
      logFiles
          .sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      for (int i = 0; i < logFiles.length - _maxLogFiles + 1; i++) {
        try {
          await logFiles[i].delete();
        } catch (e) {
          print(
              'Failed to delete old log file: ${logFiles[i].path}, error: $e');
        }
      }
    }
  }

  String _formatContext(Map<String, dynamic> context) {
    return context.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
}
