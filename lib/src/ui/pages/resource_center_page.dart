import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/resource_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/index.dart';
import 'resource_detail_page.dart';
import 'installed_resources_page.dart';

/// 资源中心主页面
class ResourceCenterPage extends StatefulWidget {
  const ResourceCenterPage({super.key});

  @override
  State<ResourceCenterPage> createState() => _ResourceCenterPageState();
}

class _ResourceCenterPageState extends State<ResourceCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ResourceManager _resourceManager = ResourceManager();
  final SearchService _searchService = SearchService();

  SearchParams _searchParams = SearchParams(type: ResourceType.mod);
  List<Resource> _resources = [];
  bool _isLoading = false;
  bool _showFilter = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initResourceManager();
    _searchResources();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initResourceManager() async {
    await _resourceManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final newType = _tabController.index == 0 ? ResourceType.mod : ResourceType.resourcePack;
      setState(() {
        _searchParams = _searchParams.copyWith(type: newType);
      });
      _searchResources();
    }
  }

  Future<void> _searchResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _searchService.search(_searchParams);
      if (mounted) {
        setState(() {
          _resources = result.resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '搜索失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchParams = _searchParams.copyWith(query: query);
    });
    _searchResources();
  }

  void _onFilterChanged(SearchParams params) {
    setState(() {
      _searchParams = params.copyWith(
        type: _searchParams.type,
        query: _searchParams.query,
      );
    });
    _searchResources();
  }

  void _toggleFilter() {
    setState(() {
      _showFilter = !_showFilter;
    });
  }

  void _navigateToDetail(Resource resource) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResourceDetailPage(resource: resource),
      ),
    );
  }

  void _navigateToInstalled() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InstalledResourcesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = BAColors.backgroundOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: BAColors.surfaceOf(context),
        elevation: 0,
        title: Text(
          '资源中心',
          style: BATypography.headlineMedium.copyWith(color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: _navigateToInstalled,
            tooltip: '已安装资源',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '模组'),
            Tab(text: '资源包'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context, textPrimary, textSecondary),
          if (_showFilter)
            ResourceFilter(
              initialParams: _searchParams,
              onFilterChanged: _onFilterChanged,
            ),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: BAColors.surfaceOf(context),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: '搜索模组或资源包...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: BAColors.surfaceVariantOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _showFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilter ? BAColors.primary : textSecondary,
            ),
            onPressed: _toggleFilter,
            tooltip: '筛选',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: BAColors.danger),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BAPrimaryButton(
              text: '重试',
              onPressed: _searchResources,
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
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: BAColors.textSecondaryOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到资源',
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _resources.length,
      itemBuilder: (context, index) {
        final resource = _resources[index];
        final isInstalled = _resourceManager.isResourceInstalled(
          resource.source,
          resource.id,
        );
        return ResourceCard(
          resource: resource,
          isInstalled: isInstalled,
          onTap: () => _navigateToDetail(resource),
        );
      },
    );
  }
}
