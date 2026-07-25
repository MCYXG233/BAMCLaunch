import 'package:flutter/material.dart';

import '../../components/ba_notification.dart';
import '../../components/color_picker_panel.dart';
import '../../theme/colors.dart';
import '../../theme/theme_manager.dart';
import 'settings_components.dart';

/// 通用设置页:外观(语言/主题/主题风格)、行为(自动更新/开机自启/托盘)、更新检查
class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({
    super.key,
    required this.themeManagerInitialized,
    required this.language,
    required this.themeMode,
    required this.autoUpdate,
    required this.launchAtStartup,
    required this.minimizeToTray,
    required this.closeToTray,
    required this.isCheckingUpdate,
    required this.themeManager,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
    required this.onAutoUpdateChanged,
    required this.onLaunchAtStartupChanged,
    required this.onMinimizeToTrayChanged,
    required this.onCloseToTrayChanged,
    required this.onCheckUpdate,
  });

  final bool themeManagerInitialized;
  final String language;
  final String themeMode;
  final bool autoUpdate;
  final bool launchAtStartup;
  final bool minimizeToTray;
  final bool closeToTray;
  final bool isCheckingUpdate;
  final ThemeManager themeManager;

  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<bool> onAutoUpdateChanged;
  final ValueChanged<bool> onLaunchAtStartupChanged;
  final ValueChanged<bool> onMinimizeToTrayChanged;
  final ValueChanged<bool> onCloseToTrayChanged;
  final VoidCallback onCheckUpdate;

  @override
  Widget build(BuildContext context) {
    if (!themeManagerInitialized) {
      return Center(
        child: CircularProgressIndicator(color: BAColors.primaryOf(context)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '外观',
          children: [
            SettingsRow(
              icon: Icons.language,
              title: '语言',
              subtitle: language,
              control: SettingsDropdown<String>(
                value: language,
                items: const [
                  DropdownMenuItem(value: '简体中文', child: Text('简体中文')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) onLanguageChanged(value);
                },
              ),
            ),
            SettingsRow(
              icon: Icons.palette,
              title: '主题',
              subtitle: _themeModeDisplayName(themeMode),
              control: SettingsDropdown<String>(
                value: themeMode,
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('深色')),
                  DropdownMenuItem(value: 'light', child: Text('浅色')),
                  DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                ],
                onChanged: (value) {
                  if (value != null) onThemeModeChanged(value);
                },
              ),
            ),
            SettingsRow(
              icon: Icons.style,
              title: '主题风格',
              subtitle: themeManager.isBlueArchive ? '蔚蓝档案' : 'Minecraft',
              control: SettingsDropdown<String>(
                value: themeManager.isBlueArchive
                    ? 'blue_archive'
                    : 'minecraft',
                items: const [
                  DropdownMenuItem(value: 'blue_archive', child: Text('蔚蓝档案')),
                  DropdownMenuItem(
                    value: 'minecraft',
                    child: Text('Minecraft'),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  if (value == 'blue_archive') {
                    await themeManager.setBlueArchiveTheme();
                  } else {
                    await themeManager.setMinecraftTheme();
                  }
                  NotificationManager().showSuccess('主题风格已切换');
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ColorPickerPanel(
                themeKey: themeManager.isBlueArchive
                    ? 'blue_archive'
                    : 'minecraft',
                brightness: Theme.of(context).brightness == Brightness.light
                    ? Brightness.light
                    : Brightness.dark,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        SettingsCard(
          title: '行为',
          children: [
            SettingsRow(
              icon: Icons.update,
              title: '自动更新',
              subtitle: '启动时检查更新',
              control: SettingsSwitch(
                value: autoUpdate,
                onChanged: onAutoUpdateChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.power_settings_new,
              title: '开机自启动',
              subtitle: '系统启动时自动运行',
              control: SettingsSwitch(
                value: launchAtStartup,
                onChanged: onLaunchAtStartupChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.minimize,
              title: '最小化到托盘',
              subtitle: '最小化时隐藏到系统托盘',
              control: SettingsSwitch(
                value: minimizeToTray,
                onChanged: onMinimizeToTrayChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.close_fullscreen,
              title: '关闭时最小化到托盘',
              subtitle: '关闭窗口时最小化到系统托盘',
              control: SettingsSwitch(
                value: closeToTray,
                onChanged: onCloseToTrayChanged,
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '更新',
          children: [
            SettingsRow(
              icon: Icons.system_update,
              title: '检查更新',
              subtitle: isCheckingUpdate ? '正在检查...' : '手动检查新版本',
              control: SettingsPrimaryButton(
                text: isCheckingUpdate ? '' : '检查',
                onPressed: onCheckUpdate,
                isLoading: isCheckingUpdate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 主题模式显示名(从主文件迁移)
String _themeModeDisplayName(String mode) {
  switch (mode) {
    case 'light':
      return '浅色';
    case 'system':
      return '跟随系统';
    default:
      return '深色';
  }
}
