import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/custom_title_bar.dart';
import '../components/ba_sidebar.dart';
import '../components/ba_buttons.dart';
import '../../config/config_manager_impl.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../game/java/java_manager.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../core/logger.dart';
import 'version_page.dart';
import 'account_page.dart';
import 'settings_page.dart';
import 'resource_center_page.dart';

/// 主界面页面
/// 包含侧边栏导航、启动卡片、最近游戏记录等功能
class BAMCHomePage extends StatefulWidget {
  const BAMCHomePage({super.key});

  @override
  State<BAMCHomePage> createState() => _BAMCHomePageState();
}

class _BAMCHomePageState extends State<BAMCHomePage> {
  String _selectedNavItem = 'home';
  bool _isLaunching = false;
  String? _selectedVersion;
  String? _selectedAccountName;
  String? _javaStatus;
  final List<Map<String, String>> _recentGames = [
    {'version': '1.20.1', 'time': '2小时前', 'account': '玩家1'},
    {'version': '1.19.4', 'time': '昨天', 'account': '玩家2'},
    {'version': '1.18.2', 'time': '3天前', 'account': '玩家1'},
  ];

  final List<BASidebarItem> _navItems = const [
    BASidebarItem(icon: Icons.home, label: '主页', id: 'home'),
    BASidebarItem(icon: Icons.extension, label: '版本管理', id: 'versions'),
    BASidebarItem(icon: Icons.inventory_2, label: '资源中心', id: 'resource-center'),
    BASidebarItem(icon: Icons.people, label: '账户管理', id: 'accounts'),
    BASidebarItem(icon: Icons.settings, label: '设置', id: 'settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    try {
      // 加载已安装版本
      final versionManager = VersionManager();
      final installedVersions = await versionManager.getInstalledVersions();
      if (installedVersions.isNotEmpty) {
        setState(() {
          _selectedVersion = installedVersions.first;
        });
      }

      // 加载选中账户
      final accountManager = AccountManager();
      final selectedAccount = await accountManager.getSelectedAccount();
      if (selectedAccount != null) {
        setState(() {
          _selectedAccountName = selectedAccount.username;
        });
      }

      // 检查Java状态
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

  /// 启动游戏
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

      // 获取必要的管理器
      final accountManager = AccountManager();
      final javaManager = JavaManager();
      final gameLauncher = GameLauncher();
      final configManager = ConfigManagerImpl();

      // 获取账户
      final accounts = await accountManager.getAccounts();
      final account = accounts.firstWhere(
        (a) => a.username == _selectedAccountName,
        orElse: () => accounts.first,
      );

      // 获取Java
      final java = await javaManager.getSelectedJava();
      if (java == null) {
        throw Exception('未找到有效的Java安装');
      }

      // 获取游戏目录
      final gameDir = await VersionManager().getGameDir();

      // 构建启动参数
      final launchArgs = LaunchArguments(
        gameVersion: _selectedVersion!,
        gameDirectory: gameDir,
        javaPath: java.path,
        account: account,
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      // 启动游戏
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

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.background,
      body: Column(
        children: [
          // 自定义标题栏
          CustomTitleBar(title: 'BAMC 启动器', showWindowControls: true),
          // 主内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧侧边栏
                BASidebar(
                  items: _navItems,
                  selectedId: _selectedNavItem,
                  onSelected: (id) {
                    setState(() {
                      _selectedNavItem = id;
                    });
                  },
                  collapsible: true,
                  initiallyCollapsed: false,
                ),
                // 右侧内容区
                Expanded(child: _buildContentArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea() {
    switch (_selectedNavItem) {
      case 'home':
        return _buildHomeContent();
      case 'versions':
        return const BAMCVersionPage();
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

  /// 构建主页内容
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎文本
          Text(
            '欢迎回来，老师',
            style: BATypography.headlineMedium.copyWith(
              color: BAColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '准备好开始新的冒险了吗？',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // 启动卡片
          _buildLaunchCard(),
          const SizedBox(height: 32),
          // 最近游戏记录
          _buildRecentGames(),
        ],
      ),
    );
  }

  /// 构建启动卡片
  Widget _buildLaunchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surface,
        borderRadius: BATheme.borderRadius,
        boxShadow: BATheme.shadows,
        border: Border.all(color: BAColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速启动',
            style: BATypography.headlineSmall.copyWith(
              color: BAColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // 配置信息行
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.extension,
                  label: '游戏版本',
                  value: _selectedVersion ?? '未选择',
                  color: BAColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person,
                  label: '游戏账户',
                  value: _selectedAccountName ?? '未选择',
                  color: BAColors.secondary,
                  onTap: () {
                    // 跳转到账户管理页面
                    setState(() {
                      _selectedNavItem = 'accounts';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.code,
                  label: 'Java环境',
                  value: _javaStatus ?? '检测中...',
                  color: BAColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 启动按钮
          SizedBox(
            width: double.infinity,
            child: BAPrimaryButton(
              text: '启动游戏',
              onPressed: _launchGame,
              loading: _isLaunching,
              height: 56,
              leadingIcon: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息项组件
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariant,
          borderRadius: BATheme.borderRadiusSmall,
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
                    color: BAColors.textSecondary,
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
                color: BAColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建最近游戏记录
  Widget _buildRecentGames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近游戏',
          style: BATypography.headlineSmall.copyWith(
            color: BAColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentGames.map((game) => _buildGameRecordItem(game)).toList(),
      ],
    );
  }

  /// 构建游戏记录项
  Widget _buildGameRecordItem(Map<String, String> game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surface,
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BAColors.primary.withOpacity(0.2),
              borderRadius: BATheme.borderRadiusSmall,
            ),
            child: Icon(
              Icons.sports_esports,
              color: BAColors.primary,
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
                    color: BAColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '玩家: ${game['account']}',
                  style: BATypography.bodySmall.copyWith(
                    color: BAColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            game['time'] ?? '',
            style: BATypography.bodySmall.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
