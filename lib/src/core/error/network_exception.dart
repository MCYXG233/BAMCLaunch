import 'app_exception.dart';

/// 网络异常类型
enum NetworkErrorType {
  /// 连接超时
  timeout,
  
  /// 连接被拒绝
  connectionRefused,
  
  /// 连接失败
  connectionFailed,
  
  /// DNS 解析失败
  dnsFailed,
  
  /// 服务器错误（5xx）
  serverError,
  
  /// 客户端错误（4xx）
  clientError,
  
  /// 资源未找到（404）
  notFound,
  
  /// 请求被取消
  cancelled,
  
  /// SSL 证书错误
  sslError,
  
  /// 未知错误
  unknown,
}

/// 网络异常
/// 
/// 当网络请求失败时抛出。
final class NetworkException extends AppException {
  /// 请求的 URL
  final Uri? uri;

  /// HTTP 方法
  final String? method;

  /// HTTP 状态码（如果有）
  final int? statusCode;

  /// 错误类型
  final NetworkErrorType errorType;

  const NetworkException({
    required String message,
    this.uri,
    this.method,
    this.statusCode,
    this.errorType = NetworkErrorType.unknown,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userFriendlyMessage {
    switch (errorType) {
      case NetworkErrorType.timeout:
        return '网络连接超时，请检查网络后重试';
      case NetworkErrorType.connectionRefused:
        return '无法连接到服务器，请稍后重试';
      case NetworkErrorType.connectionFailed:
        return '网络连接失败，请检查网络设置';
      case NetworkErrorType.dnsFailed:
        return 'DNS 解析失败，请检查网络配置';
      case NetworkErrorType.serverError:
        return '服务器繁忙，请稍后重试';
      case NetworkErrorType.clientError:
        return '请求格式错误';
      case NetworkErrorType.notFound:
        return '请求的资源不存在';
      case NetworkErrorType.cancelled:
        return '请求已取消';
      case NetworkErrorType.sslError:
        return '安全连接建立失败';
      case NetworkErrorType.unknown:
        return '网络错误，请检查网络连接';
    }
  }

  @override
  String get debugDescription {
    final buffer = StringBuffer('NetworkException: $userFriendlyMessage');
    if (uri != null) buffer.write(', url=$uri');
    if (method != null) buffer.write(', method=$method');
    if (statusCode != null) buffer.write(', statusCode=$statusCode');
    buffer.write(', errorType=$errorType');
    return buffer.toString();
  }

  /// 工厂方法：从 HTTP 状态码创建
  factory NetworkException.fromStatusCode(
    int statusCode, {
    Uri? uri,
    String? method,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    NetworkErrorType errorType;
    if (statusCode >= 500) {
      errorType = NetworkErrorType.serverError;
    } else if (statusCode == 404) {
      errorType = NetworkErrorType.notFound;
    } else if (statusCode >= 400) {
      errorType = NetworkErrorType.clientError;
    } else {
      errorType = NetworkErrorType.unknown;
    }

    return NetworkException(
      message: 'HTTP $statusCode',
      uri: uri,
      method: method,
      statusCode: statusCode,
      errorType: errorType,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
