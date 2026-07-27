import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 工具栏按钮 - 图标 + 文本的统一风格按钮
class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? BAColors.surfaceOf(context),
          foregroundColor: color ?? BAColors.textPrimaryOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: BAColors.borderOf(context)),
          ),
        ),
      ),
    );
  }
}

/// 搜索框 - 工具栏中的模组搜索输入框
class ModSearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ModSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 300),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: BAColors.primaryOf(context).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: '搜索模组...',
            hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
            prefixIcon: Icon(
              Icons.search,
              color: BAColors.textSecondaryOf(context),
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}

/// 排序下拉选择
class SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const SortDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: value,
            dropdownColor: BAColors.surfaceOf(context),
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 13,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: BAColors.textSecondaryOf(context),
            ),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('按名称')),
              DropdownMenuItem(value: 'version', child: Text('按版本')),
              DropdownMenuItem(value: 'date', child: Text('按日期')),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

/// "显示禁用"开关
class ShowDisabledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ShowDisabledSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '显示禁用',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: BAColors.primaryOf(context),
        ),
      ],
    );
  }
}

/// 批量操作栏 - 多选模式下的批量启用/禁用/删除
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onBatchEnable;
  final VoidCallback onBatchDisable;
  final VoidCallback onBatchDelete;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
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
            onPressed: hasSelection ? onBatchEnable : null,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('批量启用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: hasSelection ? onBatchDisable : null,
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
