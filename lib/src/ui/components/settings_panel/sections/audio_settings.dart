import 'package:flutter/material.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 音频设置
class AudioSettings extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const AudioSettings({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (volume * 100).toInt();
    return SettingsContentArea(
      title: '音频',
      breadcrumbs: const ['个性化', '音频'],
      children: [
        SettingsSectionCard(
          title: '音频',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up_outlined,
                    size: 28,
                    color: SettingsPalette.textSecondary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '小提示',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SettingsPalette.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '在任何界面中，按下 Ctrl 键 + 滚动鼠标滚轮就可以快速调整音量。',
                style: TextStyle(
                  fontSize: 11,
                  color: SettingsPalette.textHint(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SliderRow(
              icon: Icons.volume_down_outlined,
              title: '音量',
              valueLabel: '$percent%',
              value: percent.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (v) => onVolumeChanged(v / 100),
              minLabel: '0%',
              maxLabel: '50%',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '背景音乐',
          initiallyCollapsed: true,
          children: [
            SwitchRow(
              icon: Icons.music_note_outlined,
              title: '播放 BAMCLaunch 背景音乐',
              subtitle: '控制由主题或 BAMCLaunch 功能提供的背景音乐',
              value: false,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.pause_circle_outline,
              title: '失去焦点时自动停止背景音乐',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '音效',
          initiallyCollapsed: true,
          children: [
            SwitchRow(
              icon: Icons.spatial_audio_outlined,
              title: '播放音效',
              subtitle: '按键音、通知提示音',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
