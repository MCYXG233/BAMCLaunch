import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/layout/bamc_card.dart';
import '../../components/dialogs/error_dialog.dart';

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
  bool _showCharacter = true;

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
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          _buildBackground(),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: BamcColors.backgroundStarsGradient,
      ),
      child: Stack(
        children: [
          _buildStars(),
          _buildOrbitalRings(),
        ],
      ),
    );
  }

  Widget _buildStars() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.6,
        child: CustomPaint(
          painter: _StarFieldPainter(),
        ),
      ),
    );
  }

  Widget _buildOrbitalRings() {
    return Positioned(
      top: 100,
      right: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: BamcColors.primary.withOpacity(0.15),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        _buildHeroSection(),
        _buildStatsSection(),
        _buildQuickActionsSection(),
        _buildVersionSection(),
      ],
    );
  }

  Widget _buildTopBar() {
    final selectedAccount = widget.accountManager.selectedAccount;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: BamcColors.statPrimaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BamcColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedAccount?.username ?? '未登录',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedAccount?.id ?? 'Minecraft ID',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildTopActionButton('日志', Icons.book_outlined),
              const SizedBox(width: 12),
              _buildTopActionButton('背景', Icons.wallpaper_outlined),
              const SizedBox(width: 12),
              _buildTopActionButton('设置', Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton(String label, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: BamcColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BamcColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: BamcColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: BamcColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              gradient: BamcColors.welcomeGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: BamcColors.accent.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '欢迎回来！',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '准备好开始新的冒险了吗？',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(255, 255, 255, 0.9),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text(
                        '今日运势',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(255, 255, 255, 0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '大吉',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -20,
            child: AnimatedOpacity(
              opacity: _showCharacter ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                width: 280,
                height: 360,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/character.png'),
                    fit: BoxFit.contain,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: '已安装版本',
              value: _installedVersionsCount.toString(),
              icon: Icons.gamepad_rounded,
              gradient: BamcColors.statPrimaryGradient,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: '已安装模组',
              value: _installedModsCount.toString(),
              icon: Icons.extension_rounded,
              gradient: BamcColors.statSecondaryGradient,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: '游戏时长',
              value: _playTime,
              icon: Icons.timer_rounded,
              gradient: BamcColors.statAccentGradient,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: '启动次数',
              value: '128',
              icon: Icons.rocket_launch_rounded,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.warningLight,
                  BamcColors.warning,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return BamcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: BamcColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                title: '功能1',
                icon: Icons.featured_play_list_rounded,
                color: BamcColors.primary,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                title: '功能2',
                icon: Icons.dashboard_rounded,
                color: BamcColors.secondary,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                title: '功能3',
                icon: Icons.widgets_rounded,
                color: BamcColors.accent,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                title: '功能4',
                icon: Icons.more_horiz_rounded,
                color: BamcColors.warning,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: BamcColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BamcColors.border,
                    width: 1,
                  ),
                ),
                child: const Text(
                  '时间显示',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              BamcButton(
                text: '启动游戏',
                onPressed: _launchGameQuick,
                type: BamcButtonType.primary,
                size: BamcButtonSize.large,
                icon: Icons.play_arrow_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: BamcCard(
        padding: const EdgeInsets.all(16),
        onTap: () {},
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
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
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedVersions.length,
                    itemBuilder: (context, index) {
                      return _buildVersionCard(_recommendedVersions[index]);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(Version version) {
    final isRelease = version.type.toString() == 'release';
    
    return BamcCard(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      width: 220,
      onTap: () => _launchGame(version),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.surfaceLight,
                  BamcColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BamcColors.borderLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isRelease ? Icons.gamepad_rounded : Icons.science_rounded,
                size: 44,
                color: isRelease ? BamcColors.primaryLight : BamcColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Minecraft ${version.id}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isRelease
                  ? BamcColors.success.withOpacity(0.15)
                  : BamcColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRelease
                    ? BamcColors.success.withOpacity(0.3)
                    : BamcColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              isRelease ? '稳定版' : '快照版',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isRelease ? BamcColors.success : BamcColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
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

  Future<void> _launchGameQuick() async {
    if (_recommendedVersions.isNotEmpty) {
      await _launchGame(_recommendedVersions.first);
    }
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

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final random = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final starSize = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.8 + 0.2;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}