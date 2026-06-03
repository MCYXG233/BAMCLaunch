import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../event/event.dart' as event_module;
import '../event/event_bus.dart';

/// 日志级别枚举
///
/// 定义了日志系统支持的五种日志级别，按严重程度从低到高排列：
/// - [debug]: 调试信息，用于开发阶段的详细诊断
/// - [info]: 一般信息，记录正常的程序运行状态
/// - [warn]: 警告信息，表示潜在问题但不影响程序运行
/// - [error]: 错误信息，表示程序遇到了错误但可以继续运行
/// - [fatal]: 致命错误，表示程序无法继续运行的严重错误
enum LogLevel {
  /// 调试信息
  ///
  /// 用于开发阶段的详细诊断信息，通常在生产环境中会被过滤掉。
  /// 包含详细的程序执行流程、变量状态等信息。
  debug,

  /// 一般信息
  ///
  /// 用于记录程序正常运行状态的信息，如启动、关闭、重要操作完成等。
  /// 这些信息有助于了解程序的运行情况。
  info,

  /// 警告信息
  ///
  /// 表示程序遇到了潜在问题，但不会影响程序的正常运行。
  /// 例如：使用了已弃用的API、配置项缺失但使用了默认值等。
  warn,

  /// 错误信息
  ///
  /// 表示程序遇到了错误，但程序仍可以继续运行。
  /// 例如：文件操作失败、网络请求失败等可恢复的错误。
  error,

  /// 致命错误
  ///
  /// 表示程序遇到了无法恢复的严重错误，通常需要立即终止程序。
  /// 例如：关键资源初始化失败、数据损坏等。
  fatal,
}

/// 日志记录类
///
/// 封装单条日志记录的所有信息，包括时间戳、日志级别、消息内容、
/// 错误对象、堆栈跟踪和额外数据。该类提供了日志格式化和
/// JSON序列化的功能。
///
/// 示例用法：
/// ```dart
/// final record = LogRecord(
///   timestamp: DateTime.now(),
///   level: LogLevel.info,
///   message: '用户登录成功',
///   data: {'userId': '12345'},
/// );
/// print(record.format());
/// ```
class LogRecord {
  /// 日志记录的时间戳
  ///
  /// 记录日志产生的时间，精确到毫秒。
  final DateTime timestamp;

  /// 日志级别
  ///
  /// 表示该条日志的严重程度，用于日志过滤和分类。
  final LogLevel level;

  /// 日志消息内容
  ///
  /// 描述日志事件的主要文本信息。
  final String message;

  /// 错误对象
  ///
  /// 可选的错误对象，通常在记录异常时使用。
  /// 可以是任意类型的对象，最终会被转换为字符串输出。
  final Object? error;

  /// 堆栈跟踪信息
  ///
  /// 可选的堆栈跟踪，通常在记录异常时使用，
  /// 用于定位问题发生的代码位置。
  final StackTrace? stackTrace;

  /// 额外数据
  ///
  /// 可选的键值对数据，用于记录与日志相关的上下文信息。
  /// 例如：用户ID、请求参数、响应数据等。
  final Map<String, dynamic>? data;

  /// 创建日志记录实例
  ///
  /// [timestamp] 和 [level] 和 [message] 为必填参数，
  /// [error]、[stackTrace] 和 [data] 为可选参数。
  LogRecord({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.data,
  });

  /// 将日志记录转换为JSON格式
  ///
  /// 返回一个包含所有日志信息的Map，可用于JSON序列化。
  /// 时间戳会被转换为ISO 8601格式的字符串。
  ///
  /// 返回的Map包含以下键：
  /// - `timestamp`: ISO 8601格式的时间戳字符串
  /// - `level`: 日志级别名称字符串
  /// - `message`: 日志消息
  /// - `error`: 错误信息的字符串表示（可能为null）
  /// - `stackTrace`: 堆栈跟踪字符串（可能为null）
  /// - `data`: 额外数据Map（可能为null）
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

