import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 主界面设置
class HomeInterfaceSettings extends StatelessWidget {
  const HomeInterfaceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '主界面',
      breadcrumbs: const ['个性化', '主界面'],
      children: [
        SettingsSectionCard(
          title: '显示',
          children: [
            SwitchRow(
              icon: Icons.notifications_outlined,
              title: '在主界面上显示通知和实时任务',
              subtitle: '不希望这些信息将会被收起至动画器托盘中',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '启动区域',
          children: [
            DropdownRow(
              icon: Icons.play_circle_outline,
              title: '启动按钮的行为',
              subtitle: '修改当前下拉启动按钮的行为',
              value: 'last_instance',
              items: const [
                DropdownMenuItem(
                  value: 'last_instance',
                  child: Text('上次启动的实例'),
                ),
                DropdownMenuItem(value: 'instance_list', child: Text('显示所有实例')),
              ],
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.grid_view,
              title: '简洁启动区',
              subtitle: '当前体展开时，启动区域的按钮将会横显示并紧凑排列。',
              value: false,
              onChanged: (_) {},
            ),
            DropdownRow(
              icon: Icons.center_focus_strong_outlined,
              title: '启动区域显示方式',
              subtitle: '自定义启动区域显示的位置和方式',
              value: '居中',
              items: const [
                DropdownMenuItem(value: '居中', child: Text('居中')),
                DropdownMenuItem(value: '左对齐', child: Text('左对齐')),
                DropdownMenuItem(value: '右对齐', child: Text('右对齐')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
