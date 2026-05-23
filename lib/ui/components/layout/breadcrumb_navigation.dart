import 'package:flutter/material.dart';
import '../../theme/colors.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: BamcColors.surfaceDark,
        border: const Border(
          bottom: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          BreadcrumbItem item = entry.value;
          bool isLast = index == items.length - 1;

          List<Widget> parts = [];

          parts.add(MouseRegion(
            cursor: item.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: item.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: item.isActive
                      ? BamcColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                  border: item.isActive
                      ? Border.all(
                          color: BamcColors.primaryLight,
                          width: 1,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ),
                  boxShadow: item.isActive
                      ? [
                          BoxShadow(
                            color: BamcColors.primary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        item.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: item.isActive
                        ? BamcColors.primaryLight
                        : BamcColors.textSecondary,
                  ),
                ),
              ),
            ),
          ));

          if (!isLast) {
            parts.addAll([
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: BamcColors.textTertiary,
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