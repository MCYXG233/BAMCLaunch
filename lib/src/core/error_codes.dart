/// 错误码定义
/// 用于统一管理应用中的所有错误类型
class ErrorCodes {
  // ========== 网络相关错误 (1000-1999) ==========
  /// 网络连接失败
  static const int networkConnectionFailed = 1000;

  /// 请求超时
  static const int networkTimeout = 1001;

  /// HTTP错误
  static const int networkHttpError = 1002;

  /// 下载失败
  static const int networkDownloadFailed = 1003;

  /// 请求被取消
  static const int networkCancelled = 1004;

  /// 资源未找到 (404)
  static const int networkNotFound = 1005;

  /// 服务器错误 (5xx)
  static const int networkServerError = 1006;

  /// 请求格式错误 (4xx)
  static const int networkClientError = 1007;

  /// DNS解析失败
  static const int networkDnsFailed = 1008;

  /// SSL证书错误
  static const int networkSslError = 1009;

  /// JSON解析失败
  static const int networkJsonParseError = 1010;

  /// 无法获取文件大小
  static const int networkFileSizeError = 1011;

  /// 不支持的下载方式
  static const int networkUnsupportedDownload = 1012;

  // ========== 认证相关错误 (2000-2999) ==========
  /// Microsoft认证失败
  static const int authMicrosoftFailed = 2000;

  /// Xbox认证失败
  static const int authXboxFailed = 2001;

  /// Minecraft认证失败
  static const int authMinecraftFailed = 2002;

  /// Token无效
  static const int authInvalidToken = 2003;

  /// Token过期
  static const int authTokenExpired = 2004;

  /// 认证失败（通用）
  static const int authFailed = 2005;

  /// 授权码交换失败
  static const int authCodeExchangeFailed = 2006;

  /// Token刷新失败
  static const int authRefreshFailed = 2007;

  /// Xbox Live认证失败
  static const int authXboxLiveFailed = 2008;

  /// XSTS Token获取失败
  static const int authXstsFailed = 2009;

  /// 账户未拥有Minecraft
  static const int authOwnershipCheckFailed = 2010;

  /// 设备码过期
  static const int authDeviceCodeExpired = 2011;

  /// 用户拒绝授权
  static const int authUserDenied = 2012;

  /// Authlib认证失败
  static const int authAuthlibFailed = 2013;

  /// 缺少认证参数
  static const int authMissingParameter = 2014;

  // ========== 文件相关错误 (3000-3999) ==========
  /// 文件不存在
  static const int fileNotFound = 3000;

  /// 文件读取失败
  static const int fileReadFailed = 3001;

  /// 文件写入失败
  static const int fileWriteFailed = 3002;

  /// 磁盘空间不足
  static const int fileInsufficientSpace = 3003;

  /// 归档解析失败
  static const int fileArchiveError = 3004;

  /// 文件哈希校验失败
  static const int fileHashMismatch = 3005;

  // ========== 游戏相关错误 (4000-4999) ==========
  /// 游戏版本不存在
  static const int gameVersionNotFound = 4000;

  /// 游戏启动失败
  static const int gameLaunchFailed = 4001;

  /// Java未找到
  static const int gameJavaNotFound = 4002;

  /// Java版本不兼容
  static const int gameJavaVersionIncompatible = 4003;

  /// Java路径无效
  static const int gameJavaInvalidPath = 4004;

  // ========== 实例相关错误 (5000-5999) ==========
  /// 实例不存在
  static const int instanceNotFound = 5000;

  /// 实例创建失败
  static const int instanceCreateFailed = 5001;

  /// 实例删除失败
  static const int instanceDeleteFailed = 5002;

  /// 未选择游戏目录
  static const int instanceDirectoryNotSelected = 5003;

  // ========== 整合包相关错误 (6000-6999) ==========
  /// 整合包解析失败
  static const int modpackParseFailed = 6000;

  /// 整合包格式不支持
  static const int modpackUnsupportedFormat = 6001;

  // ========== 加载器相关错误 (7000-7999) ==========
  /// 加载器安装失败
  static const int loaderInstallFailed = 7000;

  /// 加载器版本不兼容
  static const int loaderVersionIncompatible = 7001;

  /// 加载器信息获取失败
  static const int loaderFetchFailed = 7002;

  // ========== 备份相关错误 (8000-8999) ==========
  /// 备份创建失败
  static const int backupCreateFailed = 8000;

  /// 备份源不存在
  static const int backupSourceNotFound = 8001;

  /// 实例导入失败
  static const int instanceImportFailed = 8002;

