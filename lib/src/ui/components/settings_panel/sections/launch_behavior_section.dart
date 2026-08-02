import 'package:flutter/material.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 启动行为 - 启动器自身与游戏进程的行为
class LaunchBehaviorSection extends StatelessWidget {
  final bool launchAtStartup;
  final bool minimizeToTray;
  final bool closeToTray;
  final String processPriority;
  final bool skipFirstScreenOptions;
  final bool displayGameLog;
  final String customTitle;
  final ValueChanged<bool> onLaunchAtStartupChanged;
  final ValueChanged<bool> onMinimizeToTrayChanged;
  final ValueChanged<bool> onCloseToTrayChanged;
  final ValueChanged<String> onProcessPriorityChanged;
  final ValueChanged<bool> onSkipFirstScreenChanged;
  final ValueChanged<bool> onDisplayGameLogChanged;
  final ValueChanged<String> onCustomTitleChanged;

  const LaunchBehaviorSection({
    super.key,
    required this.launchAtStartup,
    required this.minimizeToTray,
    required this.closeToTray,
    required this.processPriority,
    required this.skipFirstScreenOptions,
    required this.displayGameLog,
    required this.customTitle,
    required this.onLaunchAtStartupChanged,
    required this.onMinimizeToTrayChanged,
    required this.onCloseToTrayChanged,
    required this.onProcessPriorityChanged,
    required this.onSkipFirstScreenChanged,
    required this.onDisplayGameLogChanged,
    required this.onCustomTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '启动行为',
      breadcrumbs: const ['游戏', '启动行为'],
      children: [
        SettingsSectionCard(
          title: '启动器自身',
          titleIcon: Icons.rocket_launch_outlined,
          children: [
            SwitchRow(
              icon: Icons.power_settings_new,
              title: '开机自启',
              subtitle: '系统启动时自动运行启动器',
              value: launchAtStartup,
              onChanged: onLaunchAtStartupChanged,
            ),
            SwitchRow(
              icon: Icons.minimize,
              title: '最小化到托盘',
              subtitle: '关闭主窗口时不退出，仅隐藏',
              value: minimizeToTray,
              onChanged: onMinimizeToTrayChanged,
            ),
            SwitchRow(
              icon: Icons.close,
              title: '关闭时直接退出',
              subtitle: '默认推荐关闭（最小化到托盘）',
              value: !closeToTray,
              onChanged: (v) => onCloseToTrayChanged(!v),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '游戏进程',
          titleIcon: Icons.gamepad_outlined,
          children: [
            DropdownRow(
              icon: Icons.priority_high_outlined,
              title: '进程优先级',
              subtitle: '设置游戏进程相对系统的优先级',
              value: processPriority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('低（不抢占系统）')),
                DropdownMenuItem(value: 'normal', child: Text('普通（默认）')),
                DropdownMenuItem(value: 'high', child: Text('高（游戏优先）')),
                DropdownMenuItem(value: 'realtime', child: Text('实时（谨慎使用）')),
              ],
              onChanged: (v) {
                if (v != null) onProcessPriorityChanged(v);
              },
            ),
            SwitchRow(
              icon: Icons.skip_next_outlined,
              title: '跳过首屏选项',
              subtitle: '跳过语言/账户等首屏选择界面',
              value: skipFirstScreenOptions,
              onChanged: onSkipFirstScreenChanged,
            ),
            SwitchRow(
              icon: Icons.terminal_outlined,
              title: '显示游戏日志',
              subtitle: '游戏运行时侧边显示日志输出',
              value: displayGameLog,
              onChanged: onDisplayGameLogChanged,
            ),
            SwitchRow(
              icon: Icons.title_outlined,
              title: '自定义窗口标题',
              subtitle: customTitle.isEmpty
                  ? '使用 BAMCLaunch'
                  : '当前：$customTitle',
              value: customTitle.isNotEmpty,
              onChanged: (v) {
                onCustomTitleChanged(
                  v
                      ? customTitle.isEmpty
                            ? 'BAMCLaunch'
                            : customTitle
                      : '',
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
