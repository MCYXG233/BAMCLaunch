import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../components/index.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../game/java/java_manager.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../core/logger.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'resource_center_page.dart';
import 'game_library_page.dart';

/// 蔚蓝档案风格主界面
class BAMCHomePage extends StatefulWidget {
  const BAMCHomePage({super.key});

  @override
  State<BAMCHomePage> createState() => _BAMCHomePageState();
}

class _BAMCHomePageState extends State<BAMCHomePage>
    with SingleTickerProviderStateMixin {
  String _selectedNavItem = 'home';
  bool _isLaunching = false;
  String? _selectedVersion;
  String? _selectedAccountName;
  String? _javaStatus;
  bool _sidebarCollapsed = false;

  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  final List<BASidebarItem> _navItems = [
    BASidebarItem(
      id: 'home',
      icon: Icons.home_rounded,
      label: '主页',
      badge: null,
      onTap: () {},
    ),
    BASidebarItem(
      id: 'game-library',
      icon: Icons.gamepad_rounded,
      label: '游戏库',
      badge: null,
      onTap: () {},
    ),
    BASidebarItem(
      id: 'resource-center',
      icon: Icons.inventory_2_rounded,
      label: '资源中心',
      badge: null,
      onTap: () {},
    ),
    BASidebarItem(
      id: 'accounts',
      icon: Icons.people_rounded,
      label: '账户管理',
      badge: null,
      onTap: () {},
    ),
    BASidebarItem(
      id: 'settings',
      icon: Icons.settings_rounded,
      label: '设置',
      badge: null,
      onTap: () {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: BAAnimations.elasticInOut,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: BAAnimations.elasticOut,
      ),
    );
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: BAAnimations.smooth,
      ),
    );

    _loadInitialData().then((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final versionManager = VersionManager();
      final installedVersions = await versionManager.getInstalledVersions();
      if (installedVersions.isNotEmpty) {
        setState(() {
          _selectedVersion = installedVersions.first;
        });
      }

      final accountManager = AccountManager();
      final selectedAccount = await accountManager.getSelectedAccount();
      if (selectedAccount != null) {
        setState(() {
          _selectedAccountName = selectedAccount.username;
        });
      }

      final javaManager = JavaManager();
      final selectedJava = await javaManager.getSelectedJava();
      setState(() {
        _javaStatus = selectedJava != null
            ? 'Java ${selectedJava.majorVersion}'
            : '未检测到Java';
      });
    } catch (e) {
      Logger().error('加载初始数据失败', e);
    }
  }

  Future<void> _launchGame() async {
    if (_isLaunching) return;
    if (_selectedVersion == null) {
      _showErrorSnackBar('请先选择游戏版本');
      return;
    }
    if (_selectedAccountName == null) {
      _showErrorSnackBar('请先选择游戏账户');
      return;
    }

    setState(() {
      _isLaunching = true;
    });

    try {
      final logger = Logger();
      logger.info('正在启动游戏: $_selectedVersion');

      final accountManager = AccountManager();
      final javaManager = JavaManager();
      final gameLauncher = GameLauncher();

      final accounts = await accountManager.getAccounts();
      final account = accounts.firstWhere(
        (a) => a.username == _selectedAccountName,
        orElse: () => accounts.first,
      );

      final java = await javaManager.getSelectedJava();
      if (java == null) {
        throw Exception('未找到有效的Java安装');
      }

      final gameDir = await VersionManager().getGameDir();

      final launchArgs = LaunchArguments(
        gameVersion: _selectedVersion!,
        gameDirectory: gameDir,
        javaPath: java.path,
        account: account,
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      await gameLauncher.launch(launchArgs);

      if (mounted) {
        _showSuccessSnackBar('游戏启动成功！');
      }
    } catch (e, stackTrace) {
      Logger().error('游戏启动失败', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('游戏启动失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.success,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BATheme.borderRadiusSmall,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BATheme.borderRadiusSmall,
        ),
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: BAColors.backgroundGradientOf(context),
        ),
        child: Column(
          children: [
            CustomTitleBar(title: 'BAMC 启动器', showWindowControls: true),
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        return Container(
          width: _sidebarCollapsed ? 72 : 260,
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _navItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) => _buildNavItem(_navItems[index]),
                ),
              ),
              _buildSidebarFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BAColors.primary.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          BAPulseBuilder(
            enabled: true,
            duration: const Duration(seconds: 2),
            scaleFactor: 1.05,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: BAColors.primaryGradient,
                borderRadius: BATheme.borderRadiusMedium,
                boxShadow: BATheme.shadowsSmallOf(context),
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          if (!_sidebarCollapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BAMC 启动器',
                    style: BATypography.titleMedium.copyWith(
                      color: BAColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'v2.0.0',
                    style: BATypography.bodySmall.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(BASidebarItem item) {
    final isSelected = item.id == _selectedNavItem;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedNavItem = item.id;
          });
        },
        borderRadius: BATheme.borderRadiusSmall,
        child: BAFloatBuilder(
          enabled: isSelected,
          floatDistance: 3,
          duration: const Duration(seconds: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: BAAnimations.smooth,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 14 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? BAColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BATheme.borderRadiusSmall,
              border: isSelected
                  ? Border.all(color: BAColors.primary.withOpacity(0.3), width: 1)
                  : null,
              boxShadow: isSelected ? BATheme.shadowsSmallOf(context) : [],
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: BAAnimations.elasticOut,
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? BAColors.primary
                        : BAColors.textSecondaryOf(context),
                    size: 22,
                  ),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _sidebarCollapsed ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        item.label,
                        style: BATypography.bodyMedium.copyWith(
                          color: isSelected
                              ? BAColors.primary
                              : BAColors.textPrimaryOf(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BAColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: BATypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: BAIconButton(
        onPressed: _toggleSidebar,
        icon: _sidebarCollapsed
            ? Icons.arrow_right_rounded
            : Icons.arrow_left_rounded,
        tooltip: _sidebarCollapsed ? '展开侧边栏' : '收起侧边栏',
        size: 24,
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildContentArea(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentArea() {
    switch (_selectedNavItem) {
      case 'home':
        return _buildHomeContent();
      case 'game-library':
        return const GameLibraryPage();
      case 'resource-center':
        return const ResourceCenterPage();
      case 'accounts':
        return const BAMCAccountPage();
      case 'settings':
        return const BAMCSettingsPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 32),
          _buildLaunchSection(),
          const SizedBox(height: 32),
          _buildRecentGames(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '欢迎回来，老师',
            style: BATypography.headlineLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '准备好开始新的冒险了吗？',
            style: BATypography.bodyLarge.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchSection() {
    return BAGlowBuilder(
      enabled: true,
      glowColor: BAColors.primary,
      maxGlowRadius: 5,
      duration: const Duration(seconds: 3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadiusLarge,
          boxShadow: BATheme.shadowsOf(context),
          border: Border.all(
            color: BAColors.borderOf(context),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BAColors.primary.withOpacity(0.15),
                    borderRadius: BATheme.borderRadiusSmall,
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: BAColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '快速启动',
                  style: BATypography.titleLarge.copyWith(
                    color: BAColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildInfoGrid(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: BAPrimaryButton(
                text: '启动游戏',
                onPressed: _launchGame,
                loading: _isLaunching,
                leadingIcon: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            icon: Icons.extension_rounded,
            label: '游戏版本',
            value: _selectedVersion ?? '未选择',
            color: BAColors.primary,
            onTap: () {
              setState(() {
                _selectedNavItem = 'versions';
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.person_rounded,
            label: '游戏账户',
            value: _selectedAccountName ?? '未选择',
            color: BAColors.secondary,
            onTap: () {
              setState(() {
                _selectedNavItem = 'accounts';
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.code_rounded,
            label: 'Java环境',
            value: _javaStatus ?? '检测中...',
            color: BAColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return BAFloatBuilder(
      enabled: onTap != null,
      floatDistance: 2,
      duration: const Duration(seconds: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: BAAnimations.smooth,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BATheme.borderRadiusMedium,
            border: Border.all(
              color: BAColors.borderOf(context),
              width: 1,
            ),
            boxShadow: onTap != null ? BATheme.shadowsSmallOf(context) : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: BATypography.label.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      color: color,
                      size: 14,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: BATypography.bodyLarge.copyWith(
                  color: BAColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentGames() {
    final recentGames = [
      {'version': '1.20.1', 'time': '2小时前', 'account': '玩家1'},
      {'version': '1.19.4', 'time': '昨天', 'account': '玩家2'},
      {'version': '1.18.2', 'time': '3天前', 'account': '玩家1'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近游戏',
          style: BATypography.titleLarge.copyWith(
            color: BAColors.textPrimaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BATheme.borderRadiusLarge,
            boxShadow: BATheme.shadowsOf(context),
            border: Border.all(
              color: BAColors.borderOf(context),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentGames.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: BAColors.borderOf(context),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            itemBuilder: (context, index) =>
                _buildGameRecordItem(recentGames[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildGameRecordItem(Map<String, String> game, int index) {
    return BAAnimationBuilder(
      builder: (context, animation) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(20 * (1 - animation.value), 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedVersion = game['version'];
                  });
                },
                borderRadius: BATheme.borderRadiusSmall,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: BAColors.primaryGradient,
                          borderRadius: BATheme.borderRadiusMedium,
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minecraft ${game['version']}',
                              style: BATypography.bodyLarge.copyWith(
                                color: BAColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '玩家: ${game['account']}',
                              style: BATypography.bodySmall.copyWith(
                                color: BAColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        game['time'] ?? '',
                        style: BATypography.bodySmall.copyWith(
                          color: BAColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 100),
      curve: BAAnimations.smooth,
    );
  }
}