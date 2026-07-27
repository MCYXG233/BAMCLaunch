import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 高级设置 - 代理、JVM 参数、游戏参数、窗口大小
class AdvancedSettings extends StatelessWidget {
  final TextEditingController proxyHostCtrl;
  final TextEditingController proxyPortCtrl;
  final TextEditingController jvmArgsCtrl;
  final TextEditingController gameArgsCtrl;
  final String gameWindowSize;
  final ValueChanged<String> onGameWindowSizeChanged;
  final ValueChanged<String> onProxyHostSubmitted;
  final ValueChanged<String> onProxyPortSubmitted;
  final ValueChanged<String> onJvmArgsSubmitted;
  final ValueChanged<String> onGameArgsSubmitted;

  const AdvancedSettings({
    super.key,
    required this.proxyHostCtrl,
    required this.proxyPortCtrl,
    required this.jvmArgsCtrl,
    required this.gameArgsCtrl,
    required this.gameWindowSize,
    required this.onGameWindowSizeChanged,
    required this.onProxyHostSubmitted,
    required this.onProxyPortSubmitted,
    required this.onJvmArgsSubmitted,
    required this.onGameArgsSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '高级',
      breadcrumbs: const ['游戏', '高级'],
      children: [
        // 提示
        InfoCard(child: UnsupportedNote(text: '当前版本的 BAMCLaunch 尚不支持此功能。')),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '高级启动',
          children: [
            SwitchRow(
              icon: Icons.lan_outlined,
              title: 'IPv6 协议栈',
              subtitle:
                  '允许 Minecraft 实例通过 IPv6 协议栈进行网络连接。这项设置可能会影响 BAMCLaunch 大厅。',
              value: false,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.replay_circle_filled,
              title: '自定义 Java 垃圾回收器',
              subtitle: '在使用 Java 9 或更高版本 Java 时可选择预设的垃圾回收器（GC）',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: 'Minecraft 窗体',
          children: [
            SwitchRow(
              icon: Icons.aspect_ratio,
              title: '自定义窗体大小',
              subtitle: '部分模组加载器可能不支持此功能。',
              value: false,
              onChanged: (_) {},
            ),
            DropdownRow(
              icon: Icons.crop_landscape,
              title: '游戏窗口大小',
              subtitle: '启动游戏时的默认窗口分辨率',
              value: gameWindowSize,
              items: const [
                DropdownMenuItem(value: '1280x720', child: Text('1280x720')),
                DropdownMenuItem(value: '1920x1080', child: Text('1920x1080')),
                DropdownMenuItem(value: '1600x900', child: Text('1600x900')),
                DropdownMenuItem(value: '1366x768', child: Text('1366x768')),
              ],
              onChanged: (v) {
                if (v != null) onGameWindowSizeChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '代理服务器',
          children: [
            TextFieldRow(
              icon: Icons.language,
              title: '代理主机',
              subtitle: 'HTTP 代理服务器地址',
              hintText: '例如: 127.0.0.1',
              controller: proxyHostCtrl,
              onSubmitted: onProxyHostSubmitted,
            ),
            TextFieldRow(
              icon: Icons.numbers,
              title: '代理端口',
              subtitle: '代理服务器端口号',
              hintText: '例如: 1080',
              controller: proxyPortCtrl,
              keyboardType: TextInputType.number,
              onSubmitted: onProxyPortSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '启动参数',
          children: [
            TextFieldRow(
              icon: Icons.code,
              title: 'JVM 参数',
              subtitle: '传递给 Java 虚拟机的额外参数',
              hintText: '例如: -XX:+UseG1GC -XX:MaxGCPauseMillis=50',
              controller: jvmArgsCtrl,
              onSubmitted: onJvmArgsSubmitted,
            ),
            TextFieldRow(
              icon: Icons.gamepad,
              title: '游戏参数',
              subtitle: '传递给 Minecraft 的额外启动参数',
              hintText: '例如: --demo',
              controller: gameArgsCtrl,
              onSubmitted: onGameArgsSubmitted,
            ),
          ],
        ),
      ],
    );
  }
}
