import 'package:flutter/material.dart';
import '../../../../instance/models.dart';
import '../../../../game/game_statistics.dart';
import '../../../theme/colors.dart';
import '../../../components/ba_context_menu.dart';
import '../../../components/instance_tile.dart';

class GameLibraryInstanceGrid extends StatelessWidget {
  final List<GameInstance> instances;
  final String? selectedInstanceId;
  final Set<String> launchingIds;
  final String searchQuery;
  final int selectedFilter;
  final GameStatisticsManager statsManager;
  final ValueChanged<GameInstance> onSelectInstance;
  final ValueChanged<GameInstance> onLaunchGame;
  final ValueChanged<GameInstance> onDuplicateInstance;
  final ValueChanged<GameInstance> onExportInstance;
  final ValueChanged<GameInstance> onOpenBackupManager;
  final ValueChanged<GameInstance> onOpenModManager;
  final ValueChanged<GameInstance> onDeleteInstance;

  const GameLibraryInstanceGrid({
    super.key,
    required this.instances,
    required this.selectedInstanceId,
    required this.launchingIds,
    required this.searchQuery,
    required this.selectedFilter,
    required this.statsManager,
    required this.onSelectInstance,
    required this.onLaunchGame,
    required this.onDuplicateInstance,
    required this.onExportInstance,
    required this.onOpenBackupManager,
    required this.onOpenModManager,
    required this.onDeleteInstance,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours小时$minutes分';
    } else {
      return '$minutes分';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (instances.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: instances.length,
        itemBuilder: (context, index) {
          final instance = instances[index];
          return _buildInstanceCard(context, instance);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              searchQuery.isNotEmpty || selectedFilter != 0
                  ? Icons.search_off_rounded
                  : Icons.rocket_launch_rounded,
              size: 48,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            searchQuery.isNotEmpty || selectedFilter != 0
                ? '没有找到匹配的实例'
                : '还没有游戏实例',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            searchQuery.isNotEmpty || selectedFilter != 0
                ? '尝试修改搜索条件或切换筛选项'
                : '点击右下角按钮创建第一个实例',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceCard(BuildContext context, GameInstance instance) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = launchingIds.contains(instance.id);
    final instanceStats = statsManager.getInstanceStatistics(instance.id);

    final status = isRunning
        ? InstanceTileStatus.running
        : (isLaunching
              ? InstanceTileStatus.launching
              : InstanceTileStatus.stopped);

    final hasLoader = instance.loader != null && instance.loader!.isNotEmpty;
    final parts = <String>[
      if (instance.version.isNotEmpty) instance.version,
      if (hasLoader) instance.loader!,
      if (instanceStats != null)
        _formatDuration(Duration(seconds: instanceStats.totalPlayTimeSeconds)),
    ];
    final subtitle = parts.join(' · ');
    final showSubtitle = subtitle.isNotEmpty && subtitle != instance.name;

    return InstanceTile(
      name: instance.name,
      subtitle: showSubtitle ? subtitle : '',
      status: status,
      selected: selectedInstanceId == instance.id,
      onTap: () => onSelectInstance(instance),
      contextMenuItems: [
        BAContextMenuItem(
          icon: Icons.play_arrow_rounded,
          label: '启动',
          onTap: () => onLaunchGame(instance),
        ),
        BAContextMenuItem(
          icon: Icons.copy_rounded,
          label: '复制',
          onTap: () => onDuplicateInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.file_upload_rounded,
          label: '导出',
          onTap: () => onExportInstance(instance),
        ),
        BAContextMenuItem(
          icon: Icons.backup_rounded,
          label: '备份管理',
          onTap: () => onOpenBackupManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.extension_rounded,
          label: '模组管理',
          onTap: () => onOpenModManager(instance),
        ),
        BAContextMenuItem(
          icon: Icons.delete_outline_rounded,
          label: '删除',
          danger: true,
          onTap: () => onDeleteInstance(instance),
        ),
      ],
    );
  }
}
