import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/models.dart';
import '../components/ba_notification.dart';
import '../animations/ba_animations.dart';
import '../animations/ba_effects.dart';
import 'ba_resource_detail_page.dart';

class BAResourceCenterPage extends StatefulWidget {
  const BAResourceCenterPage({super.key});

  @override
  State<BAResourceCenterPage> createState() => _BAResourceCenterPageState();
}

class _BAResourceCenterPageState extends State<BAResourceCenterPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SearchService _searchService = SearchService();

  // 收藏（全局共享）
  final Set<String> _favoriteIds = {};

  static const int _pageSize = 20;

  // ==================== Tab 0: Modrinth 源 ====================
  final TextEditingController _modrinthSearchCtrl = TextEditingController();
  final ScrollController _modrinthScrollCtrl = ScrollController();
  List<Resource> _modrinthResources = [];
  bool _modrinthLoading = false;
  bool _modrinthLoadingMore = false;
  bool _modrinthHasMore = true;
  String? _modrinthError;
  String _modrinthQuery = '';
  ResourceType? _modrinthType;
  String _modrinthSort = 'downloads';
  int _modrinthPage = 1;
  String? _modrinthGameVersion;
  String? _modrinthLoader;

  // ==================== Tab 2: 热门整合包 ====================
  final TextEditingController _modpackSearchCtrl = TextEditingController();
  final ScrollController _modpackScrollCtrl = ScrollController();
  List<Resource> _modpackResources = [];
  bool _modpackLoading = false;
  bool _modpackLoadingMore = false;
  bool _modpackHasMore = true;
  String? _modpackError;
  String _modpackQuery = '';
  String _modpackSort = 'downloads';
  int _modpackPage = 1;
  String? _modpackGameVersion;
  String? _modpackLoader;

  // ==================== 常量 ====================
  static const _modrinthTypeOptions = <MapEntry<String, ResourceType?>>[
    MapEntry('全部', null),
    MapEntry('模组', ResourceType.mod),
    MapEntry('资源包', ResourceType.resourcePack),
    MapEntry('整合包', ResourceType.modpack),
    MapEntry('光影包', ResourceType.shader),
    MapEntry('数据包', ResourceType.dataPack),
  ];

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('downloads', '最多下载'),
    MapEntry('newest', '最新发布'),
    MapEntry('updated', '最近更新'),
    MapEntry('name', '按名称'),
  ];

  static const _gameVersions = [
    '1.21.4', '1.21.1', '1.20.6', '1.20.4', '1.20.1',
    '1.19.4', '1.18.2', '1.16.5', '1.12.2',
  ];

  static const _loaders = <MapEntry<String, String>>[
    MapEntry('fabric', 'Fabric'),
    MapEntry('forge', 'Forge'),
    MapEntry('quilt', 'Quilt'),
    MapEntry('neoforge', 'NeoForge'),
  ];

  static const Map<ResourceType?, IconData> _typeIcons = {
    null: Icons.apps,
    ResourceType.mod: Icons.extension,
    ResourceType.resourcePack: Icons.palette,
    ResourceType.modpack: Icons.inventory_2,
    ResourceType.shader: Icons.lightbulb,
    ResourceType.dataPack: Icons.folder_copy,
  };

  static Map<ResourceType?, Color> _typeColorsOf(BuildContext context) => {
    null: BAColors.primaryOf(context),
    ResourceType.mod: BAColors.accentPinkOf(context),
    ResourceType.resourcePack: BAColors.successOf(context),
    ResourceType.modpack: BAColors.warningOf(context),
    ResourceType.shader: const Color(0xFFE6C46A),
    ResourceType.dataPack: const Color(0xFF7AA5D6),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _modrinthScrollCtrl.addListener(_onModrinthScroll);
    _modpackScrollCtrl.addListener(_onModpackScroll);
    _tabController.addListener(_onTabChanged);
    _performModrinthSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _modrinthSearchCtrl.dispose();
    _modrinthScrollCtrl.dispose();
    _modpackSearchCtrl.dispose();
    _modpackScrollCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // 切换到热门整合包时自动加载
    if (_tabController.index == 2 && _modpackResources.isEmpty && !_modpackLoading) {
      _performModpackSearch();
    }
  }

  // ==================== Modrinth 搜索逻辑 ====================

  void _onModrinthScroll() {
    if (_modrinthScrollCtrl.position.pixels >=
        _modrinthScrollCtrl.position.maxScrollExtent - 300) {
      if (!_modrinthLoadingMore && _modrinthHasMore && !_modrinthLoading) {
        _loadMoreModrinth();
      }
    }
  }

  Future<void> _performModrinthSearch() async {
    if (!mounted) return;
    setState(() {
      _modrinthLoading = true;
      _modrinthError = null;
      _modrinthPage = 1;
      _modrinthHasMore = true;
    });

    try {
      final params = SearchParams(
        query: _modrinthQuery,
        type: _modrinthType,
        page: 1,
        pageSize: _pageSize,
        sortBy: _modrinthSort,
        gameVersions: _modrinthGameVersion != null ? [_modrinthGameVersion!] : null,
        loaders: _modrinthLoader != null ? [_modrinthLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _modrinthResources = result.resources;
        _modrinthHasMore = result.resources.length >= _pageSize;
        _modrinthLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modrinthError = e.toString();
        _modrinthLoading = false;
      });
    }
  }

  Future<void> _loadMoreModrinth() async {
    if (_modrinthLoadingMore || !_modrinthHasMore) return;
    if (!mounted) return;
    setState(() => _modrinthLoadingMore = true);

    try {
      final nextPage = _modrinthPage + 1;
      final params = SearchParams(
        query: _modrinthQuery,
        type: _modrinthType,
        page: nextPage,
        pageSize: _pageSize,
        sortBy: _modrinthSort,
        gameVersions: _modrinthGameVersion != null ? [_modrinthGameVersion!] : null,
        loaders: _modrinthLoader != null ? [_modrinthLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _modrinthPage = nextPage;
        _modrinthResources.addAll(result.resources);
        _modrinthHasMore = result.resources.length >= _pageSize;
        _modrinthLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _modrinthLoadingMore = false);
      NotificationManager().showError('加载失败', message: e.toString());
    }
  }

  // ==================== 热门整合包搜索逻辑 ====================

  void _onModpackScroll() {
    if (_modpackScrollCtrl.position.pixels >=
        _modpackScrollCtrl.position.maxScrollExtent - 300) {
      if (!_modpackLoadingMore && _modpackHasMore && !_modpackLoading) {
        _loadMoreModpack();
      }
    }
  }

  Future<void> _performModpackSearch() async {
    if (!mounted) return;
    setState(() {
      _modpackLoading = true;
      _modpackError = null;
      _modpackPage = 1;
      _modpackHasMore = true;
    });

    try {
      final params = SearchParams(
        query: _modpackQuery,
        type: ResourceType.modpack,
        page: 1,
        pageSize: _pageSize,
        sortBy: _modpackSort,
        gameVersions: _modpackGameVersion != null ? [_modpackGameVersion!] : null,
        loaders: _modpackLoader != null ? [_modpackLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _modpackResources = result.resources;
        _modpackHasMore = result.resources.length >= _pageSize;
        _modpackLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modpackError = e.toString();
        _modpackLoading = false;
      });
    }
  }

  Future<void> _loadMoreModpack() async {
    if (_modpackLoadingMore || !_modpackHasMore) return;
    if (!mounted) return;
    setState(() => _modpackLoadingMore = true);

    try {
      final nextPage = _modpackPage + 1;
      final params = SearchParams(
        query: _modpackQuery,
        type: ResourceType.modpack,
        page: nextPage,
        pageSize: _pageSize,
        sortBy: _modpackSort,
        gameVersions: _modpackGameVersion != null ? [_modpackGameVersion!] : null,
        loaders: _modpackLoader != null ? [_modpackLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _modpackPage = nextPage;
        _modpackResources.addAll(result.resources);
        _modpackHasMore = result.resources.length >= _pageSize;
        _modpackLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _modpackLoadingMore = false);
      NotificationManager().showError('加载失败', message: e.toString());
    }
  }

  // ==================== 通用操作 ====================

  void _toggleFavorite(String resourceId) {
    setState(() {
      if (_favoriteIds.contains(resourceId)) {
        _favoriteIds.remove(resourceId);
      } else {
        _favoriteIds.add(resourceId);
      }
    });
  }

  void _onResourceTap(Resource resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceDetailPage(
          resource: resource,
          isFavorite: _favoriteIds.contains(resource.id),
          onFavoriteToggle: () => _toggleFavorite(resource.id),
        ),
      ),
    );
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    } else if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildTabBar(context),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildModrinthTab(context),
              _buildCurseForgeTab(context),
              _buildModpackTab(context),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- 顶部标题栏 ----------

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 24, 0),
      child: Row(
        children: [
          BAAnimations.breathe(
            isActive: true,
            duration: const Duration(milliseconds: 3000),
            minOpacity: 0.85,
            maxOpacity: 1.0,
            glowRadius: 10.0,
            glowColor: BAColors.primaryOf(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BAColors.primaryLightOf(context),
                    BAColors.primaryOf(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.extension,
                color: Color(0xFFFFFFFF),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '资源中心',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '浏览和下载 Mod、资源包、整合包',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 资源数量指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                Icon(Icons.inventory_2,
                    color: BAColors.textPrimaryOf(context).withValues(alpha: 0.85),
                    size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_currentResourceCount()} 个资源',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context).withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _currentResourceCount() {
    switch (_tabController.index) {
      case 0:
        return _modrinthResources.length;
      case 1:
        return 0; // CurseForge
      case 2:
        return _modpackResources.length;
      default:
        return 0;
    }
  }

  // ---------- Tab 栏 ----------

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BAColors.primaryOf(context).withValues(alpha: 0.2),
              BAColors.primaryOf(context).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: BAColors.primaryOf(context).withValues(alpha: 0.4),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: BAColors.primaryOf(context),
        unselectedLabelColor: BAColors.textSecondaryOf(context),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelPadding: EdgeInsets.zero,
        indicatorPadding: const EdgeInsets.all(3),
        tabs: [
          _buildTab(Icons.cloud_outlined, 'Modrinth 源'),
          _buildTab(Icons.construction_outlined, 'CurseForge 源'),
          _buildTab(Icons.inventory_2_outlined, '热门整合包'),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ================================================================
  //  Modrinth 源 Tab
  // ================================================================

  Widget _buildModrinthTab(BuildContext context) {
    return Column(
      children: [
        _buildModrinthFilterBar(context),
        const SizedBox(height: 8),
        Expanded(child: _buildModrinthGrid(context)),
      ],
    );
  }

  Widget _buildModrinthFilterBar(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final border = BAColors.borderOf(context).withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BAColors.backgroundSecondaryOf(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // 搜索行
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _modrinthSearchCtrl,
                    onSubmitted: (v) {
                      _modrinthQuery = v;
                      _performModrinthSearch();
                    },
                    style: TextStyle(
                        color: textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '搜索模组、资源包、整合包...',
                      hintStyle: TextStyle(
                          color: BAColors.textDisabledOf(context)),
                      prefixIcon: Icon(Icons.search,
                          color: textSecondary, size: 16),
                      suffixIcon: _modrinthQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: textSecondary, size: 14),
                              onPressed: () {
                                _modrinthSearchCtrl.clear();
                                _modrinthQuery = '';
                                _performModrinthSearch();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: BAColors.surfaceVariantOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 排序菜单
              _buildSortButton(
                currentSort: _modrinthSort,
                onSelected: (v) {
                  _modrinthSort = v;
                  _performModrinthSearch();
                },
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 6),
              // 游戏版本
              _buildCompactDropdown(
                value: _modrinthGameVersion,
                hint: '版本',
                items: _gameVersions,
                onChanged: (v) {
                  _modrinthGameVersion = v;
                  _performModrinthSearch();
                },
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 6),
              // 加载器
              _buildCompactDropdown(
                value: _modrinthLoader,
                hint: '加载器',
                items: _loaders.map((e) => e.value).toList(),
                displayItems: _loaders.map((e) => e.key).toList(),
                onChanged: (v) {
                  _modrinthLoader = v;
                  _performModrinthSearch();
                },
                textPrimary: textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 类型筛选 Chips
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _modrinthTypeOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final opt = _modrinthTypeOptions[index];
                final selected = _modrinthType == opt.value;
                final color = _typeColorsOf(context)[opt.value] ??
                    BAColors.primaryOf(context);
                return _buildTypeChip(
                  label: opt.key,
                  icon: _typeIcons[opt.value] ?? Icons.apps,
                  selected: selected,
                  color: color,
                  onTap: () {
                    _modrinthType = opt.value;
                    _performModrinthSearch();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModrinthGrid(BuildContext context) {
    if (_modrinthLoading) {
      return _buildLoadingPlaceholder(context);
    }
    if (_modrinthError != null) {
      return _buildErrorWidget(context, _modrinthError!, _performModrinthSearch);
    }
    if (_modrinthResources.isEmpty) {
      return _buildEmptyWidget(context, '没有找到相关资源', '尝试调整筛选条件');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAColors.backgroundSecondaryOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calcColumns(constraints.maxWidth);
          return GridView.builder(
            controller: _modrinthScrollCtrl,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemCount: _modrinthResources.length + (_modrinthLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _modrinthResources.length) {
                return _buildGridLoadingMore(context);
              }
              return _buildResourceGridCard(context, _modrinthResources[index]);
            },
          );
        },
      ),
    );
  }

  // ================================================================
  //  CurseForge 源 Tab（占位）
  // ================================================================

  Widget _buildCurseForgeTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BAAnimations.breathe(
            isActive: true,
            duration: const Duration(milliseconds: 3000),
            minOpacity: 0.7,
            maxOpacity: 1.0,
            glowRadius: 14,
            glowColor: const Color(0xFFF16436),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF16436), Color(0xFFD94412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF16436).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CurseForge 源',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '即将接入，敬请期待',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context)
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BAColors.borderOf(context).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    size: 14,
                    color: BAColors.textSecondaryOf(context)),
                const SizedBox(width: 8),
                Text(
                  '需要配置 CurseForge API Key 后启用',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  //  热门整合包 Tab
  // ================================================================

  Widget _buildModpackTab(BuildContext context) {
    return Column(
      children: [
        _buildModpackFilterBar(context),
        const SizedBox(height: 8),
        Expanded(child: _buildModpackGrid(context)),
      ],
    );
  }

  Widget _buildModpackFilterBar(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final border = BAColors.borderOf(context).withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BAColors.backgroundSecondaryOf(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          // 整合包标识
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.warningOf(context).withValues(alpha: 0.2),
                  BAColors.warningOf(context).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BAColors.warningOf(context).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2,
                    size: 14, color: BAColors.warningOf(context)),
                const SizedBox(width: 6),
                Text(
                  '整合包',
                  style: TextStyle(
                    color: BAColors.warningOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 搜索框
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _modpackSearchCtrl,
                onSubmitted: (v) {
                  _modpackQuery = v;
                  _performModpackSearch();
                },
                style: TextStyle(color: textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '搜索整合包...',
                  hintStyle:
                      TextStyle(color: BAColors.textDisabledOf(context)),
                  prefixIcon: Icon(Icons.search,
                      color: textSecondary, size: 16),
                  suffixIcon: _modpackQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: textSecondary, size: 14),
                          onPressed: () {
                            _modpackSearchCtrl.clear();
                            _modpackQuery = '';
                            _performModpackSearch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: BAColors.surfaceVariantOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildSortButton(
            currentSort: _modpackSort,
            onSelected: (v) {
              _modpackSort = v;
              _performModpackSearch();
            },
            textPrimary: textPrimary,
          ),
          const SizedBox(width: 6),
          _buildCompactDropdown(
            value: _modpackGameVersion,
            hint: '版本',
            items: _gameVersions,
            onChanged: (v) {
              _modpackGameVersion = v;
              _performModpackSearch();
            },
            textPrimary: textPrimary,
          ),
          const SizedBox(width: 6),
          _buildCompactDropdown(
            value: _modpackLoader,
            hint: '加载器',
            items: _loaders.map((e) => e.value).toList(),
            displayItems: _loaders.map((e) => e.key).toList(),
            onChanged: (v) {
              _modpackLoader = v;
              _performModpackSearch();
            },
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildModpackGrid(BuildContext context) {
    if (_modpackLoading) {
      return _buildLoadingPlaceholder(context);
    }
    if (_modpackError != null) {
      return _buildErrorWidget(context, _modpackError!, _performModpackSearch);
    }
    if (_modpackResources.isEmpty) {
      return _buildEmptyWidget(context, '暂无整合包数据', '稍后再试或调整筛选条件');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAColors.backgroundSecondaryOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calcColumns(constraints.maxWidth);
          return GridView.builder(
            controller: _modpackScrollCtrl,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemCount: _modpackResources.length + (_modpackLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _modpackResources.length) {
                return _buildGridLoadingMore(context);
              }
              return _buildResourceGridCard(context, _modpackResources[index]);
            },
          );
        },
      ),
    );
  }

  // ================================================================
  //  共享 UI 组件
  // ================================================================

  /// 根据宽度计算列数
  int _calcColumns(double width) {
    if (width >= 1200) return 3;
    if (width >= 700) return 2;
    return 2;
  }

  /// 排序按钮
  Widget _buildSortButton({
    required String currentSort,
    required ValueChanged<String> onSelected,
    required Color textPrimary,
  }) {
    final label = _sortOptions
        .firstWhere((e) => e.key == currentSort,
            orElse: () => const MapEntry('downloads', '最多下载'))
        .value;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: BAColors.backgroundSecondaryOf(context),
      itemBuilder: (_) => _sortOptions
          .map((opt) => PopupMenuItem(
                value: opt.key,
                height: 36,
                child: Row(
                  children: [
                    if (currentSort == opt.key)
                      Icon(Icons.check,
                          size: 14, color: BAColors.primaryOf(context))
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 8),
                    Text(
                      opt.value,
                      style: TextStyle(
                        color: currentSort == opt.key
                            ? BAColors.primaryOf(context)
                            : textPrimary,
                        fontSize: 12,
                        fontWeight: currentSort == opt.key
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 14, color: textPrimary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: textPrimary, fontSize: 11)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                size: 14, color: textPrimary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  /// 紧凑下拉选择
  Widget _buildCompactDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    List<String>? displayItems,
    required ValueChanged<String?> onChanged,
    required Color textPrimary,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          hint: Text(hint,
              style: TextStyle(
                  color: textPrimary.withValues(alpha: 0.5), fontSize: 11)),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 14, color: textPrimary.withValues(alpha: 0.6)),
          dropdownColor: BAColors.backgroundSecondaryOf(context),
          style: TextStyle(color: textPrimary, fontSize: 11),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('全部', style: TextStyle(fontSize: 11, color: textPrimary)),
            ),
            ...List.generate(items.length, (i) {
              return DropdownMenuItem<String>(
                value: items[i],
                child: Text(displayItems != null ? displayItems[i] : items[i]),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// 类型筛选 Chip
  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected
                    ? color
                    : BAColors.textSecondaryOf(context).withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : BAColors.textPrimaryOf(context),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 资源网格卡片 ----------

  Widget _buildResourceGridCard(BuildContext context, Resource resource) {
    final typeColors = _typeColorsOf(context);
    final typeColor = typeColors[resource.type] ?? BAColors.primaryOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    return _HoverScaleCard(
      onTap: () => _onResourceTap(resource),
      hoverBorderColor: typeColor,
      defaultBorderColor: BAColors.borderOf(context).withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // 左侧：图标
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor.withValues(alpha: 0.2),
                    typeColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: resource.iconUrl != null
                    ? Image.network(
                        resource.iconUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            _typeIcons[resource.type] ?? Icons.apps,
                            size: 26,
                            color: typeColor,
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: typeColor,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          _typeIcons[resource.type] ?? Icons.apps,
                          size: 26,
                          color: typeColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // 中间：信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 名称行
                  Text(
                    resource.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 描述（1行）
                  Text(
                    resource.description.isNotEmpty
                        ? resource.description
                        : resource.summary ?? '',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // 标签行：分类 + 游戏版本
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [
                      // 分类标签（最多2个）
                      ...resource.categories.take(2).map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: BAColors.backgroundSecondaryOf(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: textSecondary, fontSize: 9)),
                        ),
                      ),
                      // 游戏版本
                      if (resource.supportedGameVersions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: BAColors.primaryOf(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource.supportedGameVersions.first,
                            style: TextStyle(
                              color: BAColors.primaryOf(context),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 右侧：作者 + 下载量
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 作者
                if (resource.authors.isNotEmpty)
                  Text(
                    resource.authors.first.name,
                    style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.8),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // 下载量
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download,
                        size: 11,
                        color: textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 2),
                    Text(
                      _formatDownloads(resource.downloads),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 收藏按钮
                GestureDetector(
                  onTap: () => _toggleFavorite(resource.id),
                  child: BAAnimations.pulse(
                    isActive: _favoriteIds.contains(resource.id),
                    duration: const Duration(milliseconds: 1200),
                    scaleBegin: 1.0,
                    scaleEnd: 1.2,
                    child: Icon(
                      _favoriteIds.contains(resource.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoriteIds.contains(resource.id)
                          ? BAColors.dangerOf(context)
                          : textSecondary.withValues(alpha: 0.5),
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 状态 Widget ----------

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Center(
      child: BAEffects.shimmer(
        isActive: true,
        baseColor: BAColors.surfaceVariantOf(context),
        highlightColor: BAColors.surfaceOf(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: BAColors.primaryOf(context),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '正在加载资源...',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              color: BAColors.dangerOf(context), size: 36),
          const SizedBox(height: 12),
          Text(
            '加载失败',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primaryOf(context),
              foregroundColor: BAColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(
      BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.5),
              size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLoadingMore(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: BAColors.primaryOf(context),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

/// 悬停缩放卡片 - 鼠标悬停时提供缩放和阴影增强效果
class _HoverScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color hoverBorderColor;
  final Color defaultBorderColor;

  const _HoverScaleCard({
    required this.child,
    this.onTap,
    required this.hoverBorderColor,
    required this.defaultBorderColor,
  });

  @override
  State<_HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<_HoverScaleCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: 0.04 + 0.06 * _shadowAnimation.value),
                      blurRadius: 8 + 12 * _shadowAnimation.value,
                      offset: Offset(0, 2 + 4 * _shadowAnimation.value),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: widget.hoverBorderColor
                            .withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
