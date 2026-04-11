import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../theme/colors.dart';
import '../buttons/bamc_button.dart';

class VersionInstallDialog extends StatefulWidget {
  final VersionManager versionManager;

  const VersionInstallDialog({
    super.key,
    required this.versionManager,
  });

  @override
  State<VersionInstallDialog> createState() => _VersionInstallDialogState();
}

class _VersionInstallDialogState extends State<VersionInstallDialog> {
  bool _isLoading = false;
  List<VersionEntry> _availableVersions = [];
  List<VersionEntry> _filteredVersions = [];
  String _searchQuery = '';
  VersionEntry? _selectedVersion;
  double _installationProgress = 0.0;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final manifest = await widget.versionManager.getVersionManifest();
      setState(() {
        _availableVersions = manifest.versions;
        _filteredVersions = manifest.versions;
      });
    } catch (e) {
      logger.error('Failed to load versions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredVersions = _availableVersions
          .where((version) =>
              version.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _installVersion() async {
    if (_selectedVersion == null) return;

    setState(() => _isInstalling = true);

    try {
      await widget.versionManager.installVersion(
        _selectedVersion!.id,
        (progress) {
          setState(() => _installationProgress = progress);
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      logger.error('Failed to install version: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('安装失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isInstalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BamcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '安装版本',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: BamcColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 搜索框
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: BamcColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BamcColors.border),
              ),
              child: TextField(
                onChanged: _handleSearch,
                decoration: const InputDecoration(
                  hintText: '搜索版本...',
                  hintStyle: TextStyle(color: BamcColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.search, color: BamcColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 版本列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BamcColors.border),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredVersions.length,
                        itemBuilder: (context, index) {
                          final version = _filteredVersions[index];
                          final isSelected = _selectedVersion?.id == version.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? BamcColors.primary.withOpacity(0.1)
                                  : BamcColors.background,
                              border: const Border(
                                bottom: BorderSide(color: BamcColors.border),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() => _selectedVersion = version);
                              },
                              title: Text(
                                version.id,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? BamcColors.primary
                                      : BamcColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                _getVersionTypeText(version.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BamcColors.textSecondary,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: BamcColors.primary,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // 进度条（安装时显示）
            if (_isInstalling) ...[
              LinearProgressIndicator(
                value: _installationProgress,
                backgroundColor: BamcColors.background,
                color: BamcColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],

            // 按钮栏
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BamcButton(
                  text: '取消',
                  onPressed:
                      _isInstalling ? null : () => Navigator.pop(context),
                  type: BamcButtonType.outline,
                  size: BamcButtonSize.medium,
                ),
                const SizedBox(width: 12),
                BamcButton(
                  text: _isInstalling ? '安装中...' : '安装',
                  onPressed: _isInstalling || _selectedVersion == null
                      ? null
                      : _installVersion,
                  type: BamcButtonType.primary,
                  size: BamcButtonSize.medium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVersionTypeText(VersionType type) {
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
        return '自定义版本';
    }
  }
}
