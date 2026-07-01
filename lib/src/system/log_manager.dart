import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String logger;
  final String message;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'logger': logger,
      'message': message,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      logger: json['logger'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  @override
  String toString() {
    final levelStr = level.name.toUpperCase().padRight(7);
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    
    var result = '[$timeStr] [$levelStr] [$logger] $message';
    
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      result += '\n$stackTrace';
    }
    
    return result;
  }
}

/// 日志管理配置
class LogManagerConfig {
  /// 最大日志文件大小（字节）
  final int maxFileSize;

  /// 保留的日志文件数量
  final int maxBackupFiles;

  /// 日志保留天数
  final int retentionDays;

  /// 是否启用文件日志
  final bool enableFileLogging;

  /// 是否启用控制台日志
  final bool enableConsoleLogging;

  /// 日志级别
  final LogLevel minLevel;

  LogManagerConfig({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxBackupFiles = 7,
    this.retentionDays = 30,
    this.enableFileLogging = true,
    this.enableConsoleLogging = true,
    this.minLevel = LogLevel.debug,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxFileSize': maxFileSize,
      'maxBackupFiles': maxBackupFiles,
      'retentionDays': retentionDays,
      'enableFileLogging': enableFileLogging,
      'enableConsoleLogging': enableConsoleLogging,
      'minLevel': minLevel.name,
    };
  }

  factory LogManagerConfig.fromJson(Map<String, dynamic> json) {
    return LogManagerConfig(
      maxFileSize: json['maxFileSize'] as int? ?? 10 * 1024 * 1024,
      maxBackupFiles: json['maxBackupFiles'] as int? ?? 7,
      retentionDays: json['retentionDays'] as int? ?? 30,
      enableFileLogging: json['enableFileLogging'] as bool? ?? true,
      enableConsoleLogging: json['enableConsoleLogging'] as bool? ?? true,
      minLevel: LogLevel.values.firstWhere(
        (e) => e.name == json['minLevel'],
        orElse: () => LogLevel.debug,
      ),
    );
  }

  LogManagerConfig copyWith({
    int? maxFileSize,
    int? maxBackupFiles,
    int? retentionDays,
    bool? enableFileLogging,
    bool? enableConsoleLogging,
    LogLevel? minLevel,
  }) {
    return LogManagerConfig(
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxBackupFiles: maxBackupFiles ?? this.maxBackupFiles,
      retentionDays: retentionDays ?? this.retentionDays,
      enableFileLogging: enableFileLogging ?? this.enableFileLogging,
      enableConsoleLogging: enableConsoleLogging ?? this.enableConsoleLogging,
      minLevel: minLevel ?? this.minLevel,
    );
  }
}

/// 日志管理器
class LogManager {
  static LogManager? _instance;

  final Logger _logger = Logger('LogManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 日志目录
  Directory? _logDir;

  /// 当前日志文件
  File? _currentLogFile;

  /// 日志配置
  LogManagerConfig _config;

  /// 日志缓存
  final List<LogEntry> _logCache = [];

  /// 最大缓存条目数
  static const int _maxCacheSize = 1000;

  /// 是否初始化
  bool _initialized = false;

  LogManager._internal() : _config = LogManagerConfig();

  /// 获取单例实例
  static LogManager get instance {
    return ServiceLocator.instance.tryGet<LogManager>() ??
        (_instance ??= LogManager._internal());
  }

  /// 工厂构造函数
  factory LogManager() => instance;

  /// 初始化日志管理器
  Future<void> initialize({
    String? customPath,
    LogManagerConfig? config,
  }) async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _logDir = Directory(path.join(supportDir, 'logs'));

      if (!await _logDir!.exists()) {
        await _logDir!.create(recursive: true);
      }

      if (config != null) {
        _config = config;
      }

      await _rotateLogIfNeeded();
      await _cleanOldLogs();

      _logger.info('Log manager initialized at ${_logDir!.path}');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize log manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 记录日志
  Future<void> log(
    LogLevel level,
    String logger,
    String message, {
    String? stackTrace,
  }) async {
    if (level.index < _config.minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      logger: logger,
      message: message,
      stackTrace: stackTrace,
    );

    // 添加到缓存
    _logCache.add(entry);
    if (_logCache.length > _maxCacheSize) {
      _logCache.removeAt(0);
    }

    // 写入控制台
    if (_config.enableConsoleLogging) {
      _printToConsole(entry);
    }

    // 写入文件
    if (_config.enableFileLogging) {
      await _writeToFile(entry);
    }
  }

  /// 打印到控制台
  void _printToConsole(LogEntry entry) {
    // 简单的控制台输出
    _logger.debug(entry.toString());
  }

  /// 写入日志文件
  Future<void> _writeToFile(LogEntry entry) async {
    if (_currentLogFile == null) return;

    try {
      await _currentLogFile!.writeAsString(
        '${entry.toString()}\n',
        mode: FileMode.append,
      );

      // 检查是否需要轮转
      await _rotateLogIfNeeded();
    } catch (e) {
      _logger.warn('Failed to write log: $e');
    }
  }

  /// 检查并执行日志轮转
  Future<void> _rotateLogIfNeeded() async {
    if (_logDir == null) return;

    final today = DateTime.now();
    final logFileName = 'bamc_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}.log';
    _currentLogFile = File(path.join(_logDir!.path, logFileName));

    if (!await _currentLogFile!.exists()) {
      await _currentLogFile!.create(recursive: true);
    }

    // 检查文件大小
    try {
      final stat = await _currentLogFile!.stat();
      if (stat.size > _config.maxFileSize) {
        await _rotateLog();
      }
    } catch (e) {
      _logger.warn('Failed to check log file size: $e');
    }
  }

  /// 执行日志轮转
  Future<void> _rotateLog() async {
    if (_logDir == null || _currentLogFile == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedName = '${_currentLogFile!.path}.$timestamp';
      await _currentLogFile!.rename(rotatedName);

      // 删除旧的轮转日志
      await _cleanOldRotatedLogs();

      // 创建新文件
      _currentLogFile = File(_currentLogFile!.path);
      await _currentLogFile!.create(recursive: true);
    } catch (e) {
      _logger.warn('Failed to rotate log: $e');
    }
  }

  /// 清理旧的轮转日志
  Future<void> _cleanOldRotatedLogs() async {
    if (_logDir == null) return;

    try {
      await for (final entity in _logDir!.list()) {
        if (entity is File && entity.path.contains('.log.')) {
          // 删除超过备份数量的轮转日志
          final age = DateTime.now().difference(await entity.stat().then((s) => s.modified));
          if (age.inDays > _config.maxBackupFiles) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      _logger.warn('Failed to clean old rotated logs: $e');
    }
  }

  /// 清理过期日志
  Future<void> _cleanOldLogs() async {
    if (_logDir == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: _config.retentionDays));

    try {
      await for (final entity in _logDir!.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            _logger.info('Deleted old log: ${entity.path}');
          }
        }
      }
    } catch (e) {
      _logger.warn('Failed to clean old logs: $e');
    }
  }

