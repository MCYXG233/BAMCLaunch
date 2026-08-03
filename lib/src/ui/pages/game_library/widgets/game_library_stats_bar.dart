import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class GameLibraryStatsBar extends StatelessWidget {
  final Duration totalPlayTime;
  final int totalLaunchCount;
  final Duration todayPlayTime;

  const GameLibraryStatsBar({
    super.key,
    required this.totalPlayTime,
    required this.totalLaunchCount,
    required this.todayPlayTime,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatCell(
              context,
              label: '总游戏时间',
              value: _formatDuration(totalPlayTime),
            ),
            _buildStatDivider(context),
            _buildStatCell(
              context,
              label: '总启动次数',
              value: '$totalLaunchCount 次',
            ),
            _buildStatDivider(context),
            _buildStatCell(
              context,
              label: '今日游戏',
              value: _formatDuration(todayPlayTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: BAColors.borderOf(context).withValues(alpha: 0.5),
    );
  }
}
