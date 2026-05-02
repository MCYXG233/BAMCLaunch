import 'dart:async';
import 'models/exception_models.dart';
import 'logger.dart';

/// 错误恢复管理器
/// 参考 HMCL 的错误处理机制，提供自动错误恢复功能
class ErrorRecoveryManager {
  /// 错误恢复策略映射
  final Map<ErrorType, ErrorRecoveryStrategy> _strategies = {};

  /// 错误历史记录
  final List<ErrorHistoryEntry> _errorHistory = [];

  /// 最大历史记录数
  final int maxHistoryCount;

  /// 重试计数器
  final Map<String, int> _retryCounters = {};

  /// 最大重试次数
  final int maxRetryCount;

  /// 构造函数
  ErrorRecoveryManager({
    this.maxHistoryCount = 1000,
    this.maxRetryCount = 3,
  }) {
    _initializeDefaultStrategies();
  }

  /// 初始化默认恢复策略
  void _initializeDefaultStrategies() {
    // 网络错误恢复策略
    _strategies[ErrorType.network] = ErrorRecoveryStrategy(
      type: ErrorType.network,
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
      recoveryAction: (error) async {
        logger.info('尝试网络错误恢复: ${error.message}');
        // 等待一段时间后重试
        await Future.delayed(const Duration(seconds: 2));
        return true;
      },
    );

    // 下载错误恢复策略
    _strategies[ErrorType.download] = ErrorRecoveryStrategy(
      type: ErrorType.download,
      maxRetries: 5,
      retryDelay: const Duration(seconds: 3),
      recoveryAction: (error) async {
        logger.info('尝试下载错误恢复: ${error.message}');
        // 可以切换下载源或等待网络恢复
        await Future.delayed(const Duration(seconds: 3));
        return true;
      },
    );

    // 文件错误恢复策略
    _strategies[ErrorType.file] = ErrorRecoveryStrategy(
      type: ErrorType.file,
      maxRetries: 2,
      retryDelay: const Duration(seconds: 1),
      recoveryAction: (error) async {
        logger.info('尝试文件错误恢复: ${error.message}');
        // 可以尝试重新创建目录或文件
        await Future.delayed(const Duration(seconds: 1));
        return true;
      },
    );

    // 版本错误恢复策略
    _strategies[ErrorType.version] = ErrorRecoveryStrategy(
      type: ErrorType.version,
      maxRetries: 2,
      retryDelay: const Duration(seconds: 5),
      recoveryAction: (error) async {
        logger.info('尝试版本错误恢复: ${error.message}');
        // 可以尝试重新下载版本文件
        await Future.delayed(const Duration(seconds: 5));
        return true;
      },
    );

    // 游戏启动错误恢复策略
    _strategies[ErrorType.gameLaunch] = ErrorRecoveryStrategy(
      type: ErrorType.gameLaunch,
      maxRetries: 1,
      retryDelay: const Duration(seconds: 10),
      recoveryAction: (error) async {
        logger.info('尝试游戏启动错误恢复: ${error.message}');
        // 可以尝试重新检测Java或清理临时文件
        await Future.delayed(const Duration(seconds: 10));
        return true;
      },
    );
  }

  /// 注册恢复策略
  /// [strategy]: 恢复策略
  void registerStrategy(ErrorRecoveryStrategy strategy) {
    _strategies[strategy.type] = strategy;
    logger.info('注册错误恢复策略: ${strategy.type}');
  }

