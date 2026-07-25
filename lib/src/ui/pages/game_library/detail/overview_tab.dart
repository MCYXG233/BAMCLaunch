import 'package:flutter/material.dart';

import '../../../../game/game_statistics.dart';
import '../../../../instance/models.dart';
import '../../../theme/colors.dart';
import 'detail_info_widgets.dart';

/// 概览Tab
///
/// 展示实例信息卡片、统计信息、启动按钮、操作按钮行
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.instance,
    required this.launchingIds,
    required this.onLaunch,
    required this.onDuplicate,
    required this.onExport,
    required this.onOpenBackupManager,
    required this.onOpenModManager,
    required this.onDelete,
  });

  final GameInstance instance;
  final Set<String> launchingIds;

  final void Function(GameInstance instance) onLaunch;
  final void Function(GameInstance instance) onDuplicate;
  final void Function(GameInstance instance) onExport;
  final void Function(GameInstance instance) onOpenBackupManager;
  final void Function(GameInstance instance) onOpenModManager;
  final void Function(GameInstance instance) onDelete;

  @override
  Widget build(BuildContext context) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = launchingIds.contains(instance.id);
    final statsManager = GameStatisticsManager.instance;
    final instanceStats = statsManager.getInstanceStatistics(instance.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewInfoCard(context),
          const SizedBox(height: 20),

          // 统计信息网格
          Row(
            children: [
              Expanded(
                child: OverviewStatItem(
                  icon: Icons.access_time_rounded,
                  label: '游戏时长',
                  value: _formatDuration(
                    Duration(
                      seconds:
                          instanceStats?.totalPlayTimeSeconds ??
                          (instance.playTimeSeconds ?? 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OverviewStatItem(
                  icon: Icons.calendar_today_rounded,
                  label: '上次启动',
                  value: _formatDateTime(
                    instance.lastPlayed ?? instanceStats?.lastLaunchTime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OverviewStatItem(
                  icon: Icons.extension_rounded,
                  label: 'Mod数量',
                  value: '${instance.resources.mods.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OverviewStatItem(
                  icon: Icons.rocket_launch_rounded,
                  label: '启动次数',
                  value: '${instanceStats?.launchCount ?? 0} 次',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 启动按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: (isRunning || isLaunching)
                    ? null
                    : () => onLaunch(instance),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isRunning
                          ? [BAColors.successOf(context), BAColors.successDark]
                          : isLaunching
                          ? [BAColors.warningOf(context), BAColors.warningDark]
                          : [
                              BAColors.primaryLightOf(context),
                              BAColors.primaryOf(context),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isRunning
                                    ? BAColors.successOf(context)
                                    : isLaunching
                                    ? BAColors.warningOf(context)
                                    : BAColors.primaryOf(context))
                                .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLaunching
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFFFFF),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRunning
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFFFFFFFF),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRunning ? '游戏运行中' : '启动游戏',
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮行
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OverviewActionButton(
                icon: Icons.copy_rounded,
                label: '复制',
                onTap: () => onDuplicate(instance),
              ),
              OverviewActionButton(
                icon: Icons.file_upload_rounded,
                label: '导出',
                onTap: () => onExport(instance),
              ),
              OverviewActionButton(
                icon: Icons.backup_rounded,
                label: '备份',
                onTap: () => onOpenBackupManager(instance),
              ),
              OverviewActionButton(
                icon: Icons.extension_rounded,
                label: '模组管理',
                onTap: () => onOpenModManager(instance),
              ),
              OverviewActionButton(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                isDanger: true,
                onTap: () => onDelete(instance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 概览 - 实例信息卡片
  Widget _buildOverviewInfoCard(BuildContext context) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = launchingIds.contains(instance.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: BAColors.shadowOf(context).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 实例大图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRunning
                    ? [BAColors.successOf(context), BAColors.successDark]
                    : [
                        BAColors.primaryLightOf(context),
                        BAColors.primaryOf(context),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRunning
                              ? BAColors.successOf(context)
                              : BAColors.primaryOf(context))
                          .withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFFFFF),
              size: 36,
            ),
          ),
          const SizedBox(width: 20),

          // 实例信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instance.name,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InfoRow(
                  icon: Icons.update_rounded,
                  label: '版本',
                  value: instance.version,
                ),
                if (instance.loader != null) ...[
                  const SizedBox(height: 4),
                  InfoRow(
                    icon: Icons.layers_rounded,
                    label: '加载器',
                    value: instance.loader!,
                  ),
                ],
                if (instance.description != null &&
                    instance.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: '描述',
                    value: instance.description!,
                  ),
                ],
                const SizedBox(height: 4),
                InfoRow(
                  icon: Icons.circle,
                  label: '状态',
                  value: isRunning ? '运行中' : (isLaunching ? '启动中' : '就绪'),
                  valueColor: isRunning
                      ? BAColors.successOf(context)
                      : isLaunching
                      ? BAColors.warningOf(context)
                      : BAColors.primaryLightOf(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时长为"X时Y分"或"Y分"
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours时$minutes分';
    } else {
      return '$minutes分';
    }
  }

  /// 格式化日期时间为"YYYY-MM-DD HH:MM"
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '从未';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
