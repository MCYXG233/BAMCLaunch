import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';
import '../widgets/section_separator.dart';

/// Java 虚拟机与内存设置
class JavaSettings extends StatelessWidget {
  // 业务参数（从父组件传入或在内部管理）
  final String gameDirectory;
  final String javaPath;
  final double memoryAllocation;
  final ValueChanged<String> onGameDirectoryChanged;
  final ValueChanged<String> onJavaPathChanged;
  final ValueChanged<double> onMemoryChanged;

  const JavaSettings({
    super.key,
    required this.gameDirectory,
    required this.javaPath,
    required this.memoryAllocation,
    required this.onGameDirectoryChanged,
    required this.onJavaPathChanged,
    required this.onMemoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: 'Java 虚拟机与内存',
      breadcrumbs: const ['游戏', 'Java 虚拟机与内存'],
      children: [
        SettingsSectionCard(
          title: 'Java 虚拟机',
          children: [
            // 提示卡片
            InfoCard(
              child: Row(
                children: [
                  Icon(Icons.coffee, size: 20, color: SettingsPalette.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '请尽可能在"高级核心设置"中针对每一个游戏实例单独调整所使用的 Java 虚拟机，而不是直接关闭自动 Java 选择。',
                          style: TextStyle(
                            fontSize: 12,
                            color: SettingsPalette.textPrimary(context),
                          ),
                        ),
                        if (false) const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SwitchRow(
              icon: Icons.auto_awesome,
              title: '让 BAMCLaunch 自动决定 Java 虚拟机',
              subtitle: '当无法找到合适版本时，BAMCLaunch 将会自动安装一个',
              value: javaPath.isEmpty,
              onChanged: (_) => onJavaPathChanged(''),
            ),
            DropdownRow(
              icon: Icons.list_alt,
              title: '计算机中已安装的 Java 虚拟机列表',
              subtitle: '选择将不生效，BAMCLaunch 会根据运行实例的要求自动选择或安装合适的 Java 虚拟机。',
              value: javaPath.isEmpty ? 'auto' : javaPath,
              items: [
                if (javaPath.isNotEmpty)
                  DropdownMenuItem(value: javaPath, child: Text(javaPath)),
                const DropdownMenuItem(
                  value: 'auto',
                  child: Text('可以查看已安装的 Java 虚拟机'),
                ),
              ],
              onChanged: javaPath.isEmpty
                  ? null
                  : (v) {
                      if (v != null && v != 'auto') onJavaPathChanged(v);
                    },
            ),
            ButtonRow(
              icon: Icons.cloud_download_outlined,
              title: 'Java 发行版获取来源',
              subtitle: '选择从何处获取自动安装的 Java 运行时',
              buttonLabel: '管理',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.install_desktop,
              title: '安装 Java 虚拟机',
              buttonLabel: '管理',
              onPressed: () {},
            ),
            ButtonRow(
              icon: Icons.tune,
              title: '高级 Java 虚拟机设置',
              buttonLabel: '管理',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSectionCard(
          title: '内存',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前计算机已安装',
                          style: TextStyle(
                            fontSize: 10,
                            color: SettingsPalette.textHint(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(16384).toStringAsFixed(1)} GB',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: SettingsPalette.textPrimary(context),
                          ),
                        ),
                        Text(
                          '/ 15.8 GB',
                          style: TextStyle(
                            fontSize: 10,
                            color: SettingsPalette.textHint(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minecraft 将使用其中的',
                          style: TextStyle(
                            fontSize: 10,
                            color: SettingsPalette.textHint(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(memoryAllocation / 1024).toStringAsFixed(1)} GB',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: SettingsPalette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliderRow(
              icon: Icons.memory,
              title: '内存分配',
              valueLabel: '${(memoryAllocation / 1024).toStringAsFixed(1)} GB',
              value: memoryAllocation,
              min: 512,
              max: 16384,
              divisions: 32,
              onChanged: (v) => onMemoryChanged(v),
              minLabel: '0.5 GB',
              maxLabel: '16 GB',
            ),
            SwitchRow(
              icon: Icons.auto_fix_high,
              title: '自动设置内存',
              subtitle: '让 BAMCLaunch 自动调整所需内存',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
