import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 辅助功能设置 - 动画速率、窗体等
class AccessibilitySettings extends StatelessWidget {
  const AccessibilitySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContentArea(
      title: '辅助功能',
      breadcrumbs: const ['个性化', '辅助功能'],
      children: [
        SettingsSectionCard(
          title: '动画性能',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '极快',
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                      Text(
                        '默认',
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                      Text(
                        '极慢',
                        style: TextStyle(
                          fontSize: 11,
                          color: SettingsPalette.textHint(context),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: SettingsPalette.accent,
                      inactiveTrackColor: SettingsPalette.accent.withValues(
                        alpha: 0.2,
                      ),
                      thumbColor: Colors.white,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: 50,
                      min: 0,
                      max: 100,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
            SwitchRow(
              icon: Icons.battery_saver,
              title: '低功耗模式',
              subtitle: '移除 BAMCLaunch 界面中会消耗 GPU 性能的动画与视觉效果，这可能导致您的体验下降。',
              value: false,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.power_outlined,
              title: '开启游戏后自动开启低功耗模式',
              subtitle: '启动游戏后自动进入低功耗模式，游戏退出后自动恢复。',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '窗体',
          children: [
            SwitchRow(
              icon: Icons.crop_square,
              title: '自动展开或缩小 BAMCLaunch 窗体',
              subtitle: '允许 BAMCLaunch 在打开部分页面时自动调整窗体大小。',
              value: true,
              onChanged: (_) {},
            ),
            DropdownRow(
              icon: Icons.center_focus_weak,
              title: '调整类型',
              subtitle: '窗体在调整时优先选择的类型。',
              value: 'expand_priority',
              items: const [
                DropdownMenuItem(value: 'expand_priority', child: Text('展开优先')),
                DropdownMenuItem(value: 'shrink_priority', child: Text('缩小优先')),
                DropdownMenuItem(value: 'none', child: Text('不调整')),
              ],
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.fullscreen,
              title: '还原窗体宽度',
              subtitle: '当离开特定页面后将窗体还原到初始设置的大小。',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
