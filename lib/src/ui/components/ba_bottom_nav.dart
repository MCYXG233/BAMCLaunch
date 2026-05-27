import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';

/// 蔚蓝档案风格底部导航栏
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
      height: 70,
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          top: BorderSide(color: BAThemeColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.games_outlined,
            selectedIcon: Icons.games,
            label: '游戏库',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.download_outlined,
            selectedIcon: Icons.download,
            label: '资源中心',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? BAThemeColors.primary : BAThemeColors.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isSelected ? BAThemeColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 10 : 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BAThemeColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: color,
                    size: isSelected ? 28 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
