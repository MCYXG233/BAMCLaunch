import 'package:flutter/material.dart';

import '../../../game/game_statistics.dart';
import '../../components/ba_dialog.dart';
import '../../components/ba_notification.dart';
import '../../theme/colors.dart';
import 'settings_components.dart';

/// 统计设置页:展示游戏时长、启动次数等统计,支持清除数据
class StatisticsSettingsPage extends StatefulWidget {
  const StatisticsSettingsPage({super.key});

  @override
  State<StatisticsSettingsPage> createState() => _StatisticsSettingsPageState();
}

class _StatisticsSettingsPageState extends State<StatisticsSettingsPage> {
  final GameStatisticsManager _statisticsManager =
      GameStatisticsManager.instance;

  /// 将时长格式化为"X小时Y分钟"或"Y分钟"
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else {
      return '$minutes分钟';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPlayTime = _statisticsManager.getTotalPlayTime();
    final totalLaunchCount = _statisticsManager.getTotalLaunchCount();
    final todayPlayTime = _statisticsManager.getTodayPlayTime();
    final mostPlayed = _statisticsManager.getMostPlayedInstance();

    final children = <Widget>[
      SettingsCard(
        title: '总统计',
        children: [
          SettingsRow(
            icon: Icons.access_time,
            title: '总游戏时长',
            subtitle: _formatDuration(totalPlayTime),
            control: const SizedBox.shrink(),
          ),
          SettingsRow(
            icon: Icons.casino,
            title: '总启动次数',
            subtitle: '$totalLaunchCount 次',
            control: const SizedBox.shrink(),
          ),
          SettingsRow(
            icon: Icons.calendar_today,
            title: '今日游戏',
            subtitle: _formatDuration(todayPlayTime),
            control: const SizedBox.shrink(),
          ),
        ],
      ),
    ];

    if (mostPlayed != null) {
      children.add(
        SettingsCard(
          title: '最常玩的实例',
          children: [
            SettingsRow(
              icon: Icons.star,
              title: mostPlayed.instanceName,
              subtitle:
                  '${_formatDuration(Duration(seconds: mostPlayed.totalPlayTimeSeconds))} / ${mostPlayed.launchCount}次',
              control: const SizedBox.shrink(),
              iconColor: BAColors.accentPinkDarkOf(context),
            ),
          ],
        ),
      );
    }

    children.add(
      SettingsCard(
        title: '数据管理',
        children: [
          SettingsRow(
            icon: Icons.delete_outline,
            title: '清除统计数据',
            subtitle: '清除所有游戏统计数据',
            control: SettingsPrimaryButton(
              text: '清除',
              onPressed: () async {
                final confirmed = await BAConfirmDialog.show(
                  context: context,
                  title: '清除统计数据',
                  content: '确定要清除所有统计数据吗？此操作不可撤销',
                  confirmText: '清除',
                );
                if (confirmed) {
                  await _statisticsManager.clearAllData();
                  if (mounted) setState(() {});
                  NotificationManager().showSuccess('统计数据已清除');
                }
              },
              color: BAColors.accentPinkDarkOf(context),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: children,
    );
  }
}
