import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../instance/models.dart';
import '../resource_constants.dart';
import 'sort_button.dart';
import 'compact_dropdown.dart';
import 'type_chip.dart';

/// 资源筛选栏 - 搜索 + chips + 下拉的统一容器
///
/// 参考 BakaXL 笨蛋广场风格，但不生搬硬套：
/// - 顶部大搜索框独占一行（最突出）
/// - 类型 chips 一行横向多选（颜色高亮）
/// - 工具行：加载器 / 版本 / 排序（紧凑右对齐）
/// - 背景采用不透明 surface，保证清晰
class ResourceFilterBar extends StatelessWidget {
  // 搜索
  final TextEditingController searchController;
  final String query;
  final String searchHint;
  final ValueChanged<String> onQuerySubmitted;
  final VoidCallback onQueryCleared;

  // 排序
  final String sort;
  final ValueChanged<String> onSortChanged;

  // 资源类型 chips（可为 null 表示无类型筛选，例如 ModpackTab）
  final ResourceType? selectedType;
  final ValueChanged<ResourceType?>? onTypeChanged;

  // 版本下拉
  final String? gameVersion;
  final ValueChanged<String?> onGameVersionChanged;

  // 加载器下拉
  final String? loader;
  final ValueChanged<String?> onLoaderChanged;

  // 左侧徽标（整合包 Tab 专用），如不传则隐藏
  final String? leftBadgeText;
  final IconData? leftBadgeIcon;
  final Color? leftBadgeColor;

  const ResourceFilterBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.searchHint,
    required this.onQuerySubmitted,
    required this.onQueryCleared,
    required this.sort,
    required this.onSortChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.gameVersion,
    required this.onGameVersionChanged,
    required this.loader,
    required this.onLoaderChanged,
    this.leftBadgeText,
    this.leftBadgeIcon,
    this.leftBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: BAColors.shadowOf(context).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：大搜索框独占一行
          _buildSearchField(context),
          // 类型 chips 行（如果有）
          if (onTypeChanged != null) ...[
            const SizedBox(height: 12),
            _buildTypeChipsRow(context),
          ],
          // 工具行：加载器 / 版本 / 排序
          const SizedBox(height: 10),
          _buildToolsRow(context),
        ],
      ),
    );
  }

  /// 大搜索框（可带左侧徽标）
  Widget _buildSearchField(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final border = BAColors.borderOf(context).withValues(alpha: 0.5);

    final searchField = SizedBox(
      height: 42,
      child: TextField(
        controller: searchController,
        onSubmitted: onQuerySubmitted,
        style: TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: TextStyle(
            color: BAColors.textDisabledOf(context),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: textSecondary,
            size: 20,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: textSecondary,
                    size: 16,
                  ),
                  onPressed: onQueryCleared,
                )
              : null,
          filled: true,
          fillColor: BAColors.surfaceVariantOf(context).withValues(alpha: 0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: BAColors.primaryOf(context).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );

    if (leftBadgeText == null) {
      return searchField;
    }

    // 带徽标：徽标 + 搜索框
    final color = leftBadgeColor ?? BAColors.primaryOf(context);
    return Row(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                leftBadgeIcon ?? Icons.inventory_2_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                leftBadgeText!,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: searchField),
      ],
    );
  }

  /// 类型 chips 行
  Widget _buildTypeChipsRow(BuildContext context) {
    final typeColors = ResourceConstants.typeColorsOf(context);

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ResourceConstants.modrinthTypeOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final opt = ResourceConstants.modrinthTypeOptions[index];
          final selected = selectedType == opt.value;
          final color = typeColors[opt.value] ?? BAColors.primaryOf(context);
          return Padding(
            // 视觉上让 chips 上下居中
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: TypeChip(
              label: opt.key,
              icon: ResourceConstants.typeIcons[opt.value] ?? Icons.apps,
              selected: selected,
              color: color,
              onTap: () => onTypeChanged?.call(opt.value),
            ),
          );
        },
      ),
    );
  }

  /// 工具行：加载器 / 版本 / 排序（紧凑右对齐）
  Widget _buildToolsRow(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);

    return Row(
      children: [
        // 加载器
        CompactDropdown(
          value: loader,
          hint: '加载器',
          items: ResourceConstants.loaders.map((e) => e.value).toList(),
          displayItems: ResourceConstants.loaders.map((e) => e.key).toList(),
          onChanged: onLoaderChanged,
          textPrimary: textPrimary,
        ),
        const SizedBox(width: 8),
        // 版本
        CompactDropdown(
          value: gameVersion,
          hint: '游戏版本',
          items: ResourceConstants.gameVersions,
          onChanged: onGameVersionChanged,
          textPrimary: textPrimary,
        ),
        const Spacer(),
        // 排序
        SortButton(
          currentSort: sort,
          onSelected: onSortChanged,
          textPrimary: textPrimary,
        ),
      ],
    );
  }
}
