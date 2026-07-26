import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 模组管理页顶部栏
///
/// 展示"模组管理"徽章、模组数量、冲突/缺失依赖警告徽章
class ModHeader extends StatelessWidget {
  final int modCount;
  final int conflictCount;
  final int missingDepCount;

  const ModHeader({
    super.key,
    required this.modCount,
    required this.conflictCount,
    required this.missingDepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧"模组管理"徽章
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: BAColors.secondaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: BAColors.secondaryOf(context).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                '模组管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 中间模组数量
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BAColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.extension,
                color: BAColors.secondaryOf(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$modCount',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' 个模组',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // 右侧警告徽章
        if (conflictCount > 0)
          _WarningBadge(
            text: '$conflictCount 冲突',
            color: BAColors.dangerOf(context),
          ),
        if (missingDepCount > 0)
          _WarningBadge(
            text: '$missingDepCount 缺失依赖',
            color: Colors.orange,
          ),
      ],
    );
  }
}

/// 警告徽章
class _WarningBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _WarningBadge({required this.text, required this.color});

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