  /// 格式化日志记录为可读字符串
  ///
  /// 将日志记录格式化为人类可读的字符串格式，包含：
  /// - 时间戳（本地时间，精确到毫秒）
  /// - 日志级别（大写）
  /// - 日志消息
  /// - 错误信息（如果有）
  /// - 堆栈跟踪（如果有）
  /// - 额外数据（如果有）
  ///
  /// 返回格式示例：
  /// ```
  /// [2024-01-15 10:30:45.123][INFO] 用户登录成功
  /// Error: 网络连接失败
  /// StackTrace:
  /// #0 main() in main.dart:10
  /// Data: {"userId":"12345"}
  /// ```
  String format() {
    final buffer = StringBuffer();
    // 格式化时间戳：使用本地时间，截取前23位获取精确到毫秒的时间
    buffer.write('[${timestamp.toLocal().toString().substring(0, 23)}]');
    // 添加日志级别标签（大写）
    buffer.write('[${_levelToString(level).toUpperCase()}]');
    // 添加日志消息
    buffer.write(' $message');

    // 如果有错误信息，添加错误详情
    if (error != null) {
      buffer.write('\nError: $error');
    }

    // 如果有堆栈跟踪，添加堆栈信息
    if (stackTrace != null) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }

    // 如果有额外数据且不为空，添加数据详情
    if (data != null && data!.isNotEmpty) {
      buffer.write('\nData: ${jsonEncode(data)}');
    }

    return buffer.toString();
  }

  /// 将日志级别枚举转换为字符串
  ///
  /// 内部辅助方法，用于格式化输出。
  /// 返回日志级别的大写字符串表示。
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

/// 日志滚动策略枚举
///
/// 定义日志文件的滚动（轮转）方式，用于控制日志文件的大小和数量：
/// - [size]: 按文件大小滚动，当日志文件达到指定大小时创建新文件
/// - [date]: 按日期滚动，每天创建一个新的日志文件
enum LogRotationStrategy {
  /// 按大小滚动
  ///
  /// 当日志文件大小达到 [LogRotationConfig.maxFileSize] 指定的最大值时，
  /// 会将当前日志文件重命名为备份文件，并创建新的日志文件。
  size,

  /// 按日期滚动
  ///
  /// 每天创建一个新的日志文件，适合需要按日期归档日志的场景。
  /// 当检测到日期变化时，会自动滚动日志文件。
  date,
}

/// 日志滚动配置类
///
/// 配置日志文件的滚动（轮转）行为，包括滚动策略、文件大小限制和文件数量限制。
/// 该类使用 const 构造函数，可以在编译时创建常量配置。
///
/// 示例用法：
/// ```dart
/// // 默认配置：按大小滚动，最大10MB，最多5个文件
/// const defaultConfig = LogRotationConfig();
///
/// // 自定义配置：按日期滚动，最多保留10个文件
/// const dateConfig = LogRotationConfig(
///   strategy: LogRotationStrategy.date,
///   maxFileCount: 10,
/// );
/// ```
class LogRotationConfig {
  /// 滚动策略
  ///
  /// 决定何时创建新的日志文件，默认为 [LogRotationStrategy.size]。
  final LogRotationStrategy strategy;

  /// 最大文件大小（字节）
  ///
  /// 仅在 [LogRotationStrategy.size] 策略时有效。
  /// 当日志文件大小达到此值时，会触发滚动。
  /// 默认值为 10MB (10 * 1024 * 1024 字节)。
  final int maxFileSize;

  /// 最大文件数量
  ///
  /// 控制保留的日志备份文件数量。
  /// 当备份数量超过此值时，最旧的备份文件会被删除。
  /// 默认值为 5。
  final int maxFileCount;

  /// 创建日志滚动配置
  ///
  /// 所有参数都有默认值，可以根据需要覆盖。
  /// - [strategy]: 滚动策略，默认按大小滚动
  /// - [maxFileSize]: 最大文件大小，默认10MB
  /// - [maxFileCount]: 最大文件数量，默认5个
  const LogRotationConfig({
    this.strategy = LogRotationStrategy.size,
    this.maxFileSize = 10 * 1024 * 1024,
    this.maxFileCount = 5,
  });
}

