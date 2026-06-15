/// 应用异常基类
/// 
/// 所有自定义异常都应继承此类。
/// 提供用户友好的错误消息和技术详情分离。
/// 
/// 使用方式：
/// ```dart
/// try {
///   await downloadFile(url);
/// } on NetworkException catch (e) {
///   // 显示用户友好的消息
///   showSnackBar(e.userFriendlyMessage);
///   // 技术详情用于日志
///   logger.error(e.debugDescription);
/// }
/// ```
sealed class AppException implements Exception {
  /// 用户友好的错误消息
  /// 
  /// 用于 UI 显示，应简洁、有指导性。
  String get userFriendlyMessage;

  /// 技术详情
  /// 
  /// 用于日志记录和调试，应包含完整的错误信息。
  String get debugDescription;

  /// 原始异常（如果有）
  final Object? cause;

  /// 堆栈跟踪（如果有）
  final StackTrace? stackTrace;

  const AppException({
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => debugDescription;
}

/// 失败严重性等级
/// 
/// 用于决定如何处理异常。
enum FailureSeverity {
  /// 低：后台任务失败，静默记录日志
  low,
  
  /// 中：用户操作失败，显示 SnackBar
  medium,
  
  /// 高：关键操作失败，弹窗
  high,
  
  /// 致命：不可恢复，应用无法继续
  critical,
  
  /// 认证：令牌过期，需要重新登录
  auth,
}

/// 扩展方法：获取严重性等级
extension AppExceptionSeverity on AppException {
  /// 获取此异常的严重性等级
  /// 
  /// 子类应重写此属性以返回正确的等级。
  FailureSeverity get severity {
    if (this is AuthException) return FailureSeverity.auth;
    if (this is GameLaunchException) return FailureSeverity.critical;
    if (this is FileSystemException) return FailureSeverity.high;
    if (this is NetworkException) return FailureSeverity.medium;
    return FailureSeverity.medium;
  }
}
