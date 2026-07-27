import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 高级 - 代理 / 启动器行为 / 隐私 / 翻译 / 扩展
class AdvancedSection extends StatelessWidget {
  final bool useProxy;
  final TextEditingController proxyAddressCtrl;
  final TextEditingController proxyPortCtrl;
  final String language;
  final bool mcpServerEnabled;
  final int mcpServerPort;
  final bool extensionsEnabled;
  final ValueChanged<bool> onUseProxyChanged;
  final ValueChanged<String> onProxyAddressSubmitted;
  final ValueChanged<String> onProxyPortSubmitted;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onMcpServerEnabledChanged;
  final ValueChanged<int> onMcpServerPortChanged;
  final ValueChanged<bool> onExtensionsEnabledChanged;

  const AdvancedSection({
    super.key,
    required this.useProxy,
    required this.proxyAddressCtrl,
    required this.proxyPortCtrl,
    required this.language,
    required this.mcpServerEnabled,
    required this.mcpServerPort,
    required this.extensionsEnabled,
    required this.onUseProxyChanged,
    required this.onProxyAddressSubmitted,
    required this.onProxyPortSubmitted,
    required this.onLanguageChanged,
    required this.onMcpServerEnabledChanged,
    required this.onMcpServerPortChanged,
    required this.onExtensionsEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '高级',
      breadcrumbs: const ['高级'],
      children: [
        SettingsSectionCard(
          title: '网络代理',
          titleIcon: Icons.lan_outlined,
          children: [
            InfoCard(
              icon: Icons.info_outline,
              child: Text(
                '通过 HTTP/SOCKS 代理访问 Minecraft 服务器与下载源；常见于校园网/公司网络',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.vpn_lock_outlined,
              title: '使用代理',
              value: useProxy,
              onChanged: onUseProxyChanged,
            ),
            TextFieldRow(
              icon: Icons.dns_outlined,
              title: '代理地址',
              hintText: '127.0.0.1 或 socks5://127.0.0.1',
              controller: proxyAddressCtrl,
              onSubmitted: onProxyAddressSubmitted,
            ),
            TextFieldRow(
              icon: Icons.numbers_outlined,
              title: '代理端口',
              hintText: '1080',
              controller: proxyPortCtrl,
              keyboardType: TextInputType.number,
              onSubmitted: onProxyPortSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '界面语言',
          titleIcon: Icons.translate_outlined,
          children: [
            DropdownRow(
              icon: Icons.language_outlined,
              title: '界面语言',
              subtitle: '启动器文案与帮助文档使用的语言',
              value: language,
              items: const [
                DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
                DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文')),
                DropdownMenuItem(value: 'en-US', child: Text('English')),
                DropdownMenuItem(value: 'ja-JP', child: Text('日本語')),
              ],
              onChanged: (v) {
                if (v != null) onLanguageChanged(v);
              },
            ),
            SwitchRow(
              icon: Icons.translate,
              title: '翻译资源名称',
              subtitle: '下载的 mod 文件名使用中文别名（Modrinth 部分支持）',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '开发者选项',
          titleIcon: Icons.developer_mode_outlined,
          initiallyCollapsed: true,
          children: [
            InfoCard(
              icon: Icons.code_outlined,
              child: Text(
                '这些选项面向扩展开发者或集成第三方工具的用户，普通玩家无需调整。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.extension_outlined,
              title: '启用扩展',
              subtitle: '从 plugins/ 目录加载第三方扩展',
              value: extensionsEnabled,
              onChanged: onExtensionsEnabledChanged,
            ),
            SwitchRow(
              icon: Icons.terminal_outlined,
              title: '启用 MCP Server',
              subtitle: '暴露启动器状态供 IDE/AI 工具访问',
              value: mcpServerEnabled,
              onChanged: onMcpServerEnabledChanged,
            ),
            if (mcpServerEnabled)
              SliderRow(
                icon: Icons.numbers_outlined,
                title: 'MCP Server 端口',
                valueLabel: '$mcpServerPort',
                value: mcpServerPort.toDouble(),
                min: 1024,
                max: 65535,
                onChanged: (v) => onMcpServerPortChanged(v.toInt()),
                minLabel: '1024',
                maxLabel: '65535',
              ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '隐私',
          titleIcon: Icons.privacy_tip_outlined,
          initiallyCollapsed: true,
          children: [
            InfoCard(
              child: Text(
                'BAMCLaunch 不会主动收集个人信息；这里控制的是遥测数据与崩溃报告的发送。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            SwitchRow(
              icon: Icons.analytics_outlined,
              title: '发送匿名使用统计',
              subtitle: '帮助我们改进启动器',
              value: false,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.bug_report_outlined,
              title: '自动上报崩溃',
              subtitle: '崩溃时附带堆栈信息（不含账号/路径）',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
