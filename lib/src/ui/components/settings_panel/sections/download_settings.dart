import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 下载设置
class DownloadSettings extends StatelessWidget {
  final String downloadSource;
  final int concurrentDownloads;
  final String downloadPath;
  final ValueChanged<String> onDownloadSourceChanged;
  final ValueChanged<int> onConcurrentDownloadsChanged;
  final VoidCallback onPickDownloadPath;

  const DownloadSettings({
    super.key,
    required this.downloadSource,
    required this.concurrentDownloads,
    required this.downloadPath,
    required this.onDownloadSourceChanged,
    required this.onConcurrentDownloadsChanged,
    required this.onPickDownloadPath,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '下载',
      breadcrumbs: const ['网络', '下载'],
      children: [
        SettingsSectionCard(
          title: '下载源',
          children: [
            SwitchRow(
              icon: Icons.cloud_outlined,
              title: '中国大陆地区使用第三方下载源加速',
              subtitle: '使用来自 bangbang93 的 BMCLAPI 来加速下载。',
              value: downloadSource == 'bmclapi',
              onChanged: (v) =>
                  onDownloadSourceChanged(v ? 'bmclapi' : 'official'),
            ),
            DropdownRow(
              icon: Icons.public,
              title: '优先使用的下载源',
              subtitle: '优先使用选中的下载源；当它下载失败时，会自动切换到其它源重试。',
              value: downloadSource,
              items: const [
                DropdownMenuItem(value: 'official', child: Text('官方')),
                DropdownMenuItem(value: 'bmclapi', child: Text('BMCLAPI')),
              ],
              onChanged: (v) {
                if (v != null) onDownloadSourceChanged(v);
              },
            ),
            ButtonRow(
              icon: Icons.open_in_new,
              title: '了解与 BMCLAPI 有关的更多信息',
              buttonLabel: '访问',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '下载选项',
          children: [
            DropdownRow(
              icon: Icons.speed,
              title: '线程数',
              subtitle: '使用更高的线程数会加速下载，对计算机负担较大。',
              value: concurrentDownloads.toString(),
              items: [1, 2, 3, 4, 5]
                  .map(
                    (v) => DropdownMenuItem(
                      value: v.toString(),
                      child: Text('$v'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onConcurrentDownloadsChanged(int.parse(v));
              },
            ),
            ButtonRow(
              icon: Icons.save_alt,
              title: '下载保存路径',
              subtitle: downloadPath.isEmpty ? '默认路径' : downloadPath,
              buttonLabel: '选择',
              onPressed: onPickDownloadPath,
            ),
          ],
        ),
      ],
    );
  }
}
