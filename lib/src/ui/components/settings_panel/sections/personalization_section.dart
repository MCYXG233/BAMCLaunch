import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 个性化 - 主题 / 背景 / 字体 / 导航样式 / 音效
class PersonalizationSection extends StatelessWidget {
  final String themeMode;
  final String colorScheme;
  final String headNavStyle;
  final double fontSize;
  final bool enableSoundEffects;
  final bool enableSplashAnimation;
  final bool randomCustomBackground;
  final bool autoDarkenBackground;
  final bool autoPurgeLauncherLogs;
  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<String> onColorSchemeChanged;
  final ValueChanged<String> onHeadNavStyleChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onEnableSoundEffectsChanged;
  final ValueChanged<bool> onEnableSplashAnimationChanged;
  final ValueChanged<bool> onRandomCustomBackgroundChanged;
  final ValueChanged<bool> onAutoDarkenBackgroundChanged;
  final ValueChanged<bool> onAutoPurgeLauncherLogsChanged;
  final VoidCallback onOpenThemeEditor;
  final VoidCallback onManageBackground;

  const PersonalizationSection({
    super.key,
    required this.themeMode,
    required this.colorScheme,
    required this.headNavStyle,
    required this.fontSize,
    required this.enableSoundEffects,
    required this.enableSplashAnimation,
    required this.randomCustomBackground,
    required this.autoDarkenBackground,
    required this.autoPurgeLauncherLogs,
    required this.onThemeModeChanged,
    required this.onColorSchemeChanged,
    required this.onHeadNavStyleChanged,
    required this.onFontSizeChanged,
    required this.onEnableSoundEffectsChanged,
    required this.onEnableSplashAnimationChanged,
    required this.onRandomCustomBackgroundChanged,
    required this.onAutoDarkenBackgroundChanged,
    required this.onAutoPurgeLauncherLogsChanged,
    required this.onOpenThemeEditor,
    required this.onManageBackground,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '个性化',
      breadcrumbs: const ['个性化'],
      children: [
        SettingsSectionCard(
          title: '主题与外观',
          titleIcon: Icons.palette_outlined,
          children: [
            DropdownRow(
              icon: Icons.dark_mode_outlined,
              title: '主题模式',
              subtitle: '深色 / 浅色 / 跟随系统',
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
              icon: Icons.color_lens_outlined,
              title: '配色方案',
              subtitle: '蔚蓝档案 / Minecraft / 自定义',
              value: colorScheme,
              items: const [
                DropdownMenuItem(
                  value: 'blue_archive',
                  child: Text('蔚蓝档案（默认）'),
                ),
                DropdownMenuItem(value: 'minecraft', child: Text('Minecraft')),
                DropdownMenuItem(value: 'custom', child: Text('自定义')),
              ],
              onChanged: (v) {
                if (v != null) onColorSchemeChanged(v);
              },
            ),
            ButtonRow(
              icon: Icons.brush_outlined,
              title: '自定义主题编辑器',
              subtitle: '颜色、字体、圆角、阴影',
              buttonLabel: '打开',
              onPressed: onOpenThemeEditor,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '背景',
          titleIcon: Icons.wallpaper_outlined,
          children: [
            ButtonRow(
              icon: Icons.image_outlined,
              title: '背景图片',
              subtitle: '选择本地图片作为主背景',
              buttonLabel: '管理',
              onPressed: onManageBackground,
            ),
            SwitchRow(
              icon: Icons.auto_awesome_outlined,
              title: '随机自定义背景',
              subtitle: '每次启动随机使用文件夹内的图片',
              value: randomCustomBackground,
              onChanged: onRandomCustomBackgroundChanged,
            ),
            SwitchRow(
              icon: Icons.dark_mode_outlined,
              title: '自动加深背景',
              subtitle: '保证前景文字清晰可读',
              value: autoDarkenBackground,
              onChanged: onAutoDarkenBackgroundChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '导航与字体',
          titleIcon: Icons.text_fields_outlined,
          children: [
            DropdownRow(
              icon: Icons.tab_outlined,
              title: '顶部导航样式',
              subtitle: '顶部 Tab 的展示方式',
              value: headNavStyle,
              items: const [
                DropdownMenuItem(value: 'tabs', child: Text('标签栏')),
                DropdownMenuItem(value: 'icons', child: Text('图标列')),
                DropdownMenuItem(value: 'breadcrumb', child: Text('面包屑')),
              ],
              onChanged: (v) {
                if (v != null) onHeadNavStyleChanged(v);
              },
            ),
            SliderRow(
              icon: Icons.format_size_outlined,
              title: '界面字号',
              valueLabel: '${fontSize.toStringAsFixed(0)} px',
              value: fontSize,
              min: 12,
              max: 18,
              divisions: 6,
              onChanged: onFontSizeChanged,
              minLabel: '小',
              maxLabel: '大',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '音效与动画',
          titleIcon: Icons.audiotrack_outlined,
          children: [
            SwitchRow(
              icon: Icons.volume_up_outlined,
              title: '启用音效',
              subtitle: '点击、通知、下载完成等反馈音',
              value: enableSoundEffects,
              onChanged: onEnableSoundEffectsChanged,
            ),
            SwitchRow(
              icon: Icons.movie_filter_outlined,
              title: '启动动画',
              subtitle: '启动器打开时的过渡动画',
              value: enableSplashAnimation,
              onChanged: onEnableSplashAnimationChanged,
            ),
            SwitchRow(
              icon: Icons.auto_delete_outlined,
              title: '自动清理启动器日志',
              subtitle: '避免日志文件无限增长',
              value: autoPurgeLauncherLogs,
              onChanged: onAutoPurgeLauncherLogsChanged,
            ),
          ],
        ),
      ],
    );
  }
}
