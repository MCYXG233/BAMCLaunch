import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../components/ba_login_dialog.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
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
      Logger.instance.error('加载账户数据失败', e);
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final scaffoldBackground = isLight ? BAColors.lightBackground : BAColors.darkBackground;

    return Scaffold(
      backgroundColor: scaffoldBackground,
      body: Column(
        children: [
          // 标题栏
          _buildTitleBar(),

          // 主界面
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

          // 底部导航
          _buildBottomNav(),
        ],
      ),
    );
  }

  /// 标题栏
  Widget _buildTitleBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final windowButtonHover = isLight ? BAColors.lightBorder : const Color(0xFF232350);

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32,
        color: bgColor,
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Logo
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BAColors.primary, BAColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/BAMCLaunch_Logo.png',
                  fit: BoxFit.contain,
                  width: 20,
                  height: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'BAMC Launcher',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
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
                hoverColor: windowButtonHover,
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
                hoverColor: windowButtonHover,
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

  /// 顶部信息栏
  Widget _buildTopBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: BATheme.shadowsSmallOf(context),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BAColors.primary, BAColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: BAColors.primary.withOpacity(0.3),
                        blurRadius: 12,
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
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BAColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedAccountName == null ? '点击登录' : 'Microsoft账户',
                        style: const TextStyle(
                          color: BAColors.primary,
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
                  color: BAColors.textSecondaryOf(context),
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 50, color: BAColors.borderOf(context)),
          const SizedBox(width: 24),

          // 统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: Icons.folder,
                value: '$_instanceCount',
                label: '实例',
                color: BAColors.primary,
              ),
              const SizedBox(width: 32),
              _StatItem(
                icon: Icons.download,
                value: '$_activeDownloads',
                label: '下载中',
                color: BAColors.success,
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
                onTap: () => setState(() => _currentPage = 3),
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
        return _HomeContent(mainContext: context);
    }
  }

  Widget _buildBottomNav() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final borderColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
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
              color: borderColor.withOpacity(0.4),
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
              color: borderColor.withOpacity(0.4),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.download,
                label: '资源中心',
                isSelected: _currentPage == 2,
                onTap: () => setState(() => _currentPage = 2),
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
  final Color? hoverColor;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
    this.hoverColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final defaultHover = isLight ? const Color(0xFFE8ECF0) : const Color(0xFF232350);
    final hoverColor = widget.hoverColor ?? defaultHover;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovered
              ? (widget.isClose ? Colors.red : hoverColor)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            color: _isHovered && widget.isClose
                ? Colors.white
                : BAColors.textSecondaryOf(context),
            size: 16,
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
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;

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
            color: _isHovered ? bgColor : BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? BAColors.primary : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  widget.icon,
                  color: _isHovered ? BAColors.primary : BAColors.textSecondaryOf(context),
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
                      color: BAColors.danger,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final selectedBg = BAColors.primary.withOpacity(0.12);
    final hoverBg = isLight ? BAColors.primary.withOpacity(0.06) : BAColors.primary.withOpacity(0.08);

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
                ? hoverBg
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
                      color: widget.isSelected ? selectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected ? BAColors.primary : BAColors.textSecondaryOf(context),
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
                      color: BAColors.primary,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: BAColors.primary.withOpacity(0.4),
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
                      ? BAColors.primary
                      : BAColors.textSecondaryOf(context),
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
  final BuildContext mainContext;

  const _HomeContent({required this.mainContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildRecentGamesCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BAColors.primary, BAColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BAColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
          Text(
            '准备好开始新的冒险了吗？',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
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
    );
  }

  Widget _buildRecentGamesCard() {
    final isLight = Theme.of(mainContext).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: BATheme.shadowsSmallOf(mainContext),
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
                  color: BAColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history,
                  color: BAColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '最近游戏',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(mainContext),
                  fontSize: 18,
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
                  cardContext: mainContext,
                ),
                _GameRecordItem(
                  name: 'MOD服务器',
                  version: '1.12.2',
                  time: '昨天',
                  cardContext: mainContext,
                ),
                _GameRecordItem(
                  name: '科技模组',
                  version: '1.19.2',
                  time: '3天前',
                  cardContext: mainContext,
                ),
              ],
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
                ? (_isHovered ? Colors.white.withOpacity(0.95) : Colors.white)
                : (_isHovered ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary ? BAColors.primary : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? BAColors.primary : Colors.white,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isHovered ? cardBg : BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? BAColors.primary.withOpacity(0.4) : cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BAColors.primary, BAColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.landscape,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minecraft ${widget.version}',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.time,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context).withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isHovered ? BAColors.primary : BAColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_fill,
                color: _isHovered ? Colors.white : BAColors.textSecondaryOf(context).withOpacity(0.7),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
