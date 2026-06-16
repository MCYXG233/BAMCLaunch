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
import 'ba_settings_page.dart';

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
  bool _isLoading = true;
  List<GameInstance> _instances = [];
  int _selectedInstanceIndex = 0;
  bool _isLaunching = false;

  // 游戏统计
  int _totalPlayTimeMinutes = 0;
  int _totalLaunchCount = 0;
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        backgroundColor: isError ? BAColors.danger : BAColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatPlayTime(int? seconds) {
    if (seconds == null || seconds == 0) return '0分钟';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}小时${minutes}分钟';
    return '${minutes}分钟';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '从未';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _backgroundManager.buildBackground(
        child: SafeArea(
          child: Container(
            color: Colors.transparent,
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
      case 1:
        return const BAGameLibraryPage(key: ValueKey('library'));
      case 2:
        return const BAResourceCenterPage(key: ValueKey('resource'));
      case 3:
        return const BASettingsPage(key: ValueKey('settings'));
      default:
        return _buildHomePage(key: const ValueKey('home'));
    }
  }

  Widget _buildHomePage({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          // 左侧: 实例列表
          _buildInstanceList(),
          const SizedBox(width: 16),
          // 中间: 实例详情 + 启动按钮
          Expanded(
            child: _buildInstanceDetail(),
          ),
          const SizedBox(width: 16),
          // 右侧: 统计 + 快速入口
          _buildRightPanel(),
        ],
      ),
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
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFF5F8FF) : const Color(0xFF1A2540)).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BAColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports, color: BAColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'BAMCLaunch',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: BAColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'v1.0',
                    style: TextStyle(
                      color: BAColors.primary,
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
                  color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFF5F8FF) : const Color(0xFF1A2540)).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A)).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.85), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _selectedAccountName ?? '加载中...',
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.5), size: 12),
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
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFF5F8FF) : const Color(0xFF1A2540)).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A)).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.85), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$_instanceCount 个实例',
                  style: TextStyle(
                    color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

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

  // ==================== 主内容区 ====================

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BAColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          // 左侧: 实例列表
          _buildInstanceList(),
          const SizedBox(width: 16),
          // 中间: 实例详情 + 启动按钮
          Expanded(
            child: _buildInstanceDetail(),
          ),
          const SizedBox(width: 16),
          // 右侧: 统计 + 快速入口
          _buildRightPanel(),
        ],
      ),
    );
  }

  // ========== 实例列表 ==========

  Widget _buildInstanceList() {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: BAColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '游戏实例',
                  style: TextStyle(
                    color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _currentPage = 1),
                icon: Icon(Icons.open_in_new, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF5A6A8A) : const Color(0xFFA0B0C8)), size: 16),
                tooltip: '管理实例',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _instances.isEmpty
                ? _buildEmptyInstanceList()
                : ListView.builder(
                    itemCount: _instances.length,
                    itemBuilder: (context, index) {
                      return _buildInstanceListItem(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInstanceList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.4), size: 40),
          const SizedBox(height: 12),
          Text(
              '暂无游戏实例',
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _currentPage = 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: BAColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BAColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: BAColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '新建实例',
                      style: TextStyle(
                        color: BAColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceListItem(int index) {
    final instance = _instances[index];
    final isSelected = _selectedInstanceIndex == index;
    final isRunning = instance.status == InstanceStatus.running;

    return GestureDetector(
      onTap: () => setState(() => _selectedInstanceIndex = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primary.withValues(alpha: 0.2)
                : (Theme.of(context).brightness == Brightness.light ? const Color(0xFFE8EDFF) : const Color(0xFF2A3766)).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BAColors.primary.withValues(alpha: 0.6)
                  : (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A)).withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 实例图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getVersionColor(instance.version, context).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getVersionColor(instance.version, context).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.sports_esports,
                  color: _getVersionColor(instance.version, context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.name,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          instance.version,
                          style: TextStyle(
                            color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (instance.loader != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: BAColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              instance.loader!,
                              style: TextStyle(
                                color: BAColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (isRunning) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: BAColors.accentPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '运行中',
                              style: TextStyle(
                                color: BAColors.accentPink,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVersionColor(String version, BuildContext context) {
    if (version.startsWith('1.21')) return BAColors.primary;
    if (version.startsWith('1.20')) return BAColors.success;
    if (version.startsWith('1.19')) return BAColors.warning;
    if (version.startsWith('1.18')) return BAColors.accentPink;
    return (Theme.of(context).brightness == Brightness.light ? const Color(0xFF5A6A8A) : const Color(0xFFA0B0C8));
  }

  // ========== 实例详情 + 启动按钮 ==========

  Widget _buildInstanceDetail() {
    if (_instances.isEmpty) {
      return _buildEmptyInstanceDetail();
    }
    final instance = _instances[_selectedInstanceIndex];
    final isRunning = instance.status == InstanceStatus.running;

    return BASurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 实例标题行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 大图标
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _getVersionColor(instance.version, context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getVersionColor(instance.version, context).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.sports_esports,
                  color: _getVersionColor(instance.version, context),
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.name,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildInfoChip(Icons.tag, 'MC ${instance.version}', BAColors.primary),
                        if (instance.loader != null)
                          _buildInfoChip(Icons.extension, instance.loader!, BAColors.success),
                        if (isRunning)
                          _buildInfoChip(Icons.play_circle_filled, '运行中', BAColors.accentPink),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 实例描述
          if (instance.description != null && instance.description!.isNotEmpty) ...[
            Text(
              instance.description!,
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 信息网格
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.access_time,
                    title: '游戏时间',
                    value: _formatPlayTime(instance.playTimeSeconds),
                    color: BAColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.calendar_today,
                    title: '上次启动',
                    value: _formatDate(instance.lastPlayed),
                    color: BAColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.folder,
                    title: 'Mod 数量',
                    value: '${instance.resources.mods.length}',
                    color: BAColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 大的启动按钮
          SizedBox(
            width: double.infinity,
            height: 64,
            child: GestureDetector(
              onTap: _isLaunching ? null : _launchGame,
              child: MouseRegion(
                cursor: _isLaunching ? SystemMouseCursors.basic : SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: BAAnimationDurations.micro,
                  decoration: BoxDecoration(
                    color: _isLaunching
                        ? (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
                        : BAColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLaunching
                          ? (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
                          : BAColors.primary.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isLaunching
                            ? Colors.transparent
                            : BAColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLaunching)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFFFFF),
                            strokeWidth: 2.5,
                          ),
                        )
                      else
                        const Icon(Icons.play_arrow, color: Color(0xFFFFFFFF), size: 32),
                      const SizedBox(width: 12),
                      Text(
                        _isLaunching ? '正在启动...' : (isRunning ? '再次启动' : '启动游戏'),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInstanceDetail() {
    return BASurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports,
            color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.3),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            '还没有游戏实例',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建您的第一个 Minecraft 实例开始游戏',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => setState(() => _currentPage = 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: BAColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: const Color(0xFFFFFFFF), size: 22),
                    SizedBox(width: 8),
                    Text(
                      '创建新实例',
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ========== 右侧面板 ==========

  Widget _buildRightPanel() {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快速入口
          Text(
            '快速入口',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickEntry(Icons.add_circle_outline, '新建实例', BAColors.primary, () {
            setState(() => _currentPage = 1);
          }),
          _buildQuickEntry(Icons.download_for_offline_outlined, '资源下载', BAColors.success, () {
            setState(() => _currentPage = 2);
          }),
          _buildQuickEntry(Icons.settings_outlined, '启动器设置', BAColors.accentPink, () {
            setState(() => _currentPage = 3);
          }),
          const SizedBox(height: 20),

          // 启动器信息
          Text(
            '启动器信息',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('实例数量', '$_instanceCount'),
          _buildInfoRow('当前账号', _selectedAccountName ?? '未登录'),
          _buildInfoRow('状态', '就绪'),

          const Spacer(),

          // 底部装饰
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFE8EDFF) : const Color(0xFF2A3766)).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A)).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '提示: 在游戏库中可以管理更多实例',
                    style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.6),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEntry(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.4), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 底部导航 ====================

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home, '首页', 0),
      _NavItem(Icons.inventory_2_outlined, '游戏库', 1),
      _NavItem(Icons.grid_view, '资源', 2),
      _NavItem(Icons.settings, '设置', 3),
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
      onTap: () => setState(() => _currentPage = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? BAColors.primary.withValues(alpha: 0.5)
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
                  color: isSelected ? BAColors.primary : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF5A6A8A) : const Color(0xFFA0B0C8)),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? BAColors.primary : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF5A6A8A) : const Color(0xFFA0B0C8)),
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
