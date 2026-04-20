import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

class BreadcrumbItem {
  final String title;
  final bool isActive;
  final VoidCallback? onTap;

  BreadcrumbItem({
    required this.title,
    this.isActive = false,
    this.onTap,
  });
}

class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNavigation({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        border: const Border(
          bottom: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          BreadcrumbItem item = entry.value;
          bool isLast = index == items.length - 1;

          List<Widget> parts = [];

          // 面包屑项
          parts.add(MouseRegion(
            cursor: item.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: item.isActive
                      ? BamcColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  border: item.isActive
                      ? Border.all(
                          color: BamcColors.primary.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        item.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: item.isActive
                        ? BamcColors.primary
                        : BamcColors.textSecondary,
                  ),
                ),
              ),
            ),
          ));

          // 分隔符
          if (!isLast) {
            parts.addAll([
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: BamcColors.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
            ]);
          }

          return Row(children: parts);
        }).toList(),
      ),
    );
  }
}
