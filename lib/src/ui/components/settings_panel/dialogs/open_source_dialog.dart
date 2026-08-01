import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/settings_theme.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_content_area.dart';

/// 开源组件对话框 - 展示 BAMCLaunch 使用的开源库及其许可证
class OpenSourceDialog extends StatefulWidget {
  const OpenSourceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const OpenSourceDialog(),
    );
  }

  @override
  State<OpenSourceDialog> createState() => _OpenSourceDialogState();
}

class _OpenSourceDialogState extends State<OpenSourceDialog> {
  String _filter = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_Project> _projects = const [
    _Project(
      name: 'Flutter',
      url: 'https://github.com/flutter/flutter',
      license: 'BSD-3-Clause',
      category: '框架',
      description: 'BAMCLaunch 的核心 UI 框架。',
    ),
    _Project(
      name: 'BMCLAPI',
      url: 'https://www.bmclapi.com/',
      license: '服务',
      category: '镜像',
      description: '中国大陆地区 Minecraft 文件下载镜像。',
    ),
    _Project(
      name: 'Modrinth API',
      url: 'https://modrinth.com',
      license: 'API',
      category: '镜像',
      description: '开源 Mod 平台的 API 接入。',
    ),
    _Project(
      name: 'CurseForge API',
      url: 'https://docs.curseforge.com',
      license: 'API',
      category: '镜像',
      description: 'Mod 资源平台 API 接入。',
    ),
    _Project(
      name: 'url_launcher',
      url: 'https://pub.dev/packages/url_launcher',
      license: 'BSD-3-Clause',
      category: '工具',
      description: '在系统中打开 URL。',
    ),
    _Project(
      name: 'file_picker',
      url: 'https://pub.dev/packages/file_picker',
      license: 'MIT',
      category: '工具',
      description: '本地文件与目录选择器。',
    ),
    _Project(
      name: 'media_kit',
      url: 'https://github.com/media-kit/media-kit',
      license: 'MIT',
      category: '媒体',
      description: '跨平台媒体播放核心。',
    ),
    _Project(
      name: 'shared_preferences',
      url: 'https://pub.dev/packages/shared_preferences',
      license: 'BSD-3-Clause',
      category: '存储',
      description: '键值对持久化。',
    ),
    _Project(
      name: 'flutter_riverpod',
      url: 'https://riverpod.dev',
      license: 'MIT',
      category: '框架',
      description: '响应式状态管理。',
    ),
    _Project(
      name: 'provider',
      url: 'https://pub.dev/packages/provider',
      license: 'MIT',
      category: '框架',
      description: 'InheritedWidget 封装。',
    ),
    _Project(
      name: 'archive',
      url: 'https://pub.dev/packages/archive',
      license: 'BSD-3-Clause',
      category: '工具',
      description: 'Zip / 7z / Tar 归档读写。',
    ),
    _Project(
      name: 'fl_chart',
      url: 'https://pub.dev/packages/fl_chart',
      license: 'MIT',
      category: '可视化',
      description: '统计页图表。',
    ),
    _Project(
      name: 'lottie',
      url: 'https://pub.dev/packages/lottie',
      license: 'MIT',
      category: '动效',
      description: 'After Effects 动效播放。',
    ),
    _Project(
      name: 'crypto',
      url: 'https://pub.dev/packages/crypto',
      license: 'BSD-3-Clause',
      category: '安全',
      description: '哈希算法（SHA-256 / MD5 等）。',
    ),
    _Project(
      name: 'encrypt',
      url: 'https://pub.dev/packages/encrypt',
      license: 'BSD-3-Clause',
      category: '安全',
      description: '对称加密（AES）。',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Project> get _filteredProjects {
    if (_filter.isEmpty) return _projects;
    return _projects
        .where((p) =>
            p.name.toLowerCase().contains(_filter.toLowerCase()) ||
            p.category.contains(_filter) ||
            p.description.contains(_filter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<_Project>>{};
    for (final p in _filteredProjects) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 720,
        height: 640,
        decoration: BoxDecoration(
          gradient: SettingsPalette.backgroundGradient(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SettingsPalette.panelShadow(context),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            Expanded(
              child: SettingsContentArea(
                title: '开源组件',
                breadcrumbs: const ['关于', '开源组件'],
                children: byCategory.entries
                    .map((e) => _buildCategorySection(context, e.key, e.value))
                    .toList(),
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
            '开源组件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SettingsPalette.textPrimary(context),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: SettingsPalette.glassWhite(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SettingsPalette.cardBorder(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.search,
              size: 14,
              color: SettingsPalette.textHint(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _filter = v),
                style: TextStyle(
                  fontSize: 12,
                  color: SettingsPalette.textPrimary(context),
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: '搜索组件',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.textHint(context),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<_Project> projects,
  ) {
    return SettingsSectionCard(
      title: category,
      titleIcon: _categoryIcon(category),
      children: projects.map((p) => _buildProjectRow(context, p)).toList(),
    );
  }

  Widget _buildProjectRow(BuildContext context, _Project p) {
    return SettingRow(
      icon: Icons.code,
      title: p.name,
      subtitle: '${p.license} · ${p.description}',
      onTap: () => _open(p.url),
      trailing: Icon(
        Icons.open_in_new,
        size: 16,
        color: SettingsPalette.textSecondary(context),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case '框架':
        return Icons.extension_outlined;
      case '工具':
        return Icons.build_outlined;
      case '媒体':
        return Icons.play_circle_outline;
      case '镜像':
        return Icons.cloud_outlined;
      case '存储':
        return Icons.storage_outlined;
      case '可视化':
        return Icons.bar_chart_outlined;
      case '动效':
        return Icons.animation_outlined;
      case '安全':
        return Icons.shield_outlined;
      default:
        return Icons.code_outlined;
    }
  }

  Future<void> _open(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _Project {
  final String name;
  final String url;
  final String license;
  final String category;
  final String description;

  const _Project({
    required this.name,
    required this.url,
    required this.license,
    required this.category,
    required this.description,
  });
}