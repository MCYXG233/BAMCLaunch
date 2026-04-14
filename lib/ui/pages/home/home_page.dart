import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/layout/bamc_card.dart';

class HomePage extends StatefulWidget {
  final IVersionManager versionManager;
  
  const HomePage({super.key, required this.versionManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  int _installedVersionsCount = 0;
  List<Version> _recommendedVersions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 加载已安装版本数量
      final installedVersions = await widget.versionManager.getInstalledVersions();
      setState(() => _installedVersionsCount = installedVersions.length);

      // 加载推荐版本（最新稳定版）
      final manifest = await widget.versionManager.getVersionManifest();
      final latestRelease = manifest.versions.firstWhere(
        (v) => v.type == 'release',
        orElse: () => manifest.versions.first,
      );
      
      final latestVersion = await widget.versionManager.getVersionInfo(latestRelease.id);
      setState(() => _recommendedVersions = [latestVersion]);
    } catch (e) {
      logger.error('Failed to load home page data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎区域
          _buildWelcomeSection(),
          const SizedBox(height: 32),

          // 快速启动区域
          _buildQuickLaunchSection(),
          const SizedBox(height: 32),

          // 统计信息区域
          _buildStatisticsSection(),
          const SizedBox(height: 32),

          // 推荐版本区域
          _buildRecommendedVersionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary,
            BamcColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '欢迎回来！',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '准备好开始新的冒险了吗？',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLaunchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速启动',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
          childAspectRatio: 2,
          children: [
            _buildQuickLaunchCard(
              title: '最近启动',
              icon: Icons.history,
              color: BamcColors.primary,
              onTap: () {
                // 导航到版本管理页面
                Navigator.pushNamed(context, '/versions');
              },
            ),
            _buildQuickLaunchCard(
              title: '创建新游戏',
              icon: Icons.add,
              color: BamcColors.secondary,
              onTap: () {
                // 导航到版本管理页面的安装版本功能
                Navigator.pushNamed(context, '/versions');
              },
            ),
            _buildQuickLaunchCard(
              title: '导入整合包',
              icon: Icons.import_export,
              color: BamcColors.success,
              onTap: () {
                // 导航到整合包页面
                Navigator.pushNamed(context, '/modpacks');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLaunchCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: BamcCard(
        padding: const EdgeInsets.all(16),
        elevation: 4,
        hoverable: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
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

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '统计信息',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                title: '已安装版本',
                value: _installedVersionsCount.toString(),
                icon: Icons.gamepad,
                color: BamcColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatisticCard(
                title: '已安装模组',
                value: '0', // 暂时显示0，后续集成模组管理
                icon: Icons.extension,
                color: BamcColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatisticCard(
                title: '游戏时长',
                value: '0h', // 暂时显示0，后续集成游戏时长统计
                icon: Icons.timer,
                color: BamcColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return BamcCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: BamcColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BamcColors.textPrimary,
              ),
            ),
            BamcButton(
              text: '查看全部',
              onPressed: () {
                // 导航到版本管理页面
                Navigator.pushNamed(context, '/versions');
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.small,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 200,
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

  Widget _buildVersionCard(Version version) {
    return BamcCard(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      width: 200,
      elevation: 4,
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: BamcColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.gamepad,
                size: 48,
                color: BamcColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Minecraft ${version.id}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            version.type == 'release' ? '稳定版' : '快照版',
            style: TextStyle(
              fontSize: 12,
              color: version.type == 'release' ? BamcColors.success : BamcColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BamcButton(
              text: '启动游戏',
              onPressed: () async {
                // 这里应该调用游戏启动逻辑
                logger.info('Starting game version: ${version.id}');
              },
              type: BamcButtonType.primary,
              size: BamcButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }
}