/// 日志输出器抽象接口
///
/// 定义日志输出的标准接口，所有日志输出器都必须实现此接口。
/// 通过实现此接口，可以将日志输出到不同的目标，如控制台、文件、网络等。
///
/// 生命周期：
/// 1. 调用 [initialize] 进行初始化
/// 2. 多次调用 [write] 输出日志记录
/// 3. 调用 [dispose] 释放资源
///
/// 示例实现：
/// ```dart
/// class NetworkLogOutput implements LogOutput {
///   @override
///   Future<void> initialize() async {
///     // 建立网络连接
///   }
///
///   @override
///   Future<void> write(LogRecord record) async {
///     // 发送日志到服务器
///   }
///
///   @override
///   Future<void> dispose() async {
///     // 关闭网络连接
///   }
/// }
/// ```
abstract class LogOutput {
  /// 输出日志记录
  ///
  /// 将单条日志记录写入输出目标。此方法可能会被频繁调用，
  /// 实现时应考虑性能和线程安全。
  ///
  /// [record] 要输出的日志记录，包含所有日志信息。
  Future<void> write(LogRecord record);

  /// 初始化输出器
  ///
  /// 在开始输出日志之前调用，用于准备输出所需的资源。
  /// 例如：创建文件、建立网络连接等。
  /// 如果输出器已经初始化，重复调用应该直接返回。
  Future<void> initialize();

  /// 关闭输出器
  ///
  /// 在不再需要输出日志时调用，用于释放资源。
  /// 例如：关闭文件句柄、断开网络连接等。
  /// 调用此方法后，不应再调用 [write] 方法。
  Future<void> dispose();
}

/// 控制台日志输出器
///
/// 将日志输出到标准控制台（stdout）。这是最简单的日志输出器，
/// 适用于开发调试阶段。每条日志都会通过 [print] 函数输出。
///
/// 特点：
/// - 无需初始化配置
/// - 日志直接输出到控制台
/// - 不支持日志滚动
/// - 适合开发和调试使用
class ConsoleLogOutput implements LogOutput {
  /// 初始化状态标志
  ///
  /// 标记输出器是否已完成初始化，防止重复初始化。
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    // 如果已经初始化，直接返回，避免重复初始化
    if (_initialized) return;
    _initialized = true;
  }

  @override
  Future<void> write(LogRecord record) async {
    // 将格式化后的日志记录输出到控制台
    print(record.format());
  }

  @override
  Future<void> dispose() async {
    // 控制台输出器无需释放资源
  }
}

/// 文件日志输出器
///
/// 将日志输出到文件系统，支持日志滚动（轮转）功能。
/// 日志文件存储在应用支持目录的 logs 子目录下。
///
/// 特点：
/// - 支持按大小或按日期滚动日志文件
/// - 支持配置最大文件大小和文件数量
/// - 异步写入，避免阻塞主线程
/// - 写入操作串行化，保证日志顺序
///
/// 文件命名规则：
/// - 当前日志文件：使用 [logFileName] 参数指定的名称
/// - 备份日志文件：在原文件名后添加 .1、.2、.3 等后缀
///
/// 示例用法：
/// ```dart
/// final fileOutput = FileLogOutput(
///   logFileName: 'app.log',
///   rotationConfig: LogRotationConfig(
///     strategy: LogRotationStrategy.size,
///     maxFileSize: 5 * 1024 * 1024, // 5MB
///     maxFileCount: 10,
///   ),
/// );
/// await fileOutput.initialize();
/// ```
class FileLogOutput implements LogOutput {
  /// 平台适配器
  ///
  /// 用于获取应用支持目录等平台相关功能。
  final IPlatformAdapter _platformAdapter;

  /// 日志滚动配置
  ///
  /// 控制日志文件的滚动行为。
  final LogRotationConfig _rotationConfig;

  /// 日志文件名
  ///
  /// 当前日志文件的名称，不包含路径。
  final String _logFileName;

  /// 初始化状态标志
  ///
  /// 标记输出器是否已完成初始化。
  bool _initialized = false;

  /// 当前日志文件对象
  ///
  /// 初始化后指向实际的日志文件。
  File? _logFile;

  /// 当前写入操作的完成器
  ///
  /// 用于串行化写入操作，确保日志按顺序写入文件。
  /// 当有写入操作正在进行时，新的写入操作会等待前一个完成。
  Completer<void>? _currentWriteCompleter;

