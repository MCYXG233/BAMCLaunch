import 'package:flutter/material.dart';
import '../../ui/theme/colors.dart';

/// 通用操作按钮
class DiagnosticActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const DiagnosticActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? (onPressed == null
                      ? BAColors.primaryOf(context).withValues(alpha: 0.4)
                      : BAColors.primaryOf(context))
                : BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : BAColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : (onPressed == null
                          ? BAColors.textDisabledOf(context)
                          : BAColors.textPrimaryOf(context)),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : (onPressed == null
                            ? BAColors.textDisabledOf(context)
                            : BAColors.textPrimaryOf(context)),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
