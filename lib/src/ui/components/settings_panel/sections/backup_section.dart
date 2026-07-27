import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 自动备份 - 实例存档与配置的自动备份
class BackupSection extends StatelessWidget {
  final bool autoBackupEnabled;
  final String autoBackupSchedule;
  final int autoBackupKeepCount;
  final bool autoBackupCompress;
  final ValueChanged<bool> onAutoBackupEnabledChanged;
  final ValueChanged<String> onAutoBackupScheduleChanged;
  final ValueChanged<int> onAutoBackupKeepCountChanged;
  final ValueChanged<bool> onAutoBackupCompressChanged;

  const BackupSection({
    super.key,
    required this.autoBackupEnabled,
    required this.autoBackupSchedule,
    required this.autoBackupKeepCount,
    required this.autoBackupCompress,
    required this.onAutoBackupEnabledChanged,
    required this.onAutoBackupScheduleChanged,
    required this.onAutoBackupKeepCountChanged,
    required this.onAutoBackupCompressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '自动备份',
      breadcrumbs: const ['备份', '自动备份'],
      children: [
        SettingsSectionCard(
          title: '备份策略',
          titleIcon: Icons.backup_outlined,
          children: [
            InfoCard(
              icon: Icons.shield_outlined,
              child: Text(
                '为实例的存档与配置创建快照，可在崩溃或误操作后一键恢复。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.toggle_on_outlined,
              title: '启用自动备份',
              subtitle: '关闭后所有实例都不会自动备份',
              value: autoBackupEnabled,
              onChanged: onAutoBackupEnabledChanged,
            ),
            DropdownRow(
              icon: Icons.schedule_outlined,
              title: '备份周期',
              subtitle: '只在实例启动后达到时间间隔时执行',
              value: autoBackupSchedule,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
                DropdownMenuItem(value: 'onlaunch', child: Text('每次启动')),
              ],
              onChanged: (v) {
                if (v != null) onAutoBackupScheduleChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '保留与压缩',
          titleIcon: Icons.archive_outlined,
          children: [
            SliderRow(
              icon: Icons.layers_outlined,
              title: '保留备份数',
              valueLabel: '$autoBackupKeepCount 份',
              value: autoBackupKeepCount.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (v) => onAutoBackupKeepCountChanged(v.toInt()),
              minLabel: '1',
              maxLabel: '50',
            ),
            SwitchRow(
              icon: Icons.compress_outlined,
              title: '压缩备份',
              subtitle: '减少磁盘占用，但备份/恢复耗时更长',
              value: autoBackupCompress,
              onChanged: onAutoBackupCompressChanged,
            ),
            ButtonRow(
              icon: Icons.history_outlined,
              title: '查看历史备份',
              buttonLabel: '打开',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.restore_outlined,
              title: '立即备份所有实例',
              buttonLabel: '执行',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
