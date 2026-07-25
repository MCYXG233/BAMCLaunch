import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logger.dart';
import '../../../platform/platform_adapter_factory.dart';
import '../../components/ba_notification.dart';
import '../../theme/colors.dart';
import 'settings_components.dart';

/// 关于设置页:展示应用信息、链接、缓存清理
///
/// 完全自包含:版本号集中在本类内定义,与 pubspec.yaml 保持一致
class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  /// 应用版本号(集中管理,与 pubspec.yaml 保持一致)
  static const String _appVersion = '1.0.0';

  /// 应用构建号
  static const String _appBuild = '1';

  /// 应用全版本显示
  String get _appVersionDisplay => 'v$_appVersion+$_appBuild';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '关于',
          children: [
            SettingsRow(
              icon: Icons.info_outline,
              title: '关于 BAMC Launch',
              subtitle: '查看应用信息和许可证',
              control: SettingsPrimaryButton(
                text: '查看',
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('关于 BAMC Launch'),
                    content: Text(
                      '版本 $_appVersionDisplay\n© 2024 BAMC Launch Team',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SettingsRow(
              icon: Icons.code,
              title: 'GitHub 仓库',
              subtitle: '访问源代码',
              control: SettingsPrimaryButton(
                text: '访问',
                onPressed: () => _launchURL(
                  context,
                  'https://github.com/TSSForsunshine/BAMCLaunch',
                ),
              ),
            ),
            SettingsRow(
              icon: Icons.feedback,
              title: '问题反馈',
              subtitle: '提交 Bug 或建议',
              control: SettingsPrimaryButton(
                text: '反馈',
                onPressed: () => _launchURL(
                  context,
                  'https://github.com/TSSForsunshine/BAMCLaunch/issues',
                ),
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '维护',
          children: [
            SettingsRow(
              icon: Icons.cleaning_services,
              title: '清除缓存',
              subtitle: '清理临时文件释放存储空间',
              control: SettingsPrimaryButton(
                text: '清除',
                onPressed: () => _confirmClearCache(context),
                color: BAColors.accentPinkDarkOf(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 调用系统浏览器打开外部链接
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        NotificationManager().showError('打开链接失败', message: e.toString());
      }
    }
  }

  /// 弹出二次确认对话框,确认后执行缓存清理
  Future<void> _confirmClearCache(BuildContext context) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除缓存'),
        content: const Text('此操作将清理启动器临时文件（包括下载缓存、解压中间文件等）。\n\n确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: BAColors.dangerOf(context),
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      await _clearCache(context);
    }
  }

  /// 递归删除临时目录下所有文件
  Future<void> _clearCache(BuildContext context) async {
    try {
      final platformAdapter = PlatformAdapterFactory.create();
      final tempDir = await platformAdapter.getTempDirectory();
      final directory = Directory(tempDir);
      if (await directory.exists()) {
        int count = 0;
        await for (final entity in directory.list(recursive: true)) {
          try {
            await entity.delete(recursive: true);
            count++;
          } catch (e, st) {
            Logger.instance.error('删除临时文件失败', e, st);
          }
        }
        if (context.mounted) {
          NotificationManager().showSuccess(
            '缓存已清除',
            message: '已清理 $count 个临时文件',
          );
        }
      } else {
        if (context.mounted) {
          NotificationManager().showInfo('缓存为空', message: '没有需要清理的临时文件');
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationManager().showError('清除缓存失败', message: e.toString());
      }
    }
  }
}
