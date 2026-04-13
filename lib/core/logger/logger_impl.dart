import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'i_logger.dart';

/// 日志实现类
/// 提供日志记录、文件管理、日志轮转等功能
class LoggerImpl implements ILogger {
  /// 单例实例
  static final LoggerImpl _instance = LoggerImpl._internal();

  /// 日志文件
  late File _logFile;
  /// 日志文件写入流
  late IOSink _logSink;
  /// 初始化状态
  bool _isInitialized = false;
  /// 当前日志级别
  LogLevel _logLevel = LogLevel.debug;
  /// 日志队列
  final Queue<String> _logQueue = Queue();
  /// 日志流控制器，用于异步处理日志
  final StreamController<String> _logStreamController =
      StreamController.broadcast();
  /// 日志流订阅
  late StreamSubscription<String> _logSubscription;
  /// 最大日志文件数量
  static const int _maxLogFiles = 10;
  /// 最大日志文件大小（10MB）
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB

  /// 工厂构造函数，返回单例实例
  factory LoggerImpl() => _instance;

  /// 私有构造函数
  LoggerImpl._internal();

  /// 初始化日志系统
  /// [logFilePath]: 日志文件路径
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

  /// 记录调试级别日志
  /// [message]: 日志消息
  /// [context]: 日志上下文信息
  @override
  void debug(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.debug)) {
      _log('DEBUG', message, context);
    }
  }

  /// 记录信息级别日志
  /// [message]: 日志消息
  /// [context]: 日志上下文信息
  @override
  void info(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.info)) {
      _log('INFO', message, context);
    }
  }

  /// 记录警告级别日志
  /// [message]: 日志消息
  /// [context]: 日志上下文信息
  @override
  void warn(String message, [Map<String, dynamic>? context]) {
    if (_shouldLog(LogLevel.warn)) {
      _log('WARN', message, context);
    }
  }

  /// 记录错误级别日志
  /// [message]: 日志消息
  /// [context]: 日志上下文信息
  /// [error]: 错误对象
  @override
  void error(String message, [Map<String, dynamic>? context, dynamic error]) {
    if (_shouldLog(LogLevel.error)) {
      _log('ERROR', message, context, error);
    }
  }

  /// 设置日志级别
  /// [level]: 日志级别
  @override
  void setLogLevel(LogLevel level) {
    _logLevel = level;
    info('Log level changed', {'level': level.name});
  }

  /// 获取当前日志级别
  @override
  LogLevel getLogLevel() {
    return _logLevel;
  }

  /// 刷新日志缓冲区
  @override
  Future<void> flush() async {
    if (_isInitialized) {
      await _logSink.flush();
    }
  }

  /// 关闭日志系统
  @override
  void close() {
    if (_isInitialized) {
      _logSubscription.cancel();
      _logStreamController.close();
      _logSink.close();
      _isInitialized = false;
    }
  }

  /// 检查是否应该记录指定级别的日志
  /// [level]: 日志级别
  /// 返回是否应该记录
  bool _shouldLog(LogLevel level) {
    return level.index >= _logLevel.index;
  }

  /// 内部日志记录方法
  /// [level]: 日志级别
  /// [message]: 日志消息
  /// [context]: 日志上下文信息
  /// [error]: 错误对象
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

  /// 启动异步日志处理
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

  /// 执行日志文件轮转
  /// [logDirectory]: 日志目录路径
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

  /// 格式化上下文信息
  /// [context]: 上下文信息
  /// 返回格式化后的上下文字符串
  String _formatContext(Map<String, dynamic> context) {
    return context.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
}
