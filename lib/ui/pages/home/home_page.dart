import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/layout/bamc_card.dart';
import '../../components/dialogs/error_dialog.dart';

/// 主页
///
/// 融合 Minecraft × 蔚蓝档案风格的主页
/// 特点：
/// - 欢迎横幅带渐变
/// - 统计卡片带图标
/// - 快速启动卡片
/// - 推荐版本横向滚动
class HomePage extends StatefulWidget {
  final IVersionManager versionManager;
  final IContentManager contentManager;
  final IGameLauncher gameLauncher;
  final AccountManager accountManager;
  final VoidCallback? onNavigateToVersions;
  final VoidCallback? onNavigateToModpacks;
  
  const HomePage({
    super.key,
    required this.versionManager,
    required this.contentManager,
    required this.gameLauncher,
    required this.accountManager,
    this.onNavigateToVersions,
    this.onNavigateToModpacks,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  int _installedVersionsCount = 0;
  int _installedModsCount = 0;
  String _playTime = '0h';
  List<Version> _recommendedVersions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = [
        widget.versionManager.getInstalledVersions(),
        widget.versionManager.getVersionManifest(),
        widget.contentManager.getInstalledContent(ContentType.mod),
      ];

      final results = await Future.wait(futures, eagerError: true);

      final installedVersions = results[0] as List<Version>;
      setState(() => _installedVersionsCount = installedVersions.length);

      final manifest = results[1] as VersionManifest;
      final latestRelease = manifest.versions.firstWhere(
        (v) => v.type.toString() == 'release',
        orElse: () => manifest.versions.first,
      );
      
      final latestVersion = await widget.versionManager.getVersionInfo(latestRelease.id);
      setState(() => _recommendedVersions = [latestVersion]);

      final installedMods = results[2] as List<ContentItem>;
      setState(() => _installedModsCount = installedMods.length);
      setState(() => _playTime = '0h');
    } catch (e) {
      logger.error('Failed to load home page data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎横幅
          _buildWelcomeBanner(),
          const SizedBox(height: 24),

          // 统计信息
          _buildStatisticsSection(),
          const SizedBox(height: 24),

          // 快速启动
          _buildQuickLaunchSection(),
          const SizedBox(height: 24),

          // 推荐版本
          _buildRecommendedVersionsSection(),
        ],
      ),
    );
  }

  /// 构建欢迎横幅
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: BamcColors.welcomeGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: BamcColors.primary.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰性圆形元素
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // 主内容
          Row(
            children: [
              // 像素风图标
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gamepad_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '欢迎回来！',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '准备好开始新的冒险了吗？',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧装饰图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 24,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatisticsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            title: '已安装版本',
            value: _installedVersionsCount.toString(),
            icon: Icons.gamepad_rounded,
            gradient: BamcColors.statPrimaryGradient,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatisticCard(
            title: '已安装模组',
            value: _installedModsCount.toString(),
            icon: Icons.extension_rounded,
            gradient: BamcColors.statSecondaryGradient,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatisticCard(
            title: '游戏时长',
            value: _playTime,
            icon: Icons.timer_rounded,
            gradient: BamcColors.statAccentGradient,
          ),
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return BamcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // 数值
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: BamcColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: BamcColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速启动
  Widget _buildQuickLaunchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速启动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildQuickLaunchCard(
              title: '最近启动',
              subtitle: '继续上次的游戏',
              icon: Icons.history_rounded,
              color: BamcColors.primary,
              onTap: () => widget.onNavigateToVersions?.call(),
            ),
            _buildQuickLaunchCard(
              title: '创建新游戏',
              subtitle: '安装新版本',
              icon: Icons.add_rounded,
              color: BamcColors.secondary,
              onTap: () => widget.onNavigateToVersions?.call(),
            ),
            _buildQuickLaunchCard(
              title: '导入整合包',
              subtitle: '从本地导入',
              icon: Icons.file_download_outlined,
              color: BamcColors.accent,
              onTap: () => widget.onNavigateToModpacks?.call(),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建快速启动卡片
  Widget _buildQuickLaunchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BamcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // 图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          // 文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: BamcColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // 箭头
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: BamcColors.textTertiary,
          ),
        ],
      ),
    );
  }

  /// 构建推荐版本
  Widget _buildRecommendedVersionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '推荐版本',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
              ),
            ),
            BamcButton(
              text: '查看全部',
              onPressed: () => widget.onNavigateToVersions?.call(),
              type: BamcButtonType.outline,
              size: BamcButtonSize.small,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendedVersions.length,
                  itemBuilder: (context, index) {
                    return _buildVersionCard(_recommendedVersions[index]);
                  },
                ),
              ),
      ],
    );
  }

  /// 构建版本卡片
  Widget _buildVersionCard(Version version) {
    final isRelease = version.type.toString() == 'release';
    
    return BamcCard(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      width: 200,
      onTap: () => _launchGame(version),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本图标区域
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.background,
                  BamcColors.backgroundDark,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BamcColors.borderLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isRelease ? Icons.gamepad_rounded : Icons.science_rounded,
                size: 40,
                color: isRelease ? BamcColors.primary : BamcColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 版本名称
          Text(
            'Minecraft ${version.id}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // 版本类型标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isRelease
                  ? BamcColors.successSurface
                  : BamcColors.accentSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isRelease
                    ? BamcColors.success.withValues(alpha: 0.3)
                    : BamcColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              isRelease ? '稳定版' : '快照版',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isRelease ? BamcColors.successDark : BamcColors.accentDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 启动按钮
          SizedBox(
            width: double.infinity,
            child: BamcButton(
              text: '启动游戏',
              onPressed: () => _launchGame(version),
              type: BamcButtonType.primary,
              size: BamcButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGame(Version version) async {
    try {
      final selectedAccount = widget.accountManager.selectedAccount;
      if (selectedAccount == null) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '请先选择一个账户');
        }
        return;
      }

      final javaResult = await widget.gameLauncher.detectJava();
      if (!javaResult.found) {
        if (mounted) {
          ErrorDialog.show(context, '错误', '未找到Java环境: ${javaResult.error}');
        }
        return;
      }

      final config = await widget.gameLauncher.buildLaunchConfig(
        gameVersion: version.id,
        username: selectedAccount.username,
        uuid: selectedAccount.id,
        accessToken: selectedAccount.tokenData?.accessToken ?? '',
        memoryMb: 4096,
      );

      await widget.gameLauncher.launchGame(config);
      logger.info('Game launched successfully: ${version.id}');
    } catch (e) {
      logger.error('Failed to launch game: $e');
      if (mounted) {
        ErrorDialog.show(context, '启动失败', '无法启动游戏: $e');
      }
    }
  }
}
