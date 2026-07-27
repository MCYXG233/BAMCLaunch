import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../instance/models.dart';
import '../../../../resource_center/models.dart';
import '../resource_constants.dart';
import '../widgets/sort_button.dart';
import '../widgets/compact_dropdown.dart';
import '../widgets/type_chip.dart';
import '../widgets/resource_grid_card.dart';
import '../widgets/state_widgets.dart';

/// Modrinth 源 Tab - 包含筛选栏与资源网格
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
                    controller: searchController,
                    onSubmitted: onQuerySubmitted,
                    style: TextStyle(color: textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '搜索模组、资源包、整合包...',
                      hintStyle: TextStyle(
                        color: BAColors.textDisabledOf(context),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textSecondary,
                        size: 16,
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: textSecondary,
                                size: 14,
                              ),
                              onPressed: onQueryCleared,
                            )
                          : null,
                      filled: true,
                      fillColor: BAColors.surfaceVariantOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SortButton(
                currentSort: sort,
                onSelected: onSortChanged,
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 6),
              CompactDropdown(
                value: gameVersion,
                hint: '版本',
                items: ResourceConstants.gameVersions,
                onChanged: onGameVersionChanged,
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 6),
              CompactDropdown(
                value: loader,
                hint: '加载器',
                items: ResourceConstants.loaders.map((e) => e.value).toList(),
                displayItems: ResourceConstants.loaders
                    .map((e) => e.key)
                    .toList(),
                onChanged: onLoaderChanged,
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
              itemCount: ResourceConstants.modrinthTypeOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final opt = ResourceConstants.modrinthTypeOptions[index];
                final selected = type == opt.value;
                final color =
                    ResourceConstants.typeColorsOf(context)[opt.value] ??
                    BAColors.primaryOf(context);
                return TypeChip(
                  label: opt.key,
                  icon: ResourceConstants.typeIcons[opt.value] ?? Icons.apps,
                  selected: selected,
                  color: color,
                  onTap: () => onTypeChanged(opt.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (loading) {
      return const ResourceLoadingPlaceholder();
    }
    if (error != null) {
      return ResourceErrorWidget(error: error!, onRetry: onRetry);
    }
    if (resources.isEmpty) {
      return const ResourceEmptyWidget(title: '没有找到相关资源', subtitle: '尝试调整筛选条件');
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
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
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
        const SizedBox(height: 8),
        Expanded(child: _buildGrid(context)),
      ],
    );
  }
}
