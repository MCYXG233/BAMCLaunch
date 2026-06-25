import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 底部导航栏
///
/// 5个导航入口：主页 / 游戏库 / 资源中心 / 账户 / 更多
class BABottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BABottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 64,
      decoration: BoxDecoration(
        color: BAColors.glassOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(Icons.home, '主页', 0, context),
          _buildNavItem(Icons.grid_3x3, '游戏库', 1, context),
          _buildNavItem(Icons.archive, '资源中心', 2, context),
          _buildNavItem(Icons.person, '账户', 3, context),
          _buildNavItem(Icons.more_horiz, '更多', 4, context),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, BuildContext context) {
    bool isSelected = currentIndex == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            onTap(index);
          },
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.20 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                    size: isSelected ? 26 : 22,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  child: Text(label),
                  style: TextStyle(
                    color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                    fontSize: isSelected ? 13 : 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
