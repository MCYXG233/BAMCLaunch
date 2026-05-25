import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../../resource_center/download_service.dart';
import '../../resource_center/resource_manager.dart';
import '../../resource_center/search_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/index.dart';

/// 资源详情页面
class ResourceDetailPage extends StatefulWidget {
  final Resource resource;

  const ResourceDetailPage({
    super.key,
    required this.resource,
  });

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final ResourceManager _resourceManager = ResourceManager();
  final DownloadService _downloadService = DownloadService();
  final SearchService _searchService = SearchService();

  List<ResourceVersion> _versions = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String _errorMessage = '';
  String? _selectedVersionId;
  InstalledResource? _installedResource;

  @override
  void initState() {
    super.initState();
    _loadVersions();
    _checkInstalled();
  }

  SearchSource _getSourceEnum(String source) {
    switch (source) {
      case 'modrinth':
        return SearchSource.modrinth;
      case 'curseforge':
        return SearchSource.curseforge;
      default:
        return SearchSource.modrinth;
    }
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final source = _getSourceEnum(widget.resource.source);
      final versions = await _searchService.getVersions(widget.resource.id, source);
      if (mounted) {
        setState(() {
          _versions = versions;
          if (versions.isNotEmpty) {
            _selectedVersionId = versions.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载版本失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkInstalled() async {
    await _resourceManager.initialize();
    final installed = _resourceManager.getInstalledResourceBySource(
      widget.resource.source,
      widget.resource.id,
    );
    if (mounted) {
      setState(() {
        _installedResource = installed;
      });
    }
  }

  Future<void> _downloadVersion() async {
    if (_selectedVersionId == null || _isDownloading) return;

    final version = _versions.firstWhere(
      (v) => v.id == _selectedVersionId,
      orElse: () => _versions.first,
    );

    setState(() {
      _isDownloading = true;
    });

    try {
      await _downloadService.downloadResource(
        widget.resource,
        version,
      );
      if (mounted) {
        _checkInstalled();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载并安装成功!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
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
        title: Text(
          widget.resource.name,
          style: BATypography.headlineMedium.copyWith(color: textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, textPrimary, textSecondary),
            const SizedBox(height: 24),
            _buildDescription(context, textPrimary, textSecondary),
            const SizedBox(height: 24),
            _buildVersions(context, textPrimary, textSecondary),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.resource.name,
                style: BATypography.headlineMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.resource.authors.isNotEmpty)
                Text(
                  '作者: ${widget.resource.authors.map((a) => a.name).join(', ')}',
                  style: BATypography.bodyMedium.copyWith(
                    color: textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              _buildStats(context, textSecondary),
              const SizedBox(height: 16),
              if (_installedResource != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BAColors.success.withOpacity(0.1),
                    borderRadius: BATheme.borderRadiusSmall,
                    border: Border.all(
                      color: BAColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: BAColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '已安装 (${_installedResource!.installedVersion})',
                          style: BATypography.bodyMedium.copyWith(
                            color: BAColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    final surfaceVariant = BAColors.surfaceVariantOf(context);
    final primaryColor = BAColors.primary;

    final IconData iconData;
    switch (widget.resource.type) {
      case ResourceType.mod:
        iconData = Icons.extension;
        break;
      case ResourceType.resourcePack:
        iconData = Icons.palette;
        break;
      case ResourceType.modpack:
        iconData = Icons.folder;
        break;
    }

    if (widget.resource.iconUrl != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadius,
        ),
        child: ClipRRect(
          borderRadius: BATheme.borderRadius,
          child: Image.network(
            widget.resource.iconUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(iconData, color: primaryColor, size: 64);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadius,
        ),
        child: Icon(iconData, color: primaryColor, size: 64),
      );
    }
  }

  Widget _buildStats(BuildContext context, Color textSecondary) {
    return Wrap(
      spacing: 16,
      children: [
        _buildStatItem(
          context,
          Icons.download,
          '${widget.resource.downloads}',
          textSecondary,
        ),
        _buildStatItem(
          context,
          Icons.thumb_up,
          '${widget.resource.likes}',
          textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    Color color,
  ) {
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

  Widget _buildDescription(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '描述',
          style: BATypography.headlineSmall.copyWith(
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BATheme.borderRadius,
            border: Border.all(color: BAColors.borderOf(context)),
          ),
          child: Text(
            widget.resource.description,
            style: BATypography.bodyMedium.copyWith(
              color: textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSupportedVersions(context, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildSupportedVersions(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '支持的游戏版本',
          style: BATypography.bodyLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.resource.supportedGameVersions.map((version) {
            return Chip(
              label: Text(version),
              backgroundColor: BAColors.surfaceVariantOf(context),
              labelStyle: TextStyle(color: textSecondary),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          '支持的加载器',
          style: BATypography.bodyLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.resource.supportedLoaders.map((loader) {
            return Chip(
              label: Text(loader),
              backgroundColor: BAColors.surfaceVariantOf(context),
              labelStyle: TextStyle(color: textSecondary),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVersions(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '版本列表',
          style: BATypography.headlineSmall.copyWith(
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                : _buildVersionList(context, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildVersionList(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
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
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: BAColors.borderOf(context),
        ),
        itemBuilder: (context, index) {
          final version = _versions[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Radio<String>(
              value: version.id,
              groupValue: _selectedVersionId,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVersionId = value;
                  });
                }
              },
            ),
            title: Text(
              version.name,
              style: BATypography.bodyLarge.copyWith(
                color: textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '版本: ${version.versionNumber}',
                  style: BATypography.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '游戏版本: ${version.gameVersions.join(', ')}',
                  style: BATypography.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '发布时间: ${version.releaseDate.toLocal().toString().split(' ')[0]}',
                  style: BATypography.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            trailing: _buildDownloadButton(context, version),
            onTap: () {
              setState(() {
                _selectedVersionId = version.id;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, ResourceVersion version) {
    return BAPrimaryButton(
      text: _isDownloading ? '下载中...' : '下载',
      onPressed: _selectedVersionId == version.id && !_isDownloading
          ? _downloadVersion
          : null,
      loading: _isDownloading && _selectedVersionId == version.id,
    );
  }
}
