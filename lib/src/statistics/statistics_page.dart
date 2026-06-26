import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/theme/colors.dart';
import '../ui/components/ba_notification.dart';
import '../game/game_statistics.dart';
import 'play_time_tracker.dart';
import 'statistics_chart.dart';

/// 统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final PlayTimeTracker _playTimeTracker = PlayTimeTracker.instance;
  final GameStatisticsManager _statisticsManager = GameStatisticsManager.instance;

  TimeRange _selectedTimeRange = TimeRange.week;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _playTimeTracker.initialize();
    await _statisticsManager.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = BAColors.backgroundOf(context);
    final textColor = BAColors.textPrimaryOf(context);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '游戏统计',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TimeRangeSelector(
                selectedRange: _selectedTimeRange,
                onRangeChanged: (range) {
                  setState(() {
                    _selectedTimeRange = range;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isInitialized
                ? _buildStatisticsContent()
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildPlayTimeChart(),
          const SizedBox(height: 24),
          _buildInstanceDistributionChart(),
          const SizedBox(height: 24),
          _buildPlayTimeLeaderboard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalPlayTime = _playTimeTracker.getTotalPlayTime();
    final todayPlayTime = _selectedTimeRange == TimeRange.week
        ? _playTimeTracker.getWeekPlayTime()
        : _playTimeTracker.getMonthPlayTime();
    final totalLaunchCount = _statisticsManager.getTotalLaunchCount();
    final topInstance = _playTimeTracker.getTopPlayTimeEntries(limit: 1).firstOrNull;

    return Row(
      children: [
        Expanded(
          child: StatisticsCard(
            title: '总游戏时长',
            value: _formatDuration(totalPlayTime),
            subtitle: '累计游戏时间',
            icon: Icons.access_time,
            iconColor: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatisticsCard(
            title: _selectedTimeRange == TimeRange.week ? '本周游戏时长' : '本月游戏时长',
            value: _formatDuration(todayPlayTime),
            subtitle: _selectedTimeRange == TimeRange.week ? '最近7天' : '最近30天',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatisticsCard(
            title: '总启动次数',
            value: '$totalLaunchCount',
            subtitle: '游戏启动次数',
            icon: Icons.play_arrow,
            iconColor: const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatisticsCard(
            title: '最常玩实例',
            value: topInstance?.instanceName ?? '-',
            subtitle: topInstance != null
                ? _formatDuration(Duration(seconds: topInstance.playTimeSeconds))
                : '暂无数据',
            icon: Icons.star,
            iconColor: const Color(0xFFFFE66D),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayTimeChart() {
    final days = _selectedTimeRange == TimeRange.week ? 7 : 30;
    final dailyData = _playTimeTracker.getDailyPlayTimeData(days: days);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: BAColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '每日游戏时长',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: DailyPlayTimeChart(
              data: dailyData,
              barColor: BAColors.primaryOf(context),
              labelColor: BAColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceDistributionChart() {
    final topEntries = _playTimeTracker.getTopPlayTimeEntries(limit: 10);
    final instanceData = <String, int>{};

    for (final entry in topEntries) {
      instanceData[entry.instanceName] = entry.playTimeSeconds;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: BAColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '各实例游戏时长分布',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: InstanceDistributionChart(data: instanceData),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTimeLeaderboard() {
    final topEntries = _playTimeTracker.getTopPlayTimeEntries(limit: 10);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: BAColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '游戏时长排行榜 (Top 10)',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '暂无游戏记录',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...topEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final rank = index + 1;

              return _buildLeaderboardItem(
                rank: rank,
                instanceName: item.instanceName,
                playTime: item.playTimeSeconds,
                launchCount: item.launchCount,
                lastPlayed: item.lastPlayed,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String instanceName,
    required int playTime,
    required int launchCount,
    DateTime? lastPlayed,
  }) {
    Color rankColor;
    IconData? rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = BAColors.textSecondaryOf(context);
        rankIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: rank <= 3
            ? rankColor.withOpacity(0.1)
            : BAColors.surfaceVariantOf(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: rank <= 3
            ? Border.all(color: rankColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instanceName,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastPlayed != null
                      ? '最后游玩: ${_formatDate(lastPlayed)}'
                      : '暂无游玩记录',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(Duration(seconds: playTime)),
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$launchCount 次启动',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
