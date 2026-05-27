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

  // ========== 文件相关错误 (3000-3999) ==========
  /// 文件不存在
  static const int fileNotFound = 3000;

  /// 文件读取失败
  static const int fileReadFailed = 3001;

  /// 文件写入失败
  static const int fileWriteFailed = 3002;

  /// 磁盘空间不足
  static const int fileInsufficientSpace = 3003;

  // ========== 游戏相关错误 (4000-4999) ==========
  /// 游戏版本不存在
  static const int gameVersionNotFound = 4000;

  /// 游戏启动失败
  static const int gameLaunchFailed = 4001;

  /// Java未找到
  static const int gameJavaNotFound = 4002;

  /// Java版本不兼容
  static const int gameJavaVersionIncompatible = 4003;

  // ========== 实例相关错误 (5000-5999) ==========
  /// 实例不存在
  static const int instanceNotFound = 5000;

  /// 实例创建失败
  static const int instanceCreateFailed = 5001;

  /// 实例删除失败
  static const int instanceDeleteFailed = 5002;

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
    ErrorCodes.authMicrosoftFailed: 'Microsoft认证失败',
    ErrorCodes.authXboxFailed: 'Xbox认证失败',
    ErrorCodes.authMinecraftFailed: 'Minecraft认证失败',
    ErrorCodes.authInvalidToken: '认证Token无效',
    ErrorCodes.authTokenExpired: '认证Token已过期，请重新登录',
    ErrorCodes.fileNotFound: '文件不存在',
    ErrorCodes.fileReadFailed: '文件读取失败',
    ErrorCodes.fileWriteFailed: '文件写入失败',
    ErrorCodes.fileInsufficientSpace: '磁盘空间不足',
    ErrorCodes.gameVersionNotFound: '游戏版本不存在',
    ErrorCodes.gameLaunchFailed: '游戏启动失败',
    ErrorCodes.gameJavaNotFound: '未找到Java，请安装Java',
    ErrorCodes.gameJavaVersionIncompatible: 'Java版本不兼容',
    ErrorCodes.instanceNotFound: '实例不存在',
    ErrorCodes.instanceCreateFailed: '实例创建失败',
    ErrorCodes.instanceDeleteFailed: '实例删除失败',
    ErrorCodes.modpackParseFailed: '整合包解析失败',
    ErrorCodes.modpackUnsupportedFormat: '不支持的整合包格式',
    ErrorCodes.loaderInstallFailed: '加载器安装失败',
    ErrorCodes.loaderVersionIncompatible: '加载器版本不兼容',
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
        return '请重新登录';
      case ErrorCodes.gameJavaNotFound:
        return '请安装Java 8 或 Java 17';
      default:
        return null;
    }
  }
}

/// 应用异常基类
class AppException implements Exception {
  /// 错误码
  final int errorCode;

  /// 错误信息
  final String message;

  /// 详细信息
  final String? detail;

  /// 原始异常
  final Object? originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 是否可重试
  final bool retryable;

  AppException({
    required this.errorCode,
    required this.message,
    this.detail,
    this.originalError,
    this.stackTrace,
    this.retryable = false,
  });

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

  @override
  String toString() {
    return 'AppException [$errorCode]: $message';
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
