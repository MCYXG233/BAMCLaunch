import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 关于 - 启动器版本信息
class AboutSection extends StatelessWidget {
  final bool autoUpdate;
  final String launcherVersion;
  final String buildTime;
  final VoidCallback onCheckUpdate;
  final ValueChanged<bool> onAutoUpdateChanged;
  final VoidCallback onViewChangelog;
  final VoidCallback onViewOpenSource;

  const AboutSection({
    super.key,
    required this.autoUpdate,
    required this.launcherVersion,
    required this.buildTime,
    required this.onCheckUpdate,
    required this.onAutoUpdateChanged,
    required this.onViewChangelog,
    required this.onViewOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '关于',
      breadcrumbs: const ['关于'],
      children: [
        SettingsSectionCard(
          title: 'BAMCLaunch',
          titleIcon: Icons.info_outline,
          children: [
            InfoCard(
              icon: Icons.verified_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前已是最新版本',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SettingsPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '检查更新 · 启动器版本 $launcherVersion',
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.textHint(context),
                    ),
                  ),
                ],
              ),
            ),
            ButtonRow(
              icon: Icons.system_update_alt_outlined,
              title: '检查更新',
              subtitle: '手动检查启动器是否有新版本',
              buttonLabel: '检查',
              onPressed: onCheckUpdate,
            ),
            SwitchRow(
              icon: Icons.update_outlined,
              title: '自动检查更新',
              subtitle: '启动时自动提示更新到最新版',
              value: autoUpdate,
              onChanged: onAutoUpdateChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '版本详情',
          titleIcon: Icons.tag_outlined,
          children: [
            InfoRow(
              icon: Icons.numbers_outlined,
              label: '版本',
              value: launcherVersion,
            ),
            const InfoRow(
              icon: Icons.architecture_outlined,
              label: '架构',
              value: 'windows-x86_64',
            ),
            const InfoRow(
              icon: Icons.commit_outlined,
              label: '构建通道',
              value: '开发版',
            ),
            InfoRow(
              icon: Icons.update_outlined,
              label: '构建时间',
              value: buildTime,
            ),
            ButtonRow(
              icon: Icons.history_outlined,
              title: '更新日志',
              buttonLabel: '查看',
              onPressed: onViewChangelog,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '鸣谢',
          titleIcon: Icons.favorite_outline,
          initiallyCollapsed: true,
          children: [
            InfoCard(
              icon: Icons.handshake_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _creditLine(context, '开发协力', 'BAMCLaunch 开发者团队'),
                  _creditLine(context, '镜像支持', 'BMCLAPI、MCNB 等社区镜像'),
                  _creditLine(context, '灵感来源', '蔚蓝档案主题、HUD 与视觉风格'),
                ],
              ),
            ),
            ButtonRow(
              icon: Icons.code_outlined,
              title: '查看开源组件',
              subtitle: '本项目使用的开源库及其许可证',
              buttonLabel: '查看',
              onPressed: onViewOpenSource,
            ),
          ],
        ),
      ],
    );
  }

  Widget _creditLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textSecondary(context),
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

/// 信息行 - 关于页中的静态键值对
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SettingsPalette.textHint(context)),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
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
                fontWeight: FontWeight.w500,
                color: SettingsPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
