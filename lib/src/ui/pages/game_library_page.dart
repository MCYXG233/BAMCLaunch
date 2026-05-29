import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/index.dart';
import '../../instance/index.dart';
import '../../extension/index.dart';
import 'version_page.dart';

/// 游戏库页面（合并实例管理和版本管理）
class GameLibraryPage extends StatefulWidget {
  const GameLibraryPage({super.key});

  @override
  State<GameLibraryPage> createState() => _GameLibraryPageState();
}

class _GameLibraryPageState extends State<GameLibraryPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        const SizedBox(height: 24),
        Expanded(
          child: _selectedTab == 0
              ? InstanceManagerPage()
              : BAMCVersionPage(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              icon: Icons.folder_rounded,
              label: '实例管理',
              isSelected: _selectedTab == 0,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
            ),
          ),
          Expanded(
            child: _buildTab(
              icon: Icons.system_update_alt_rounded,
              label: '版本管理',
              isSelected: _selectedTab == 1,
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = BAColors.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: primaryColor.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black54),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
