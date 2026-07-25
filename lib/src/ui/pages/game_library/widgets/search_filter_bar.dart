import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 搜索框 + 筛选按钮行
///
/// 内部不持有状态,所有输入事件通过回调向上传递
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.filters,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final List<String> filters;
  final int selectedFilter;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<int> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 搜索框 - 毛玻璃
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.shadowOf(context).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '搜索实例...',
                  hintStyle: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: BAColors.textSecondaryOf(context),
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: BAColors.textSecondaryOf(context),
                            size: 18,
                          ),
                          onPressed: onSearchCleared,
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
          ),
          const SizedBox(width: 16),

          // 筛选按钮 - 毛玻璃
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(filters.length, (index) {
                final isSelected = selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onFilterSelected(index),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  BAColors.primaryLightOf(context),
                                  BAColors.primaryOf(context),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : BAColors.surfaceOf(
                                context,
                              ).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : BAColors.borderOf(
                                  context,
                                ).withValues(alpha: 0.5),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: BAColors.primaryOf(
                                    context,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filters[index],
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : BAColors.textSecondaryOf(context),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
