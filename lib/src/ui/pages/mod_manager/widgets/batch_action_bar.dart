import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 批量操作栏
///
/// 多选模式下显示，包含全选、批量启用/禁用/删除按钮
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final bool canEnable;
  final bool canDisable;
  final VoidCallback onSelectAll;
  final VoidCallback onBatchEnable;
  final VoidCallback onBatchDisable;
  final VoidCallback onBatchDelete;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.canEnable,
    required this.canDisable,
    required this.onSelectAll,
    required this.onBatchEnable,
    required this.onBatchDisable,
    required this.onBatchDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.primaryOf(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.primaryOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            '已选择 $selectedCount 个模组',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(onPressed: onSelectAll, child: const Text('全选')),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: hasSelection && canEnable ? onBatchEnable : null,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('批量启用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: hasSelection && canDisable ? onBatchDisable : null,
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('批量禁用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: hasSelection ? onBatchDelete : null,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('批量删除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.dangerOf(context),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
