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
  content,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(isHovering ? 6.0 : 0.0, isHovering ? -3.0 : 0.0)
            ..scale(isHovering ? 1.02 : 1.0),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? BamcColors.primary
                : isHovering
                    ? BamcColors.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BamcColors.primary,
                      BamcColors.primaryDark,
                      BamcColors.secondaryDark,
                    ],
                  )
                : null,
            border: isSelected
                ? Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 2,
                  )
                : isHovering
                    ? Border.all(
                        color: BamcColors.primary.withOpacity(0.6),
                        width: 1,
                      )
                    : Border.all(
                        color: BamcColors.border,
                        width: 1,
                      ),
            boxShadow: isSelected || isHovering
                ? [
                    BoxShadow(
                      color: BamcColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: BamcColors.primary.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : isHovering
                          ? BamcColors.primary.withOpacity(0.3)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : isHovering
                            ? BamcColors.primary
                            : BamcColors.border,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : BamcColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.white : BamcColors.textPrimary,
                  fontFamily: isSelected ? 'Minecraft' : null,
                  shadows: isSelected
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
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
      width: 250,
      decoration: const BoxDecoration(
        color: BamcColors.surface,
        border: Border(
          right: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo区域
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.primary.withOpacity(0.15),
                  BamcColors.secondary.withOpacity(0.15),
                ],
              ),
              border: const Border(
                bottom: BorderSide(
                  color: BamcColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            BamcColors.primary,
                            BamcColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BamcColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.gamepad_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BAMCLauncher',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BamcColors.primary,
                            fontFamily: 'Minecraft',
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
                  ],
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
                    item: NavigationItem.content,
                    title: '资源中心',
                    icon: Icons.library_books_outlined,
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
