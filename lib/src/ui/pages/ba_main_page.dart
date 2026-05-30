import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
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
  final InstanceManager _instanceManager = InstanceManager();
  String? _selectedAccountName;
  bool _isLoading = true;
  List<GameInstance> _instances = [];

  @override
  void initState() {
    super.initState();
    _initWindow();
    _loadAccountData();
    _initInstanceManager();
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

  Future<void> _initInstanceManager() async {
    try {
      await _instanceManager.initialize();
      if (mounted) {
        setState(() {
          _instances = _instanceManager.instances;
        });
      }
    } catch (e) {
      Logger.instance.error('初始化实例管理器失败', e);
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
      backgroundColor: BAColors.backgroundOf(context),
      body: Column(
        children: [
          // 标题栏
          _buildTitleBar(),

          // 主界面
          Expanded(
            child: _buildContent(),
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
        height: 40,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          border: Border(
            bottom: BorderSide(
              color: BAColors.borderOf(context).withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Logo
            Image.asset(
              'assets/images/BAMCLaunch_Logo.png',
              width: 80,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 20),

            // 用户信息
            GestureDetector(
              onTap: _openAccountSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: BAColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedAccountName ?? '未登录',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 实例数
            _buildStatusItem(Icons.folder, '${_instances.length}', BAColors.primary),
            const SizedBox(width: 16),

            // 下载中
            _buildStatusItem(Icons.download, '0', BAColors.warning),
            const SizedBox(width: 16),

            // 通知
            _buildIconButton(Icons.notifications_none, onTap: () {}),
            const SizedBox(width: 8),

            // 设置
            _buildIconButton(Icons.settings, onTap: () => setState(() => _currentPage = 3)),
            const SizedBox(width: 8),

            // 窗口控制
            if (Platform.isWindows) ...[
              _WindowButton(
                icon: Icons.remove,
                onTap: () => windowManager.minimize(),
                hoverColor: BAColors.surfaceVariantOf(context),
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
                hoverColor: BAColors.surfaceVariantOf(context),
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

  Widget _buildStatusItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, color: BAColors.textSecondaryOf(context), size: 18),
        ),
      ),
    );
  }

  /// 内容区
  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildPageContent(_currentPage),
    );
  }

  Widget _buildPageContent(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return _HomeContent(
          key: const ValueKey(0),
          mainContext: context,
          instances: _instances,
          accountName: _selectedAccountName,
        );
      case 1:
        return const BAGameLibraryPage(key: ValueKey(1));
      case 2:
        return const BAResourceCenterPage(key: ValueKey(2));
      case 3:
        return const BASettingsPage(key: ValueKey(3));
      default:
        return _HomeContent(
          key: const ValueKey(0),
          mainContext: context,
          instances: _instances,
          accountName: _selectedAccountName,
        );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 56,
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: BAColors.borderOf(context).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(Icons.home, '主页', 0),
          _buildNavItem(Icons.grid_3x3, '游戏库', 1),
          _buildNavItem(Icons.archive, '资源中心', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentPage == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _currentPage = index);
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Icon(
                      icon,
                      color: isSelected ? BAColors.primary : BAColors.textSecondaryOf(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? BAColors.primary : BAColors.textSecondaryOf(context),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.isClose
                    ? BAColors.dangerOf(context)
                    : widget.hoverColor)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            color: _isHovered && widget.isClose
                ? BAColors.textOnPrimary
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

  const _ActionButton({required this.icon, this.badge, required this.onTap});

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
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? BAColors.primaryOf(context)
                  : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  widget.icon,
                  color: _isHovered
                      ? BAColors.primary
                      : BAColors.textSecondaryOf(context),
                  size: 20,
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BAColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: TextStyle(
                        color: BAColors.textOnPrimary,
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
    final selectedBg = BAColors.primaryOf(context).withOpacity(0.12);
    final hoverBg = BAColors.primaryOf(context).withOpacity(0.08);

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
                      color: widget.isSelected
                          ? selectedBg
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected
                          ? BAColors.primary
                          : BAColors.textSecondaryOf(context),
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
                      color: BAColors.primaryOf(context),
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: BAColors.primaryOf(
                                  context,
                                ).withOpacity(0.4),
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
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
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
  final Key? key;
  final BuildContext mainContext;
  final List<GameInstance> instances;
  final String? accountName;

  const _HomeContent({
    this.key,
    required this.mainContext,
    required this.instances,
    this.accountName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          Expanded(child: _buildRecentGamesCard()),
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
          Text(
            '欢迎回来，${accountName ?? '玩家'}',
            style: TextStyle(
              color: BAColors.textOnPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '准备好开始新的冒险了吗？',
            style: TextStyle(
              color: BAColors.textOnPrimary.withOpacity(0.9),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                icon: Icons.play_arrow,
                label: '开始游戏',
                isPrimary: true,
                onTap: () {},
              ),
              _QuickActionButton(icon: Icons.add, label: '创建实例', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGamesCard() {
    // 按 lastPlayed 排序，最近的在前
    final sortedInstances = List<GameInstance>.from(instances);
    sortedInstances.sort((a, b) {
      if (a.lastPlayed == null && b.lastPlayed == null) return 0;
      if (a.lastPlayed == null) return 1;
      if (b.lastPlayed == null) return -1;
      return b.lastPlayed!.compareTo(a.lastPlayed!);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(mainContext),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BAColors.borderOf(mainContext)),
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
                  color: BAColors.primaryOf(mainContext).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.history,
                  color: BAColors.primaryOf(mainContext),
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
            child: sortedInstances.isEmpty
                ? Center(
                    child: Text(
                      '还没有游戏实例',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(mainContext),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedInstances.length,
                    itemBuilder: (context, index) {
                      final instance = sortedInstances[index];
                      return _GameRecordItem(
                        name: instance.name,
                        version: instance.version,
                        lastPlayed: instance.lastPlayed,
                        cardContext: mainContext,
                      );
                    },
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
                ? (_isHovered
                      ? BAColors.textOnPrimary.withOpacity(0.95)
                      : BAColors.textOnPrimary)
                : (_isHovered
                      ? BAColors.textOnPrimary.withOpacity(0.25)
                      : BAColors.textOnPrimary.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? BAColors.textOnPrimary.withOpacity(0.3)
                  : BAColors.textOnPrimary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? BAColors.primary
                    : BAColors.textOnPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary
                      ? BAColors.primary
                      : BAColors.textOnPrimary,
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
  final DateTime? lastPlayed;
  final BuildContext cardContext;

  const _GameRecordItem({
    required this.name,
    required this.version,
    this.lastPlayed,
    required this.cardContext,
  });

  @override
  State<_GameRecordItem> createState() => _GameRecordItemState();
}

class _GameRecordItemState extends State<_GameRecordItem> {
  bool _isHovered = false;

  String _formatTime(DateTime? time) {
    if (time == null) return '从未玩过';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isHovered
              ? BAColors.primaryOf(context)
              : BAColors.surfaceVariantOf(widget.cardContext),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? BAColors.primaryOf(context).withOpacity(0.4)
                : BAColors.borderOf(widget.cardContext),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BAColors.primaryOf(context), BAColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.landscape,
                color: BAColors.textOnPrimary,
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
                      color: BAColors.textPrimaryOf(widget.cardContext),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minecraft ${widget.version}',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(widget.cardContext),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                _formatTime(widget.lastPlayed),
                style: TextStyle(
                  color: BAColors.textSecondaryOf(
                    widget.cardContext,
                  ).withOpacity(0.7),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isHovered
                    ? BAColors.primaryOf(context)
                    : BAColors.surfaceVariantOf(widget.cardContext),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_fill,
                color: _isHovered
                    ? BAColors.textOnPrimary
                    : BAColors.textSecondaryOf(
                        widget.cardContext,
                      ).withOpacity(0.7),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
