import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../resource_constants.dart';

/// 排序按钮 - 弹出菜单选择排序方式
class SortButton extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelected;
  final Color textPrimary;

  const SortButton({
    super.key,
    required this.currentSort,
    required this.onSelected,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final label = ResourceConstants.sortOptions
        .firstWhere(
          (e) => e.key == currentSort,
          orElse: () => const MapEntry('downloads', '最多下载'),
        )
        .value;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: BAColors.backgroundSecondaryOf(context),
      itemBuilder: (_) => ResourceConstants.sortOptions
          .map(
            (opt) => PopupMenuItem(
              value: opt.key,
              height: 36,
              child: Row(
                children: [
                  if (currentSort == opt.key)
                    Icon(
                      Icons.check,
                      size: 14,
                      color: BAColors.primaryOf(context),
                    )
                  else
                    const SizedBox(width: 14),
                  const SizedBox(width: 8),
                  Text(
                    opt.value,
                    style: TextStyle(
                      color: currentSort == opt.key
                          ? BAColors.primaryOf(context)
                          : textPrimary,
                      fontSize: 12,
                      fontWeight: currentSort == opt.key
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 15, color: textPrimary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: textPrimary, fontSize: 12)),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: textPrimary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
