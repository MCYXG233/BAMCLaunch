import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 详情页子Tab�?- BakaXL 风格（带 icon + 渐变选中态）
///
/// 每个 Tab �?14px icon 提升可读性；选中态保留渐�?+ 阴影�?/// 未选中态靠左对齐，hover 态由 Material InkWell 提供微妙水波�?class GameLibraryDetailTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final List<IconData> icons;

  const GameLibraryDetailTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFFFFFFFF),
        unselectedLabelColor:
            BAColors.textSecondaryOf(context).withValues(alpha: 0.85),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BAColors.primaryLightOf(context),
              BAColors.primaryOf(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: BAColors.primaryOf(context).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(10),
        tabs: List.generate(tabs.length, (i) {
          return Tab(
            height: 34,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], size: 14),
                const SizedBox(width: 6),
                Text(tabs[i]),
              ],
            ),
          );
        }),
      ),
    );
  }
}