  /// 获取日志文件列表
  Future<List<File>> getLogFiles() async {
    if (_logDir == null) return [];

    final files = <File>[];
    try {
      await for (final entity in _logDir!.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          files.add(entity);
        }
      }
    } catch (e) {
      _logger.warn('Failed to list log files: $e');
    }

    // 按修改时间排序
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  /// 读取日志内容
  Future<List<LogEntry>> readLogs({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? minLevel,
  }) async {
    final entries = <LogEntry>[];

    try {
      // 读取所有日志文件
      final files = await getLogFiles();
      for (final file in files) {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final entry = _parseLogLine(line);
            if (entry == null) continue;

            // 应用过滤器
            if (minLevel != null && entry.level.index < minLevel.index) continue;
            if (startDate != null && entry.timestamp.isBefore(startDate)) continue;
            if (endDate != null && entry.timestamp.isAfter(endDate)) continue;

            entries.add(entry);
          } catch (e) {
            // 忽略解析失败的行
          }
        }
      }

      // 按时间排序
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 应用限制
      if (limit != null && entries.length > limit) {
        return entries.sublist(0, limit);
      }
    } catch (e) {
      _logger.warn('Failed to read logs: $e');
    }

    return entries;
  }

  /// 解析日志行
  LogEntry? _parseLogLine(String line) {
    // 格式: [HH:mm:ss] [LEVEL] [logger] message
    final regex = RegExp(
      r'\[(\d{2}:\d{2}:\d{2})\]\s+\[(\w+)\]\s+\[([^\]]+)\]\s+(.+)',
    );

    final match = regex.firstMatch(line);
    if (match == null) return null;

    final timeStr = match.group(1)!;
    final levelStr = match.group(2)!;
    final logger = match.group(3)!;
    final message = match.group(4)!;

    final now = DateTime.now();
    final timeParts = timeStr.split(':');
    final timestamp = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );

    final level = LogLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == levelStr.toLowerCase(),
      orElse: () => LogLevel.info,
    );

    return LogEntry(
      timestamp: timestamp,
      level: level,
      logger: logger,
      message: message,
    );
  }

  /// 获取缓存的日志
  List<LogEntry> getCachedLogs({int? limit}) {
    if (limit != null && _logCache.length > limit) {
      return _logCache.sublist(_logCache.length - limit);
    }
    return List.from(_logCache);
  }

  /// 清除所有日志
  Future<void> clearAllLogs() async {
    if (_logDir == null) return;

    try {
      await for (final entity in _logDir!.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      _logCache.clear();
      await _currentLogFile?.create(recursive: true);
      _logger.info('All logs cleared');
    } catch (e) {
      _logger.warn('Failed to clear logs: $e');
    }
  }

  /// 获取日志总大小
  Future<int> getTotalLogSize() async {
    if (_logDir == null) return 0;

    int totalSize = 0;
    try {
      await for (final entity in _logDir!.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      _logger.warn('Failed to calculate log size: $e');
    }

    return totalSize;
  }

  /// 导出日志
  Future<String?> exportLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? outputPath,
  }) async {
    try {
      final entries = await readLogs(
        startDate: startDate,
        endDate: endDate,
      );

      if (entries.isEmpty) {
        return null;
      }

      final buffer = StringBuffer();
      buffer.writeln('=== BAMC启动器日志导出 ===');
      buffer.writeln('导出时间: ${DateTime.now()}');
      buffer.writeln('条目数量: ${entries.length}');
      buffer.writeln();
      buffer.writeln('--- 日志内容 ---');

      for (final entry in entries) {
        buffer.writeln(entry.toString());
      }

      final output = outputPath ?? path.join(_logDir!.path, 'export_${DateTime.now().millisecondsSinceEpoch}.log');
      final file = File(output);
      await file.writeAsString(buffer.toString());

      return output;
    } catch (e) {
      _logger.warn('Failed to export logs: $e');
      return null;
    }
  }

  /// 更新配置
  Future<void> updateConfig(LogManagerConfig config) async {
    _config = config;
    await _cleanOldLogs();
  }

  /// 获取当前配置
  LogManagerConfig get config => _config;
}
