import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum NavigationItem {
  home,
  versions,
  mods,
  modpacks,
  servers,
  accounts,
  settings,
}

class Sidebar extends StatefulWidget {
  final NavigationItem selectedItem;
  final Function(NavigationItem) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final Map<NavigationItem, bool> _hoverStates = {};

  void _updateHoverState(NavigationItem item, bool isHovering) {
    setState(() {
      _hoverStates[item] = isHovering;
    });
  }

  Widget _buildNavigationItem({
    required NavigationItem item,
    required String title,
    required IconData icon,
  }) {
    bool isSelected = widget.selectedItem == item;
    bool isHovering = _hoverStates[item] ?? false;

    return MouseRegion(
      onHover: (_) => _updateHoverState(item, true),
      onExit: (_) => _updateHoverState(item, false),
      child: GestureDetector(
        onTap: () => widget.onItemSelected(item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? BamcColors.primary
                : isHovering
                    ? BamcColors.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      BamcColors.primary,
                      BamcColors.primaryDark,
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : BamcColors.textPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : BamcColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: BamcColors.surface,
        border: Border(
          right: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo区域
          Container(
            height: 60,
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAMCLauncher',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BamcColors.primary,
                  ),
                ),
                Text(
                  'Minecraft Launcher',
                  style: TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 导航菜单
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildNavigationItem(
                    item: NavigationItem.home,
                    title: '主页',
                    icon: Icons.home_outlined,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.versions,
                    title: '版本管理',
                    icon: Icons.gamepad_outlined,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.mods,
                    title: '模组管理',
                    icon: Icons.extension_outlined,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.modpacks,
                    title: '整合包',
                    icon: Icons.archive_outlined,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.servers,
                    title: '服务器',
                    icon: Icons.computer_outlined,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.accounts,
                    title: '账户',
                    icon: Icons.person_outlined,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // 设置按钮
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildNavigationItem(
              item: NavigationItem.settings,
              title: '设置',
              icon: Icons.settings_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
