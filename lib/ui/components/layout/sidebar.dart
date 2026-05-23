import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum NavigationItem {
  home,
  versions,
  content,
  modpacks,
  servers,
  accounts,
  settings,
}

class Sidebar extends StatefulWidget {
  final NavigationItem selectedItem;
  final Function(NavigationItem) onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const Sidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggle,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  final Map<NavigationItem, bool> _hoverStates = {};
  final Map<NavigationItem, AnimationController?> _animationControllers = {};
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    NavigationItem.values.forEach((item) {
      _animationControllers[item] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    _animationControllers.values.forEach((controller) {
      controller?.dispose();
    });
    super.dispose();
  }

  void _updateHoverState(NavigationItem item, bool isHovering) {
    setState(() {
      _hoverStates[item] = isHovering;
    });
    if (isHovering) {
      _animationControllers[item]?.forward();
    } else {
      _animationControllers[item]?.reverse();
    }
  }

  Widget _buildNavigationItem({
    required NavigationItem item,
    required String title,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = widget.selectedItem == item;
    final isHovering = _hoverStates[item] ?? false;
    final animation = _animationControllers[item];

    return Padding(
      padding: widget.isCollapsed
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => _updateHoverState(item, true),
        onExit: (_) => _updateHoverState(item, false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onItemSelected(item),
          child: AnimatedBuilder(
            animation: animation ?? Listenable.merge([]),
            builder: (context, child) {
              final scale = isHovering && !isSelected ? 1.05 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: widget.isCollapsed
                      ? const EdgeInsets.all(12)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BamcColors.primary.withOpacity(0.15)
                        : isHovering
                            ? BamcColors.surfaceLight
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(widget.isCollapsed ? 12 : 12),
                    gradient: isSelected ? BamcColors.sidebarSelectedGradient : null,
                    border: Border.all(
                      color: isSelected
                          ? BamcColors.neonBlue
                          : isHovering
                              ? BamcColors.primary.withOpacity(0.4)
                              : Colors.transparent,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: BamcColors.neonBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: BamcColors.primary.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : isHovering
                            ? [
                                BoxShadow(
                                  color: BamcColors.shadowMedium,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                  ),
                  child: widget.isCollapsed
                      ? _buildCollapsedIcon(
                          icon: icon,
                          selectedIcon: selectedIcon,
                          isSelected: isSelected,
                          isHovering: isHovering,
                        )
                      : _buildExpandedItem(
                          icon: icon,
                          selectedIcon: selectedIcon,
                          title: title,
                          isSelected: isSelected,
                          isHovering: isHovering,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedIcon({
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required bool isHovering,
  }) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : isHovering
                  ? BamcColors.primary.withOpacity(0.15)
                  : BamcColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : isHovering
                    ? BamcColors.primary.withOpacity(0.4)
                    : BamcColors.borderLight,
            width: 1,
          ),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : isHovering
                  ? BamcColors.neonBlue
                  : BamcColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildExpandedItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required bool isSelected,
    required bool isHovering,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : isHovering
                    ? BamcColors.primary.withOpacity(0.15)
                    : BamcColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.5)
                  : isHovering
                      ? BamcColors.primary.withOpacity(0.4)
                      : BamcColors.borderLight,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: BamcColors.neonBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isSelected ? selectedIcon : icon,
            size: 18,
            color: isSelected
                ? Colors.white
                : isHovering
                    ? BamcColors.neonBlue
                    : BamcColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isHovering
                      ? BamcColors.textPrimary
                      : BamcColors.textSecondary,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (isSelected)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: BamcColors.neonBlue,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.neonBlue,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: widget.isCollapsed
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BamcColors.border.withOpacity(0),
              BamcColors.border,
              BamcColors.border.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovering ? BamcColors.surfaceLight : BamcColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovering ? BamcColors.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            widget.isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 18,
            color: BamcColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        width: widget.isCollapsed ? 80 : 260,
        decoration: BoxDecoration(
          gradient: BamcColors.sidebarGradient,
          border: const Border(
            right: BorderSide(
              color: BamcColors.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: BamcColors.shadowMedium,
              blurRadius: 15,
              offset: const Offset(3, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildLogoSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildNavigationItem(
                      item: NavigationItem.home,
                      title: '主页',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                    ),
                    _buildNavigationItem(
                      item: NavigationItem.versions,
                      title: '版本管理',
                      icon: Icons.gamepad_outlined,
                      selectedIcon: Icons.gamepad_rounded,
                    ),
                    _buildNavigationItem(
                      item: NavigationItem.content,
                      title: '资源中心',
                      icon: Icons.library_books_outlined,
                      selectedIcon: Icons.library_books_rounded,
                    ),
                    _buildNavigationItem(
                      item: NavigationItem.modpacks,
                      title: '整合包',
                      icon: Icons.archive_outlined,
                      selectedIcon: Icons.archive_rounded,
                    ),
                    _buildNavigationItem(
                      item: NavigationItem.servers,
                      title: '服务器',
                      icon: Icons.dns_outlined,
                      selectedIcon: Icons.dns_rounded,
                    ),
                  ],
                ),
              ),
            ),
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  _buildNavigationItem(
                    item: NavigationItem.accounts,
                    title: '账户',
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                  ),
                  _buildNavigationItem(
                    item: NavigationItem.settings,
                    title: '设置',
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                  ),
                ],
              ),
            ),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: widget.isCollapsed ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.15),
            BamcColors.secondary.withOpacity(0.08),
            BamcColors.accent.withOpacity(0.03),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: widget.isCollapsed
          ? _buildCollapsedLogo()
          : _buildExpandedLogo(),
    );
  }

  Widget _buildCollapsedLogo() {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: BamcColors.logoGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: BamcColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.gamepad_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExpandedLogo() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: BamcColors.logoGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BamcColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.gamepad_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BAMCLauncher',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BamcColors.textPrimary,
                  height: 1.2,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Minecraft Launcher',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: BamcColors.textTertiary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}