  // ========== 未知错误 (9000-9999) ==========
  /// 未知错误
  static const int unknown = 9000;
}

/// 错误信息映射
class ErrorMessages {
  static const Map<int, String> _messages = {
    ErrorCodes.networkConnectionFailed: '网络连接失败，请检查网络连接',
    ErrorCodes.networkTimeout: '请求超时，请稍后重试',
    ErrorCodes.networkHttpError: 'HTTP请求失败',
    ErrorCodes.networkDownloadFailed: '下载失败，请稍后重试',
    ErrorCodes.networkCancelled: '请求已取消',
    ErrorCodes.networkNotFound: '请求的资源不存在',
    ErrorCodes.networkServerError: '服务器繁忙，请稍后重试',
    ErrorCodes.networkClientError: '请求格式错误',
    ErrorCodes.networkDnsFailed: 'DNS解析失败，请检查网络配置',
    ErrorCodes.networkSslError: '安全连接建立失败',
    ErrorCodes.networkJsonParseError: '服务器响应解析失败',
    ErrorCodes.networkFileSizeError: '无法获取文件大小',
    ErrorCodes.networkUnsupportedDownload: '不支持的下载方式',
    ErrorCodes.authMicrosoftFailed: 'Microsoft认证失败',
    ErrorCodes.authXboxFailed: 'Xbox认证失败',
    ErrorCodes.authMinecraftFailed: 'Minecraft认证失败',
    ErrorCodes.authInvalidToken: '认证Token无效',
    ErrorCodes.authTokenExpired: '认证Token已过期，请重新登录',
    ErrorCodes.authFailed: '认证失败',
    ErrorCodes.authCodeExchangeFailed: '授权码交换失败',
    ErrorCodes.authRefreshFailed: 'Token刷新失败',
    ErrorCodes.authXboxLiveFailed: 'Xbox Live认证失败',
    ErrorCodes.authXstsFailed: 'XSTS Token获取失败',
    ErrorCodes.authOwnershipCheckFailed: '账户未拥有Minecraft',
    ErrorCodes.authDeviceCodeExpired: '设备码已过期',
    ErrorCodes.authUserDenied: '用户拒绝授权',
    ErrorCodes.authAuthlibFailed: 'Authlib认证失败',
    ErrorCodes.authMissingParameter: '缺少认证参数',
    ErrorCodes.fileNotFound: '文件不存在',
    ErrorCodes.fileReadFailed: '文件读取失败',
    ErrorCodes.fileWriteFailed: '文件写入失败',
    ErrorCodes.fileInsufficientSpace: '磁盘空间不足',
    ErrorCodes.fileArchiveError: '归档文件解析失败',
    ErrorCodes.fileHashMismatch: '文件哈希校验失败',
    ErrorCodes.gameVersionNotFound: '游戏版本不存在',
    ErrorCodes.gameLaunchFailed: '游戏启动失败',
    ErrorCodes.gameJavaNotFound: '未找到Java，请安装Java',
    ErrorCodes.gameJavaVersionIncompatible: 'Java版本不兼容',
    ErrorCodes.gameJavaInvalidPath: 'Java路径无效',
    ErrorCodes.instanceNotFound: '实例不存在',
    ErrorCodes.instanceCreateFailed: '实例创建失败',
    ErrorCodes.instanceDeleteFailed: '实例删除失败',
    ErrorCodes.instanceDirectoryNotSelected: '未选择游戏目录',
    ErrorCodes.modpackParseFailed: '整合包解析失败',
    ErrorCodes.modpackUnsupportedFormat: '不支持的整合包格式',
    ErrorCodes.loaderInstallFailed: '加载器安装失败',
    ErrorCodes.loaderVersionIncompatible: '加载器版本不兼容',
    ErrorCodes.loaderFetchFailed: '加载器信息获取失败',
    ErrorCodes.backupCreateFailed: '备份创建失败',
    ErrorCodes.backupSourceNotFound: '备份源不存在',
    ErrorCodes.instanceImportFailed: '实例导入失败',
    ErrorCodes.unknown: '发生未知错误',
  };

  /// 获取错误信息
  static String getMessage(int errorCode, [String? detail]) {
    final message = _messages[errorCode] ?? _messages[ErrorCodes.unknown]!;
    return detail != null ? '$message: $detail' : message;
  }

