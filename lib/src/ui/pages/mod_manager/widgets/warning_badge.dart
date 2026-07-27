import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 警告徽章 - 用于头部显示冲突/缺失依赖等警告数量
class WarningBadge extends StatelessWidget {
  final String text;
  final Color color;

  const WarningBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 警告条 - 居中展示冲突/依赖警告并提供查看详情按钮
class WarningBar extends StatelessWidget {
  final String message;
  final VoidCallback onShowDetails;

  const WarningBar({
    super.key,
    required this.message,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.dangerOf(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.dangerOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: BAColors.dangerOf(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
          TextButton(onPressed: onShowDetails, child: const Text('查看详情')),
        ],
      ),
    );
  }
}
