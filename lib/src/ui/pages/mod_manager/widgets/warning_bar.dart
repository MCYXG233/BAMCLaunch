import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 冲突/缺失依赖警告条
///
/// 检测到冲突或缺失依赖时显示，提供"查看详情"快捷入口
class WarningBar extends StatelessWidget {
  final int conflictCount;
  final int missingDepCount;
  final VoidCallback onShowDetail;

  const WarningBar({
    super.key,
    required this.conflictCount,
    required this.missingDepCount,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (conflictCount > 0) parts.add('检测到 $conflictCount 个冲突');
    if (missingDepCount > 0) parts.add('$missingDepCount 个缺失依赖');

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
              parts.join('，'),
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
          TextButton(onPressed: onShowDetail, child: const Text('查看详情')),
        ],
      ),
    );
  }
}
