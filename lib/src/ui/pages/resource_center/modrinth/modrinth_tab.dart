import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../instance/models.dart';
import '../../../../resource_center/models.dart';
import '../widgets/resource_filter_bar.dart';
import '../widgets/resource_result_bar.dart';
import '../widgets/resource_grid_card.dart';
import '../widgets/state_widgets.dart';

/// Modrinth 源 Tab - 包含筛选栏、统计与资源网格
class ModrinthTab extends StatelessWidget {
  // 控制器
  final TextEditingController searchController;
  final ScrollController scrollController;

  // 状态
  final List<Resource> resources;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String query;
  final String sort;
  final ResourceType? type;
  final String? gameVersion;
  final String? loader;

  // 收藏
  final Set<String> favoriteIds;
  final String Function(int) formatDownloads;

  // 回调
  final VoidCallback onRetry;
  final ValueChanged<String> onQuerySubmitted;
  final VoidCallback onQueryCleared;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<ResourceType?> onTypeChanged;
  final ValueChanged<String?> onGameVersionChanged;
  final ValueChanged<String?> onLoaderChanged;
  final ValueChanged<Resource> onResourceTap;
  final ValueChanged<String> onToggleFavorite;

  const ModrinthTab({
    super.key,
    required this.searchController,
    required this.scrollController,
    required this.resources,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.query,
    required this.sort,
    required this.type,
    required this.gameVersion,
    required this.loader,
    required this.favoriteIds,
    required this.formatDownloads,
    required this.onRetry,
    required this.onQuerySubmitted,
    required this.onQueryCleared,
    required this.onSortChanged,
    required this.onTypeChanged,
    required this.onGameVersionChanged,
    required this.onLoaderChanged,
    required this.onResourceTap,
    required this.onToggleFavorite,
  });

  Widget _buildFilterBar(BuildContext context) {
    return ResourceFilterBar(
      searchController: searchController,
      query: query,
      searchHint: '搜索模组、资源包、整合包...',
      onQuerySubmitted: onQuerySubmitted,
      onQueryCleared: onQueryCleared,
      sort: sort,
      onSortChanged: onSortChanged,
      selectedType: type,
      onTypeChanged: onTypeChanged,
      gameVersion: gameVersion,
      onGameVersionChanged: onGameVersionChanged,
      loader: loader,
      onLoaderChanged: onLoaderChanged,
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (loading && resources.isEmpty) {
      return const ResourceLoadingPlaceholder();
    }
    if (error != null && resources.isEmpty) {
      return ResourceErrorWidget(error: error!, onRetry: onRetry);
    }
    if (resources.isEmpty) {
      return const ResourceEmptyWidget(title: '没有找到相关资源', subtitle: '尝试调整筛选条件');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calcColumns(constraints.maxWidth);
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemCount: resources.length + (loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= resources.length) {
                return const GridLoadingMore();
              }
              final resource = resources[index];
              return ResourceGridCard(
                resource: resource,
                isFavorite: favoriteIds.contains(resource.id),
                onTap: () => onResourceTap(resource),
                onToggleFavorite: () => onToggleFavorite(resource.id),
                formatDownloads: formatDownloads,
              );
            },
          );
        },
      ),
    );
  }

  int _calcColumns(double width) {
    if (width >= 1200) return 3;
    if (width >= 700) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        const SizedBox(height: 4),
        ResourceResultBar(
          totalCount: resources.length,
          loadingMore: loadingMore,
          loading: loading,
          onRefresh: onRetry,
        ),
        Expanded(child: _buildGrid(context)),
      ],
    );
  }
}
