import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/models.dart';
import '../components/ba_notification.dart';
import 'ba_resource_detail_page.dart';

/// 资源中心页面 - 左筛右列布局
/// 
/// 布局结构:
/// - 顶部: 毛玻璃标题栏 (返回 + 标题 + 搜索框)
/// - 左侧: 筛选面板 (源选择/类型/版本/加载器/收藏)
/// - 右侧: 资源列表/网格
class BAResourceCenterPage extends StatefulWidget {
  const BAResourceCenterPage({super.key});

  @override
  State<BAResourceCenterPage> createState() => _BAResourceCenterPageState();
}

class _BAResourceCenterPageState extends State<BAResourceCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SearchService _searchService = SearchService();
  bool _isMaximized = false;

  // 资源数据
  List<Resource> _resources = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  
  // 筛选条件
  String _searchQuery = '';
  ResourceType? _selectedType;
  String _sortBy = 'downloads';
  int _currentPage = 1;
  
  // 游戏版本和加载器筛选
  String? _selectedGameVersion;
  String? _selectedLoader; // fabric / forge / quilt
  
  // 收藏筛选
  bool _showOnlyFavorites = false;
  Set<String> _favoriteIds = {};

  static const int _pageSize = 24;

  // 资源类型
  static const _typeOptions = <MapEntry<String, ResourceType?>>[
    MapEntry('全部', null),
    MapEntry('模组', ResourceType.mod),
    MapEntry('资源包', ResourceType.resourcePack),
    MapEntry('整合包', ResourceType.modpack),
  ];

  // 排序选项
  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('downloads', '最多下载'),
    MapEntry('newest', '最新发布'),
    MapEntry('updated', '最近更新'),
    MapEntry('name', '按名称'),
  ];

  // 资源类型图标
  static const Map<ResourceType?, IconData> _typeIcons = {
    null: Icons.apps,
    ResourceType.mod: Icons.extension,
    ResourceType.resourcePack: Icons.palette,
    ResourceType.modpack: Icons.inventory_2,
  };

  // 资源类型颜色
  static const Map<ResourceType?, Color> _typeColors = {
    null: BAColors.primary,
    ResourceType.mod: BAColors.accentPink,
    ResourceType.resourcePack: BAColors.success,
    ResourceType.modpack: BAColors.warning,
  };

  @override
  void initState() {
    super.initState();
    _initWindow();
    _scrollController.addListener(_onScroll);
    _performSearch();
  }

  Future<void> _initWindow() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
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
        builder: (context) => BAResourceDetailPage(
          resource: resource,
          isFavorite: _favoriteIds.contains(resource.id),
          onFavoriteToggle: () => _toggleFavorite(resource.id),
        ),
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Scaffold(
      body: Column(
        children: [
          // 顶部标题栏
          _buildHeader(context),
          
          // 主体内容：左筛右列
          Expanded(
            child: Row(
              children: [
                // 左侧筛选面板
                _buildFilterPanel(context),
                
                // 分隔线
                Container(width: 1, color: BAColors.borderOf(context).withValues(alpha: 0.3)),
                
                // 右侧资源列表
                Expanded(
                  child: _buildResourceList(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildHeader(BuildContext context) {
    return BAGlassContainer(
      blur: 20,
      opacity: 0.85,
      borderRadius: 0,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 返回按钮
            BAIconButton(
              icon: Icons.arrow_back,
              onTap: _goBack,
              size: 36,
              iconSize: 18,
            ),
            const SizedBox(width: 12),
            
            // 标题
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: BAColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.extension, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '资源中心',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            
            // 搜索框
            Expanded(
              child: Container(
                height: 40,
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索模组、资源包...',
                    hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
                    prefixIcon: Icon(Icons.search, color: BAColors.textSecondaryOf(context), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: BAColors.textSecondaryOf(context), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: BAColors.surfaceVariantOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // 资源数量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder, color: BAColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_resources.length}${_hasMore ? '+' : ''} 个资源',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // 窗口控制按钮
            Row(
              children: [
                BAWindowButton(
                  icon: Icons.remove,
                  onTap: () => windowManager.minimize(),
                  size: 32,
                ),
                const SizedBox(width: 6),
                BAWindowButton(
                  icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                  onTap: () async {
                    if (_isMaximized) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                    final isMaximized = await windowManager.isMaximized();
                    if (mounted) setState(() => _isMaximized = isMaximized);
                  },
                  size: 32,
                ),
                const SizedBox(width: 6),
                BAWindowButton(
                  icon: Icons.close,
                  onTap: () => windowManager.close(),
                  isClose: true,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 左侧筛选面板
  Widget _buildFilterPanel(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF8FAFF) : const Color(0xFF0D1321);
    final cardBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1A2540);
    final borderColor = isLight ? const Color(0xFFE0E8F0) : const Color(0xFF2A3A5A);

    return Container(
      width: 220,
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 资源类型
            _buildFilterSection(
              context,
              title: '类型',
              icon: Icons.category,
              child: Column(
                children: _typeOptions.map((type) {
                  final isSelected = _selectedType == type.value;
                  final typeColor = _typeColors[type.value] ?? BAColors.primary;
                  final typeIcon = _typeIcons[type.value] ?? Icons.apps;
                  return _buildChip(
                    label: type.key,
                    icon: typeIcon,
                    isSelected: isSelected,
                    color: typeColor,
                    onTap: () => _onTypeChanged(type.value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 游戏版本
            _buildFilterSection(
              context,
              title: '游戏版本',
              icon: Icons.history,
              child: _buildDropdown(
                context,
                value: _selectedGameVersion,
                hint: '选择版本',
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
            const SizedBox(height: 16),

            // Mod加载器
            _buildFilterSection(
              context,
              title: 'Mod加载器',
              icon: Icons.extension,
              child: Column(
                children: [
                  _buildChip(
                    label: 'Fabric',
                    icon: Icons.widgets,
                    isSelected: _selectedLoader == 'fabric',
                    color: const Color(0xFF6D8A88),
                    onTap: () => _onLoaderChanged(_selectedLoader == 'fabric' ? null : 'fabric'),
                  ),
                  const SizedBox(height: 6),
                  _buildChip(
                    label: 'Forge',
                    icon: Icons.construction,
                    isSelected: _selectedLoader == 'forge',
                    color: const Color(0xFFE87A1B),
                    onTap: () => _onLoaderChanged(_selectedLoader == 'forge' ? null : 'forge'),
                  ),
                  const SizedBox(height: 6),
                  _buildChip(
                    label: 'Quilt',
                    icon: Icons.grid_view,
                    isSelected: _selectedLoader == 'quilt',
                    color: const Color(0xFF9D65C9),
                    onTap: () => _onLoaderChanged(_selectedLoader == 'quilt' ? null : 'quilt'),
                  ),
                  const SizedBox(height: 6),
                  _buildChip(
                    label: 'NeoForge',
                    icon: Icons.architecture,
                    isSelected: _selectedLoader == 'neoforge',
                    color: const Color(0xFF6CC47F),
                    onTap: () => _onLoaderChanged(_selectedLoader == 'neoforge' ? null : 'neoforge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 排序
            _buildFilterSection(
              context,
              title: '排序',
              icon: Icons.sort,
              child: Column(
                children: _sortOptions.map((option) {
                  final isSelected = _sortBy == option.key;
                  return _buildSortOption(
                    label: option.value,
                    isSelected: isSelected,
                    onTap: () => _onSortChanged(option.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 收藏筛选
            _buildFilterSection(
              context,
              title: '我的收藏',
              icon: Icons.favorite,
              child: BASurfaceCard(
                onTap: () => setState(() => _showOnlyFavorites = !_showOnlyFavorites),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                showBorder: true,
                child: Row(
                  children: [
                    Icon(
                      _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                      color: _showOnlyFavorites ? Colors.red : BAColors.textSecondaryOf(context),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '只看收藏',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (_favoriteIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BAColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_favoriteIds.length}',
                          style: TextStyle(
                            color: BAColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 清除筛选按钮
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
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重置筛选'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BAColors.textSecondaryOf(context),
                  side: BorderSide(color: BAColors.borderOf(context)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: BAColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: BASurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : BAColors.textPrimaryOf(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? BAColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? BAColors.primary : BAColors.textSecondaryOf(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? BAColors.primary : BAColors.textSecondaryOf(context),
                  fontSize: 12,
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
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: BAColors.textDisabledOf(context),
              fontSize: 12,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: BAColors.textSecondaryOf(context), size: 18),
          dropdownColor: BAColors.surfaceOf(context),
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 12,
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

  /// 右侧资源列表
  Widget _buildResourceList(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: BAColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载资源...',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 14,
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
            Icon(Icons.error_outline, color: BAColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
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
            Icon(Icons.search_off, color: BAColors.textSecondaryOf(context), size: 56),
            const SizedBox(height: 16),
            Text(
              _showOnlyFavorites ? '还没有收藏任何资源' : '没有找到相关资源',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyFavorites ? '去浏览并收藏感兴趣的模组吧' : '尝试调整筛选条件',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: BAColors.backgroundOf(context),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: displayResources.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayResources.length) {
            return Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: BAColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final resource = displayResources[index];
          return _buildResourceCard(context, resource);
        },
      ),
    );
  }

  /// 资源卡片
  Widget _buildResourceCard(BuildContext context, Resource resource) {
    final typeColor = _typeColors[resource.type] ?? BAColors.primary;
    final isFavorite = _favoriteIds.contains(resource.id);

    return BASurfaceCard(
      onTap: () => _onResourceTap(resource),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作栏
          Row(
            children: [
              // 类型标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcons[resource.type], size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      _getTypeName(resource.type),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 收藏按钮
              GestureDetector(
                onTap: () => _toggleFavorite(resource.id),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : BAColors.textSecondaryOf(context),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 资源图标区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    typeColor.withValues(alpha: 0.15),
                    typeColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _typeIcons[resource.type] ?? Icons.apps,
                  size: 40,
                  color: typeColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 资源名称
          Text(
            resource.name,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // 下载量和作者
          Row(
            children: [
              Icon(Icons.download, size: 12, color: BAColors.textSecondaryOf(context)),
              const SizedBox(width: 4),
              Text(
                _formatDownloads(resource.downloads),
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  resource.authors.isNotEmpty ? resource.authors.first.name : '未知',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
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