  /// 创建文件日志输出器
  ///
  /// [logFileName] 日志文件名，默认为 'app.log'
  /// [rotationConfig] 日志滚动配置，默认为按大小滚动，最大10MB，最多5个文件
  FileLogOutput({
    required String logFileName,
    LogRotationConfig rotationConfig = const LogRotationConfig(),
  }) : _logFileName = logFileName,
       _rotationConfig = rotationConfig,
       _platformAdapter = PlatformAdapterFactory.instance;

  @override
  Future<void> initialize() async {
    // 如果已经初始化，直接返回，避免重复初始化
    if (_initialized) return;

    // 获取应用支持目录
    final supportDir = await _platformAdapter.getApplicationSupportDirectory();
    // 创建日志目录路径
    final logsDir = Directory(path.join(supportDir, 'logs'));

    // 如果日志目录不存在，则创建（包括所有父目录）
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    // 创建日志文件对象
    _logFile = File(path.join(logsDir.path, _logFileName));
    _initialized = true;
  }

  @override
  Future<void> write(LogRecord record) async {
    // 如果未初始化或日志文件为空，直接返回
    if (!_initialized || _logFile == null) return;

    // 如果有正在进行的写入操作，等待其完成
    // 这确保了日志写入的顺序性
    if (_currentWriteCompleter != null) {
      await _currentWriteCompleter!.future;
    }

    // 创建新的完成器，标记当前写入操作
    final completer = Completer<void>();
    _currentWriteCompleter = completer;

    try {
      // 检查是否需要滚动日志文件
      await _rotateIfNeeded();
      // 格式化日志记录并添加换行符
      final logLine = '${record.format()}\n';
      // 追加写入日志文件，并立即刷新到磁盘
      await _logFile!.writeAsString(
        logLine,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // 写入失败时，输出到控制台作为备用
      print('Failed to write log: $e');
    } finally {
      // 无论成功或失败，都标记写入操作完成
      completer.complete();
    }
  }

  /// 检查并执行日志滚动
  ///
  /// 根据配置的滚动策略检查是否需要滚动日志文件：
  /// - 按大小滚动：当文件大小超过 [LogRotationConfig.maxFileSize] 时滚动
  /// - 按日期滚动：当文件修改日期不是今天时滚动
  Future<void> _rotateIfNeeded() async {
    if (_logFile == null) return;

    if (_rotationConfig.strategy == LogRotationStrategy.size) {
      // 按大小滚动策略：检查文件大小
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        // 如果文件大小达到限制，执行滚动
        if (stat.size >= _rotationConfig.maxFileSize) {
          await _rotate();
        }
      }
    } else if (_rotationConfig.strategy == LogRotationStrategy.date) {
      // 按日期滚动策略：检查文件修改日期
      if (await _logFile!.exists()) {
        final stat = await _logFile!.stat();
        final now = DateTime.now();
        // 如果文件修改日期不是今天，执行滚动
        if (stat.modified.day != now.day) {
          await _rotate();
        }
      }
    }
  }

  /// 执行日志滚动
  ///
  /// 将当前日志文件重命名为备份文件，并删除超出数量限制的旧备份。
  ///
  /// 滚动过程：
  /// 1. 将最旧的备份文件删除（如果超出数量限制）
  /// 2. 将其他备份文件重命名（编号+1）
  /// 3. 将当前日志文件重命名为 .1 备份文件
  ///
  /// 例如，假设 maxFileCount = 3：
  /// - app.log.3 被删除（超出数量限制）
  /// - app.log.2 -> app.log.3
  /// - app.log.1 -> app.log.2
  /// - app.log -> app.log.1
  Future<void> _rotate() async {
    if (_logFile == null) return;

    // 获取日志文件路径信息
    final logPath = _logFile!.path;
    final logDir = path.dirname(logPath);
    final logName = path.basenameWithoutExtension(logPath);
    final logExt = path.extension(logPath);

    // 从最旧的备份开始重命名，避免文件名冲突
    // 倒序遍历：maxFileCount-1 到 1
    for (int i = _rotationConfig.maxFileCount - 1; i >= 1; i--) {
      // 源备份文件路径
      final src = File(path.join(logDir, '$logName.$i$logExt'));
      // 目标备份文件路径（编号+1）
      final dest = File(path.join(logDir, '$logName.${i + 1}$logExt'));

      if (await src.exists()) {
        // 如果新编号超出最大文件数量，删除文件
        if (i + 1 > _rotationConfig.maxFileCount) {
          await src.delete();
        } else {
          // 否则重命名为新编号
          await src.rename(dest.path);
        }
      }
    }

    // 将当前日志文件重命名为 .1 备份文件
    final backup = File(path.join(logDir, '$logName.1$logExt'));
    if (await _logFile!.exists()) {
      await _logFile!.rename(backup.path);
    }
  }

