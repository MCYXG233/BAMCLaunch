import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// 导航项枚举
enum NavigationItem {
  home,
  versions,
  content,
  modpacks,
  servers,
  accounts,
  settings,
}

/// 侧边栏组件
///
/// 融合 Minecraft × 蔚蓝档案风格的侧边导航
/// 特点：
/// - 毛玻璃质感
/// - 柔和渐变选中态
/// - 像素风图标点缀
/// - 流畅动效
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

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  final Map<NavigationItem, bool> _hoverStates = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateHoverState(NavigationItem item, bool isHovering) {
    setState(() {
      _hoverStates[item] = isHovering;
    });
  }

  /// 构建导航项
  Widget _buildNavigationItem({
    required NavigationItem item,
    required String title,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = widget.selectedItem == item;
    final isHovering = _hoverStates[item] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => _updateHoverState(item, true),
        onExit: (_) => _updateHoverState(item, false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onItemSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? BamcColors.primary
                  : isHovering
                      ? BamcColors.primarySurface
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              gradient: isSelected
                  ? BamcColors.sidebarSelectedGradient
                  : null,
              border: Border.all(
                color: isSelected
                    ? BamcColors.primary
                    : isHovering
                        ? BamcColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: BamcColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 图标容器
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : isHovering
                            ? BamcColors.primary.withValues(alpha: 0.1)
                            : BamcColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : isHovering
                              ? BamcColors.primary.withValues(alpha: 0.2)
                              : BamcColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : isHovering
                            ? BamcColors.primary
                            : BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // 标题
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isHovering
                              ? BamcColors.primary
                              : BamcColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                // 选中指示器
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建分隔线
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BamcColors.border.withValues(alpha: 0),
              BamcColors.border,
              BamcColors.border.withValues(alpha: 0),
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
      decoration: BoxDecoration(
        color: BamcColors.surface,
        border: const Border(
          right: BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo 区域
          _buildLogoSection(),
          
          // 主导航
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
          
          // 分隔线
          _buildDivider(),
          
          // 底部导航
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
        ],
      ),
    );
  }

  /// 构建 Logo 区域
  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            BamcColors.primarySurface.withValues(alpha: 0.6),
            BamcColors.secondarySurface.withValues(alpha: 0.3),
            BamcColors.accentSurface.withValues(alpha: 0.2),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Logo 图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: BamcColors.logoGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.gamepad_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // Logo 文字
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAMCLauncher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BamcColors.textPrimary,
                    height: 1.2,
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
      ),
    );
  }
}
