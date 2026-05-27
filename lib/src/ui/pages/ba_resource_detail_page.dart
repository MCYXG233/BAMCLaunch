import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../../resource_center/search_service.dart';
import '../../resource_center/download_service.dart';
import '../../resource_center/resource_manager.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart' show GameInstance, GameDirectory;
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/index.dart';

class BAResourceDetailPage extends StatefulWidget {
  final Resource resource;
  final SearchSource source;

  const BAResourceDetailPage({
    super.key,
    required this.resource,
    required this.source,
  });

  @override
  State<BAResourceDetailPage> createState() => _BAResourceDetailPageState();
}

class _BAResourceDetailPageState extends State<BAResourceDetailPage> {
  final SearchService _searchService = SearchService();
  final DownloadService _downloadService = DownloadService();
  final ResourceManager _resourceManager = ResourceManager();
  final InstanceManager _instanceManager = InstanceManager();

  List<ResourceVersion> _versions = [];
  bool _isLoadingVersions = false;
  String _versionError = '';
  bool _isDescriptionExpanded = false;
  bool _isDownloading = false;
  String? _downloadingVersionId;

  @override
  void initState() {
    super.initState();
    _loadVersions();
    _initManagers();
  }

  Future<void> _initManagers() async {
    await _resourceManager.initialize();
    await _instanceManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoadingVersions = true;
      _versionError = '';
    });

    try {
      final versions = await _searchService.getVersions(
        widget.resource.id,
        widget.source,
      );
      if (mounted) {
        setState(() {
          _versions = versions;
          _isLoadingVersions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _versionError = '加载版本失败: $e';
          _isLoadingVersions = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  Future<void> _onDownloadPressed(ResourceVersion version) async {
    final instances = _instanceManager.instances;
    if (instances.isEmpty) {
      NotificationManager().showWarning('暂无可用实例', message: '请先创建一个游戏实例');
      return;
    }

    final selectedInstance = await _showInstanceSelectionDialog(instances);
    if (selectedInstance == null) return;

    setState(() {
      _isDownloading = true;
      _downloadingVersionId = version.id;
    });

    try {
      await _downloadService.downloadAndInstallToInstance(
        widget.resource,
        version,
        selectedInstance.id,
      );
      if (mounted) {
        NotificationManager().showSuccess(
          '安装成功',
          message: '${widget.resource.name} ${version.versionNumber} 已安装到 ${selectedInstance.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('安装失败', message: '$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingVersionId = null;
        });
      }
    }
  }

  Future<GameInstance?> _showInstanceSelectionDialog(List<GameInstance> instances) async {
    return BAFrostedDialog.show<GameInstance>(
      context: context,
      title: '选择安装实例',
      width: 420,
      child: SizedBox(
        height: 300,
        child: ListView.separated(
          itemCount: instances.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final instance = instances[index];
            final directory = _instanceManager.directories.firstWhere(
              (d) => d.id == instance.directoryId,
              orElse: () => _instanceManager.directories.first,
            );
            return _buildInstanceItem(instance, directory);
          },
        ),
      ),
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildInstanceItem(GameInstance instance, GameDirectory directory) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(instance),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context),
          borderRadius: BATheme.borderRadiusSmall,
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BAColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.games, color: BAColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance.name,
                    style: BATypography.bodyLarge.copyWith(
                      color: BAColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${instance.version}${instance.loader != null ? ' · ${instance.loader}' : ''}',
                    style: BATypography.bodySmall.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: BAColors.textSecondaryOf(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = BAColors.backgroundOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: BAColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.resource.name,
          style: BATypography.titleLarge.copyWith(color: textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, textPrimary, textSecondary),
            const SizedBox(height: 20),
            _buildTags(context, textPrimary, textSecondary),
            const SizedBox(height: 20),
            _buildDescription(context, textPrimary, textSecondary),
            if (widget.resource.screenshotUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildScreenshots(context),
            ],
            const SizedBox(height: 20),
            _buildVersionList(context, textPrimary, textSecondary),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResourceIcon(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.resource.name,
                  style: BATypography.headlineSmall.copyWith(color: textPrimary),
                ),
                const SizedBox(height: 8),
                if (widget.resource.authors.isNotEmpty)
                  Text(
                    widget.resource.authors.map((a) => a.name).join(', '),
                    style: BATypography.bodyMedium.copyWith(color: textSecondary),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatBadge(
                      Icons.download_rounded,
                      _formatNumber(widget.resource.downloads),
                      textSecondary,
                    ),
                    const SizedBox(width: 16),
                    _buildStatBadge(
                      Icons.favorite_rounded,
                      _formatNumber(widget.resource.likes),
                      textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceIcon(BuildContext context) {
    final surfaceVariant = BAColors.surfaceVariantOf(context);

    final IconData iconData;
    switch (widget.resource.type) {
      case ResourceType.mod:
        iconData = Icons.extension;
        break;
      case ResourceType.resourcePack:
        iconData = Icons.palette;
        break;
      case ResourceType.modpack:
        iconData = Icons.folder_zip;
        break;
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BATheme.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: BATheme.borderRadius,
        child: widget.resource.iconUrl != null
            ? Image.network(
                widget.resource.iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  iconData,
                  color: BAColors.primary,
                  size: 40,
                ),
              )
            : Icon(iconData, color: BAColors.primary, size: 40),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: BATypography.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildTags(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    final hasCategories = widget.resource.categories.isNotEmpty;
    final hasGameVersions = widget.resource.supportedGameVersions.isNotEmpty;
    final hasLoaders = widget.resource.supportedLoaders.isNotEmpty;

    if (!hasCategories && !hasGameVersions && !hasLoaders) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCategories) ...[
            Text(
              '分类',
              style: BATypography.bodyMedium.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.resource.categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BAColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BAColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    cat.name,
                    style: BATypography.label.copyWith(color: BAColors.primary),
                  ),
                );
              }).toList(),
            ),
          ],
          if (hasGameVersions) ...[
            if (hasCategories) const SizedBox(height: 12),
            Text(
              '游戏版本',
              style: BATypography.bodyMedium.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.resource.supportedGameVersions.map((v) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BAColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    v,
                    style: BATypography.label.copyWith(color: textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
          if (hasLoaders) ...[
            if (hasCategories || hasGameVersions) const SizedBox(height: 12),
            Text(
              '加载器',
              style: BATypography.bodyMedium.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.resource.supportedLoaders.map((l) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BAColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BAColors.secondary.withOpacity(0.3)),
                  ),
                  child: Text(
                    l,
                    style: BATypography.label.copyWith(color: BAColors.secondary),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    final description = widget.resource.description;
    final isLong = description.length > 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介',
            style: BATypography.titleSmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: BATypography.bodyMedium.copyWith(
              color: textSecondary,
              height: 1.6,
            ),
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? '收起' : '展开更多',
                style: BATypography.bodyMedium.copyWith(
                  color: BAColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenshots(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '截图',
          style: BATypography.titleSmall.copyWith(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.resource.screenshotUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final url = widget.resource.screenshotUrls[index];
              return GestureDetector(
                onTap: () => _showFullScreenshot(url),
                child: ClipRRect(
                  borderRadius: BATheme.borderRadius,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: BAColors.surfaceVariantOf(context),
                      borderRadius: BATheme.borderRadius,
                    ),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: BAColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: BAColors.textDisabled,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenshot(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BATheme.borderRadius,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionList(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '版本列表',
          style: BATypography.titleSmall.copyWith(color: textPrimary),
        ),
        const SizedBox(height: 12),
        _buildVersionContent(context, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildVersionContent(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_isLoadingVersions) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadius,
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: BAColors.primary),
            SizedBox(height: 12),
            Text('加载版本列表中...'),
          ],
        ),
      );
    }

    if (_versionError.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadius,
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: BAColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              _versionError,
              style: BATypography.bodyMedium.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BAPrimaryButton(
              text: '重试',
              onPressed: _loadVersions,
            ),
          ],
        ),
      );
    }

    if (_versions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadius,
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Text(
          '暂无可用版本',
          style: BATypography.bodyMedium.copyWith(color: textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _versions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: BAColors.borderOf(context),
        ),
        itemBuilder: (context, index) {
          final version = _versions[index];
          return _buildVersionCard(context, version, textPrimary, textSecondary);
        },
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context,
    ResourceVersion version,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isThisDownloading = _isDownloading && _downloadingVersionId == version.id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version.name.isNotEmpty ? version.name : version.versionNumber,
                  style: BATypography.bodyLarge.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'v${version.versionNumber}',
                      style: BATypography.bodySmall.copyWith(color: BAColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(version.releaseDate),
                      style: BATypography.bodySmall.copyWith(color: textSecondary),
                    ),
                  ],
                ),
                if (version.gameVersions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: version.gameVersions.take(4).map((v) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BAColors.surfaceVariantOf(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v,
                          style: BATypography.labelSmall.copyWith(color: textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (version.download.fileSize > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(version.download.fileSize),
                    style: BATypography.bodySmall.copyWith(color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          BAPrimaryButton(
            text: '下载',
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            loading: isThisDownloading,
            onPressed: _isDownloading ? null : () => _onDownloadPressed(version),
            leadingIcon: _isDownloading
                ? null
                : const Icon(Icons.download, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
