import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 下载参数 - 线程 / 限速 / 重试 / 缓存路径
class DownloadParamsSection extends StatelessWidget {
  final int concurrentDownloads;
  final String downloadPath;
  final int maxRetries;
  final bool autoRetryDownload;
  final bool enableSpeedLimit;
  final double speedLimitValue;
  final String cacheDirectory;
  final ValueChanged<int> onConcurrentDownloadsChanged;
  final ValueChanged<String> onDownloadPathChanged;
  final ValueChanged<int> onMaxRetriesChanged;
  final ValueChanged<bool> onAutoRetryDownloadChanged;
  final ValueChanged<bool> onEnableSpeedLimitChanged;
  final ValueChanged<double> onSpeedLimitChanged;
  final ValueChanged<String> onCacheDirectoryChanged;

  const DownloadParamsSection({
    super.key,
    required this.concurrentDownloads,
    required this.downloadPath,
    required this.maxRetries,
    required this.autoRetryDownload,
    required this.enableSpeedLimit,
    required this.speedLimitValue,
    required this.cacheDirectory,
    required this.onConcurrentDownloadsChanged,
    required this.onDownloadPathChanged,
    required this.onMaxRetriesChanged,
    required this.onAutoRetryDownloadChanged,
    required this.onEnableSpeedLimitChanged,
    required this.onSpeedLimitChanged,
    required this.onCacheDirectoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '下载参数',
      breadcrumbs: const ['下载', '下载参数'],
      children: [
        SettingsSectionCard(
          title: '并发与限速',
          titleIcon: Icons.speed_outlined,
          children: [
            SliderRow(
              icon: Icons.tune,
              title: '并发下载数',
              valueLabel: '$concurrentDownloads',
              value: concurrentDownloads.toDouble(),
              min: 1,
              max: 16,
              divisions: 15,
              onChanged: (v) => onConcurrentDownloadsChanged(v.toInt()),
              minLabel: '1',
              maxLabel: '16',
            ),
            SwitchRow(
              icon: Icons.network_check,
              title: '启用下载限速',
              subtitle: '避免下载占满带宽',
              value: enableSpeedLimit,
              onChanged: onEnableSpeedLimitChanged,
            ),
            if (enableSpeedLimit)
              SliderRow(
                icon: Icons.speed,
                title: '下载限速',
                valueLabel: '${speedLimitValue.toStringAsFixed(0)} MB/s',
                value: speedLimitValue,
                min: 0.5,
                max: 50,
                divisions: 99,
                onChanged: onSpeedLimitChanged,
                minLabel: '0.5 MB/s',
                maxLabel: '50 MB/s',
              ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '重试与容错',
          titleIcon: Icons.refresh_outlined,
          children: [
            SwitchRow(
              icon: Icons.replay_outlined,
              title: '下载失败自动重试',
              subtitle: '断网或超时后自动重新下载',
              value: autoRetryDownload,
              onChanged: onAutoRetryDownloadChanged,
            ),
            SliderRow(
              icon: Icons.repeat,
              title: '最大重试次数',
              valueLabel: '$maxRetries',
              value: maxRetries.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => onMaxRetriesChanged(v.toInt()),
              minLabel: '不重试',
              maxLabel: '10 次',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '存储路径',
          titleIcon: Icons.folder_outlined,
          children: [
            SettingRow(
              icon: Icons.download_outlined,
              title: '下载保存路径',
              subtitle: downloadPath.isEmpty ? '默认路径' : downloadPath,
              onTap: () => onDownloadPathChanged(''),
              trailing: Icon(
                Icons.folder_open,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            SettingRow(
              icon: Icons.cached_outlined,
              title: '缓存目录',
              subtitle: cacheDirectory.isEmpty ? '默认缓存' : cacheDirectory,
              onTap: () => onCacheDirectoryChanged(''),
              trailing: Icon(
                Icons.cleaning_services_outlined,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
