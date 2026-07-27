import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 镜像与源站 - 下载源 / 镜像源 / 资源中心源
class DownloadSection extends StatelessWidget {
  final String downloadSource;
  final int mirrorSourceIndex;
  final String selectedMirror;
  final bool autoSwitchMirror;
  final ValueChanged<String> onDownloadSourceChanged;
  final ValueChanged<int> onMirrorSourceIndexChanged;
  final ValueChanged<String> onSelectedMirrorChanged;
  final ValueChanged<bool> onAutoSwitchMirrorChanged;

  const DownloadSection({
    super.key,
    required this.downloadSource,
    required this.mirrorSourceIndex,
    required this.selectedMirror,
    required this.autoSwitchMirror,
    required this.onDownloadSourceChanged,
    required this.onMirrorSourceIndexChanged,
    required this.onSelectedMirrorChanged,
    required this.onAutoSwitchMirrorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '镜像与源站',
      breadcrumbs: const ['下载', '镜像与源站'],
      children: [
        SettingsSectionCard(
          title: '默认下载源',
          titleIcon: Icons.cloud_outlined,
          children: [
            InfoCard(
              icon: Icons.info_outline,
              child: Text(
                '游戏文件（jar、assets、库）的下载来源。中国大陆用户可使用第三方镜像加速。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            DropdownRow(
              icon: Icons.public,
              title: '首选下载源',
              subtitle: '首选源失败时自动切换到其他源重试',
              value: downloadSource,
              items: const [
                DropdownMenuItem(value: 'official', child: Text('官方源')),
                DropdownMenuItem(value: 'bmclapi', child: Text('BMCLAPI 镜像')),
                DropdownMenuItem(value: 'mcnb', child: Text('MCNB 镜像')),
              ],
              onChanged: (v) {
                if (v != null) onDownloadSourceChanged(v);
              },
            ),
            SwitchRow(
              icon: Icons.autorenew_outlined,
              title: '下载失败自动切换源',
              subtitle: '首选源 404/超时 时自动换源',
              value: autoSwitchMirror,
              onChanged: onAutoSwitchMirrorChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '镜像源列表',
          titleIcon: Icons.dns_outlined,
          children: [
            InfoCard(
              child: Text(
                '可手动指定镜像源；指定后优先级高于默认源。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            DropdownRow(
              icon: Icons.list_alt,
              title: '当前使用镜像',
              subtitle: selectedMirror == 'auto' ? '自动选择最快镜像' : selectedMirror,
              value: selectedMirror,
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('自动（推荐）')),
                DropdownMenuItem(value: 'official', child: Text('官方源')),
                DropdownMenuItem(value: 'bmclapi', child: Text('BMCLAPI')),
              ],
              onChanged: (v) {
                if (v != null) onSelectedMirrorChanged(v);
              },
            ),
            ButtonRow(
              icon: Icons.add_link,
              title: '添加自定义镜像',
              buttonLabel: '添加',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.speed,
              title: '镜像延迟测试',
              subtitle: '测速后选择最快镜像',
              buttonLabel: '测试',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
