import 'package:flutter/material.dart';
import '../../ui/theme/colors.dart';
import '../auto_fixer.dart';

/// 修复日志部分
class DiagnosticFixLogSection extends StatelessWidget {
  final AutoFixer autoFixer;
  final VoidCallback onClearLogs;

  const DiagnosticFixLogSection({
    super.key,
    required this.autoFixer,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '修复日志', Icons.history_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BAColors.borderOf(context).withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BAColors.primaryOf(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '修复日志',
                      style: TextStyle(
                        color: BAColors.primaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (autoFixer.fixHistory.isNotEmpty)
                    TextButton(
                      onPressed: onClearLogs,
                      child: Text(
                        '清除日志',
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (autoFixer.fixHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '暂无修复日志',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...autoFixer.fixHistory.reversed.take(10).map((op) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          op.isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: op.isSuccess
                              ? BAColors.successOf(context)
                              : BAColors.dangerOf(context),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            op.operationName,
                            style: TextStyle(
                              color: BAColors.textPrimaryOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          op.duration?.inMilliseconds.toString() ?? '-',
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ms',
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BAColors.primaryOf(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: BAColors.primaryOf(context), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
