import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 主题与背景设置
class ThemeSettings extends StatelessWidget {
  final String themeMode;
  final String colorScheme;
  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<String> onColorSchemeChanged;
  final VoidCallback onBackgroundSettingsTap;

  const ThemeSettings({
    super.key,
    required this.themeMode,
    required this.colorScheme,
    required this.onThemeModeChanged,
    required this.onColorSchemeChanged,
    required this.onBackgroundSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '主题与背景',
      breadcrumbs: const ['个性化', '主题与背景'],
      children: [
        SettingsSectionCard(
          title: 'BAMCLaunch 主题',
          children: [
            ButtonRow(
              icon: Icons.file_download_outlined,
              title: '导入主题包',
              subtitle: '从本地选择 .BakaSkin4 文件并导入',
              buttonLabel: '导入',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.save_outlined,
              title: '导出当前设置为主题包',
              subtitle: '导出前颜色、深浅模式、视效与音铛打包为 .BakaSkin4',
              buttonLabel: '导出',
              onPressed: () {},
            ),
            SettingRow(
              icon: Icons.extension,
              title: '已安装的主题包',
              subtitle: '启用或停用主题包，启用后启用的主题包优先被使用。',
              onTap: () {},
              trailing: Icon(
                Icons.expand_less,
                size: 18,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                '若您安装了 BakaXL 主题，它讲将会被显示在这里。',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'BakaXL 主题是一套有个性化设置的文件，允许您保存背景、音乐等个性化设置，并与好友进行分享。',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '背景',
          children: [
            ButtonRow(
              icon: Icons.image_outlined,
              title: '背景图片',
              subtitle: '设置 BAMCLaunch 窗体的背景图片',
              buttonLabel: '管理',
              onPressed: onBackgroundSettingsTap,
            ),
            DropdownRow(
              icon: Icons.color_lens_outlined,
              title: '背景图片预览',
              subtitle: '背景图片会按照鼠标移动进行移动，营造视效效果。',
              value: 'enabled',
              items: const [
                DropdownMenuItem(value: 'enabled', child: Text('启用')),
                DropdownMenuItem(value: 'disabled', child: Text('禁用')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '配色方案',
          children: [
            SwitchRow(
              icon: Icons.palette_outlined,
              title: '主要颜色',
              subtitle: '设置背景图片时，BAMCLaunch 还会自动从图片中提取一个主要颜色。',
              value: true,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.gradient,
              title: '自动决定主要颜色',
              subtitle: '将主要颜色自动设为背景图片的中位色。',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '主题模式',
          children: [
            DropdownRow(
              icon: Icons.dark_mode_outlined,
              title: '主题模式',
              subtitle: '选择应用的外观主题',
              value: themeMode,
              items: const [
                DropdownMenuItem(value: 'dark', child: Text('深色')),
                DropdownMenuItem(value: 'light', child: Text('浅色')),
                DropdownMenuItem(value: 'system', child: Text('跟随系统')),
              ],
              onChanged: (v) {
                if (v != null) onThemeModeChanged(v);
              },
            ),
            DropdownRow(
              icon: Icons.style_outlined,
              title: '配色方案',
              subtitle: colorScheme == 'blue_archive'
                  ? '蔚蓝档案风格'
                  : 'Minecraft 风格',
              value: colorScheme,
              items: const [
                DropdownMenuItem(value: 'blue_archive', child: Text('蔚蓝档案')),
                DropdownMenuItem(value: 'minecraft', child: Text('Minecraft')),
              ],
              onChanged: (v) {
                if (v != null) onColorSchemeChanged(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
