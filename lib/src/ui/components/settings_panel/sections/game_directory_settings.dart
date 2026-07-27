import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 游戏目录设置
class GameDirectorySettings extends StatelessWidget {
  final String gameDirectory;
  final ValueChanged<String> onGameDirectoryChanged;

  const GameDirectorySettings({
    super.key,
    required this.gameDirectory,
    required this.onGameDirectoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '游戏目录',
      breadcrumbs: const ['游戏', '游戏目录'],
      children: [
        SettingsSectionCard(
          title: 'Minecraft 游戏目录',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                '默认目录位于 %APPDATA%/.bamclaunch/minecraft；如启动后运行目录不存在 .minecraft，也会自动置加入内。内置目录不能删除，自定义目录只会从列表移除，不会删除磁盘文件。',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
            SettingRow(
              icon: Icons.folder_open,
              title: '目录管理',
              subtitle:
                  '当前默认存储：${gameDirectory.isEmpty ? '未设置' : gameDirectory}',
              onTap: () {},
              trailing: Icon(
                Icons.refresh,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            DropdownRow(
              icon: Icons.folder_special,
              title: '启动器目录 _minecraft',
              subtitle: '传统 .minecraft（版本隔离）· 内置目录 · 已启用',
              value: 'minecraft',
              items: const [
                DropdownMenuItem(value: 'minecraft', child: Text('.minecraft')),
              ],
              onChanged: (_) {},
            ),
            DropdownRow(
              icon: Icons.folder_shared,
              title: 'BAMCLaunch 默认目录',
              subtitle: 'BAMCLaunch · MultiMC 兼容 · 内置目录 · 默认存储 · 已启用',
              value: 'bamclaunch',
              items: const [
                DropdownMenuItem(
                  value: 'bamclaunch',
                  child: Text('BAMCLaunch'),
                ),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
