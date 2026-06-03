import 'package:flutter/material.dart';
import '../version/models.dart';

/// 版本类型筛选选项
enum VersionFilterType {
  all('全部'),
  release('正式版'),
  snapshot('快照版'),
  oldBeta('Beta'),
  oldAlpha('Alpha');

  final String label;
  const VersionFilterType(this.label);
}

/// ModLoader筛选选项
enum LoaderFilterType {
  all('全部'),
  none('无'),
  forge('Forge'),
  fabric('Fabric'),
  quilt('Quilt'),
  neoforge('NeoForge');

  final String label;
  const LoaderFilterType(this.label);
}

/// 版本筛选状态
class VersionFilterState {
  final VersionFilterType versionType;
  final LoaderFilterType loaderType;
  final String searchQuery;

  const VersionFilterState({
    this.versionType = VersionFilterType.all,
    this.loaderType = LoaderFilterType.all,
    this.searchQuery = '',
  });

  VersionFilterState copyWith({
    VersionFilterType? versionType,
    LoaderFilterType? loaderType,
    String? searchQuery,
  }) {
    return VersionFilterState(
      versionType: versionType ?? this.versionType,
      loaderType: loaderType ?? this.loaderType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// 版本筛选栏组件
class VersionFilterBar extends StatelessWidget {
  /// 当前筛选状态
  final VersionFilterState filterState;

  /// 筛选状态改变回调
  final ValueChanged<VersionFilterState> onFilterChanged;

  /// 创建版本筛选栏
  const VersionFilterBar({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          _buildSearchField(context),
          const SizedBox(height: 12),
          // 筛选选项
          Row(
            children: [
              // 版本类型筛选
              Expanded(
                child: _buildVersionTypeFilter(context),
              ),
              const SizedBox(width: 16),
              // ModLoader筛选
              Expanded(
                child: _buildLoaderTypeFilter(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索版本...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: filterState.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  onFilterChanged(filterState.copyWith(searchQuery: ''));
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) {
        onFilterChanged(filterState.copyWith(searchQuery: value));
      },
    );
  }

  /// 构建版本类型筛选
  Widget _buildVersionTypeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '版本类型',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VersionFilterType.values.map((type) {
              final isSelected = filterState.versionType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFilterChanged(filterState.copyWith(
                      versionType: selected ? type : VersionFilterType.all,
                    ));
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建ModLoader筛选
  Widget _buildLoaderTypeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mod加载器',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LoaderFilterType.values.map((type) {
              final isSelected = filterState.loaderType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFilterChanged(filterState.copyWith(
                      loaderType: selected ? type : LoaderFilterType.all,
                    ));
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedColor: _getLoaderChipColor(type),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getLoaderChipColor(LoaderFilterType type) {
    switch (type) {
      case LoaderFilterType.forge:
        return Colors.orange.shade200;
      case LoaderFilterType.fabric:
        return Colors.cyan.shade200;
      case LoaderFilterType.quilt:
        return Colors.purple.shade200;
      case LoaderFilterType.neoforge:
        return Colors.red.shade200;
      case LoaderFilterType.none:
      case LoaderFilterType.all:
        return Colors.grey.shade200;
    }
  }
}

/// 筛选后的版本列表组件
class FilteredVersionList extends StatelessWidget {
  /// 所有版本列表
  final List<GameVersion> versions;

  /// 已安装版本列表
  final List<String> installedVersions;

  /// 筛选状态
  final VersionFilterState filterState;

  /// 点击回调
  final Function(GameVersion)? onVersionTap;

  /// 安装回调
  final Function(GameVersion)? onInstall;

  /// 卸载回调
  final Function(GameVersion)? onUninstall;

  /// 是否正在加载
  final bool isLoading;

  /// 创建筛选后的版本列表
  const FilteredVersionList({
    super.key,
    required this.versions,
    this.installedVersions = const [],
    this.filterState = const VersionFilterState(),
    this.onVersionTap,
    this.onInstall,
    this.onUninstall,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final filteredVersions = _filterVersions();

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载版本列表...'),
          ],
        ),
      );
    }

    if (filteredVersions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的版本',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (filterState.searchQuery.isNotEmpty ||
                filterState.versionType != VersionFilterType.all ||
                filterState.loaderType != LoaderFilterType.all) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // 重置筛选
                },
                child: const Text('清除筛选'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredVersions.length,
      itemBuilder: (context, index) {
        final version = filteredVersions[index];
        final isInstalled = installedVersions.contains(version.id);

        return _VersionListItem(
          version: version,
          isInstalled: isInstalled,
          onTap: () => onVersionTap?.call(version),
          onInstall: () => onInstall?.call(version),
          onUninstall: () => onUninstall?.call(version),
        );
      },
    );
  }

  /// 过滤版本列表
  List<GameVersion> _filterVersions() {
    var filtered = versions;

    // 应用搜索过滤（模糊匹配）
    if (filterState.searchQuery.isNotEmpty) {
      final query = filterState.searchQuery.toLowerCase();
      filtered = filtered.where((version) {
        return version.id.toLowerCase().contains(query);
      }).toList();
    }

    // 应用版本类型过滤
    if (filterState.versionType != VersionFilterType.all) {
      final targetType = _convertFilterType(filterState.versionType);
      if (targetType != null) {
        filtered = filtered.where((version) {
          return version.type == targetType;
        }).toList();
      }
    }

    return filtered;
  }

  /// 转换筛选类型到VersionType
  VersionType? _convertFilterType(VersionFilterType filterType) {
    switch (filterType) {
      case VersionFilterType.release:
        return VersionType.release;
      case VersionFilterType.snapshot:
        return VersionType.snapshot;
      case VersionFilterType.oldBeta:
        return VersionType.oldBeta;
      case VersionFilterType.oldAlpha:
        return VersionType.oldAlpha;
      case VersionFilterType.all:
        return null;
    }
  }
}

/// 版本列表项
class _VersionListItem extends StatelessWidget {
  final GameVersion version;
  final bool isInstalled;
  final VoidCallback? onTap;
  final VoidCallback? onInstall;
  final VoidCallback? onUninstall;

  const _VersionListItem({
    required this.version,
    required this.isInstalled,
    this.onTap,
    this.onInstall,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 版本图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getVersionColor(version.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVersionIcon(version.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 版本信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.id,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTypeChip(version.type),
                        const SizedBox(width: 8),
                        if (isInstalled) _buildInstalledChip(),
                      ],
                    ),
                  ],
                ),
              ),
              // 操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInstalled)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onUninstall,
                      tooltip: '卸载',
                    )
                  else
                    FilledButton.icon(
                      onPressed: onInstall,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('安装'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVersionColor(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Colors.green;
      case VersionType.snapshot:
        return Colors.orange;
      case VersionType.oldBeta:
        return Colors.purple;
      case VersionType.oldAlpha:
        return Colors.red;
    }
  }

  IconData _getVersionIcon(VersionType type) {
    switch (type) {
      case VersionType.release:
        return Icons.check_circle;
      case VersionType.snapshot:
        return Icons.science;
      case VersionType.oldBeta:
        return Icons.history;
      case VersionType.oldAlpha:
        return Icons.history_edu;
    }
  }

  Widget _buildTypeChip(VersionType type) {
    String label;
    Color color;

    switch (type) {
      case VersionType.release:
        label = '正式版';
        color = Colors.green;
        break;
      case VersionType.snapshot:
        label = '快照版';
        color = Colors.orange;
        break;
      case VersionType.oldBeta:
        label = 'Beta';
        color = Colors.purple;
        break;
      case VersionType.oldAlpha:
        label = 'Alpha';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstalledChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Text(
        '已安装',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