  @override
  Future<void> dispose() async {
    // 如果有正在进行的写入操作，等待其完成
    // 确保所有日志都已写入文件后再关闭
    if (_currentWriteCompleter != null) {
      await _currentWriteCompleter!.future;
    }
  }
}

/// 日志系统核心类
///
/// 提供统一的日志记录接口，支持多种输出目标和日志级别过滤。
/// 采用单例模式，确保全局只有一个日志系统实例。
///
/// 功能特点：
/// - 支持多种日志级别（debug、info、warn、error、fatal）
/// - 支持同时输出到控制台和文件
/// - 支持日志级别过滤
/// - 支持日志文件滚动
/// - 通过事件总线发布日志事件，供其他模块订阅
///
/// 使用示例：
/// ```dart
/// // 初始化日志系统
/// await Logger.instance.initialize(
///   minLevel: LogLevel.info,
///   enableConsoleOutput: true,
///   enableFileOutput: true,
///   logFileName: 'myapp.log',
/// );
///
/// // 记录日志
/// Logger.instance.info('应用启动');
/// Logger.instance.error('发生错误', error, stackTrace);
///
/// // 关闭日志系统
/// await Logger.instance.dispose();
/// ```
class Logger {
  /// 单例实例
  ///
  /// 存储全局唯一的 Logger 实例。
  static Logger? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例。如果实例不存在则创建新实例。
  /// [name] 参数被忽略，仅用于兼容性。
  factory Logger([String? name]) => _instance ??= Logger._internal();

  /// 私有构造函数
  ///
  /// 内部构造函数，用于创建单例实例。
  Logger._internal();

  /// 获取单例实例
  ///
  /// 静态属性，返回全局唯一的 Logger 实例。
  /// 如果实例不存在则自动创建。
  static Logger get instance => _instance ??= Logger._internal();

  /// 重置单例实例
  ///
  /// 将单例实例设为 null，用于测试或需要重新初始化日志系统的场景。
  /// 调用此方法后，下次访问 [instance] 会创建新的 Logger 实例。
  static void reset() {
    _instance = null;
  }

  /// 日志输出器列表
  ///
  /// 存储所有已注册的日志输出器，日志会同时输出到所有输出器。
  final List<LogOutput> _outputs = [];

  /// 最低日志级别
  ///
  /// 低于此级别的日志会被过滤，不会输出。
  /// 默认为 [LogLevel.debug]，即输出所有级别的日志。
  LogLevel _minLevel = LogLevel.debug;

  /// 初始化状态标志
  ///
  /// 标记日志系统是否已完成初始化。
  bool _initialized = false;

  /// 事件总线实例
  ///
  /// 用于发布日志事件，供其他模块订阅处理。
  final EventBus _eventBus = EventBus.instance;

