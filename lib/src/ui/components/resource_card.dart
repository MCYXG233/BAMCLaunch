import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// 资源卡片组件
class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onTap;
  final bool isInstalled;
  final bool showInstalledBadge;

  const ResourceCard({
    super.key,
    required this.resource,
    this.onTap,
    this.isInstalled = false,
    this.showInstalledBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = BAColors.surfaceOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final borderColor = BAColors.borderOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BATheme.borderRadius,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: BATheme.shadowsSmallOf(context),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleAndBadge(context, textPrimary),
                        const SizedBox(height: 8),
                        _buildDescription(textSecondary),
                        const SizedBox(height: 12),
                        _buildMetadata(context, textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isInstalled && showInstalledBadge) _buildInstalledBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final surfaceVariant = BAColors.surfaceVariantOf(context);
    
    if (resource.iconUrl != null) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadiusSmall,
        ),
        child: ClipRRect(
          borderRadius: BATheme.borderRadiusSmall,
          child: Image.network(
            resource.iconUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderIcon(context);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadiusSmall,
        ),
        child: _buildPlaceholderIcon(context),
      );
    }
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    final primaryColor = BAColors.primary;
    final IconData iconData;
    
    switch (resource.type) {
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
    
    return Icon(
      iconData,
      color: primaryColor,
      size: 32,
    );
  }

  Widget _buildTitleAndBadge(BuildContext context, Color textPrimary) {
    return Row(
      children: [
        Expanded(
          child: Text(
            resource.name,
            style: BATypography.bodyLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildSourceBadge(context),
      ],
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final primaryColor = BAColors.primary;
    final secondaryColor = BAColors.secondary;

    Color badgeColor;
    String badgeText;
    
    if (resource.source == 'modrinth') {
      badgeColor = secondaryColor;
      badgeText = 'Modrinth';
    } else if (resource.source == 'curseforge') {
      badgeColor = primaryColor;
      badgeText = 'CurseForge';
    } else {
      badgeColor = primaryColor;
      badgeText = resource.source;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: BATypography.label.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDescription(Color textSecondary) {
    return Text(
      resource.description,
      style: BATypography.bodyMedium.copyWith(
        color: textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata(BuildContext context, Color textSecondary) {
    return Row(
      children: [
        _buildMetaItem(
          context,
          Icons.download,
          _formatNumber(resource.downloads),
        ),
        const SizedBox(width: 16),
        _buildMetaItem(
          context,
          Icons.thumb_up,
          _formatNumber(resource.likes),
        ),
        const SizedBox(width: 16),
        if (resource.authors.isNotEmpty)
          Expanded(
            child: Text(
              'by ${resource.authors.first.name}',
              style: BATypography.bodySmall.copyWith(
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildMetaItem(BuildContext context, IconData icon, String text) {
    final textSecondary = BAColors.textSecondaryOf(context);
    
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: BATypography.bodySmall.copyWith(
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstalledBadge(BuildContext context) {
    final successColor = BAColors.success;
    
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: successColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: successColor),
            const SizedBox(width: 4),
            Text(
              '已安装',
              style: BATypography.label.copyWith(
                color: successColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// 已安装资源卡片组件
class InstalledResourceCard extends StatelessWidget {
  final InstalledResource resource;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const InstalledResourceCard({
    super.key,
    required this.resource,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = BAColors.surfaceOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final borderColor = BAColors.borderOf(context);
    final dangerColor = BAColors.danger;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BATheme.borderRadius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: BATheme.shadowsSmallOf(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          resource.name,
                          style: BATypography.bodyLarge.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '版本: ${resource.installedVersion}',
                    style: BATypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(resource.fileSize),
                    style: BATypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    resource.enabled ? Icons.visibility : Icons.visibility_off,
                    color: resource.enabled ? BAColors.success : textSecondary,
                  ),
                  onPressed: onToggle,
                  tooltip: resource.enabled ? '禁用' : '启用',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: dangerColor),
                  onPressed: onDelete,
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final surfaceVariant = BAColors.surfaceVariantOf(context);
    final primaryColor = BAColors.primary;
    
    final IconData iconData;
    switch (resource.type) {
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

    if (resource.iconUrl != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadiusSmall,
        ),
        child: ClipRRect(
          borderRadius: BATheme.borderRadiusSmall,
          child: Image.network(
            resource.iconUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(iconData, color: primaryColor, size: 28);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BATheme.borderRadiusSmall,
        ),
        child: Icon(iconData, color: primaryColor, size: 28),
      );
    }
  }

  Widget _buildStatusBadge(BuildContext context) {
    final successColor = BAColors.success;
    final textSecondary = BAColors.textSecondaryOf(context);
    
    final Color badgeColor = resource.enabled ? successColor : textSecondary;
    final String badgeText = resource.enabled ? '已启用' : '已禁用';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: BATypography.label.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
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
}
