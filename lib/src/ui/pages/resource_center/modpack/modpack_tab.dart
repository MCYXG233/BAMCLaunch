import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../resource_center/models.dart';
import '../widgets/resource_filter_bar.dart';
import '../widgets/resource_result_bar.dart';
import '../widgets/resource_grid_card.dart';
import '../widgets/state_widgets.dart';

/// 热门整合包 Tab - 包含筛选栏、统计与整合包网格
class ModpackTab extends StatelessWidget {
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
  final ValueChanged<String?> onGameVersionChanged;
  final ValueChanged<String?> onLoaderChanged;
  final ValueChanged<Resource> onResourceTap;
  final ValueChanged<String> onToggleFavorite;

  const ModpackTab({
    super.key,
    required this.searchController,
    required this.scrollController,
    required this.resources,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.query,
    required this.sort,
    required this.gameVersion,
    required this.loader,
    required this.favoriteIds,
    required this.formatDownloads,
    required this.onRetry,
    required this.onQuerySubmitted,
    required this.onQueryCleared,
    required this.onSortChanged,
    required this.onGameVersionChanged,
    required this.onLoaderChanged,
    required this.onResourceTap,
    required this.onToggleFavorite,
  });

  Widget _buildFilterBar(BuildContext context) {
    // Modpack Tab 已经有类型限定（modpack），不需要 type chips
    return ResourceFilterBar(
      searchController: searchController,
      query: query,
      searchHint: '搜索整合包...',
      onQuerySubmitted: onQuerySubmitted,
      onQueryCleared: onQueryCleared,
      sort: sort,
      onSortChanged: onSortChanged,
      selectedType: null,
      onTypeChanged: null,
      gameVersion: gameVersion,
      onGameVersionChanged: onGameVersionChanged,
      loader: loader,
      onLoaderChanged: onLoaderChanged,
      leftBadgeText: '整合包',
      leftBadgeIcon: Icons.inventory_2_rounded,
      leftBadgeColor: BAColors.warningOf(context),
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
      return const ResourceEmptyWidget(
        title: '暂无整合包数据',
        subtitle: '稍后再试或调整筛选条件',
      );
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
          label: '整合包',
        ),
        Expanded(child: _buildGrid(context)),
      ],
    );
  }
}
