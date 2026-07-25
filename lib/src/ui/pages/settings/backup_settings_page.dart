import 'package:flutter/material.dart';

import '../../../game/backup_manager.dart';
import '../../../instance/instance_manager.dart';
import '../../components/ba_backup_dialog.dart';
import '../../components/ba_notification.dart';
import 'settings_components.dart';

/// 备份设置页:查看备份列表、管理备份存储
class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allBackups = BackupManager.instance.getAllBackups();
    final instanceManager = InstanceManager();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '备份管理',
          children: [
            SettingsRow(
              icon: Icons.folder,
              title: '查看所有备份',
              subtitle: '${allBackups.length} 个备份',
              control: SettingsPrimaryButton(
                text: '管理',
                onPressed: () {
                  if (instanceManager.instances.isNotEmpty) {
                    BABackupDialog.show(
                      context: context,
                      instance: instanceManager.instances.first,
                    );
                  } else {
                    NotificationManager().showInfo(
                      '暂无游戏实例',
                      message: '请先创建一个游戏实例',
                    );
                  }
                },
              ),
            ),
            const SettingsRow(
              icon: Icons.storage,
              title: '备份存储',
              subtitle: '管理所有备份文件',
              control: SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
