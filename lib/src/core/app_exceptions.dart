/// BAMCLaunch 统一异常层次结构
///
/// 参考 HMCL 的异常体系设计，为每种失败场景提供专用异常类。
/// 每个异常都包含用户可读的 i18n 消息 key。
library;

/// 基础应用异常
abstract class BAMCException implements Exception {
  final String message;
  final String? i18nKey;
  final Object? originalError;
  final StackTrace? stackTrace;
  final bool retryable;

  const BAMCException({
    required this.message,
    this.i18nKey,
    this.originalError,
    this.stackTrace,
    this.retryable = false,
  });

  @override
  String toString() => message;
}

/// 认证相关异常
abstract class AuthException extends BAMCException {
  const AuthException({
    required super.message,
    super.i18nKey,
    super.originalError,
    super.stackTrace,
    super.retryable,
  });
}

class TokenExpiredException extends AuthException {
  const TokenExpiredException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: 'Token 已过期，请重新登录',
          i18nKey: 'error.auth.token_expired',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class CredentialInvalidException extends AuthException {
  const CredentialInvalidException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '凭证无效，请重新登录',
          i18nKey: 'error.auth.credential_invalid',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class CharacterDeletedException extends AuthException {
  const CharacterDeletedException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '角色已被删除',
          i18nKey: 'error.auth.character_deleted',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class ServerUnreachableException extends AuthException {
  const ServerUnreachableException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '认证服务器不可达',
          i18nKey: 'error.auth.server_unreachable',
          originalError: originalError,
          stackTrace: stackTrace,
          retryable: true,
        );
}

class AuthServerResponseMalformedException extends AuthException {
  const AuthServerResponseMalformedException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '认证服务器返回了无法解析的响应',
          i18nKey: 'error.auth.response_malformed',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// 下载相关异常
abstract class DownloadException extends BAMCException {
  const DownloadException({
    required super.message,
    super.i18nKey,
    super.originalError,
    super.stackTrace,
    super.retryable = true,
  });
}

class HashMismatchException extends DownloadException {
  final String expectedHash;
  final String actualHash;

  const HashMismatchException({
    required this.expectedHash,
    required this.actualHash,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(
          message: '文件校验失败: 期望 $expectedHash, 实际 $actualHash',
          i18nKey: 'error.download.hash_mismatch',
          originalError: originalError,
          stackTrace: stackTrace,
          retryable: true,
        );
}

class DownloadSourceUnavailableException extends DownloadException {
  const DownloadSourceUnavailableException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '所有下载源均不可用',
          i18nKey: 'error.download.source_unavailable',
          originalError: originalError,
          stackTrace: stackTrace,
          retryable: true,
        );
}

/// 游戏启动相关异常
abstract class LaunchException extends BAMCException {
  const LaunchException({
    required super.message,
    super.i18nKey,
    super.originalError,
    super.stackTrace,
  });
}

class JavaNotFoundException extends LaunchException {
  const JavaNotFoundException({Object? originalError, StackTrace? stackTrace})
      : super(
          message: '未找到可用的 Java 运行时',
          i18nKey: 'error.launch.java_not_found',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class GameFileCorruptedException extends LaunchException {
  const GameFileCorruptedException({required String filePath, Object? originalError, StackTrace? stackTrace})
      : super(
          message: '游戏文件损坏: $filePath',
          i18nKey: 'error.launch.file_corrupted',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class CrashException extends LaunchException {
  final int exitCode;
  final String? diagnosticReport;

  const CrashException({
    required this.exitCode,
    this.diagnosticReport,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(
          message: '游戏崩溃 (exit code: $exitCode)',
          i18nKey: 'error.launch.crash',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}
