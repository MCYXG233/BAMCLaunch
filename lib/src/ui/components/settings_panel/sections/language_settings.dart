import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 语言设置
class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '语言 / Language',
      breadcrumbs: const ['个性化', '语言 / Language'],
      children: [
        SettingsSectionCard(
          title: '显示语言 / Display Language',
          children: [
            DropdownRow(
              icon: Icons.translate,
              title: '语言',
              subtitle: '简体中文（中国）',
              value: 'zh-CN',
              items: const [
                DropdownMenuItem(value: 'zh-CN', child: Text('简体中文 (中国)')),
                DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文 (台灣)')),
                DropdownMenuItem(
                  value: 'en-US',
                  child: Text('English (United States)'),
                ),
                DropdownMenuItem(value: 'ja-JP', child: Text('日本語')),
              ],
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.translate_outlined,
              title: '跟随操作系统',
              subtitle: '运行 BAMCLaunch 时自动将语言切换为系统显示语言。',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '翻译官 / Translator',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                '为此语言本地化工作做出贡献的用户',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '若您参与了 BAMCLaunch 某一语言的本地化工作，您的名字将会显示在这里。',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
