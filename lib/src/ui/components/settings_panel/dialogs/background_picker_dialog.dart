import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../theme/background_manager.dart';
import '../../../../config/background_config.dart';
import '../../ba_notification.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';
import '../widgets/sidebar_nav.dart';

/// 背景选择对话框 - BakaXL 风格（与设置面板同一设计语言）
///
/// 布局：
///   - 顶栏：返回 + 标题 + 完成
///   - 内容：左侧导航（图片 / 视频 / 主题） + 右侧内容
class BackgroundPickerDialog extends StatefulWidget {
  final BackgroundConfig currentConfig;
  final ValueChanged<BackgroundConfig> onChanged;

  const BackgroundPickerDialog({
    super.key,
    required this.currentConfig,
    required this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required BackgroundConfig currentConfig,
    required ValueChanged<BackgroundConfig> onChanged,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => BackgroundPickerDialog(
        currentConfig: currentConfig,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<BackgroundPickerDialog> createState() => _BackgroundPickerDialogState();
}

class _BackgroundPickerDialogState extends State<BackgroundPickerDialog> {
  late BackgroundConfig _config = widget.currentConfig;
  late final BackgroundManager _manager = BackgroundManager();

  String _selectedSection = 'image';

  void _update(BackgroundConfig config) {
    setState(() => _config = config);
    widget.onChanged(config);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    _update(BackgroundConfig(
      type: BackgroundType.image,
      imagePath: path,
      opacity: _config.opacity,
    ));
    if (mounted) {
      NotificationManager().showSuccess('背景图片已设置');
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    _update(BackgroundConfig(
      type: BackgroundType.video,
      videoPath: path,
      opacity: _config.opacity,
    ));
    if (mounted) {
      NotificationManager().showSuccess('背景视频已设置');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 800,
        height: 560,
        decoration: BoxDecoration(
          gradient: SettingsPalette.backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: SettingsPalette.panelShadow,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  SettingsSidebar(
                    sections: [
                      SidebarSection(title: '背景类型', items: [
                        SidebarItem(
                          id: 'image',
                          icon: Icons.image_outlined,
                          label: '图片',
                        ),
                        SidebarItem(
                          id: 'video',
                          icon: Icons.movie_outlined,
                          label: '视频',
                        ),
                        SidebarItem(
                          id: 'preset',
                          icon: Icons.auto_awesome_outlined,
                          label: '预设',
                        ),
                      ]),
                    ],
                    selectedId: _selectedSection,
                    onSelected: (id) => setState(() => _selectedSection = id),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedSection),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SettingsPalette.cardBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '背景设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SettingsPalette.textPrimary(context),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 'video':
        return _buildVideoContent();
      case 'preset':
        return _buildPresetContent();
      case 'image':
      default:
        return _buildImageContent();
    }
  }

  Widget _buildImageContent() {
    return SettingsContentArea(
      title: '背景图片',
      breadcrumbs: const ['背景', '图片'],
      children: [
        SettingsSectionCard(
          title: '当前背景',
          children: [
            InfoCard(
              icon: Icons.info_outline,
              child: Text(
                '选择本地图片作为启动器背景。支持 JPG/PNG/WEBP。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            if (_config.type == BackgroundType.image &&
                _config.imagePath != null)
              SettingRow(
                icon: Icons.image,
                title: '当前图片',
                subtitle: _config.imagePath!.split(Platform.pathSeparator).last,
                trailing: _buildPreviewThumb(_config.imagePath!),
                onTap: () {},
              ),
            ButtonRow(
              icon: Icons.add_photo_alternate_outlined,
              title: '选择本地图片',
              buttonLabel: '浏览',
              onPressed: _pickImage,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '显示效果',
          initiallyCollapsed: true,
          children: [
            SliderRow(
              icon: Icons.opacity_outlined,
              title: '背景不透明度',
              valueLabel: '${(_config.opacity * 100).toInt()}%',
              value: _config.opacity,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: (v) => _update(_config.copyWith(opacity: v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return SettingsContentArea(
      title: '背景视频',
      breadcrumbs: const ['背景', '视频'],
      children: [
        SettingsSectionCard(
          title: '当前视频',
          children: [
            InfoCard(
              icon: Icons.lightbulb_outline,
              child: Text(
                '使用本地视频作为动态背景。视频会被循环播放。',
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textSecondary(context),
                ),
              ),
            ),
            if (_config.type == BackgroundType.video &&
                _config.videoPath != null)
              SettingRow(
                icon: Icons.movie,
                title: '当前视频',
                subtitle: _config.videoPath!.split(Platform.pathSeparator).last,
                onTap: () {},
              ),
            ButtonRow(
              icon: Icons.video_library_outlined,
              title: '选择本地视频',
              buttonLabel: '浏览',
              onPressed: _pickVideo,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsSectionCard(
          title: '播放控制',
          initiallyCollapsed: true,
          children: [
            SwitchRow(
              icon: Icons.loop_outlined,
              title: '循环播放',
              subtitle: '视频结束后从头开始',
              value: true,
              onChanged: (_) {},
            ),
            SwitchRow(
              icon: Icons.volume_off_outlined,
              title: '静音',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetContent() {
    final presets = <_PresetInfo>[
      _PresetInfo(
        name: '经典',
        description: 'BAMCLaunch 默认主题',
        config: BackgroundConfig.classic,
        icon: Icons.wallpaper_outlined,
      ),
      _PresetInfo(
        name: '纯色',
        description: '无背景图片，仅显示纯色',
        config: BackgroundConfig(
          type: BackgroundType.solid,
          solidColor: 0xFF5C7CFA,
          opacity: 1,
        ),
        icon: Icons.format_color_fill_outlined,
      ),
      _PresetInfo(
        name: '渐变',
        description: '蔚蓝档案风格渐变背景',
        config: BackgroundConfig.sakura,
        icon: Icons.gradient_outlined,
      ),
    ];

    return SettingsContentArea(
      title: '预设主题',
      breadcrumbs: const ['背景', '预设'],
      children: [
        SettingsSectionCard(
          title: '内置预设',
          children: presets
              .map((p) => _buildPresetRow(p))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildPresetRow(_PresetInfo preset) {
    final selected = _config.type == preset.config.type;
    return SettingRow(
      icon: preset.icon,
      title: preset.name,
      subtitle: preset.description,
      onTap: () {
        _update(preset.config);
        NotificationManager().showSuccess('已切换到「${preset.name}」');
      },
      trailing: selected
          ? Icon(Icons.check_circle, color: SettingsPalette.accent, size: 18)
          : Icon(
              Icons.chevron_right,
              size: 16,
              color: SettingsPalette.textHint(context),
            ),
    );
  }

  Widget _buildPreviewThumb(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SettingsPalette.cardSolid(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: 18,
            color: SettingsPalette.textHint(context),
          ),
        ),
      ),
    );
  }
}

class _PresetInfo {
  final String name;
  final String description;
  final BackgroundConfig config;
  final IconData icon;
  _PresetInfo({
    required this.name,
    required this.description,
    required this.config,
    required this.icon,
  });
}