  /// 初始化日志系统
  ///
  /// 此方法应该在应用启动时调用一次。重复调用会被忽略。
  ///
  /// 参数：
  /// - [minLevel]: 最低日志级别，低于此级别的日志不会输出，默认为 [LogLevel.debug]
  /// - [enableConsoleOutput]: 是否启用控制台输出，默认为 true
  /// - [enableFileOutput]: 是否启用文件输出，默认为 true
  /// - [logFileName]: 日志文件名，默认为 'app.log'
  /// - [rotationConfig]: 日志滚动配置，默认为按大小滚动，最大10MB，最多5个文件
  ///
  /// 示例：
  /// ```dart
  /// await Logger.instance.initialize(
  ///   minLevel: LogLevel.info,
  ///   enableConsoleOutput: true,
  ///   enableFileOutput: true,
  ///   logFileName: 'myapp.log',
  ///   rotationConfig: LogRotationConfig(
  ///     strategy: LogRotationStrategy.date,
  ///     maxFileCount: 7,
  ///   ),
  /// );
  /// ```
  Future<void> initialize({
    LogLevel minLevel = LogLevel.debug,
    bool enableConsoleOutput = true,
    bool enableFileOutput = true,
    String logFileName = 'app.log',
    LogRotationConfig rotationConfig = const LogRotationConfig(),
  }) async {
    // 如果已经初始化，直接返回，避免重复初始化
    if (_initialized) return;

    // 设置最低日志级别
    _minLevel = minLevel;

    // 如果启用控制台输出，创建并初始化控制台输出器
    if (enableConsoleOutput) {
      final consoleOutput = ConsoleLogOutput();
      await consoleOutput.initialize();
      _outputs.add(consoleOutput);
    }

    // 如果启用文件输出，创建并初始化文件输出器
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
  ///
  /// 动态调整日志级别过滤。低于此级别的日志不会输出。
  /// 可用于在运行时调整日志详细程度。
  ///
  /// [level] 新的最低日志级别
  ///
  /// 示例：
  /// ```dart
  /// // 生产环境只记录警告及以上级别的日志
  /// Logger.instance.setMinLevel(LogLevel.warn);
  /// ```
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 记录调试级别日志
  ///
  /// 用于记录开发调试信息，通常在生产环境中被过滤。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace, null);
  }

  /// 记录信息级别日志
  ///
  /// 用于记录程序正常运行状态的信息。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace, null);
  }

  /// 记录警告级别日志
  ///
  /// 用于记录潜在问题或不影响程序运行的异常情况。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warn, message, error, stackTrace, null);
  }

  /// 记录警告级别日志（[warn] 方法的别名）
  ///
  /// 提供此方法是为了兼容不同的命名习惯。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    warn(message, error, stackTrace);
  }

  /// 记录错误级别日志
  ///
  /// 用于记录程序遇到的错误，但程序仍可继续运行。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace, null);
  }

  /// 记录致命错误级别日志
  ///
  /// 用于记录导致程序无法继续运行的严重错误。
  ///
  /// [message] 日志消息
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace, null);
  }

  /// 内部日志记录方法
  ///
  /// 执行实际的日志记录操作，包括：
  /// 1. 检查初始化状态和日志级别过滤
  /// 2. 创建日志记录对象
  /// 3. 将日志写入所有输出器
  /// 4. 发布日志事件到事件总线
  ///
  /// [level] 日志级别
  /// [message] 日志消息
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  /// [data] 额外数据
  void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    // 如果日志系统未初始化，不记录日志
    if (!_initialized) return;

    // 如果日志级别低于最低级别，过滤掉该日志
    if (level.index < _minLevel.index) return;

    // 创建日志记录对象
    final record = LogRecord(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // 将日志写入所有输出器
    for (final output in _outputs) {
      output.write(record);
    }

    // 发布日志事件到事件总线，供其他模块订阅处理
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
  ///
  /// 将内部 [LogLevel] 枚举转换为事件模块的 [event_module.LogLevel] 枚举。
  /// 这是必要的，因为日志系统和事件系统使用了不同的日志级别枚举定义。
  ///
  /// 注意：[LogLevel.fatal] 会被转换为 [event_module.LogLevel.error]，
  /// 因为事件模块没有 fatal 级别。
  ///
  /// [level] 内部日志级别
  /// 返回对应的日志事件级别
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
        // 事件模块没有 fatal 级别，使用 error 代替
        return event_module.LogLevel.error;
    }
  }

  /// 关闭日志系统
  ///
  /// 释放所有日志输出器的资源，清空输出器列表。
  /// 调用此方法后，日志系统将不再记录日志，直到重新初始化。
  ///
  /// 示例：
  /// ```dart
  /// await Logger.instance.dispose();
  /// ```
  Future<void> dispose() async {
    // 关闭所有输出器，释放资源
    for (final output in _outputs) {
      await output.dispose();
    }
    // 清空输出器列表
    _outputs.clear();
    // 重置初始化状态
    _initialized = false;
  }
}