  /// 处理错误
  /// [error]: 错误
  /// [context]: 上下文信息
  /// 返回是否恢复成功
  Future<bool> handleError(AppException error, {Map<String, dynamic>? context}) async {
    // 记录错误历史
    _addToHistory(ErrorHistoryEntry(
      error: error,
      timestamp: DateTime.now(),
      context: context,
    ));

    // 获取恢复策略
    final strategy = _strategies[error.type];
    if (strategy == null) {
      logger.warn('没有找到错误恢复策略: ${error.type}');
      return false;
    }

    // 检查重试次数
    final errorKey = '${error.type}_${error.message}';
    final retryCount = _retryCounters[errorKey] ?? 0;

    if (retryCount >= strategy.maxRetries) {
      logger.error('错误重试次数超过限制: $errorKey, 重试次数: $retryCount');
      _retryCounters.remove(errorKey);
      return false;
    }

    // 增加重试计数
    _retryCounters[errorKey] = retryCount + 1;

    // 执行恢复策略
    try {
      logger.info('执行错误恢复策略: ${error.type}, 重试次数: ${retryCount + 1}');

      // 等待重试延迟
      await Future.delayed(strategy.retryDelay);

      // 执行恢复动作
      final success = await strategy.recoveryAction(error);

      if (success) {
        logger.info('错误恢复成功: $errorKey');
        _retryCounters.remove(errorKey);
        return true;
      } else {
        logger.warn('错误恢复失败: $errorKey');
        return false;
      }
    } catch (e) {
      logger.error('错误恢复过程中发生异常: $e');
      return false;
    }
  }

  /// 重试操作
  /// [operation]: 操作
  /// [errorType]: 错误类型
  /// [context]: 上下文信息
  /// 返回操作结果
  Future<T> retryOperation<T>(
    Future<T> Function() operation,
    ErrorType errorType, {
    Map<String, dynamic>? context,
  }) async {
    final strategy = _strategies[errorType];
    final maxRetries = strategy?.maxRetries ?? maxRetryCount;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }

        final error = AppException(
          message: e.toString(),
          type: errorType,
          originalError: e,
        );

        logger.warn('操作失败，准备重试: ${attempt + 1}/$maxRetries');

        final recovered = await handleError(error, context: context);
        if (!recovered) {
          rethrow;
        }
      }
    }

    throw AppException(
      message: '操作失败，已达到最大重试次数',
      type: errorType,
    );
  }

  /// 添加到错误历史
  /// [entry]: 历史记录条目
  void _addToHistory(ErrorHistoryEntry entry) {
    _errorHistory.insert(0, entry);

    // 限制历史记录数量
    if (_errorHistory.length > maxHistoryCount) {
      _errorHistory.removeLast();
    }
  }

  /// 获取错误历史
  /// [count]: 记录数量
  /// 返回错误历史列表
  List<ErrorHistoryEntry> getErrorHistory({int count = 100}) {
    return _errorHistory.take(count).toList();
  }

  /// 获取指定类型的错误历史
  /// [errorType]: 错误类型
  /// 返回该类型的错误历史列表
  List<ErrorHistoryEntry> getErrorHistoryByType(ErrorType errorType) {
    return _errorHistory
        .where((entry) => entry.error.type == errorType)
        .toList();
  }

  /// 获取错误统计
  /// 返回错误统计信息
  Map<ErrorType, int> getErrorStatistics() {
    final stats = <ErrorType, int>{};
    for (final entry in _errorHistory) {
      stats[entry.error.type] = (stats[entry.error.type] ?? 0) + 1;
    }
    return stats;
  }

  /// 清理错误历史
  void clearHistory() {
    _errorHistory.clear();
    _retryCounters.clear();
    logger.info('错误历史已清理');
  }

  /// 获取重试次数
  /// [errorKey]: 错误键
  /// 返回重试次数
  int getRetryCount(String errorKey) {
    return _retryCounters[errorKey] ?? 0;
  }

  /// 重置重试计数
  /// [errorKey]: 错误键
  void resetRetryCount(String errorKey) {
    _retryCounters.remove(errorKey);
  }
}

/// 错误恢复策略
class ErrorRecoveryStrategy {
  final ErrorType type;
  final int maxRetries;
  final Duration retryDelay;
  final Future<bool> Function(AppException error) recoveryAction;

  ErrorRecoveryStrategy({
    required this.type,
    required this.maxRetries,
    required this.retryDelay,
    required this.recoveryAction,
  });
}

/// 错误历史记录条目
class ErrorHistoryEntry {
  final AppException error;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ErrorHistoryEntry({
    required this.error,
    required this.timestamp,
    this.context,
  });
}
