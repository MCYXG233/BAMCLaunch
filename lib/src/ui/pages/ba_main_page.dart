import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../theme/background_manager.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../components/ba_login_dialog.dart';
import 'ba_game_library_page.dart';
import 'ba_resource_center_page.dart';
import 'ba_account_page.dart';
import 'ba_more_page.dart';
import '../components/ba_settings_panel.dart';
import '../components/ba_immersive_home.dart';

/// Minecraft 启动器首页
///  - 顶部: 毛玻璃栏 + 窗口控制按钮
///  - 中间: 缩放动画页面切换
///  - 底部: 毛玻璃导航栏
class BAMainPage extends StatefulWidget {
  const BAMainPage({super.key});

  @override
  State<BAMainPage> createState() => _BAMainPageState();
}

class _BAMainPageState extends State<BAMainPage> {
  int _currentPage = 0;
  bool _isMaximized = false;
  final BackgroundManager _backgroundManager = BackgroundManager();

  final AccountManager _accountManager = AccountManager();
  final InstanceManager _instanceManager = InstanceManager();
  String? _selectedAccountName;
  List<GameInstance> _instances = [];
  int _selectedInstanceIndex = 0;
  bool _isLaunching = false;

  // 游戏统计
  int _instanceCount = 0;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _loadAccountData();
    _initInstanceManager();
    _initBackgroundManager();
  }

  Future<void> _initBackgroundManager() async {
    await _backgroundManager.initialize();
    _backgroundManager.addListener(_onBackgroundChanged);
    if (mounted) setState(() {});
  }

  void _onBackgroundChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _backgroundManager.removeListener(_onBackgroundChanged);
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    try {
      final selectedAccount = await _accountManager.getSelectedAccount();
      if (mounted) {
        setState(() {
          _selectedAccountName = selectedAccount?.username ?? '未登录';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAccountName = '未登录';
        });
      }
    }
  }

  Future<void> _initInstanceManager() async {
    try {
      await _instanceManager.initialize();
      if (mounted) {
        setState(() {
          _instances = List.from(_instanceManager.instances);
          _instanceCount = _instances.length;
        });
      }
    } catch (e) {
      // 初始化失败
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

  Future<void> _launchGame() async {
    if (_instances.isEmpty || _isLaunching) return;
    final instance = _instances[_selectedInstanceIndex];

    setState(() => _isLaunching = true);

    try {
      // 获取账号
      final account = await _accountManager.getSelectedAccount();
      if (account == null) {
        if (!mounted) return;
        _showNotification('请先登录账号', isError: true);
        return;
      }

      // 获取游戏目录
      final manager = InstanceManager();
      final directory = manager.directories.firstWhere(
        (d) => d.id == instance.directoryId,
        orElse: () => throw StateError('游戏目录不存在'),
      );

      // 获取配置
      final config = ConfigManager.instance;
      final javaPath = instance.config.javaPath ??
          config.get<String>(ConfigKeys.javaPath) ??
          'java';
      final memory = instance.config.maxMemory ??
          config.get<int>(ConfigKeys.memory) ??
          2048;
      final jvmArgs = instance.config.jvmArgs ?? [];
      final gameArgs = instance.config.gameArgs ?? [];

      // 组装启动参数
      final args = LaunchArguments(
        javaPath: javaPath,
        gameVersion: instance.version,
        account: account,
        gameDirectory: directory.path,
        memory: memory,
        jvmArguments: jvmArgs,
        gameArguments: gameArgs,
      );

      // 启动游戏
      await GameLauncher().launch(args);
      if (mounted) {
        _showNotification('启动成功！正在启动 ${instance.name}...');
      }
    } catch (e) {
      if (mounted) {
        _showNotification('启动失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? BAColors.dangerOf(context) : BAColors.successOf(context),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 兜底渐变背景，防止 BackgroundManager 初始化失败时页面透明
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0ECFF), Color(0xFFC9D8FF)],
          ),
        ),
        child: _backgroundManager.buildBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _buildCurrentPage(),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _buildHomePage(key: const ValueKey('home'));
      case 1:
        return const BAGameLibraryPage(key: ValueKey('library'));
      case 2:
        return const BAResourceCenterPage(key: ValueKey('resource'));
      case 3:
        return const BAAccountPage(key: ValueKey('account'));
      case 4:
        return const BAMorePage(key: ValueKey('more'));
      default:
        return _buildHomePage(key: const ValueKey('home'));
    }
  }

  Widget _buildHomePage({Key? key}) {
    return ImmersiveHomePage(
      key: key,
      instances: _instances,
      selectedInstanceIndex: _selectedInstanceIndex,
      onInstanceChanged: (index) {
        setState(() => _selectedInstanceIndex = index);
      },
      isLaunching: _isLaunching,
      onLaunch: _launchGame,
    );
  }

  // ==================== 顶部栏 ====================

  Widget _buildTopBar() {
    return BAGlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 启动器 Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BAColors.primaryOf(context).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports, color: BAColors.primaryOf(context), size: 20),
                const SizedBox(width: 8),
                Text(
                  'BAMCLaunch',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v1.0',
                    style: TextStyle(
                      color: BAColors.primaryOf(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 当前账号（可点击弹出登录对话框）
          GestureDetector(
            onTap: () async {
              final result = await showDialog<Account>(
                context: context,
                barrierColor: Colors.black54,
                builder: (context) => const BALoginDialog(),
              );
              if (result != null) {
                // 账户已变更，重新加载账户信息
                await _loadAccountData();
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: BAColors.textPrimaryOf(context).withValues(alpha: 0.85), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _selectedAccountName ?? '加载中...',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context).withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: BAColors.textPrimaryOf(context).withValues(alpha: 0.5), size: 12),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // 实例数量指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BAColors.borderOf(context).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, color: BAColors.textPrimaryOf(context).withValues(alpha: 0.85), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$_instanceCount 个实例',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context).withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 设置按钮
          IconButton(
            onPressed: () => SettingsPanel.show(context),
            tooltip: '设置',
            icon: Icon(
              Icons.settings,
              color: BAColors.textPrimaryOf(context).withValues(alpha: 0.7),
              size: 18,
            ),
          ),

          // 窗口控制按钮
          Row(
            children: [
              BAWindowButton(
                icon: Icons.minimize,
                onTap: () => windowManager.minimize(),
              ),
              const SizedBox(width: 6),
              BAWindowButton(
                icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                onTap: () async {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                  setState(() => _isMaximized = !_isMaximized);
                },
              ),
              const SizedBox(width: 6),
              BAWindowButton(
                icon: Icons.close,
                isClose: true,
                onTap: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 底部导航 ====================

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home, '首页', 0),
      _NavItem(Icons.inventory_2_outlined, '游戏', 1),
      _NavItem(Icons.explore, '发现', 2),
      _NavItem(Icons.person, '账户', 3),
      _NavItem(Icons.more_horiz, '更多', 4),
    ];

    return BAGlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => _buildNavItem(item.icon, item.label, item.index))
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () {
        // 切换 tab 时主动取消所有 TextField 焦点，避免 IME 残留
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _currentPage = index);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context).withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: BAAnimationDurations.micro,
                child: Icon(
                  icon,
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem(this.icon, this.label, this.index);
}
