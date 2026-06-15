import 'app_exception.dart';

/// 认证错误类型
enum AuthErrorType {
  /// 令牌已过期
  tokenExpired,
  
  /// 刷新令牌已过期
  refreshTokenExpired,
  
  /// 无效的令牌
  invalidToken,
  
  /// 用户名或密码错误
  invalidCredentials,
  
  /// 用户取消了认证流程
  userCancelled,
  
  /// 账户被禁用
  accountDisabled,
  
  /// 需要二次验证
  requiresMfa,
  
  /// 网络错误
  networkError,
  
  /// 未知错误
  unknown,
}

/// 认证异常
/// 
/// 当认证过程失败时抛出。
final class AuthException extends AppException {
  /// 错误类型
  final AuthErrorType errorType;

  /// 账户 ID（如果有）
  final String? accountId;

  /// 账户类型（微软账户、离线账户等）
  final String? accountType;

  const AuthException({
    required String message,
    required this.errorType,
    this.accountId,
    this.accountType,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userFriendlyMessage {
    switch (errorType) {
      case AuthErrorType.tokenExpired:
        return '登录已过期，请重新登录';
      case AuthErrorType.refreshTokenExpired:
        return '登录已过期，请重新登录';
      case AuthErrorType.invalidToken:
        return '认证信息无效，请重新登录';
      case AuthErrorType.invalidCredentials:
        return '用户名或密码错误';
      case AuthErrorType.userCancelled:
        return '登录已取消';
      case AuthErrorType.accountDisabled:
        return '账户已被禁用';
      case AuthErrorType.requiresMfa:
        return '需要额外的验证步骤';
      case AuthErrorType.networkError:
        return '网络错误，请检查网络后重试';
      case AuthErrorType.unknown:
        return '认证失败，请稍后重试';
    }
  }

  @override
  String get debugDescription {
    final buffer = StringBuffer('AuthException: $userFriendlyMessage');
    buffer.write(', errorType=$errorType');
    if (accountId != null) buffer.write(', accountId=$accountId');
    if (accountType != null) buffer.write(', accountType=$accountType');
    return buffer.toString();
  }

  @override
  FailureSeverity get severity => FailureSeverity.auth;
}
