import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/models.dart';
import '../components/ba_notification.dart';

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
  bool _notificationInitialized = false;

  static const int _pageSize = 20;

  static const _categories = <MapEntry<String, ResourceType?>>[
    MapEntry('全部', null),
    MapEntry('模组', ResourceType.mod),
    MapEntry('资源包', ResourceType.resourcePack),
    MapEntry('整合包', ResourceType.modpack),
  ];

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('downloads', '最多下载'),
    MapEntry('newest', '最新发布'),
    MapEntry('updated', '最近更新'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _performSearch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationInitialized) {
      NotificationManager().init(context);
      _notificationInitialized = true;
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
    NotificationManager().showInfo('TODO', message: '资源详情页面开发中: ${resource.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.backgroundOf(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '资源中心',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildSortDropdown(),
        _buildSearchBar(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          dropdownColor: BAColors.surfaceOf(context),
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 13,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: BAColors.textSecondaryOf(context),
            size: 20,
          ),
          items: _sortOptions.map((option) {
            return DropdownMenuItem(
              value: option.key,
              child: Text(option.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _onSortChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 150),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BAColors.borderOf(context).withOpacity(0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
          controller: _searchController,
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _searchQuery = value;
              });
            }
          },
          onSubmitted: _onSearchSubmitted,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: '搜索资源...',
            hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
            prefixIcon: Icon(
              Icons.search,
              color: BAColors.textSecondaryOf(context),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: BAColors.textSecondaryOf(context),
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _performSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedType == category.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onCategoryChanged(category.value),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BAColors.primary
                        : BAColors.surfaceOf(context).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? BAColors.primary
                          : BAColors.borderOf(context).withOpacity(0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: BAColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    category.key,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : BAColors.textSecondaryOf(context),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: BAColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正在搜索资源...',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildErrorState(),
      );
    }

    if (_resources.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('empty'),
        child: _buildEmptyState(),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('grid'),
      child: _buildResourceGrid(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: BAColors.danger, size: 48),
          const SizedBox(height: 16),
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
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: BAColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_off_rounded,
              size: 48,
              color: BAColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '没有找到相关资源',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试换个关键词或切换分类吧',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _searchQuery = '';
              _selectedType = null;
              _performSearch();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('清除筛选'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.surfaceOf(context),
              foregroundColor: BAColors.textSecondaryOf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: BAColors.borderOf(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGrid() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _ResourceCard(
                resource: _resources[index],
                onTap: () => _onResourceTap(_resources[index]),
              );
            },
            childCount: _resources.length,
          ),
        ),
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: BAColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResourceCard extends StatefulWidget {
  final Resource resource;
  final VoidCallback? onTap;

  const _ResourceCard({required this.resource, this.onTap});

  @override
  State<_ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<_ResourceCard> {
  bool _isHovered = false;

  Color get _typeColor {
    switch (widget.resource.type) {
      case ResourceType.mod:
        return BAColors.primary;
      case ResourceType.resourcePack:
        return BAColors.success;
      case ResourceType.modpack:
        return BAColors.secondary;
    }
  }

  IconData get _typeIcon {
    switch (widget.resource.type) {
      case ResourceType.mod:
        return Icons.extension;
      case ResourceType.resourcePack:
        return Icons.texture;
      case ResourceType.modpack:
        return Icons.inventory_2;
    }
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(0)}K';
    }
    return downloads.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? color
                : BAColors.borderOf(context).withOpacity(0.6),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : BATheme.shadowsSmallOf(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.resource.iconUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.resource.iconUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, a, b) => Icon(
                                    _typeIcon,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Icon(_typeIcon, color: color, size: 24),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BAColors.surfaceVariantOf(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download,
                                color: BAColors.textSecondaryOf(context), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _formatDownloads(widget.resource.downloads),
                              style: TextStyle(
                                color: BAColors.textSecondaryOf(context),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.resource.name,
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.resource.latestVersion != null
                        ? 'v${widget.resource.latestVersion!.versionNumber}'
                        : widget.resource.supportedGameVersions.isNotEmpty
                            ? widget.resource.supportedGameVersions.first
                            : '',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      widget.resource.description,
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            BAColors.primary,
                            BAColors.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: BAColors.primary
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: BAColors.secondary
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(10),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                '安装',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
