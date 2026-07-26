import 'package:flutter/material.dart';

import '../../../../mod/mod_info.dart';
import '../../../theme/colors.dart';

/// 单个模组项
///
/// 列表中渲染单个 mod 的 UI 项，支持：
/// - 普通模式：左 Switch + 名称/版本 + 删除按钮
/// - 多选模式：左 Checkbox + 名称/版本
class ModItem extends StatelessWidget {
  final ModInfo mod;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback? onSelect;

  const ModItem({
    super.key,
    required this.mod,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isMultiSelectMode ? onSelect : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withValues(alpha: 0.1)
                : BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context)
                  : mod.isEnabled
                      ? BAColors.borderOf(context)
                      : BAColors.textDisabledOf(context).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isMultiSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect?.call(),
                  activeColor: BAColors.primaryOf(context),
                ),
                const SizedBox(width: 8),
              ],
              if (!isMultiSelectMode) ...[
                Switch(
                  value: mod.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: BAColors.primaryOf(context),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BAColors.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: BAColors.primaryOf(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mod.name,
                      style: TextStyle(
                        color: mod.isEnabled
                            ? BAColors.textPrimaryOf(context)
                            : BAColors.textDisabledOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mod.version != null)
                            Text(
                              'v${mod.version}',
                              style: TextStyle(
                                color: BAColors.textSecondaryOf(context),
                                fontSize: 12,
                              ),
                            ),
                          if (mod.modId != null) ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: BAColors.textDisabledOf(context),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                mod.modId!,
                                style: TextStyle(
                                  color: BAColors.textSecondaryOf(context),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMultiSelectMode) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: BAColors.textDisabledOf(context),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
