enum LogLevel {
  debug,
  info,
  warn,
  error,
  none,
}

abstract class ILogger {
  void debug(String message, [Map<String, dynamic>? context]);
  void info(String message, [Map<String, dynamic>? context]);
  void warn(String message, [Map<String, dynamic>? context]);
  void error(String message, [Map<String, dynamic>? context, dynamic error]);
  
  void setLogLevel(LogLevel level);
  LogLevel getLogLevel();
  
  Future<void> flush();
  void close();
}