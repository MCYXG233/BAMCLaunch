import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../event/event.dart' as event_module;
import '../event/event_bus.dart';

/// 日志级别枚举
enum LogLevel {
  /// 调试信息
  debug,

  /// 一般信息
  info,

  /// 警告信息
  warn,

  /// 错误信息
  error,

  /// 致命错误
  fatal,
}

/// 日志记录
class LogRecord {
  /// 时间戳
  final DateTime timestamp;

  /// 日志级别
  final LogLevel level;

  /// 日志消息
  final String message;

  /// 错误信息
  final Object? error;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 额外数据
  final Map<String, dynamic>? data;

  LogRecord({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.data,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'data': data,
    };
  }

  /// 格式化字符串
  String format() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toLocal().toString().substring(0, 23)}]');
    buffer.write('[${_levelToString(level).toUpperCase()}]');
    buffer.write(' $message');

    if (error != null) {
      buffer.write('\nError: $error');
    }

    if (stackTrace != null) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }

    if (data != null && data!.isNotEmpty) {
      buffer.write('\nData: ${jsonEncode(data)}');
    }

    return buffer.toString();
  }

  /// 日志级别转字符串
  static String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }
}

/// 日志滚动策略
enum LogRotationStrategy {
  /// 按大小滚动
  size,

  /// 按日期滚动
  date,
}

/// 日志滚动配置
class LogRotationConfig {
  /// 滚动策略
  final LogRotationStrategy strategy;

  /// 最大文件大小（字节），仅在size策略时有效
  final int maxFileSize;

  /// 最大文件数量
  final int maxFileCount;

  const LogRotationConfig({
    this.strategy = LogRotationStrategy.size,
    this.maxFileSize = 10 * 1024 * 1024,
    this.maxFileCount = 5,
  });
}

/// 日志输出器接口
abstract class LogOutput {
  /// 输出日志记录
  Future<void> write(LogRecord record);

  /// 初始化输出器
  Future<void> initialize();

  /// 关闭输出器
  Future<void> dispose();
}

/// 控制台日志输出器
class ConsoleLogOutput implements LogOutput {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  @override
  Future<void> write(LogRecord record) async {
    print(record.format());
  }

  @override
  Future<void> dispose() async {}
}

/// 文件日志输出器
class FileLogOutput implements LogOutput {
  final IPlatformAdapter _platformAdapter;
  final LogRotationConfig _rotationConfig;
  final String _logFileName;

  bool _initialized = false;
  File? _logFile;
  Completer<void>? _currentWriteCompleter;

  FileLogOutput({
    required String logFileName,
    LogRotationConfig rotationConfig = const LogRotationConfig(),
  }) : _logFileName = logFileName,
       _rotationConfig = rotationConfig,
       _platformAdapter = PlatformAdapterFactory.instance;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final supportDir = await _platformAdapter.getApplicationSupportDirectory();
    final logsDir = Directory(path.join(supportDir, 'logs'));

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    _logFile = File(path.join(logsDir.path, _logFileName));
    _initialized = true;
  }

  @override
  Future<void> write(LogRecord record) async {
    if (!_initialized || _logFile == null) return;

    if (_currentWriteCompleter != null) {
      await _currentWriteCompleter!.future;
    }
    final completer = Completer<void>();
    _currentWriteCompleter = completer;

    try {
      await _rotateIfNeeded();
      final logLine = '${record.format()}\n';
      await _logFile!.writeAsString(
        logLine,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      print('Failed to write log: $e');
    } finally {
      completer.complete();
    }
  }

  /// 检查并执行日志滚动
  Future<void> _rotateIfNeeded() async {
    if (_logFile == null) return;

    if (_rotationConfig.strategy == LogRotationStrategy.size) {
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        if (stat.size >= _rotationConfig.maxFileSize) {
          await _rotate();
        }
      }
    } else if (_rotationConfig.strategy == LogRotationStrategy.date) {
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        final now = DateTime.now();
        if (stat.modified.day != now.day) {
          await _rotate();
        }
      }
    }
  }

  /// 执行日志滚动
  Future<void> _rotate() async {
    if (_logFile == null) return;

    final logPath = _logFile!.path;
    final logDir = path.dirname(logPath);
    final logName = path.basenameWithoutExtension(logPath);
    final logExt = path.extension(logPath);

    for (int i = _rotationConfig.maxFileCount - 1; i >= 1; i--) {
      final src = File(path.join(logDir, '$logName.$i$logExt'));
      final dest = File(path.join(logDir, '$logName.${i + 1}$logExt'));
      if (await src.exists()) {
        if (i + 1 > _rotationConfig.maxFileCount) {
          await src.delete();
        } else {
          await src.rename(dest.path);
        }
      }
    }

    final backup = File(path.join(logDir, '$logName.1$logExt'));
    if (await _logFile!.exists()) {
      await _logFile!.rename(backup.path);
    }
  }

  @override
  Future<void> dispose() async {
    if (_currentWriteCompleter != null) {
      await _currentWriteCompleter!.future;
    }
  }
}

