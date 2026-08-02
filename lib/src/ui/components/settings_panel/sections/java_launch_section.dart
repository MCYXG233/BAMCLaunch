import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// Java 与启动 - 内存分配 / JVM / GC / 启动参数 / 分辨率
class JavaLaunchSection extends StatelessWidget {
  final String javaPath;
  final double memoryAllocation;
  final TextEditingController jvmArgsCtrl;
  final TextEditingController gameArgsCtrl;
  final String gameWindowSize;
  final bool autoDownloadJava;
  final bool fullscreen;
  final String gcStrategy;
  final ValueChanged<String> onJavaPathChanged;
  final ValueChanged<double> onMemoryChanged;
  final ValueChanged<String> onJvmArgsSubmitted;
  final ValueChanged<String> onGameArgsSubmitted;
  final ValueChanged<String> onGameWindowSizeChanged;
  final ValueChanged<bool> onAutoDownloadJavaChanged;
  final ValueChanged<bool> onFullscreenChanged;
  final ValueChanged<String> onGcStrategyChanged;
  final VoidCallback onPickInstalledJava;

  const JavaLaunchSection({
    super.key,
    required this.javaPath,
    required this.memoryAllocation,
    required this.jvmArgsCtrl,
    required this.gameArgsCtrl,
    required this.gameWindowSize,
    required this.autoDownloadJava,
    required this.fullscreen,
    required this.gcStrategy,
    required this.onJavaPathChanged,
    required this.onMemoryChanged,
    required this.onJvmArgsSubmitted,
    required this.onGameArgsSubmitted,
    required this.onGameWindowSizeChanged,
    required this.onAutoDownloadJavaChanged,
    required this.onFullscreenChanged,
    required this.onGcStrategyChanged,
    required this.onPickInstalledJava,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: 'Java 与启动',
      breadcrumbs: const ['游戏', 'Java 与启动'],
      children: [
        SettingsSectionCard(
          title: 'Java 运行时',
          titleIcon: Icons.coffee_outlined,
          children: [
            InfoCard(
              icon: Icons.tips_and_updates_outlined,
              child: Text(
                '这里设置的是全局默认值。每个实例可在其实例设置中单独覆盖 Java 路径与参数。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.cloud_download_outlined,
              title: '自动下载 Java',
              subtitle: '找不到合适版本时，BAMCLaunch 会自动下载',
              value: autoDownloadJava,
              onChanged: onAutoDownloadJavaChanged,
            ),
            SettingRow(
              icon: Icons.code,
              title: 'Java 可执行文件路径',
              subtitle: javaPath.isEmpty ? '使用 PATH 中的 java' : javaPath,
              onTap: () => onJavaPathChanged(''),
              trailing: Icon(
                Icons.folder_open,
                size: 16,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            ButtonRow(
              icon: Icons.search,
              title: '从已安装版本中选择',
              buttonLabel: '选择',
              onPressed: onPickInstalledJava,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '内存分配',
          titleIcon: Icons.memory_outlined,
          children: [
            SliderRow(
              icon: Icons.tune,
              title: '默认内存上限',
              valueLabel: '${(memoryAllocation / 1024).toStringAsFixed(1)} GB',
              value: memoryAllocation,
              min: 1024,
              max: 16384,
              divisions: 30,
              onChanged: (v) => onMemoryChanged(v),
              onChangeEnd: onMemoryChanged,
              minLabel: '1 GB',
              maxLabel: '16 GB',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '垃圾回收器',
          titleIcon: Icons.recycling_outlined,
          children: [
            DropdownRow(
              icon: Icons.auto_awesome,
              title: 'GC 策略',
              subtitle: '仅对 Java 9+ 生效；某些模组可能不兼容',
              value: gcStrategy,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('默认（G1GC）')),
                DropdownMenuItem(value: 'zgc', child: Text('ZGC（低延迟）')),
                DropdownMenuItem(
                  value: 'shenandoah',
                  child: Text('Shenandoah'),
                ),
                DropdownMenuItem(value: 'parallel', child: Text('Parallel GC')),
              ],
              onChanged: (v) {
                if (v != null) onGcStrategyChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '启动参数',
          titleIcon: Icons.terminal_outlined,
          children: [
            TextFieldRow(
              icon: Icons.code,
              title: 'JVM 参数',
              subtitle: '附加到 Java 启动命令',
              hintText: '例如：-XX:+UseG1GC -XX:MaxGCPauseMillis=50',
              controller: jvmArgsCtrl,
              onSubmitted: onJvmArgsSubmitted,
            ),
            TextFieldRow(
              icon: Icons.gamepad_outlined,
              title: '游戏参数',
              subtitle: '附加到 Minecraft 启动命令',
              hintText: '例如：--demo',
              controller: gameArgsCtrl,
              onSubmitted: onGameArgsSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '窗口与分辨率',
          titleIcon: Icons.crop_landscape_outlined,
          children: [
            SwitchRow(
              icon: Icons.fullscreen,
              title: '默认全屏启动',
              value: fullscreen,
              onChanged: onFullscreenChanged,
            ),
            DropdownRow(
              icon: Icons.aspect_ratio_outlined,
              title: '窗口分辨率',
              subtitle: '非全屏时生效',
              value: gameWindowSize,
              items: const [
                DropdownMenuItem(value: '854x480', child: Text('854 × 480')),
                DropdownMenuItem(value: '1280x720', child: Text('1280 × 720')),
                DropdownMenuItem(value: '1600x900', child: Text('1600 × 900')),
                DropdownMenuItem(
                  value: '1920x1080',
                  child: Text('1920 × 1080'),
                ),
                DropdownMenuItem(
                  value: '2560x1440',
                  child: Text('2560 × 1440'),
                ),
              ],
              onChanged: (v) {
                if (v != null) onGameWindowSizeChanged(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
