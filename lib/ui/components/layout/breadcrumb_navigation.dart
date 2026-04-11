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
          BamcEffects.standardShadow(
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: item.isActive
                      ? BamcColors.primary.withOpacity(0.1)
                      : Colors.transparent,
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: BamcColors.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
            ]);
          }

          return Row(children: parts);
        }).toList(),
      ),
    );
  }
}
