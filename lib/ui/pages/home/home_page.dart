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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isLoading = false;
  int _installedVersionsCount = 0;
  int _installedModsCount = 0;
  String _playTime = '0h';
  List<Version> _recommendedVersions = [];
  late AnimationController _characterAnimationController;
  late Animation<double> _characterAnimation;

  @override
  void initState() {
    super.initState();
    _characterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _characterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _characterAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _characterAnimationController.forward();
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

      final latestVersion =
          await widget.versionManager.getVersionInfo(latestRelease.id);
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
  void dispose() {
    _characterAnimationController.dispose();
    super.dispose();
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
          _buildBackgroundGradientOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCharacter(),
          _buildVersionInfo(),
          _buildModpackInfo(),
          _buildPlayTime(),
          _buildRecommendations(),
        ],
      ),
    );
  }
}
Stars() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.5,
        child: CustomPaint(
          painter: _StarFieldPainter(),
        ),
      ),
    );
  }

  Widget _buildOrbitalRings() {
    return Stack(
      children: [
        Positioned(
          top: 200,
          right: -150,
          child: AnimatedContainer(
            duration: const Duration(seconds: 25),
            curve: Curves.linear,
            width: 550,
            height: 550,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BamcColors.primary.withOpacity(0.12),
                width: 2,
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          right: -80,
          child: AnimatedContainer(
            duration: const Duration(seconds: 18),
            curve: Curves.linear,
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BamcColors.accent.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundGradientOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 500,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BamcColors.primary.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAccountInfo(selectedAccount),
          _buildTopActions(),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(Account? account) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: BamcColors.statPrimaryGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: BamcColors.primary.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: account != null
                ? const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account?.username ?? '未登录',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BamcColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Minecraft ID',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: BamcColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BamcColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    account?.id ?? '点击登录',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BamcColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        _buildTopActionButton('日志', Icons.book_outlined),
        const SizedBox(width: 12),
        _buildTopActionButton('背景', Icons.wallpaper_outlined),
        const SizedBox(width: 12),
        _buildTopActionButton('设置', Icons.settings_outlined),
      ],
    );
  }

  Widget _buildTopActionButton(String label, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: BamcColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BamcColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: BamcColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                  letterSpacing: 0.1,
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
            height: 400,
            decoration: BoxDecoration(
              gradient: BamcColors.welcomeGradientEnhanced,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.primary.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: BamcColors.accent.withOpacity(0.2),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '欢迎回来！',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '准备好开始新的冒险了吗？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(255, 255, 255, 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text(
                        '今日运势',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(255, 255, 255, 0.85),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '大吉',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: BamcColors.neonGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BamcColors.neonGreen.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '诸事顺遂',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: BamcColors.neonGreen,
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
            right: 40,
            bottom: -40,
            child: AnimatedBuilder(
              animation: _characterAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _characterAnimation.value) * 30),
                  child: Opacity(
                    opacity: _characterAnimation.value,
                    child: Container(
                      width: 260,
                      height: 340,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: BamcColors.accent.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                BamcColors.accent.withOpacity(0.1),
                                BamcColors.primary.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.girl,
                              size: 180,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
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
      type: BamcCardType.glass,
      padding: const EdgeInsets.all(22),
      hoverable: true,
      showGlow: true,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadowMedium,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: BamcColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: BamcColors.textSecondary,
              letterSpacing: 0.1,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              letterSpacing: 0.2,
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
              _buildTimeDisplay(),
              const SizedBox(width: 16),
              BamcButton(
                text: '启动游戏',
                onPressed: _launchGameQuick,
                type: BamcButtonType.primary,
                size: BamcButtonSize.large,
                icon: Icons.play_arrow_rounded,
                showGlow: true,
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
        type: BamcCardType.elevated,
        padding: const EdgeInsets.all(18),
        hoverable: true,
        glowColor: color,
        onTap: () {},
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BamcColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: BamcColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            DateTime.now().toString().split(' ')[1].split('.')[0],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: BamcColors.textSecondary,
              fontFamily: 'Monaco',
            ),
          ),
        ],
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                  letterSpacing: 0.2,
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
                  height: 260,
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
      type: BamcCardType.elevated,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(22),
      width: 240,
      hoverable: true,
      glowColor: isRelease ? BamcColors.neonBlue : BamcColors.accent,
      onTap: () => _launchGame(version),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.surfaceLight,
                  BamcColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BamcColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isRelease ? Icons.gamepad_rounded : Icons.science_rounded,
                size: 50,
                color: isRelease ? BamcColors.neonBlue : BamcColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Minecraft ${version.id}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isRelease
                  ? BamcColors.success.withOpacity(0.15)
                  : BamcColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRelease
                    ? BamcColors.success.withOpacity(0.4)
                    : BamcColors.accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              isRelease ? '稳定版' : '快照版',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isRelease ? BamcColors.success : BamcColors.accent,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: BamcButton(
              text: '启动游戏',
              onPressed: () => _launchGame(version),
              type: BamcButtonType.primary,
              size: BamcButtonSize.small,
              showGlow: true,
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

    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final starSize = random.nextDouble() * 2.5 + 0.3;
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