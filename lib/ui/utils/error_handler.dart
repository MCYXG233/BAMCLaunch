import 'package:flutter/material.dart';
import '../../core/logger/logger.dart';
import '../components/dialogs/error_dialog.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context,
    Object error,
    StackTrace stackTrace, {
    String title = '操作失败',
    String message = '发生了一个错误，请稍后重试',
    VoidCallback? onRetry,
  }) {
    // 记录错误日志
    logger.error(message, {'stackTrace': stackTrace}, error);
    
    // 显示错误对话框
    ErrorDialog.show(
      context,
      title,
      message,
      details: error.toString(),
      onRetry: onRetry,
    );
  }

  static void handleNetworkError(
    BuildContext context,
    Object error,
    VoidCallback? onRetry,
  ) {
    handleError(
      context,
      error,
      StackTrace.current,
      title: '网络连接失败',
      message: '无法连接到服务器，请检查网络连接后重试',
      onRetry: onRetry,
    );
  }

  static void handleFileError(
    BuildContext context,
    Object error,
    VoidCallback? onRetry,
  ) {
    handleError(
      context,
      error,
      StackTrace.current,
      title: '文件操作失败',
      message: '文件读取或写入失败，请检查权限后重试',
      onRetry: onRetry,
    );
  }

  static void handleValidationError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void handleSuccess(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}