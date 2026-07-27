import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 游戏目录 - 根目录 / 版本隔离 / 自定义候选
class GameDirectorySection extends StatelessWidget {
  final String gameDirectory;
  final bool versionIsolation;
  final ValueChanged<String> onGameDirectoryChanged;
  final ValueChanged<bool> onVersionIsolationChanged;
  final VoidCallback onAddCustomPath;
  final VoidCallback onRescanSystem;

  const GameDirectorySection({
    super.key,
    required this.gameDirectory,
    required this.versionIsolation,
    required this.onGameDirectoryChanged,
    required this.onVersionIsolationChanged,
    required this.onAddCustomPath,
    required this.onRescanSystem,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '游戏目录',
      breadcrumbs: const ['游戏', '游戏目录'],
      children: [
        SettingsSectionCard(
          title: 'Minecraft 文件存放位置',
          titleIcon: Icons.folder_open,
          children: [
            InfoCard(
              icon: Icons.info_outline,
              child: Text(
                '默认目录位于 %APPDATA%/.bamclaunch/minecraft，启用版本隔离后每个实例拥有独立子目录。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SettingRow(
              icon: Icons.folder_outlined,
              title: '游戏根目录',
              subtitle: gameDirectory.isEmpty ? '尚未设置' : gameDirectory,
              onTap: () {},
              trailing: Icon(
                Icons.edit_outlined,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            ButtonRow(
              icon: Icons.folder_open,
              title: '选择其他目录',
              buttonLabel: '浏览',
              onPressed: () => onGameDirectoryChanged(''),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '版本隔离',
          titleIcon: Icons.layers_outlined,
          children: [
            InfoCard(
              icon: Icons.lightbulb_outline,
              child: Text(
                '启用后每个游戏实例的 mods、配置、存档互不干扰；关闭则所有实例共享同一目录。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.account_tree_outlined,
              title: '启用版本隔离',
              subtitle: '推荐开启，可避免 mod 冲突',
              value: versionIsolation,
              onChanged: onVersionIsolationChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '扫描候选路径',
          titleIcon: Icons.travel_explore_outlined,
          initiallyCollapsed: true,
          children: [
            InfoCard(
              child: Text(
                'BAMCLaunch 在自动检测 .minecraft 目录时会按此列表依次尝试。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            ButtonRow(
              icon: Icons.add_location_alt_outlined,
              title: '添加自定义路径',
              buttonLabel: '添加',
              onPressed: onAddCustomPath,
            ),
            ButtonRow(
              icon: Icons.refresh,
              title: '重新扫描系统',
              buttonLabel: '扫描',
              onPressed: onRescanSystem,
            ),
          ],
        ),
      ],
    );
  }
}