  /// 获取错误的解决方案提示
  static String? getSolution(int errorCode) {
    switch (errorCode) {
      case ErrorCodes.networkConnectionFailed:
      case ErrorCodes.networkTimeout:
        return '请检查网络连接，或稍后重试';
      case ErrorCodes.authTokenExpired:
      case ErrorCodes.authRefreshFailed:
        return '请重新登录';
      case ErrorCodes.gameJavaNotFound:
        return '请安装Java 8 或 Java 17';
      case ErrorCodes.fileInsufficientSpace:
        return '请清理磁盘空间后重试';
      default:
        return null;
    }
  }
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

/// 统一应用异常类
///
/// 所有业务异常均使用此类，通过 [errorCode] 区分错误类型。
/// 同时支持 [FailureSeverity] 等级和用户友好的错误消息。
class AppException implements Exception {
  /// 错误码
  final int errorCode;

  /// 用户友好的错误消息（用于 UI 显示）
  final String message;

  /// 技术详情（用于日志记录和调试）
  final String? detail;

  /// 原始异常
  final Object? originalError;

  /// 原始异常的别名（兼容旧抽象类接口）
  Object? get cause => originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 是否可重试
  final bool retryable;

  /// 异常的严重性等级
  final FailureSeverity severity;

  AppException({
    required this.errorCode,
    required this.message,
    this.detail,
    this.originalError,
    this.stackTrace,
    this.retryable = false,
    FailureSeverity? severity,
  }) : severity = severity ?? _defaultSeverity(errorCode);

  /// 用户友好的错误消息（兼容旧抽象类接口）
  String get userFriendlyMessage => message;

  /// 技术详情（兼容旧抽象类接口）
  String get debugDescription {
    final buffer = StringBuffer('AppException [$errorCode]: $message');
    if (detail != null) buffer.write(', detail=$detail');
    if (originalError != null) buffer.write(', cause=$originalError');
    return buffer.toString();
  }

  /// 从错误码创建异常
  factory AppException.fromCode(
    int errorCode, {
    String? detail,
    Object? originalError,
    StackTrace? stackTrace,
    bool retryable = false,
  }) {
    return AppException(
      errorCode: errorCode,
      message: ErrorMessages.getMessage(errorCode, detail),
      detail: detail,
      originalError: originalError,
      stackTrace: stackTrace,
      retryable: retryable,
    );
  }

  /// 根据错误码推断默认严重性
  static FailureSeverity _defaultSeverity(int errorCode) {
    if (errorCode >= 2000 && errorCode < 3000) return FailureSeverity.auth;
    if (errorCode >= 3000 && errorCode < 4000) return FailureSeverity.high;
    if (errorCode >= 4000 && errorCode < 5000) return FailureSeverity.critical;
    return FailureSeverity.medium;
  }

  @override
  String toString() {
    return 'AppException [$errorCode]: $message';
  }
}

/// 网络异常
///
/// 提供 HTTP 状态码、URL 等网络上下文信息。
final class NetworkException extends AppException {
  /// 请求的 URL
  final Uri? uri;

  /// HTTP 方法
  final String? method;

  /// HTTP 状态码（如果有）
  final int? statusCode;

  NetworkException({
    required super.message,
    super.errorCode = ErrorCodes.networkHttpError,
    this.uri,
    this.method,
    this.statusCode,
    super.originalError,
    super.stackTrace,
    super.retryable = true,
  });

  /// 工厂方法：从 HTTP 状态码创建
  factory NetworkException.fromStatusCode(
    int statusCode, {
    Uri? uri,
    String? method,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    int errorCode;
    if (statusCode >= 500) {
      errorCode = ErrorCodes.networkServerError;
    } else if (statusCode == 404) {
      errorCode = ErrorCodes.networkNotFound;
    } else if (statusCode >= 400) {
      errorCode = ErrorCodes.networkClientError;
    } else {
      errorCode = ErrorCodes.networkHttpError;
    }

    return NetworkException(
      message: 'HTTP $statusCode',
      errorCode: errorCode,
      uri: uri,
      method: method,
      statusCode: statusCode,
      originalError: cause,
      stackTrace: stackTrace,
    );
  }

  @override
  String get debugDescription {
    final buffer = StringBuffer('NetworkException: $message');
    if (uri != null) buffer.write(', url=$uri');
    if (method != null) buffer.write(', method=$method');
    if (statusCode != null) buffer.write(', statusCode=$statusCode');
    return buffer.toString();
  }
}

/// 可重试的操作结果
class RetryResult<T> {
  final T? value;
  final Object? error;
  final int attempts;
  final bool success;

  RetryResult.success(this.value, this.attempts)
      : success = true,
        error = null;

  RetryResult.failure(this.error, this.attempts)
      : success = false,
        value = null;
}
