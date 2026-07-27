import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 关于设置
class AboutSettings extends StatelessWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '关于',
      breadcrumbs: const ['其他', '关于'],
      children: [
        const InfoCard(
          child: UnsupportedNote(text: '当前版本的 BAMCLaunch 尚不支持此功能。'),
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '软件',
          children: [
            SettingRow(
              icon: Icons.system_update,
              title: '无可用更新',
              subtitle: '截至 07/27 20:13，您的 BAMCLaunch 已是最新版本。',
              trailing: Text(
                '刷新',
                style: TextStyle(fontSize: 11, color: SettingsPalette.accent),
              ),
              onTap: () {},
            ),
            SwitchRow(
              icon: Icons.update,
              title: '自动下载可用的更新',
              subtitle: '当检测到本体更新时，不再询问自动下载最新文件。',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '内部版本',
          children: [
            SettingRow(
              icon: Icons.tag,
              title: '版本',
              subtitle: 'v1.0.0+bunny-bcb056a (2026/07/27 20:13:50)',
              trailing: Text(
                '发行说明',
                style: TextStyle(fontSize: 11, color: SettingsPalette.accent),
              ),
              onTap: () {},
            ),
            InfoRow(label: '架构', value: 'windows-x86_64'),
            InfoRow(label: '构建通道', value: 'Bunny 兔兔通道'),
            SettingRow(
              icon: Icons.campaign_outlined,
              title: '有关此构建的改动信息',
              trailing: Icon(
                Icons.chevron_right,
                size: 16,
                color: SettingsPalette.textHint(context),
              ),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '开发者',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                'BAMCLaunch 开发者团队',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
            // 占位头像组
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(
                spacing: 18,
                runSpacing: 12,
                children: List.generate(3, (i) {
                  return Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SettingsPalette.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 24,
                          color: SettingsPalette.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contributor ${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SettingsPalette.textPrimary(context),
                        ),
                      ),
                      Text(
                        'BAMCLaunch 开发者',
                        style: TextStyle(
                          fontSize: 9,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            SettingRow(
              icon: Icons.favorite_outline,
              title: '开源组件',
              subtitle: '感谢所有开源项目的贡献者',
              trailing: Icon(
                Icons.chevron_right,
                size: 16,
                color: SettingsPalette.textHint(context),
              ),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '鸣谢',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCreditRow(context, '开发协力', 'BAMCLaunch 社区贡献者们'),
                  _buildCreditRow(
                    context,
                    '灵感',
                    'BakaXL、HMCL、PCL、SJMCL 等启动器的设计参考',
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '© 2024 - 2026 BAMCLaunch. 保留所有权利。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: SettingsPalette.textHint(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: SettingsPalette.textPrimary(context),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label：',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textPrimary(context),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/// 信息行 - About 页面中展示静态键值对
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: SettingsPalette.textHint(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: SettingsPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
