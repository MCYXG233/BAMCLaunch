import 'package:flutter/material.dart';

import '../../../../game/game_statistics.dart';
import '../../../../instance/models.dart';
import '../../../animations/ba_animations.dart';
import '../../../components/ba_context_menu.dart';
import '../../../theme/colors.dart';

/// 实例卡片 - 带动画悬停效果
///
/// hover 状态由父级统一管理(通过 [hoveredInstanceIds] 集合),
/// 以保证一个实例 hover 不影响其他实例的视觉状态
class InstanceCard extends StatelessWidget {
  const InstanceCard({
    super.key,
    required this.instance,
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

  final GameInstance instance;
  final Set<String> launchingIds;
  final Set<String> hoveredInstanceIds;

  /// hover 状态变化回调,参数为(实例, 是否进入 hover)
  final void Function(GameInstance instance, bool isEntering) onHoverChange;

  final VoidCallback onSelect;
  final VoidCallback onLaunch;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onOpenBackupManager;
  final VoidCallback onOpenModManager;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isRunning = instance.status == InstanceStatus.running;
    final isLaunching = launchingIds.contains(instance.id);
    final statsManager = GameStatisticsManager.instance;
    final instanceStats = statsManager.getInstanceStatistics(instance.id);

    final statusColor = isRunning
        ? BAColors.successOf(context)
        : (isLaunching
              ? BAColors.warningOf(context)
              : BAColors.primaryLightOf(context));

    final isHovered = hoveredInstanceIds.contains(instance.id);

    Widget card = BAContextMenu(
      items: [
        BAContextMenuItem(
          icon: Icons.play_arrow,
          label: '启动',
          onTap: onLaunch,
        ),
        BAContextMenuItem(
          icon: Icons.copy,
          label: '复制',
          onTap: onDuplicate,
        ),
        BAContextMenuItem(
          icon: Icons.file_upload,
          label: '导出',
          onTap: onExport,
        ),
        BAContextMenuItem(
          icon: Icons.backup,
          label: '备份管理',
          onTap: onOpenBackupManager,
        ),
        BAContextMenuItem(
          icon: Icons.extension,
          label: '模组管理',
          onTap: onOpenModManager,
        ),
        BAContextMenuItem(
          icon: Icons.delete,
          label: '删除',
          danger: true,
          onTap: onDelete,
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHoverChange(instance, true),
        onExit: (_) => onHoverChange(instance, false),
        child: AnimatedScale(
          scale: isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRunning
                    ? BAColors.successOf(context).withValues(alpha: 0.6)
                    : BAColors.borderOf(context).withValues(alpha: 0.5),
                width: isRunning ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRunning
                      ? BAColors.successOf(context).withValues(alpha: 0.25)
                      : BAColors.shadowOf(context).withValues(alpha: 0.4),
                  blurRadius: isHovered ? 24 : 16,
                  offset: Offset(0, isHovered ? 10 : 6),
                ),
                if (isHovered)
                  BoxShadow(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                if (isRunning)
                  BoxShadow(
                    color: BAColors.successOf(context).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部状态和图标
                      Row(
                        children: [
                          // 脉冲状态指示器
                          BAAnimations.pulse(
                            isActive: isRunning || isLaunching,
                            duration: Duration(
                              milliseconds: isRunning ? 1000 : 1500,
                            ),
                            scaleBegin: 1.0,
                            scaleEnd: isRunning ? 1.4 : 1.2,
                            glowColor: statusColor,
                            glowRadius: isRunning ? 8 : 5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRunning ? '运行中' : (isLaunching ? '启动中' : '就绪'),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // 操作按钮
                          if (isLaunching)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  BAColors.warningOf(context),
                                ),
                              ),
                            )
                          else
                            Icon(
                              isRunning
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_fill_rounded,
                              color: isRunning
                                  ? BAColors.successOf(context)
                                  : BAColors.primaryLightOf(context),
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 实例图标
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRunning
                                ? [
                                    BAColors.successOf(context),
                                    BAColors.successDark,
                                  ]
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
                                          : BAColors.primaryOf(context))
                                      .withValues(alpha: 0.35),
                              blurRadius: isHovered ? 18 : 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Color(0xFFFFFFFF),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 实例名称
                      Text(
                        instance.name,
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 版本信息
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BAColors.primaryOf(
                            context,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BAColors.primaryOf(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          instance.version,
                          style: TextStyle(
                            color: BAColors.primaryLightOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 加载器信息
                      if (instance.loader != null)
                        Text(
                          instance.loader!,
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(
                              context,
                            ).withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      if (instanceStats != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: BAColors.textSecondaryOf(
                                context,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_formatDuration(Duration(seconds: instanceStats.totalPlayTimeSeconds))} / ${instanceStats.launchCount}次',
                                style: TextStyle(
                                  color: BAColors.textSecondaryOf(
                                    context,
                                  ).withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ), // AnimatedContainer
        ), // AnimatedScale
      ), // MouseRegion
    ); // BAContextMenu

    // 运行中的实例添加渐变边框动画
    if (isRunning) {
      card = BAAnimations.gradientBorder(
        isActive: true,
        duration: const Duration(milliseconds: 4000),
        gradientColors: [
          BAColors.successOf(context),
          BAColors.primaryLightOf(context),
          BAColors.successOf(context),
          BAColors.primaryOf(context),
          BAColors.successOf(context),
        ],
        borderWidth: 1.5,
        borderRadius: 16,
        child: card,
      );
    }

    return card;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours时$minutes分';
    } else {
      return '$minutes分';
    }
  }
}
