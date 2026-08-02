import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../instance/models.dart';
import '../../../resource_center/search_service.dart';
import '../../../resource_center/models.dart';
import '../../components/ba_notification.dart';
import '../ba_resource_detail_page.dart';
import 'curseforge/curseforge_tab.dart';
import 'modrinth/modrinth_tab.dart';
import 'modpack/modpack_tab.dart';

/// 资源中心页面
///
/// 提供Modrinth源、CurseForge源、热门整合包三个 Tab 的浏览能力
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

  String _selectedSource = 'modrinth';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    if (_tabController.index == 1 &&
        _modpackResources.isEmpty &&
        !_modpackLoading) {
      _performModpackSearch();
    }
  }

  // ==================== Modrinth 搜索逻辑 ====================

  void _onModrinthScroll() {
    try {
      if (_modrinthScrollCtrl.position.pixels >=
          _modrinthScrollCtrl.position.maxScrollExtent - 300) {
        if (!_modrinthLoadingMore && _modrinthHasMore && !_modrinthLoading) {
          _loadMoreModrinth();
        }
      }
    } catch (_) {
      // 控制器已释放时忽略
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
        gameVersions: _modrinthGameVersion != null
            ? [_modrinthGameVersion!]
            : null,
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
        gameVersions: _modrinthGameVersion != null
            ? [_modrinthGameVersion!]
            : null,
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
    try {
      if (_modpackScrollCtrl.position.pixels >=
          _modpackScrollCtrl.position.maxScrollExtent - 300) {
        if (!_modpackLoadingMore && _modpackHasMore && !_modpackLoading) {
          _loadMoreModpack();
        }
      }
    } catch (_) {
      // 控制器已释放时忽略
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
        gameVersions: _modpackGameVersion != null
            ? [_modpackGameVersion!]
            : null,
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
        gameVersions: _modpackGameVersion != null
            ? [_modpackGameVersion!]
            : null,
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
        _buildTabBar(context),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RepaintBoundary(
                child: _selectedSource == 'curseforge'
                    ? const CurseForgeTab()
                    : ModrinthTab(
                        searchController: _modrinthSearchCtrl,
                        scrollController: _modrinthScrollCtrl,
                        resources: _modrinthResources,
                        loading: _modrinthLoading,
                        loadingMore: _modrinthLoadingMore,
                        error: _modrinthError,
                        query: _modrinthQuery,
                        sort: _modrinthSort,
                        type: _modrinthType,
                        gameVersion: _modrinthGameVersion,
                        loader: _modrinthLoader,
                        favoriteIds: _favoriteIds,
                        formatDownloads: _formatDownloads,
                        onRetry: _performModrinthSearch,
                        onQuerySubmitted: (v) {
                          _modrinthQuery = v;
                          _performModrinthSearch();
                        },
                        onQueryCleared: () {
                          _modrinthSearchCtrl.clear();
                          _modrinthQuery = '';
                          _performModrinthSearch();
                        },
                        onSortChanged: (v) {
                          _modrinthSort = v;
                          _performModrinthSearch();
                        },
                        onTypeChanged: (v) {
                          _modrinthType = v;
                          _performModrinthSearch();
                        },
                        onGameVersionChanged: (v) {
                          _modrinthGameVersion = v;
                          _performModrinthSearch();
                        },
                        onLoaderChanged: (v) {
                          _modrinthLoader = v;
                          _performModrinthSearch();
                        },
                        onResourceTap: _onResourceTap,
                        onToggleFavorite: _toggleFavorite,
                      ),
              ),
              RepaintBoundary(
                child: ModpackTab(
                  searchController: _modpackSearchCtrl,
                  scrollController: _modpackScrollCtrl,
                  resources: _modpackResources,
                  loading: _modpackLoading,
                  loadingMore: _modpackLoadingMore,
                  error: _modpackError,
                  query: _modpackQuery,
                  sort: _modpackSort,
                  gameVersion: _modpackGameVersion,
                  loader: _modpackLoader,
                  favoriteIds: _favoriteIds,
                  formatDownloads: _formatDownloads,
                  onRetry: _performModpackSearch,
                  onQuerySubmitted: (v) {
                    _modpackQuery = v;
                    _performModpackSearch();
                  },
                  onQueryCleared: () {
                    _modpackSearchCtrl.clear();
                    _modpackQuery = '';
                    _performModpackSearch();
                  },
                  onSortChanged: (v) {
                    _modpackSort = v;
                    _performModpackSearch();
                  },
                  onGameVersionChanged: (v) {
                    _modpackGameVersion = v;
                    _performModpackSearch();
                  },
                  onLoaderChanged: (v) {
                    _modpackLoader = v;
                    _performModpackSearch();
                  },
                  onResourceTap: _onResourceTap,
                  onToggleFavorite: _toggleFavorite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- 顶部标题栏 ----------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：图标 + 标题 + 副信息（与游戏库页统一格式）
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(
                        context,
                      ).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '资源中心',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currentResourceCount()} 个资源',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildSourceSelector(context),
        ],
      ),
    );
  }

  int _currentResourceCount() {
    switch (_tabController.index) {
      case 0:
        return _selectedSource == 'curseforge' ? 0 : _modrinthResources.length;
      case 1:
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
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        indicatorPadding: const EdgeInsets.all(3),
        tabs: [
          _buildTab(Icons.explore_outlined, '资源浏览'),
          _buildTab(Icons.local_fire_department_outlined, '热门推荐'),
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
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSourceSelector(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final primary = BAColors.primaryOf(context);
    final isModrinth = _selectedSource == 'modrinth';

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == _selectedSource) return;
        setState(() => _selectedSource = value);
      },
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: BAColors.backgroundSecondaryOf(context),
      itemBuilder: (_) => [
        _buildSourceMenuItem(
          'modrinth',
          'Modrinth',
          Icons.cloud_outlined,
          const Color(0xFF1BD96A),
          isModrinth,
          textPrimary,
          primary,
        ),
        _buildSourceMenuItem(
          'curseforge',
          'CurseForge',
          Icons.construction_outlined,
          const Color(0xFFF16436),
          !isModrinth,
          textPrimary,
          primary,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isModrinth ? Icons.cloud_outlined : Icons.construction_outlined,
              color: isModrinth
                  ? const Color(0xFF1BD96A)
                  : const Color(0xFFF16436),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isModrinth ? 'Modrinth' : 'CurseForge',
              style: TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSourceMenuItem(
    String value,
    String label,
    IconData icon,
    Color color,
    bool selected,
    Color textPrimary,
    Color primary,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          if (selected)
            Icon(Icons.check, size: 14, color: primary)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? primary : textPrimary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
