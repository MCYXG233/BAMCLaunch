import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../components/ba_login_dialog.dart';
import '../theme/colors.dart';
import '../theme/ba_theme_colors.dart';
import 'ba_game_library_page.dart';
import 'ba_resource_center_page.dart';
import 'ba_settings_page.dart';

/// 蔚蓝档案风格主页面
/// 完全模仿蔚蓝档案UI，但适合MC启动器
class BAMCMainPage extends StatefulWidget {
  const BAMCMainPage({super.key});

  @override
  State<BAMCMainPage> createState() => _BAMCMainPageState();
}

class _BAMCMainPageState extends State<BAMCMainPage> {
  int _currentPage = 0;
  bool _isMaximized = false;

  // 账户相关
  final AccountManager _accountManager = AccountManager();
  String? _selectedAccountName;
  bool _isLoading = true;

  // 模拟数据
  int _instanceCount = 6;
  int _activeDownloads = 2;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    try {
      final selectedAccount = await _accountManager.getSelectedAccount();
      if (mounted) {
        setState(() {
          _selectedAccountName = selectedAccount?.username;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger().error('加载账户数据失败', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openAccountSelector() async {
    final result = await showDialog<Account>(
      context: context,
      builder: (context) => const BALoginDialog(),
    );
    if (result != null && mounted) {
      await _loadAccountData();
    }
  }

  Future<void> _initWindow() async {
    if (Platform.isWindows || Platform.isMacOS) {
      final isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = isMaximized;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1A),
      body: Column(
        children: [
          // 标题栏
          _buildTitleBar(),

          // 主界面
          Expanded(
            child: Row(
              children: [
                // 左侧快捷栏
                _buildLeftSidebar(),

                // 内容区
                Expanded(
                  child: Column(
                    children: [
                      // 顶部信息栏
                      _buildTopBar(),
                      const SizedBox(height: 12),

                      // 内容
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 底部导航
          _buildBottomNav(),
        ],
      ),
    );
  }

  /// 标题栏
  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32,
        color: const Color(0xFF070710),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Logo
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.extension, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'BAMC Launcher',
              style: TextStyle(
                color: Color(0xFFA8A8C0),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),

            // 窗口控制
            if (Platform.isWindows) ...[
              _WindowButton(
                icon: Icons.remove,
                onTap: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                onTap: () async {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                onTap: () => windowManager.close(),
                isClose: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 左侧快捷栏
  Widget _buildLeftSidebar() {
    return Container(
      width: 56,
      color: const Color(0xFF15152E),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.extension, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 24),
          // 快捷按钮
          _SidebarButton(
            icon: Icons.grid_view,
            label: '视图',
            onTap: () {},
          ),
          _SidebarButton(
            icon: Icons.fullscreen,
            label: '全屏',
            onTap: () {},
          ),
          const Spacer(),
          _SidebarButton(
            icon: Icons.help_outline,
            label: '帮助',
            onTap: () {},
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 顶部信息栏
  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15152E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          // 用户信息（可点击）
          GestureDetector(
            onTap: _openAccountSelector,
            child: Row(
              children: [
                // 头像
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B8DEF).withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _selectedAccountName == null ? Icons.person_add : Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAccountName ?? '未登录',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B8DEF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedAccountName == null ? '点击登录' : 'Microsoft账户',
                        style: const TextStyle(
                          color: Color(0xFF5B8DEF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 50, color: const Color(0xFF2A2A4A)),
          const SizedBox(width: 24),

          // 统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: Icons.folder,
                value: '$_instanceCount',
                label: '实例',
                color: const Color(0xFF5B8DEF),
              ),
              const SizedBox(width: 32),
              _StatItem(
                icon: Icons.download,
                value: '$_activeDownloads',
                label: '下载中',
                color: const Color(0xFF5BD38D),
              ),
            ],
          ),

          const Spacer(),

          // 功能按钮
          Row(
            children: [
              _ActionButton(
                icon: Icons.mail_outline,
                badge: 3,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.settings,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 内容区
  Widget _buildContent() {
    switch (_currentPage) {
      case 0:
        return _HomeContent();
      case 1:
        return const BAGameLibraryPage();
      case 2:
        return const BAResourceCenterPage();
      case 3:
        return const BASettingsPage();
      default:
        return _HomeContent();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          top: BorderSide(
            color: BAThemeColors.border,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home,
                label: '主页',
                isSelected: _currentPage == 0,
                onTap: () => setState(() => _currentPage = 0),
              ),
            ),
            Container(
              width: 1,
              color: BAThemeColors.border.withOpacity(0.4),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.games,
                label: '游戏库',
                isSelected: _currentPage == 1,
                onTap: () => setState(() => _currentPage = 1),
              ),
            ),
            Container(
              width: 1,
              color: BAThemeColors.border.withOpacity(0.4),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.download,
                label: '资源中心',
                isSelected: _currentPage == 2,
                onTap: () => setState(() => _currentPage = 2),
              ),
            ),
            Container(
              width: 1,
              color: BAThemeColors.border.withOpacity(0.4),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.settings,
                label: '设置',
                isSelected: _currentPage == 3,
                onTap: () => setState(() => _currentPage = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 窗口按钮
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovered
              ? (widget.isClose ? Colors.red : const Color(0xFF232350))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            color: _isHovered && widget.isClose ? Colors.white : const Color(0xFFA8A8C0),
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// 侧边栏按钮
class _SidebarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFF1C1C3A) : const Color(0xFF15152E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFFA8A8C0),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA8A8C0),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// 功能按钮
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF232350) : const Color(0xFF1C1C3A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? const Color(0xFF5B8DEF) : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  widget.icon,
                  color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFFA8A8C0),
                  size: 20,
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _indicatorWidth;
  late Animation<double> _iconSize;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorWidth = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _iconSize = Tween<double>(begin: 24, end: 28).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    if (widget.isSelected) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isSelected
                ? BAThemeColors.primary.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? BAThemeColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected
                          ? BAThemeColors.primary
                          : BAThemeColors.textSecondary,
                      size: _iconSize.value,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    width: _indicatorWidth.value,
                    height: 3,
                    decoration: BoxDecoration(
                      color: BAThemeColors.primary,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: BAThemeColors.primary.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? BAThemeColors.primary
                      : BAThemeColors.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主页内容
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 欢迎区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BAColors.primary, BAColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '欢迎回来，老师',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '准备好开始新的冒险了吗？',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _QuickActionButton(
                      icon: Icons.play_arrow,
                      label: '开始游戏',
                      isPrimary: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _QuickActionButton(
                      icon: Icons.add,
                      label: '创建实例',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 最近游戏
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF15152E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A4A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: BAColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '最近游戏',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _GameRecordItem(
                          name: '原版生存',
                          version: '1.20.1',
                          time: '2小时前',
                        ),
                        _GameRecordItem(
                          name: 'MOD服务器',
                          version: '1.12.2',
                          time: '昨天',
                        ),
                        _GameRecordItem(
                          name: '科技模组',
                          version: '1.19.2',
                          time: '3天前',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷按钮
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? Colors.white : Colors.white.withOpacity(0.9))
                : (_isHovered ? const Color(0xFF7BA3F5).withOpacity(0.2) : Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary ? const Color(0xFF5B8DEF) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? const Color(0xFF5B8DEF) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 游戏记录项
class _GameRecordItem extends StatefulWidget {
  final String name;
  final String version;
  final String time;

  const _GameRecordItem({
    required this.name,
    required this.version,
    required this.time,
  });

  @override
  State<_GameRecordItem> createState() => _GameRecordItemState();
}

class _GameRecordItemState extends State<_GameRecordItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF1C1C3A) : const Color(0xFF15152E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? const Color(0xFF5B8DEF).withOpacity(0.5) : const Color(0xFF2A2A4A),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.landscape, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minecraft ${widget.version}',
                    style: const TextStyle(
                      color: Color(0xFFA8A8C0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.time,
              style: const TextStyle(
                color: Color(0xFF5C5C70),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.play_circle_fill,
              color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFF5C5C70),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

/// 游戏库内容
class _GameLibraryContent extends StatelessWidget {
  const _GameLibraryContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 标题栏
          Row(
            children: [
              const Text(
                '游戏库',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _ActionChip(icon: Icons.refresh, label: '刷新', onTap: () {}),
              const SizedBox(width: 8),
              _ActionChip(icon: Icons.add, label: '创建实例', onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),

          // 标签栏
          Container(
            height: 40,
            child: Row(
              children: [
                _TabChip(label: '全部', isSelected: true),
                _TabChip(label: '游戏中'),
                _TabChip(label: '已安装'),
                _TabChip(label: '可更新'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 实例列表
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return _InstanceCard(
                  name: ['原版生存', 'MOD服务器', '科技模组', '匠魂生存', '空岛生存', 'RPG冒险'][index],
                  version: ['1.20.1', '1.12.2', '1.19.2', '1.16.5', '1.18.2', '1.20.1'][index],
                  loader: ['原版', 'Forge', 'Fabric', 'Forge', 'Fabric', 'Forge'][index],
                  isPlaying: index == 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作标签
class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF232350) : const Color(0xFF1C1C3A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFF2A2A4A),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFFA8A8C0),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered ? const Color(0xFF5B8DEF) : const Color(0xFFA8A8C0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签芯片
class _TabChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TabChip({
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF5B8DEF).withOpacity(0.1)
                : (_isHovered ? const Color(0xFF1C1C3A) : const Color(0xFF15152E)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF5B8DEF)
                  : (_isHovered ? const Color(0xFF5B8DEF).withOpacity(0.5) : const Color(0xFF2A2A4A)),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected || _isHovered
                  ? const Color(0xFF5B8DEF)
                  : const Color(0xFFA8A8C0),
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 实例卡片
class _InstanceCard extends StatefulWidget {
  final String name;
  final String version;
  final String loader;
  final bool isPlaying;

  const _InstanceCard({
    required this.name,
    required this.version,
    required this.loader,
    this.isPlaying = false,
  });

  @override
  State<_InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<_InstanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPlaying
        ? const Color(0xFF5BD38D)
        : const Color(0xFF5B8DEF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF15152E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? statusColor : const Color(0xFF2A2A4A),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片区
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.2),
                      statusColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.landscape,
                        size: 48,
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.isPlaying ? '游戏中' : '就绪',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.games, label: widget.version),
                      const SizedBox(width: 6),
                      _InfoChip(icon: Icons.extension, label: widget.loader),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 信息芯片
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C3A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFA8A8C0)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA8A8C0),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// 资源中心内容
class _ResourceCenterContent extends StatelessWidget {
  const _ResourceCenterContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_rounded,
              size: 64,
              color: Color(0xFF5B8DEF),
            ),
            SizedBox(height: 16),
            Text(
              '资源中心',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '浏览和下载Minecraft模组、整合包',
              style: TextStyle(
                color: Color(0xFFA8A8C0),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置内容
class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_rounded,
              size: 64,
              color: Color(0xFFFF6B8A),
            ),
            SizedBox(height: 16),
            Text(
              '设置',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '配置启动器设置',
              style: TextStyle(
                color: Color(0xFFA8A8C0),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
