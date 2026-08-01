import 'package:flutter/material.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 实例管理 - 主页实例列表的展示方式
class InstanceSection extends StatelessWidget {
  final String instancesNavType;
  final String instanceSortOption;
  final bool launchPageQuickSwitch;
  final ValueChanged<String> onInstancesNavTypeChanged;
  final ValueChanged<String> onInstanceSortOptionChanged;
  final ValueChanged<bool> onLaunchPageQuickSwitchChanged;

  const InstanceSection({
    super.key,
    required this.instancesNavType,
    required this.instanceSortOption,
    required this.launchPageQuickSwitch,
    required this.onInstancesNavTypeChanged,
    required this.onInstanceSortOptionChanged,
    required this.onLaunchPageQuickSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '实例管理',
      breadcrumbs: const ['游戏', '实例管理'],
      children: [
        SettingsSectionCard(
          title: '主页实例列表',
          titleIcon: Icons.dashboard_outlined,
          children: [
            DropdownRow(
              icon: Icons.view_module_outlined,
              title: '导航类型',
              subtitle: '主页底部/侧栏的实例切换方式',
              value: instancesNavType,
              items: const [
                DropdownMenuItem(value: 'tabs', child: Text('底部标签栏')),
                DropdownMenuItem(value: 'sidebar', child: Text('侧边栏')),
                DropdownMenuItem(value: 'grid', child: Text('网格卡片')),
              ],
              onChanged: (v) {
                if (v != null) onInstancesNavTypeChanged(v);
              },
            ),
            DropdownRow(
              icon: Icons.sort_outlined,
              title: '默认排序',
              subtitle: '主页实例列表默认按此字段排序',
              value: instanceSortOption,
              items: const [
                DropdownMenuItem(value: 'name', child: Text('按名称')),
                DropdownMenuItem(value: 'lastPlayed', child: Text('按最近游玩')),
                DropdownMenuItem(value: 'playtime', child: Text('按游玩时长')),
                DropdownMenuItem(value: 'createdAt', child: Text('按创建时间')),
                DropdownMenuItem(value: 'version', child: Text('按游戏版本')),
              ],
              onChanged: (v) {
                if (v != null) onInstanceSortOptionChanged(v);
              },
            ),
            SwitchRow(
              icon: Icons.bolt_outlined,
              title: '启动页快捷切换',
              subtitle: '在主页快速切换最近游玩的实例',
              value: launchPageQuickSwitch,
              onChanged: onLaunchPageQuickSwitchChanged,
            ),
          ],
        ),
      ],
    );
  }
}
