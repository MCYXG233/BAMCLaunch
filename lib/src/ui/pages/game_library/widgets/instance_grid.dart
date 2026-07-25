import 'package:flutter/material.dart';

import '../../../../instance/models.dart';
import '../../../theme/colors.dart';
import 'instance_card.dart';

/// 实例网格
///
/// 根据搜索/筛选条件展示实例列表,空状态自适应文案
class InstanceGrid extends StatelessWidget {
  const InstanceGrid({
    super.key,
    required this.instances,
    required this.searchQuery,
    required this.selectedFilter,
    required this.launchingIds,
    required this.hoveredInstanceIds,
    required this.onHoverChange,
    required this.onSelect,
    required this.onLaunch,
    required this.onDuplicate,
    required this.onExport,
    required this.onOpenBackupManager,
    required this.onOpenModManager,
    required this.onDelete,
  });

  final List<GameInstance> instances;
  final String searchQuery;
  final int selectedFilter;
  final Set<String> launchingIds;
  final Set<String> hoveredInstanceIds;

  /// hover 状态变化回调,参数为(实例, 是否进入 hover)
  final void Function(GameInstance instance, bool isEntering) onHoverChange;

  final void Function(GameInstance instance) onSelect;
  final void Function(GameInstance instance) onLaunch;
  final void Function(GameInstance instance) onDuplicate;
  final void Function(GameInstance instance) onExport;
  final void Function(GameInstance instance) onOpenBackupManager;
  final void Function(GameInstance instance) onOpenModManager;
  final void Function(GameInstance instance) onDelete;

  @override
  Widget build(BuildContext context) {
    if (instances.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 响应式网格:根据宽度动态调整列数
          final width = constraints.maxWidth;
          final crossAxisCount = width < 600
              ? 2
              : width < 900
              ? 3
              : width < 1300
              ? 4
              : width < 1700
              ? 5
              : 6;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: instances.length,
            itemBuilder: (context, index) {
              final instance = instances[index];
              return InstanceCard(
                instance: instance,
                launchingIds: launchingIds,
                hoveredInstanceIds: hoveredInstanceIds,
                onHoverChange: onHoverChange,
                onSelect: () => onSelect(instance),
                onLaunch: () => onLaunch(instance),
                onDuplicate: () => onDuplicate(instance),
                onExport: () => onExport(instance),
                onOpenBackupManager: () => onOpenBackupManager(instance),
                onOpenModManager: () => onOpenModManager(instance),
                onDelete: () => onDelete(instance),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilter = searchQuery.isNotEmpty || selectedFilter != 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 圆形卡片包裹图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              hasFilter
                  ? Icons.search_off_rounded
                  : Icons.rocket_launch_rounded,
              size: 48,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            hasFilter ? '没有找到匹配的实例' : '还没有游戏实例',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasFilter ? '尝试修改搜索条件或切换筛选项' : '点击右下角按钮创建第一个实例',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
