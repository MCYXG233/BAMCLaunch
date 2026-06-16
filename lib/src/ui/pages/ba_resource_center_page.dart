import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/models.dart';
import '../components/ba_notification.dart';

/// 蔚蓝档案风格资源中心页面（MC启动器版）
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

  List<Resource> _resources = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';
  ResourceType? _selectedType;
  String _sortBy = 'downloads';
  int _currentPage = 1;

  static const int _pageSize = 20;

  // MC启动器资源分类
  static const _categories = <MapEntry<String, ResourceType?>>[
    MapEntry('全部', null),
    MapEntry('模组', ResourceType.mod),
    MapEntry('资源包', ResourceType.resourcePack),
    MapEntry('整合包', ResourceType.modpack),
    MapEntry('光影', null), // 可扩展
    MapEntry('材质包', ResourceType.resourcePack),
  ];

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('downloads', '最多下载'),
    MapEntry('newest', '最新发布'),
    MapEntry('updated', '最近更新'),
  ];

  // 资源图标映射
  static const Map<ResourceType?, IconData> _typeIcons = {
    null: Icons.apps,
    ResourceType.mod: Icons.extension,
    ResourceType.resourcePack: Icons.palette,
    ResourceType.modpack: Icons.inventory_2,
  };

  // 资源颜色映射
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
    if (Platform.isWindows || Platform.isMacOS) {
      final isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = isMaximized;
        });
      }
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
        _scrollController.position.maxScrollExtent - 200) {
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

  void _onCategoryChanged(ResourceType? type) {
    if (_selectedType == type) return;
    if (!mounted) return;
    setState(() {
      _selectedType = type;
    });
    _performSearch();
  }

  void _onSortChanged(String sortBy) {
    if (_sortBy == sortBy) return;
    if (!mounted) return;
    setState(() {
      _sortBy = sortBy;
    });
    _performSearch();
  }

  void _onSearchSubmitted(String query) {
    _searchQuery = query;
    _performSearch();
  }

  void _onResourceTap(Resource resource) {
    NotificationManager().showInfo('资源详情', message: '资源详情页面开发中: ${resource.name}');
  }

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Column(
      children: [
        // 顶部标题栏
        _buildHeader(context),
        const SizedBox(height: 20),

        // 搜索和分类区域
        _buildSearchAndCategories(context),
        const SizedBox(height: 20),

        // 资源列表
        Expanded(
          child: _buildResourceList(context),
        ),
      ],
    );
  }

  /// 顶部标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: BAColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.extension,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '资源中心',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // 统计信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download,
                  color: BAColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_resources.length}',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' 个资源',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索和分类区域
  Widget _buildSearchAndCategories(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.6),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: '搜索模组、资源包、整合包...',
                hintStyle: TextStyle(
                  color: BAColors.textDisabledOf(context),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: BAColors.textSecondaryOf(context),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: BAColors.textSecondaryOf(context),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 分类和排序
          Row(
            children: [
              // 分类标签
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isSelected = _selectedType == category.value;
                      final typeColor = _typeColors[category.value] ?? BAColors.primary;

                      return Padding(
                        padding: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
                        child: InkWell(
                          onTap: () => _onCategoryChanged(category.value),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        typeColor.withOpacity(0.8),
                                        typeColor,
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : BAColors.surfaceOf(context).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : BAColors.borderOf(context).withOpacity(0.6),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: typeColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcons[category.value] ?? Icons.apps,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : typeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.key,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : BAColors.textSecondaryOf(context),
                                    fontSize: 13,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 排序下拉菜单
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BAColors.borderOf(context).withOpacity(0.6),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: Icon(
                      Icons.sort,
                      color: BAColors.textSecondaryOf(context),
                      size: 18,
                    ),
                    dropdownColor: BAColors.surfaceOf(context),
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 13,
                    ),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option.key,
                        child: Text(option.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onSortChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 资源列表
  Widget _buildResourceList(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: BAColors.secondaryGradient,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '正在加载资源...',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 16,
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BAColors.danger.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: BAColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '加载失败',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: BAColors.secondaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BAColors.secondary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _searchQuery.isNotEmpty
                  ? '没有找到相关资源'
                  : '还没有资源',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? '尝试搜索其他关键词'
                  : '去下载一些模组和资源包吧',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _resources.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _resources.length) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BAColors.secondary),
              ),
            );
          }
          final resource = _resources[index];
          return _buildResourceCard(context, resource);
        },
      ),
    );
  }

  /// 资源卡片
  Widget _buildResourceCard(BuildContext context, Resource resource) {
    final typeColor = _typeColors[resource.type] ?? BAColors.primary;

    return BASurfaceCard(
      onTap: () => _onResourceTap(resource),
      shadowColor: typeColor.withOpacity(0.15),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部类型标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcons[resource.type] ?? Icons.apps,
                      size: 14,
                      color: typeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTypeName(resource.type),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 资源图标
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    typeColor.withOpacity(0.2),
                    typeColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _typeIcons[resource.type] ?? Icons.apps,
                  size: 48,
                  color: typeColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 资源名称
          Text(
            resource.name,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 下载量和作者
          Row(
            children: [
              Icon(
                Icons.download,
                size: 14,
                color: BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDownloads(resource.downloads),
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                resource.authors.isNotEmpty
                    ? resource.authors.first.name
                    : '未知作者',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
