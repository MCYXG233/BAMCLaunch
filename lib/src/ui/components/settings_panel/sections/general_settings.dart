import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 通用设置 - 启动行为、动画、托盘
class GeneralSettings extends StatelessWidget {
  final bool launchAtStartup;
  final bool minimizeToTray;
  final bool closeToTray;
  final bool autoUpdate;
  final bool enableAnimation;
  final ValueChanged<bool> onLaunchAtStartupChanged;
  final ValueChanged<bool> onMinimizeToTrayChanged;
  final ValueChanged<bool> onCloseToTrayChanged;
  final ValueChanged<bool> onAutoUpdateChanged;
  final ValueChanged<bool> onEnableAnimationChanged;

  const GeneralSettings({
    super.key,
    required this.launchAtStartup,
    required this.minimizeToTray,
    required this.closeToTray,
    required this.autoUpdate,
    required this.enableAnimation,
    required this.onLaunchAtStartupChanged,
    required this.onMinimizeToTrayChanged,
    required this.onCloseToTrayChanged,
    required this.onAutoUpdateChanged,
    required this.onEnableAnimationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '通用',
      breadcrumbs: const ['通用'],
      children: [
        SettingsSectionCard(
          title: '启动行为',
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
              subtitle: '最小化时隐藏到系统托盘',
              value: minimizeToTray,
              onChanged: onMinimizeToTrayChanged,
            ),
            SwitchRow(
              icon: Icons.close,
              title: '关闭到托盘',
              subtitle: '关闭窗口时最小化到托盘而非退出',
              value: closeToTray,
              onChanged: onCloseToTrayChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '更新与动画',
          children: [
            SwitchRow(
              icon: Icons.system_update,
              title: '自动更新',
              subtitle: '启动器版本发布新时，不再询问自动下载最新文件',
              value: autoUpdate,
              onChanged: onAutoUpdateChanged,
            ),
            SwitchRow(
              icon: Icons.animation,
              title: '动画效果',
              subtitle: '启用界面动画过渡',
              value: enableAnimation,
              onChanged: onEnableAnimationChanged,
            ),
          ],
        ),
      ],
    );
  }
}
