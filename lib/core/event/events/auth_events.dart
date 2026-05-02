import '../app_event.dart';

/// 认证状态枚举
enum AuthState {
  loggedOut,
  loggingIn,
  loggedIn,
  expired,
  failed,
}

/// 认证状态变更事件
class AuthStateChangedEvent extends AppEvent {
  final String accountId;
  final AuthState oldState;
  final AuthState newState;

  AuthStateChangedEvent({
    required this.accountId,
    required this.oldState,
    required this.newState,
  });
}

/// 登录成功事件
class LoginSuccessEvent extends AppEvent {
  final String accountId;
  final String username;

  LoginSuccessEvent({
    required this.accountId,
    required this.username,
  });
}

/// 登录失败事件
class LoginFailedEvent extends AppEvent {
  final String accountId;
  final String error;

  LoginFailedEvent({
    required this.accountId,
    required this.error,
  });
}

/// 登出事件
class LogoutEvent extends AppEvent {
  final String accountId;

  LogoutEvent({required this.accountId});
}

/// Token 刷新事件
class TokenRefreshedEvent extends AppEvent {
  final String accountId;

  TokenRefreshedEvent({required this.accountId});
}
