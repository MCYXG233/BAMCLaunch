import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';
import '../widgets/section_separator.dart';

/// 账户与档案 - 当前版本大部分功能未实现
class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '账户与档案',
      breadcrumbs: const ['账户与档案'],
      children: [
        const InfoCard(
          child: UnsupportedNote(text: '当前版本的 BAMCLaunch 尚不支持此功能。'),
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: 'BAMCLaunch 账户',
          initiallyCollapsed: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                '当前版本的 BAMCLaunch 尚不支持此功能。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: 'Minecraft 用户档案',
          children: [
            // 档案卡片占位
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: SettingsPalette.cardSolid(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SettingsPalette.cardBorder(context),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '当前未配置 Minecraft 用户档案',
                  style: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.textHint(context),
                  ),
                ),
              ),
            ),
            ButtonRow(
              icon: Icons.add_circle_outline,
              title: '新增一个档案',
              buttonLabel: '新增',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.cloud_outlined,
              title: '管理整合包或服务端使用的凭证档案',
              subtitle: '整合包或服务端可以要求使用专门的第三方认证服务器。',
              buttonLabel: '管理',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
