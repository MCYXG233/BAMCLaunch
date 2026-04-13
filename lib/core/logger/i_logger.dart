enum LogLevel {
  debug,
  info,
  warn,
  error,
  none,
}

abstract class ILogger {
  /// 初始化日志系统
  /// [logFilePath]: 日志文件保存路径
  Future<void> initialize(String logFilePath);
  
  void debug(String message, [Map<String, dynamic>? context]);
  void info(String message, [Map<String, dynamic>? context]);
  void warn(String message, [Map<String, dynamic>? context]);
  void error(String message, [Map<String, dynamic>? context, dynamic error]);
  
  void setLogLevel(LogLevel level);
  LogLevel getLogLevel();
  
  Future<void> flush();
  void close();
}