/// 日志系统
class Logger {
  static Logger? _instance;

  factory Logger([String? name]) => _instance ??= Logger._internal();

  Logger._internal();

  static Logger get instance => _instance ??= Logger._internal();

  static void reset() {
    _instance = null;
  }

  final List<LogOutput> _outputs = [];
  LogLevel _minLevel = LogLevel.debug;
  bool _initialized = false;
  final EventBus _eventBus = EventBus.instance;

  /// 初始化日志系统
  ///
  /// [minLevel] 最低日志级别
  /// [enableConsoleOutput] 是否启用控制台输出
  /// [enableFileOutput] 是否启用文件输出
  /// [logFileName] 日志文件名
  /// [rotationConfig] 日志滚动配置
  Future<void> initialize({
    LogLevel minLevel = LogLevel.debug,
    bool enableConsoleOutput = true,
    bool enableFileOutput = true,
    String logFileName = 'app.log',
    LogRotationConfig rotationConfig = const LogRotationConfig(),
  }) async {
    if (_initialized) return;

    _minLevel = minLevel;

    if (enableConsoleOutput) {
      final consoleOutput = ConsoleLogOutput();
      await consoleOutput.initialize();
      _outputs.add(consoleOutput);
    }

    if (enableFileOutput) {
      final fileOutput = FileLogOutput(
        logFileName: logFileName,
        rotationConfig: rotationConfig,
      );
      await fileOutput.initialize();
      _outputs.add(fileOutput);
    }

    _initialized = true;
  }

  /// 设置最低日志级别
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 记录调试日志
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace, null);
  }

  /// 记录信息日志
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace, null);
  }

  /// 记录警告日志
  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warn, message, error, stackTrace, null);
  }

  /// 记录警告日志 (warning 是 warn 的别名)
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    warn(message, error, stackTrace);
  }

  /// 记录错误日志
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace, null);
  }

  /// 记录致命错误日志
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace, null);
  }

  /// 记录日志
  void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    if (!_initialized) return;
    if (level.index < _minLevel.index) return;

    final record = LogRecord(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    for (final output in _outputs) {
      output.write(record);
    }

    _eventBus.publish(
      event_module.LogEvent(
        level: _convertLogLevel(level),
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// 转换日志级别
  event_module.LogLevel _convertLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return event_module.LogLevel.debug;
      case LogLevel.info:
        return event_module.LogLevel.info;
      case LogLevel.warn:
        return event_module.LogLevel.warn;
      case LogLevel.error:
        return event_module.LogLevel.error;
      case LogLevel.fatal:
        return event_module.LogLevel.error;
    }
  }

  /// 关闭日志系统
  Future<void> dispose() async {
    for (final output in _outputs) {
      await output.dispose();
    }
    _outputs.clear();
    _initialized = false;
  }
}
