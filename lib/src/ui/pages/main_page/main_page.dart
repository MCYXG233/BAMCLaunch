import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../account/account.dart';
import '../../../account/account_manager.dart';
import '../../../config/config_keys.dart';
import '../../../config/config_manager.dart';
import '../../../core/logger.dart';
import '../../../di/providers.dart';
import '../../../game/launcher/game_launcher.dart';
import '../../../game/launcher/models.dart';
import '../../../instance/instance_manager.dart';
import '../../../instance/models.dart';
import '../../theme/background_manager.dart';
import '../../theme/colors.dart';
import '../../components/ba_login_dialog.dart';
import '../../components/ba_settings_panel.dart';
import 'main_page_providers.dart';
import 'widgets/app_top_bar.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/page_router.dart';

/// Minecraft 启动器首页
///  - 顶部: 毛玻璃栏 + 窗口控制按钮
///  - 中间: 缩放动画页面切换
///  - 底部: 毛玻璃导航栏
class BAMainPage extends ConsumerStatefulWidget {
  const BAMainPage({super.key});

  @override
  ConsumerState<BAMainPage> createState() => _BAMainPageState();
}

class _BAMainPageState extends ConsumerState<BAMainPage> {
  bool _isMaximized = false;
  final BackgroundManager _backgroundManager = BackgroundManager();

  final AccountManager _accountManager = AccountManager();
  final InstanceManager _instanceManager = InstanceManager();

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
        ref.read(selectedAccountNameProvider.notifier).state =
            selectedAccount?.username ?? '未登录';
      }
    } catch (e) {
      if (mounted) {
        ref.read(selectedAccountNameProvider.notifier).state = '未登录';
      }
    }
  }

  Future<void> _initInstanceManager() async {
    try {
      await _instanceManager.initialize();
      if (mounted) {
        final instances = List<GameInstance>.from(_instanceManager.instances);
        ref.read(instancesProvider.notifier).state = instances;
      }
    } catch (e, st) {
      Logger.instance.error('初始化实例管理器失败', e, st);
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
    final instances = ref.read(instancesProvider);
    final selectedIndex = ref.read(selectedInstanceIndexProvider);
    final isLaunching = ref.read(isLaunchingProvider);
    if (instances.isEmpty || isLaunching) return;
    final instance = instances[selectedIndex];

    ref.read(isLaunchingProvider.notifier).state = true;

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
      final javaPath =
          instance.config.javaPath ??
          config.get<String>(ConfigKeys.javaPath) ??
          'java';
      final memory =
          instance.config.maxMemory ??
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
        ref.read(isLaunchingProvider.notifier).state = false;
      }
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? BAColors.dangerOf(context)
            : BAColors.successOf(context),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    if (mounted) {
      setState(() => _isMaximized = !_isMaximized);
    }
  }

  void _onAccountTap() async {
    final result = await showDialog<Account>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const BALoginDialog(),
    );
    if (result != null) {
      // 账户已变更，重新加载账户信息
      await _loadAccountData();
    }
  }

  void _onSettingsTap() {
    SettingsPanel.show(context);
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
                AppTopBar(
                  onAccountTap: _onAccountTap,
                  onSettingsTap: _onSettingsTap,
                  isMaximized: _isMaximized,
                  onToggleMaximize: _toggleMaximize,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: PageRouter(onLaunch: _launchGame),
                  ),
                ),
                const BottomNav(items: defaultNavItems),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
