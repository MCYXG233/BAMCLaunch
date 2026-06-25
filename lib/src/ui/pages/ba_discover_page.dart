import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';
import '../components/ba_common_widgets.dart';

/// 发现页面
/// 整合新闻动态、资源下载、搜索功能
class BADiscoverPage extends StatefulWidget {
  const BADiscoverPage({super.key});

  @override
  State<BADiscoverPage> createState() => _BADiscoverPageState();
}

class _BADiscoverPageState extends State<BADiscoverPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和搜索
          _buildHeader(isLight),
          const SizedBox(height: 16),

          // 搜索框
          _buildSearchBar(isLight),
          const SizedBox(height: 16),

          // 标签页
          _buildTabBar(isLight),
          const SizedBox(height: 16),

          // 内容区
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isLight) {
    return Row(
      children: [
        Icon(
          Icons.explore,
          color: BAThemeColors.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          '发现',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isLight ? BAThemeColors.textPrimary : BAThemeColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isLight) {
    return BAGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: '搜索模组、资源包、光影...',
          hintStyle: TextStyle(
            color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isLight) {
    return BAGlassContainer(
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
        indicator: BoxDecoration(
          color: BAThemeColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '热门'),
          Tab(text: '最新'),
          Tab(text: '分类'),
          Tab(text: '我的下载'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildHotContent(),
        _buildLatestContent(),
        _buildCategoryContent(),
        _buildMyDownloadsContent(),
      ],
    );
  }

  Widget _buildHotContent() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildResourceCard(
          title: '热门资源 ${index + 1}',
          subtitle: '这是一个热门的模组或资源包',
          icon: Icons.star,
          downloads: '${(index + 1) * 1000}',
        );
      },
    );
  }

  Widget _buildLatestContent() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildNewsCard(
          title: 'Minecraft 新闻 ${index + 1}',
          summary: '这是最新的 Minecraft 相关新闻...',
          time: '${index + 1} 小时前',
        );
      },
    );
  }

  Widget _buildCategoryContent() {
    final categories = [
      {'name': '模组', 'icon': Icons.extension, 'count': '10,000+'},
      {'name': '资源包', 'icon': Icons.palette, 'count': '5,000+'},
      {'name': '光影包', 'icon': Icons.lightbulb, 'count': '1,000+'},
      {'name': '整合包', 'icon': Icons.inventory_2, 'count': '500+'},
      {'name': '地图', 'icon': Icons.map, 'count': '2,000+'},
      {'name': '数据包', 'icon': Icons.dataset, 'count': '3,000+'},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          name: category['name'] as String,
          icon: category['icon'] as IconData,
          count: category['count'] as String,
        );
      },
    );
  }

  Widget _buildMyDownloadsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无下载记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String downloads,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return BAGlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BAThemeColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLight ? BAThemeColors.textPrimary : BAThemeColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.download,
                size: 14,
                color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                downloads,
                style: TextStyle(
                  fontSize: 11,
                  color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String summary,
    required String time,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BAGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: BAThemeColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.article,
                color: BAThemeColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLight ? BAThemeColors.textPrimary : BAThemeColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required IconData icon,
    required String count,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return BAGlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: BAThemeColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isLight ? BAThemeColors.textPrimary : BAThemeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
