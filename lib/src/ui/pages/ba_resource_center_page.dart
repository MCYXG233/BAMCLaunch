import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/models.dart';
import '../components/ba_notification.dart';
import 'ba_resource_detail_page.dart';

class BAResourceCenterPage extends StatefulWidget {
  const BAResourceCenterPage({super.key});

  @override
  State<BAResourceCenterPage> createState() => _BAResourceCenterPageState();
}

class _BAResourceCenterPageState extends State<BAResourceCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SearchService _searchService = SearchService();

  List<Resource> _resources = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  String _searchQuery = '';
  ResourceType? _selectedType;
  String _sortBy = 'downloads';
  int _currentPage = 1;

  String? _selectedGameVersion;
  String? _selectedLoader;

  bool _showOnlyFavorites = false;
  Set<String> _favoriteIds = {};

  static const int _pageSize = 20;

  static const _typeOptions = <MapEntry<String, ResourceType?>>[
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

  static const Map<ResourceType?, IconData> _typeIcons = {
    null: Icons.apps,
    ResourceType.mod: Icons.extension,
    ResourceType.resourcePack: Icons.palette,
    ResourceType.modpack: Icons.inventory_2,
    ResourceType.shader: Icons.lightbulb,
    ResourceType.dataPack: Icons.folder_copy,
  };

  static const Map<ResourceType?, Color> _typeColors = {
    null: BAColors.primary,
    ResourceType.mod: BAColors.accentPink,
    ResourceType.resourcePack: BAColors.success,
    ResourceType.modpack: BAColors.warning,
    ResourceType.shader: Color(0xFFE6C46A),
    ResourceType.dataPack: Color(0xFF7AA5D6),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final params = SearchParams(
        query: _searchQuery,
        type: _selectedType,
        page: 1,
        pageSize: _pageSize,
        sortBy: _sortBy,
        gameVersions: _selectedGameVersion != null ? [_selectedGameVersion!] : null,
        loaders: _selectedLoader != null ? [_selectedLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _resources = result.resources;
        _hasMore = result.resources.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final params = SearchParams(
        query: _searchQuery,
        type: _selectedType,
        page: nextPage,
        pageSize: _pageSize,
        sortBy: _sortBy,
        gameVersions: _selectedGameVersion != null ? [_selectedGameVersion!] : null,
        loaders: _selectedLoader != null ? [_selectedLoader!] : null,
      );
      final result = await _searchService.search(params);
      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        _resources.addAll(result.resources);
        _hasMore = result.resources.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      NotificationManager().showError('加载失败', message: e.toString());
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _performSearch();
  }

  void _onTypeChanged(ResourceType? type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _performSearch();
  }

  void _onSortChanged(String sortBy) {
    if (_sortBy == sortBy) return;
    setState(() {
      _sortBy = sortBy;
    });
    _performSearch();
  }

  void _onGameVersionChanged(String? version) {
    if (_selectedGameVersion == version) return;
    setState(() {
      _selectedGameVersion = version;
    });
    _performSearch();
  }

  void _onLoaderChanged(String? loader) {
    if (_selectedLoader == loader) return;
    setState(() {
      _selectedLoader = loader;
    });
    _performSearch();
  }

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

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Column(
      children: [
        // 顶部自定义标题栏
        _buildHeader(context),
        const SizedBox(height: 12),

        // 主体内容
        Expanded(
          child: Row(
            children: [
              // 左侧筛选面板
              _buildFilterPanel(context),
              const SizedBox(width: 12),

              // 右侧资源列表
              Expanded(child: _buildResourceList(context)),
            ],
          ),
        ),
      ],
    );
  }

  /// 顶部自定义标题栏 - 蔚蓝档案风格
  Widget _buildHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 24, 0),
      child: Row(
        children: [
          // 图标 + 标题 + 副标题
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BAColors.primaryLight, BAColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primary.withOpacity(0.4),
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '资源中心',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF1A2744) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '浏览和下载Mod、资源包、整合包',
                    style: TextStyle(
                      color: (isLight ? const Color(0xFF1A2744) : Colors.white)
                          .withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 搜索框
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: '搜索模组、资源包...',
                  hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
                  prefixIcon: Icon(Icons.search,
                      color: BAColors.textSecondaryOf(context), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: BAColors.textSecondaryOf(context), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: BAColors.surfaceVariantOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 资源数量指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (isLight ? const Color(0xFFEEF1FA) : const Color(0xFF2A3558))
                  .withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2,
                    color: (isLight ? const Color(0xFF1A2744) : Colors.white)
                        .withValues(alpha: 0.85),
                    size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_resources.length}${_hasMore ? '+' : ''} 个资源',
                  style: TextStyle(
                    color: (isLight ? const Color(0xFF1A2744) : Colors.white)
                        .withValues(alpha: 0.9),
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

  Widget _buildFilterPanel(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor =
        (isLight ? const Color(0xFFEEF1FA) : const Color(0xFF1A2544))
            .withValues(alpha: 0.85);
    final borderColor =
        (isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
            .withValues(alpha: 0.5);
    final textColor = isLight ? const Color(0xFF1A2744) : Colors.white;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(
              context,
              title: '类型',
              icon: Icons.category,
              textColor: textColor,
              child: Column(
                children: _typeOptions.map((type) {
                  final isSelected = _selectedType == type.value;
                  final typeColor = _typeColors[type.value] ?? BAColors.primary;
                  final typeIcon = _typeIcons[type.value] ?? Icons.apps;
                  return _buildFilterChip(
                    label: type.key,
                    icon: typeIcon,
                    isSelected: isSelected,
                    color: typeColor,
                    textColor: textColor,
                    onTap: () => _onTypeChanged(type.value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            _buildFilterSection(
              context,
              title: '游戏版本',
              icon: Icons.history,
              textColor: textColor,
              child: _buildDropdown(
                context,
                value: _selectedGameVersion,
                hint: '选择版本',
                textColor: textColor,
                items: const [
                  '1.21.x',
                  '1.20.x',
                  '1.19.x',
                  '1.18.x',
                  '1.16.x',
                  '1.12.x',
                ],
                onChanged: _onGameVersionChanged,
              ),
            ),
            const SizedBox(height: 18),

            _buildFilterSection(
              context,
              title: 'Mod加载器',
              icon: Icons.extension,
              textColor: textColor,
              child: Column(
                children: [
                  _buildFilterChip(
                    label: 'Fabric',
                    icon: Icons.widgets,
                    isSelected: _selectedLoader == 'fabric',
                    color: const Color(0xFF6D8A88),
                    textColor: textColor,
                    onTap: () =>
                        _onLoaderChanged(_selectedLoader == 'fabric' ? null : 'fabric'),
                  ),
                  const SizedBox(height: 4),
                  _buildFilterChip(
                    label: 'Forge',
                    icon: Icons.construction,
                    isSelected: _selectedLoader == 'forge',
                    color: const Color(0xFFE87A1B),
                    textColor: textColor,
                    onTap: () =>
                        _onLoaderChanged(_selectedLoader == 'forge' ? null : 'forge'),
                  ),
                  const SizedBox(height: 4),
                  _buildFilterChip(
                    label: 'Quilt',
                    icon: Icons.grid_view,
                    isSelected: _selectedLoader == 'quilt',
                    color: const Color(0xFF9D65C9),
                    textColor: textColor,
                    onTap: () =>
                        _onLoaderChanged(_selectedLoader == 'quilt' ? null : 'quilt'),
                  ),
                  const SizedBox(height: 4),
                  _buildFilterChip(
                    label: 'NeoForge',
                    icon: Icons.architecture,
                    isSelected: _selectedLoader == 'neoforge',
                    color: const Color(0xFF6CC47F),
                    textColor: textColor,
                    onTap: () => _onLoaderChanged(
                        _selectedLoader == 'neoforge' ? null : 'neoforge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _buildFilterSection(
              context,
              title: '排序',
              icon: Icons.sort,
              textColor: textColor,
              child: Column(
                children: _sortOptions.map((option) {
                  final isSelected = _sortBy == option.key;
                  return _buildSortOption(
                    label: option.value,
                    isSelected: isSelected,
                    textColor: textColor,
                    onTap: () => _onSortChanged(option.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            _buildFilterSection(
              context,
              title: '我的收藏',
              icon: Icons.favorite,
              textColor: textColor,
              child: GestureDetector(
                onTap: () => setState(() => _showOnlyFavorites = !_showOnlyFavorites),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showOnlyFavorites
                        ? BAColors.primary.withValues(alpha: 0.12)
                        : (Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF2A3558)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                        color: _showOnlyFavorites ? Colors.red : textColor.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '只看收藏',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (_favoriteIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: BAColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_favoriteIds.length}',
                            style: const TextStyle(
                              color: BAColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 重置筛选按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _selectedGameVersion = null;
                    _selectedLoader = null;
                    _sortBy = 'downloads';
                    _showOnlyFavorites = false;
                  });
                  _performSearch();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('重置筛选'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor.withValues(alpha: 0.8),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color textColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: BAColors.primary, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : (Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF2A3558)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? color : textColor.withValues(alpha: 0.7), size: 13),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : textColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color:
                isSelected ? BAColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? BAColors.primary : textColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? BAColors.primary : textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    String? value,
    required String hint,
    required Color textColor,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF2A3558),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down,
              color: textColor.withValues(alpha: 0.6), size: 16),
          dropdownColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF1A2544),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildResourceList(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: BAColors.primary,
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
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: BAColors.danger, size: 36),
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
            Text(
              _errorMessage!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final displayResources = _showOnlyFavorites
        ? _resources.where((r) => _favoriteIds.contains(r.id)).toList()
        : _resources;

    if (displayResources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: BAColors.textSecondaryOf(context).withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            Text(
              _showOnlyFavorites ? '还没有收藏任何资源' : '没有找到相关资源',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _showOnlyFavorites ? '去浏览并收藏感兴趣的模组吧' : '尝试调整筛选条件',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: (isLight ? const Color(0xFFEEF1FA) : const Color(0xFF1A2544))
            .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
              .withValues(alpha: 0.5),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: displayResources.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayResources.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: BAColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          final resource = displayResources[index];
          return _buildResourceCard(context, resource, isLight);
        },
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Resource resource, bool isLight) {
    final typeColor = _typeColors[resource.type] ?? BAColors.primary;
    final isFavorite = _favoriteIds.contains(resource.id);
    final cardBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF2A3558);
    final cardBorder = (isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A))
        .withValues(alpha: 0.35);
    final textPrimary = isLight ? const Color(0xFF1A2744) : Colors.white;
    final textSecondary =
        (isLight ? const Color(0xFF1A2744) : Colors.white).withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _onResourceTap(resource),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: resource.iconUrl != null
                      ? Image.network(
                          resource.iconUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              _typeIcons[resource.type] ?? Icons.apps,
                              size: 28,
                              color: typeColor.withValues(alpha: 0.7),
                            ),
                          ),
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
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
                            size: 28,
                            color: typeColor.withValues(alpha: 0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // 中间信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getTypeName(resource.type),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            resource.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.description.isNotEmpty
                          ? resource.description
                          : resource.summary ?? '',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (resource.categories.isNotEmpty)
                          ...resource.categories.take(3).map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? const Color(0xFFEEF1FA)
                                      : const Color(0xFF1A2544),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (resource.supportedGameVersions.isNotEmpty)
                          Text(
                            resource.supportedGameVersions.first,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (resource.source.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: BAColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              resource.source.toUpperCase(),
                              style: const TextStyle(
                                color: BAColors.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 右侧：下载量 + 作者 + 收藏
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, size: 11, color: textSecondary),
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
                  const SizedBox(height: 4),
                  Text(
                    resource.authors.isNotEmpty ? resource.authors.first.name : '未知',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _toggleFavorite(resource.id),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeName(ResourceType? type) {
    switch (type) {
      case ResourceType.mod:
        return '模组';
      case ResourceType.resourcePack:
        return '资源包';
      case ResourceType.modpack:
        return '整合包';
      case ResourceType.shader:
        return '光影包';
      case ResourceType.dataPack:
        return '数据包';
      default:
        return '其他';
    }
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    } else if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }
}