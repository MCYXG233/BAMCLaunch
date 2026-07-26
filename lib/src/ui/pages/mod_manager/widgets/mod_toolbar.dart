import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 模组管理工具栏
///
/// 包含搜索框 + 排序下拉 + 显示禁用开关 + 检查更新/冲突检测/多选按钮
class ModToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final bool showDisabled;
  final ValueChanged<bool> onShowDisabledChanged;
  final bool isMultiSelectMode;
  final int conflictCount;
  final VoidCallback onCheckUpdates;
  final VoidCallback onShowConflicts;
  final VoidCallback onToggleMultiSelect;

  const ModToolbar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.showDisabled,
    required this.onShowDisabledChanged,
    required this.isMultiSelectMode,
    required this.conflictCount,
    required this.onCheckUpdates,
    required this.onShowConflicts,
    required this.onToggleMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 搜索框
          ConstrainedBox(
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
                controller: searchController,
                onChanged: onSearchChanged,
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
          ),
          const SizedBox(width: 12),
          // 排序下拉
          ConstrainedBox(
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
                  value: sortBy,
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
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 显示禁用开关
          Row(
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
                value: showDisabled,
                onChanged: onShowDisabledChanged,
                activeThumbColor: BAColors.primaryOf(context),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: Icons.refresh,
            label: '检查更新',
            onPressed: onCheckUpdates,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.warning,
            label: '冲突检测',
            onPressed: onShowConflicts,
            color: conflictCount > 0 ? BAColors.dangerOf(context) : null,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: isMultiSelectMode ? Icons.close : Icons.checklist,
            label: isMultiSelectMode ? '取消选择' : '多选',
            onPressed: onToggleMultiSelect,
            color: isMultiSelectMode ? BAColors.primaryOf(context) : null,
          ),
        ],
      ),
    );
  }
}

/// 工具栏按钮 - 统一图标+文字的方形按钮
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ToolbarButton({
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
