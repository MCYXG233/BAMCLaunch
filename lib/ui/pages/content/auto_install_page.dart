import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/lists/bamc_list.dart';
import './version_detail_page.dart';

class AutoInstallPage extends StatefulWidget {
  final VersionManager versionManager;

  const AutoInstallPage({super.key, required this.versionManager});

  @override
  State<AutoInstallPage> createState() => _AutoInstallPageState();
}

class _AutoInstallPageState extends State<AutoInstallPage> {
  bool _isLoading = false;
  List<Version> _versions = [];
  VersionCategory _selectedCategory = VersionCategory.release;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final manifest = await widget.versionManager.getVersionManifest();
      setState(() => _versions = manifest.versions.map((entry) => Version(
            id: entry.id,
            type: entry.type,
            releaseTime: entry.releaseTime,
            time: entry.time,
            complianceLevel: 0,
            download: null,
            assetIndex: null,
            libraries: [],
            arguments: [],
            jvmArguments: [],
            mainClass: '',
            inheritsFrom: '',
            status: VersionStatus.not_installed,
          )).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载版本失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Version> _getFilteredVersions() {
    return _versions.where((version) {
      switch (_selectedCategory) {
        case VersionCategory.release:
          return version.type == VersionType.release;
        case VersionCategory.snapshot:
          return version.type == VersionType.snapshot;
        case VersionCategory.oldAlpha:
          return version.type == VersionType.old_alpha ||
              version.type == VersionType.old_beta;
        case VersionCategory.preRelease:
          return false;
        case VersionCategory.other:
          return version.type == VersionType.custom;
      }
    }).toList();
  }

  Widget _buildVersionCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryTab(VersionCategory.release, '正式版'),
            Container(width: 1, height: 40, color: BamcColors.border),
            _buildCategoryTab(VersionCategory.snapshot, '快照版'),
            Container(width: 1, height: 40, color: BamcColors.border),
            _buildCategoryTab(VersionCategory.oldAlpha, '远古版'),
            Container(width: 1, height: 40, color: BamcColors.border),
            _buildCategoryTab(VersionCategory.preRelease, '预览版'),
            Container(width: 1, height: 40, color: BamcColors.border),
            _buildCategoryTab(VersionCategory.other, '特殊版本'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(VersionCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return TextButton(
      onPressed: () {
        setState(() => _selectedCategory = category);
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? BamcColors.primary.withOpacity(0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? BamcColors.primary : BamcColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildVersionList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filteredVersions = _getFilteredVersions();
    
    if (filteredVersions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: BamcColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              '暂无${_getCategoryLabel(_selectedCategory)}',
              style: const TextStyle(color: BamcColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return BamcList<Version>(
      items: filteredVersions,
      itemBuilder: (context, version, index, isSelected) {
        return BamcListItem(
          leading: _buildVersionIcon(version),
          title: Text(version.id),
          subtitle: Text('${_getVersionTypeLabel(version.type)} · ${version.releaseTime}'),
          trailing: BamcButton(
            text: '安装',
            onPressed: () => _handleInstallVersion(version),
            type: BamcButtonType.primary,
            size: BamcButtonSize.small,
          ),
          selected: isSelected,
        );
      },
      onTap: (version) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VersionDetailPage(version: version, versionManager: widget.versionManager),
          ),
        );
      },
    );
  }

  Widget _buildVersionIcon(Version version) {
    Color color;
    IconData icon;

    switch (version.type) {
      case VersionType.release:
        color = BamcColors.success;
        icon = Icons.check_circle;
        break;
      case VersionType.snapshot:
        color = BamcColors.warning;
        icon = Icons.update;
        break;
      case VersionType.old_alpha:
      case VersionType.old_beta:
        color = BamcColors.info;
        icon = Icons.history;
        break;
      case VersionType.custom:
        color = BamcColors.danger;
        icon = Icons.star;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  void _handleInstallVersion(Version version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要安装版本 ${version.id} 吗？'),
            const SizedBox(height: 16),
            // 这里可以添加模组加载器选择、附加组件选择等
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _installVersion(version);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  Future<void> _installVersion(Version version) async {
    setState(() => _isLoading = true);
    try {
      await widget.versionManager.installVersion(version.id, (progress) {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('版本 ${version.id} 安装成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('安装失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showVersionDetails(Version version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('版本详情: ${version.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${_getVersionTypeLabel(version.type)}'),
            Text('发布时间: ${version.releaseTime}'),
            const SizedBox(height: 16),
            // 这里可以添加更多详细信息
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getVersionTypeLabel(VersionType type) {
    switch (type) {
      case VersionType.release:
        return '正式版';
      case VersionType.snapshot:
        return '快照版';
      case VersionType.old_alpha:
        return '远古Alpha';
      case VersionType.old_beta:
        return '远古Beta';
      case VersionType.custom:
        return '自定义';
      default:
        return '未知';
    }
  }

  String _getCategoryLabel(VersionCategory category) {
    switch (category) {
      case VersionCategory.release:
        return '正式版';
      case VersionCategory.snapshot:
        return '快照版';
      case VersionCategory.oldAlpha:
        return '远古版';
      case VersionCategory.preRelease:
        return '预览版';
      case VersionCategory.other:
        return '特殊版本';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本分类标签
          _buildVersionCategoryTabs(),
          const SizedBox(height: 20),

          // 版本列表
          _buildVersionList(),
        ],
      ),
    );
  }
}