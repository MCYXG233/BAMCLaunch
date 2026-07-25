import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 游戏库顶部标题栏
class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.instanceCount,
    required this.onRefresh,
  });

  final int instanceCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
      child: Row(
        children: [
          // 中间：图标 + 标题 + 副标题
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(context).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gamepad,
                  color: Color(0xFFFFFFFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '游戏库',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '管理你的 Minecraft 实例',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(
                        context,
                      ).withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // 右侧：实例总数统计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BAColors.borderOf(context).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BAColors.primaryLightOf(context),
                        BAColors.primaryOf(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: Color(0xFFFFFFFF),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$instanceCount',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '个实例',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 操作按钮：刷新
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BAColors.borderOf(context).withValues(alpha: 0.5),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(14),
                child: Icon(
                  Icons.refresh_rounded,
                  color: BAColors.primaryLightOf(context),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 游戏统计卡片行(总时长/总次数/今日时长)
class LibraryStatsRow extends StatelessWidget {
  const LibraryStatsRow({
    super.key,
    required this.totalPlayTime,
    required this.totalLaunchCount,
    required this.todayPlayTime,
  });

  final Duration totalPlayTime;
  final int totalLaunchCount;
  final Duration todayPlayTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.access_time,
            label: '总游戏时长',
            value: _formatDuration(totalPlayTime),
            accent: BAColors.primaryLightOf(context),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.casino,
            label: '总启动次数',
            value: '$totalLaunchCount 次',
            accent: BAColors.primaryOf(context),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.calendar_today,
            label: '今日游戏',
            value: _formatDuration(todayPlayTime),
            accent: BAColors.borderOf(context),
          ),
        ],
      ),
    );
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.3),
                    accent.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Icon(
                icon,
                color: BAColors.textPrimaryOf(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(
                        context,
                      ).withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
