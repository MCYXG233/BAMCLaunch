import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'logger.dart';

class ExceptionHandler {
  static final ExceptionHandler _instance = ExceptionHandler._internal();

  bool _isInitialized = false;

  factory ExceptionHandler() => _instance;

  ExceptionHandler._internal();

  void initialize() {
    if (_isInitialized) return;

    // 设置Flutter框架异常处理
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      } else {
        _handleFlutterError(details);
      }
    };

    // 设置Isolate错误处理
    Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
      final error = pair[0];
      final stackTrace = pair[1];
      _handleIsolateError(error, stackTrace);
    }).sendPort);

    _isInitialized = true;
    logger.info('ExceptionHandler initialized');
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    logger.error(
        'Flutter framework error',
        {
          'exception': details.exceptionAsString(),
          'library': details.library,
          'context': details.context?.toString(),
        },
        details.exception);

    // 可以在这里添加错误报告逻辑
    if (details.stack != null) {
      _reportError(details.exception, details.stack!);
    }
  }

  void _handleIsolateError(dynamic error, StackTrace stackTrace) {
    logger.error(
        'Isolate error',
        {
          'error': error.toString(),
        },
        error);

    _reportError(error, stackTrace);
  }

  void _reportError(dynamic error, StackTrace stackTrace) {
    // 这里可以实现错误报告逻辑
    logger.warn('Error reported to exception handler', {
      'errorType': error.runtimeType.toString(),
      'stackTrace': stackTrace.toString(),
    });
  }

  static void handleAsyncError(Object error, StackTrace stackTrace) {
    logger.error(
        'Unhandled async error',
        {
          'errorType': error.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
        error);
  }

  static void handleZoneError(Object error, StackTrace stackTrace) {
    logger.error(
        'Unhandled zone error',
        {
          'errorType': error.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
        error);
  }
}
