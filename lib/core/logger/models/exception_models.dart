enum ErrorType {
  network,
  file,
  authentication,
  version,
  download,
  gameLaunch,
  content,
  modpack,
  server,
  configuration,
  ui,
  unknown,
}

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

class AppException implements Exception {
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AppException({
    required this.message,
    required this.type,
    this.severity = ErrorSeverity.medium,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}

class NetworkException extends AppException {
  final int? statusCode;
  final String? url;

  NetworkException({
    required super.message,
    this.statusCode,
    this.url,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.network,
          severity: statusCode != null && statusCode >= 500
              ? ErrorSeverity.high
              : ErrorSeverity.medium,
          context: {
            'statusCode': statusCode,
            'url': url,
          },
        );
}

class FileException extends AppException {
  final String? filePath;
  final String? operation;

  FileException({
    required super.message,
    this.filePath,
    this.operation,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.file,
          severity: ErrorSeverity.medium,
          context: {
            'filePath': filePath,
            'operation': operation,
          },
        );
}

class AuthenticationException extends AppException {
  final String? accountType;
  final String? provider;

  AuthenticationException({
    required super.message,
    this.accountType,
    this.provider,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.authentication,
          severity: ErrorSeverity.high,
          context: {
            'accountType': accountType,
            'provider': provider,
          },
        );
}

class VersionException extends AppException {
  final String? versionId;

  VersionException({
    required super.message,
    this.versionId,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.version,
          severity: ErrorSeverity.medium,
          context: {
            'versionId': versionId,
          },
        );
}

class DownloadException extends AppException {
  final String? url;
  final String? fileName;

  DownloadException({
    required super.message,
    this.url,
    this.fileName,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.download,
          severity: ErrorSeverity.medium,
          context: {
            'url': url,
            'fileName': fileName,
          },
        );
}

class GameLaunchException extends AppException {
  final String? versionId;
  final String? javaPath;

  GameLaunchException({
    required super.message,
    this.versionId,
    this.javaPath,
    super.originalError,
    super.stackTrace,
  }) : super(
          type: ErrorType.gameLaunch,
          severity: ErrorSeverity.high,
          context: {
            'versionId': versionId,
            'javaPath': javaPath,
          },
        );
}

class CrashReport {
  final String reportId;
  final DateTime timestamp;
  final String appVersion;
  final String osVersion;
  final String deviceInfo;
  final ErrorType errorType;
  final String errorMessage;
  final String stackTrace;
  final Map<String, dynamic>? context;
  final bool isAnonymous;

  CrashReport({
    required this.reportId,
    required this.timestamp,
    required this.appVersion,
    required this.osVersion,
    required this.deviceInfo,
    required this.errorType,
    required this.errorMessage,
    required this.stackTrace,
    this.context,
    this.isAnonymous = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'timestamp': timestamp.toIso8601String(),
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceInfo': deviceInfo,
      'errorType': errorType.name,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'context': context,
      'isAnonymous': isAnonymous,
    };
  }
}
