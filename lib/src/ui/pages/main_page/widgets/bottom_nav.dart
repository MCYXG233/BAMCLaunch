import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../components/ba_common_widgets.dart';
import '../main_page_providers.dart';

/// 底部导航项描述
class NavItem {
  final IconData icon;
  final String label;
  final int index;

  const NavItem(this.icon, this.label, this.index);
}

/// 底部导航栏 - 5 个 Tab
class BottomNav extends ConsumerWidget {
  final List<NavItem> items;

  const BottomNav({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BAGlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _NavItemWidget(item: item)).toList(),
      ),
    );
  }
}

class _NavItemWidget extends ConsumerWidget {
  final NavItem item;

  const _NavItemWidget({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final isSelected = currentPage == item.index;
    return GestureDetector(
      onTap: () {
        // 切换 tab 时主动取消所有 TextField 焦点，避免 IME 残留
        FocusManager.instance.primaryFocus?.unfocus();
        ref.read(currentPageProvider.notifier).state = item.index;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context).withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: BAAnimationDurations.micro,
                child: Icon(
                  item.icon,
                  color: isSelected
                      ? BAColors.primaryOf(context)
                      : BAColors.textSecondaryOf(context),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? BAColors.primaryOf(context)
                      : BAColors.textSecondaryOf(context),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 默认 5 个 Tab 列表
const defaultNavItems = <NavItem>[
  NavItem(Icons.home, '首页', 0),
  NavItem(Icons.inventory_2_outlined, '游戏', 1),
  NavItem(Icons.explore, '发现', 2),
  NavItem(Icons.person, '账户', 3),
  NavItem(Icons.more_horiz, '更多', 4),
];
