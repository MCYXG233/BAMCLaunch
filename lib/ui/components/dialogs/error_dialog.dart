import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';

class ErrorDialog {
  static void show(
    BuildContext context,
    String title,
    String message, {
    String? details,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: BamcColors.background,
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: BamcColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: BamcColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: BamcColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (details != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: BamcColors.surface,
                    border: Border.all(color: BamcColors.border),
                  ),
                  child: Text(
                    details,
                    style: const TextStyle(
                      color: BamcColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      wordSpacing: -1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '关闭',
              style: TextStyle(color: BamcColors.textSecondary),
            ),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BamcColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}
