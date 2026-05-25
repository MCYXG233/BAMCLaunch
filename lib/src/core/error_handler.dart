import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logger.dart';
import '../event/event.dart';
import '../event/event_bus.dart';

/// 异常事件
class ExceptionEvent extends Event {
  /// 错误信息
  final Object error;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 是否为致命错误
  final bool isFatal;

  ExceptionEvent({required this.error, this.stackTrace, this.isFatal = false});
}

/// 全局异常处理器
class ErrorHandler {
  static ErrorHandler? _instance;

  factory ErrorHandler() => _instance ??= ErrorHandler._internal();

  ErrorHandler._internal();

  static ErrorHandler get instance => _instance ??= ErrorHandler._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger.instance;
  final EventBus _eventBus = EventBus.instance;
  bool _initialized = false;
  FlutterExceptionHandler? _originalOnError;
  ErrorWidgetBuilder? _originalErrorWidgetBuilder;

  /// 初始化全局异常处理器
  ///
  /// [appRunner] 应用运行函数
  Future<void> initialize(FutureOr<void> Function() appRunner) async {
    if (_initialized) return;

    _originalOnError = FlutterError.onError;
    _originalErrorWidgetBuilder = ErrorWidget.builder;

    FlutterError.onError = _handleFlutterError;
    ErrorWidget.builder = _buildErrorWidget;

    PlatformDispatcher.instance.onError = _handlePlatformError;

    _initialized = true;

    await runZonedGuarded<Future<void>>(() async {
      await appRunner();
    }, _handleZoneError);
  }

  /// 处理Flutter框架异常
  void _handleFlutterError(FlutterErrorDetails details) {
    _logger.error('Flutter framework error', details.exception, details.stack);

    _eventBus.publish(
      ExceptionEvent(
        error: details.exception,
        stackTrace: details.stack,
        isFatal: false,
      ),
    );

    if (_originalOnError != null) {
      _originalOnError!(details);
    } else {
      FlutterError.presentError(details);
    }
  }

  /// 处理平台异常
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    _logger.error('Platform error', error, stackTrace);

    _eventBus.publish(
      ExceptionEvent(error: error, stackTrace: stackTrace, isFatal: false),
    );

    return true;
  }

  /// 处理Zone异常
  void _handleZoneError(Object error, StackTrace stackTrace) {
    _logger.fatal('Uncaught error in zone', error, stackTrace);

    _eventBus.publish(
      ExceptionEvent(error: error, stackTrace: stackTrace, isFatal: true),
    );
  }

  /// 构建错误Widget
  Widget _buildErrorWidget(FlutterErrorDetails details) {
    if (kDebugMode) {
      return _originalErrorWidgetBuilder?.call(details) ??
          ErrorWidget.builder(details);
    }

    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              '页面出现错误',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// 手动报告异常
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    bool isFatal = false,
  }) {
    if (isFatal) {
      _logger.fatal('Manually reported error', error, stackTrace);
    } else {
      _logger.error('Manually reported error', error, stackTrace);
    }

    _eventBus.publish(
      ExceptionEvent(error: error, stackTrace: stackTrace, isFatal: isFatal),
    );
  }

  /// 关闭异常处理器
  void dispose() {
    if (_initialized) {
      FlutterError.onError = _originalOnError;
      if (_originalErrorWidgetBuilder != null) {
        ErrorWidget.builder = _originalErrorWidgetBuilder!;
      }
      PlatformDispatcher.instance.onError = null;
      _initialized = false;
    }
  }
}
