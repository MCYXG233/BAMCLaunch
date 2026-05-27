import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../../core/error_codes.dart';
import 'ba_buttons.dart';

/// 错误对话框
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? solution;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final bool showRetryButton;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.solution,
    this.error,
    this.stackTrace,
    this.onRetry,
    this.onClose,
    this.showRetryButton = false,
  });

  /// 从异常创建错误对话框
  factory ErrorDialog.fromException(
    Object error, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    String message;
    String? solution;
    bool retryable = false;

    if (error is AppException) {
      message = error.message;
      solution = ErrorMessages.getSolution(error.errorCode);
      retryable = error.retryable;
    } else {
      message = error.toString();
    }

    return ErrorDialog(
      title: title ?? '出错了',
      message: message,
      solution: solution,
      error: error,
      onRetry: retryable ? onRetry : null,
      onClose: onClose,
      showRetryButton: retryable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadius,
          boxShadow: BATheme.shadowsOf(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BAColors.danger.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: BAColors.danger,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: BATypography.headlineMedium.copyWith(
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 错误消息
                  Text(
                    message,
                    style: BATypography.bodyMedium.copyWith(
                      color: BAColors.textPrimaryOf(context),
                    ),
                  ),

                  // 解决方案
                  if (solution != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BAColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BAColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: BAColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              solution!,
                              style: BATypography.bodyMedium.copyWith(
                                color: BAColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 按钮栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: BAColors.borderOf(context),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showRetryButton && onRetry != null) ...[
                    BAPrimaryButton(
                      text: '重试',
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry!();
                      },
                      leadingIcon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                  BASecondaryButton(
                    text: '关闭',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onClose?.call();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示错误对话框
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? solution,
    Object? error,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
    VoidCallback? onClose,
    bool showRetryButton = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        solution: solution,
        error: error,
        stackTrace: stackTrace,
        onRetry: onRetry,
        onClose: onClose,
        showRetryButton: showRetryButton,
      ),
    );
  }

  /// 从异常显示错误对话框
  static Future<void> showException(
    BuildContext context,
    Object error, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog.fromException(
        error,
        title: title,
        onRetry: onRetry,
        onClose: onClose,
      ),
    );
  }
}

/// 简易的错误提示（SnackBar）
class ErrorSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: BAColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: BAColors.danger,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
