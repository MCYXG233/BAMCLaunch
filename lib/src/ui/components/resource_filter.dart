import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_buttons.dart';
import 'ba_inputs.dart';

/// 筛选回调类型
typedef FilterCallback = void Function(SearchParams params);

/// 资源筛选组件
class ResourceFilter extends StatefulWidget {
  final SearchParams initialParams;
  final FilterCallback onFilterChanged;
  final VoidCallback? onReset;

  const ResourceFilter({
    super.key,
    required this.initialParams,
    required this.onFilterChanged,
    this.onReset,
  });

  @override
  State<ResourceFilter> createState() => _ResourceFilterState();
}

class _ResourceFilterState extends State<ResourceFilter> {
  late SearchParams _currentParams;
  final List<String> _gameVersions = [
    '1.20.4',
    '1.20.1',
    '1.19.4',
    '1.19.2',
    '1.18.2',
    '1.17.1',
    '1.16.5',
    '1.12.2',
  ];
  final List<String> _loaders = [
    'Fabric',
    'Forge',
    'Quilt',
    'NeoForge',
  ];
  final List<String> _sortOptions = [
    'relevance',
    'downloads',
    'updated',
    'newest',
  ];

  @override
  void initState() {
    super.initState();
    _currentParams = widget.initialParams;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = BAColors.surfaceOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final borderColor = BAColors.borderOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '筛选选项',
                style: BATypography.headlineSmall.copyWith(
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  '重置',
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGameVersionFilter(context, textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildLoaderFilter(context, textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildSortFilter(context, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildGameVersionFilter(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '游戏版本',
          style: BATypography.bodyLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gameVersions.map((version) {
            final isSelected = _currentParams.gameVersions?.contains(version) ?? false;
            return FilterChip(
              label: Text(version),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    final newVersions = List<String>.from(_currentParams.gameVersions ?? [])
                      ..add(version);
                    _currentParams = _currentParams.copyWith(gameVersions: newVersions);
                  } else {
                    final newVersions = List<String>.from(_currentParams.gameVersions ?? [])
                      ..remove(version);
                    _currentParams = _currentParams.copyWith(
                      gameVersions: newVersions.isEmpty ? null : newVersions,
                    );
                  }
                  widget.onFilterChanged(_currentParams);
                });
              },
              selectedColor: BAColors.primary.withOpacity(0.2),
              checkmarkColor: BAColors.primary,
              backgroundColor: BAColors.surfaceVariantOf(context),
              labelStyle: TextStyle(color: isSelected ? BAColors.primary : textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? BAColors.primary : BAColors.borderOf(context),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoaderFilter(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '加载器',
          style: BATypography.bodyLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _loaders.map((loader) {
            final isSelected = _currentParams.loaders?.contains(loader) ?? false;
            return FilterChip(
              label: Text(loader),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    final newLoaders = List<String>.from(_currentParams.loaders ?? [])
                      ..add(loader);
                    _currentParams = _currentParams.copyWith(loaders: newLoaders);
                  } else {
                    final newLoaders = List<String>.from(_currentParams.loaders ?? [])
                      ..remove(loader);
                    _currentParams = _currentParams.copyWith(
                      loaders: newLoaders.isEmpty ? null : newLoaders,
                    );
                  }
                  widget.onFilterChanged(_currentParams);
                });
              },
              selectedColor: BAColors.secondary.withOpacity(0.2),
              checkmarkColor: BAColors.secondary,
              backgroundColor: BAColors.surfaceVariantOf(context),
              labelStyle: TextStyle(color: isSelected ? BAColors.secondary : textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? BAColors.secondary : BAColors.borderOf(context),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortFilter(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    final sortLabels = {
      'relevance': '相关性',
      'downloads': '下载量',
      'updated': '更新时间',
      'newest': '最新发布',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '排序方式',
          style: BATypography.bodyLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: BAColors.borderOf(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentParams.sortBy,
              isExpanded: true,
              dropdownColor: BAColors.surfaceOf(context),
              style: BATypography.bodyMedium.copyWith(color: textPrimary),
              items: _sortOptions.map((sort) {
                return DropdownMenuItem<String>(
                  value: sort,
                  child: Text(sortLabels[sort] ?? sort),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentParams = _currentParams.copyWith(sortBy: value);
                    widget.onFilterChanged(_currentParams);
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _currentParams = widget.initialParams.copyWith(
        gameVersions: null,
        loaders: null,
        categories: null,
        sortBy: 'relevance',
      );
      widget.onFilterChanged(_currentParams);
    });
    widget.onReset?.call();
  }
}
