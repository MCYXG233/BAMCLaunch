import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../config/background_config.dart';
import '../../components/ba_background_selector.dart';
import '../../components/ba_notification.dart';
import '../../theme/background_manager.dart';
import 'settings_components.dart';

/// 背景设置页:配置背景类型、图片、视频、模糊与不透明度
class BackgroundSettingsPage extends StatelessWidget {
  const BackgroundSettingsPage({
    super.key,
    required this.backgroundConfig,
    required this.onConfigChanged,
  });

  /// 当前背景配置
  final BackgroundConfig backgroundConfig;

  /// 配置变更回调(由父组件持有并 setState)
  final ValueChanged<BackgroundConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final backgroundManager = BackgroundManager.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '背景设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: BABackgroundSelector(
                currentConfig: backgroundConfig,
                onConfigChanged: (config) async {
                  await backgroundManager.saveBackgroundConfig(config);
                  onConfigChanged(config);
                  NotificationManager().showSuccess('背景设置已保存');
                },
                onPickImage: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.path != null) {
                      final customConfig = BackgroundConfig(
                        type: BackgroundType.image,
                        imagePath: file.path,
                        blur: backgroundConfig.blur,
                        opacity: backgroundConfig.opacity,
                      );
                      await backgroundManager.saveBackgroundConfig(
                        customConfig,
                      );
                      onConfigChanged(customConfig);
                      NotificationManager().showSuccess('已选择图片: ${file.name}');
                    }
                  }
                },
                onPickVideo: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp4', 'avi', 'mov', 'mkv'],
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.path != null) {
                      final customConfig = BackgroundConfig(
                        type: BackgroundType.video,
                        videoPath: file.path,
                        blur: backgroundConfig.blur,
                        opacity: backgroundConfig.opacity,
                      );
                      await backgroundManager.saveBackgroundConfig(
                        customConfig,
                      );
                      onConfigChanged(customConfig);
                      NotificationManager().showSuccess('已选择视频: ${file.name}');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
