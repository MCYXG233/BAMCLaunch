import 'dart:async';
import 'error_codes.dart';
import 'logger.dart';

/// 重试策略配置
class RetryConfig {
  /// 最大重试次数
  final int maxRetries;

  /// 初始延迟（毫秒）
  final int initialDelayMs;

  /// 最大延迟（毫秒）
  final int maxDelayMs;

  /// 延迟倍数（指数退避）
  final double backoffMultiplier;

  /// 重试的条件判断
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 10000,
    this.backoffMultiplier = 2.0,
    this.shouldRetry,
  });

  /// 默认配置（用于网络请求）
  static const RetryConfig network = RetryConfig(
    maxRetries: 3,
    initialDelayMs: 1000,
    maxDelayMs: 8000,
    backoffMultiplier: 2.0,
  );

  /// 快速重试配置
  static const RetryConfig fast = RetryConfig(
    maxRetries: 2,
    initialDelayMs: 500,
    maxDelayMs: 2000,
    backoffMultiplier: 1.5,
  );

  /// 计算第n次重试的延迟时间
  Duration getDelay(int attempt) {
    final delayMs = initialDelayMs * (backoffMultiplier * (attempt - 1));
    return Duration(milliseconds: delayMs.clamp(initialDelayMs, maxDelayMs).toInt());
  }
}

/// 重试助手类
class RetryHelper {
  static final Logger _logger = Logger('RetryHelper');

  /// 执行带重试的操作
  ///
  /// [operation] 要执行的操作
  /// [config] 重试配置
  /// [onRetry] 重试时的回调
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    Object? lastError;

    while (attempt <= config.maxRetries) {
      attempt++;
      try {
        _logger.debug('Executing operation, attempt $attempt/${config.maxRetries + 1}');
        final result = await operation();
        if (attempt > 1) {
          _logger.info('Operation succeeded on attempt $attempt');
        }
        return result;
      } catch (e, stackTrace) {
        lastError = e;
        _logger.warning('Operation failed on attempt $attempt: $e', e, stackTrace);

        // 判断是否需要重试
        final shouldRetry = config.shouldRetry?.call(e) ?? _defaultShouldRetry(e);

        if (attempt <= config.maxRetries && shouldRetry) {
          final delay = config.getDelay(attempt);
          _logger.info('Retrying in ${delay.inMilliseconds}ms...');

          onRetry?.call(attempt, e);

          await Future.delayed(delay);
        } else {
          _logger.error('Max retries exceeded or error not retryable');
          rethrow;
        }
      }
    }

    // 理论上不会到这里，但为了类型安全
    throw lastError ?? AppException.fromCode(ErrorCodes.unknown);
  }

  /// 默认的重试判断逻辑
  static bool _defaultShouldRetry(Object error) {
    if (error is AppException) {
      return error.retryable;
    }

    // 判断常见的可重试错误
    const retryableErrorTypes = [
      'TimeoutException',
      'SocketException',
      'HttpException',
    ];

    final errorType = error.runtimeType.toString();
    return retryableErrorTypes.any((type) => errorType.contains(type));
  }

  /// 执行带重试的操作并返回详细结果
  static Future<RetryResult<T>> executeWithResult<T>({
    required Future<T> Function() operation,
    RetryConfig config = RetryConfig.network,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    try {
      final result = await execute<T>(
        operation: operation,
        config: config,
        onRetry: onRetry,
      );
      return RetryResult.success(result, 1);
    } catch (e) {
      // 计算尝试次数（需要重新跟踪）
      // 简化版本，这里只返回失败
      return RetryResult.failure(e, 0);
    }
  }
}
