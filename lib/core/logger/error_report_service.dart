import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'logger.dart';

class ErrorReportService {
  static final ErrorReportService _instance = ErrorReportService._internal();

  bool _isInitialized = false;
  bool _isReportingEnabled = true;
  String? _reportEndpoint;
  String? _apiKey;

  factory ErrorReportService() => _instance;

  ErrorReportService._internal();

  void initialize({
    bool enableReporting = true,
    String? reportEndpoint,
    String? apiKey,
  }) {
    _isReportingEnabled = enableReporting;
    _reportEndpoint = reportEndpoint;
    _apiKey = apiKey;
    _isInitialized = true;

    logger.info('ErrorReportService initialized', {
      'reportingEnabled': enableReporting,
      'hasEndpoint': reportEndpoint != null,
    });
  }

  Future<bool> sendErrorReport(CrashReport report) async {
    if (!_isInitialized || !_isReportingEnabled) {
      logger.warn('Error reporting is disabled', {'reportId': report.reportId});
      return false;
    }

    if (_reportEndpoint == null) {
      logger
          .warn('No report endpoint configured', {'reportId': report.reportId});
      return false;
    }

    try {
      final url = Uri.parse(_reportEndpoint!);
      final httpClient = HttpClient();

      final request = await httpClient.postUrl(url);
      request.headers.add('Content-Type', 'application/json');

      if (_apiKey != null) {
        request.headers.add('Authorization', 'Bearer $_apiKey');
      }

      final reportJson = json.encode(report.toJson());
      request.write(reportJson);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.info('Error report sent successfully', {
          'reportId': report.reportId,
          'statusCode': response.statusCode,
        });
        return true;
      } else {
        logger.error('Failed to send error report', {
          'reportId': report.reportId,
          'statusCode': response.statusCode,
          'response': responseBody,
        });
        return false;
      }
    } catch (e) {
      logger.error(
          'Exception while sending error report',
          {
            'reportId': report.reportId,
            'error': e.toString(),
          },
          e);
      return false;
    }
  }

  Future<bool> sendErrorReports(List<CrashReport> reports) async {
    int successCount = 0;

    for (final report in reports) {
      final success = await sendErrorReport(report);
      if (success) {
        successCount++;
      }

      // 添加随机延迟避免请求过快
      await Future.delayed(
          Duration(milliseconds: Random().nextInt(1000) + 500));
    }

    logger.info('Batch error report completed', {
      'total': reports.length,
      'success': successCount,
      'failed': reports.length - successCount,
    });

    return successCount == reports.length;
  }

  Future<void> sendReportFromException(
    Object error,
    StackTrace stackTrace, {
    ErrorType? errorType,
    Map<String, dynamic>? context,
    bool isAnonymous = true,
  }) async {
    try {
      final crashReport = CrashReport(
        reportId: _generateReportId(),
        timestamp: DateTime.now(),
        appVersion: '1.0.0', // 需要从配置中获取
        osVersion: Platform.operatingSystemVersion,
        deviceInfo:
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        errorType: errorType ?? _determineErrorType(error),
        errorMessage: error.toString(),
        stackTrace: stackTrace.toString(),
        context: context,
        isAnonymous: isAnonymous,
      );

      await sendErrorReport(crashReport);
    } catch (e) {
      logger.error('Failed to create and send error report', null, e);
    }
  }

  ErrorType _determineErrorType(Object error) {
    if (error is NetworkException) {
      return ErrorType.network;
    } else if (error is FileException) {
      return ErrorType.file;
    } else if (error is AuthenticationException) {
      return ErrorType.authentication;
    } else if (error is VersionException) {
      return ErrorType.version;
    } else if (error is DownloadException) {
      return ErrorType.download;
    } else if (error is GameLaunchException) {
      return ErrorType.gameLaunch;
    } else if (error is AppException) {
      return error.type;
    } else {
      return ErrorType.unknown;
    }
  }

  String _generateReportId() {
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[^\w]'), '');
    final random = Random().nextInt(1000000).toString().padLeft(6, '0');
    return 'ERR_${timestamp}_$random';
  }

  void enableReporting() {
    _isReportingEnabled = true;
    logger.info('Error reporting enabled');
  }

  void disableReporting() {
    _isReportingEnabled = false;
    logger.info('Error reporting disabled');
  }

  bool isReportingEnabled() {
    return _isReportingEnabled;
  }

  void setReportEndpoint(String endpoint) {
    _reportEndpoint = endpoint;
    logger.info('Error report endpoint updated', {'endpoint': endpoint});
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    logger.info('Error report API key updated');
  }
}
