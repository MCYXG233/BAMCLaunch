import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../animations/ba_animations.dart';
import '../../../../resource_center/models.dart';
import '../resource_constants.dart';
import 'hover_scale_card.dart';

/// 资源网格卡片 - 展示单个资源条目
class ResourceGridCard extends StatelessWidget {
  final Resource resource;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String Function(int) formatDownloads;

  const ResourceGridCard({
    super.key,
    required this.resource,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.formatDownloads,
  });

  @override
  Widget build(BuildContext context) {
    final typeColors = ResourceConstants.typeColorsOf(context);
    final typeColor = typeColors[resource.type] ?? BAColors.primaryOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    return HoverScaleCard(
      onTap: onTap,
      hoverBorderColor: typeColor,
      defaultBorderColor: BAColors.borderOf(context).withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // 左侧：图标
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor.withValues(alpha: 0.2),
                    typeColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: resource.iconUrl != null
                    ? Image.network(
                        resource.iconUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            ResourceConstants.typeIcons[resource.type] ??
                                Icons.apps,
                            size: 26,
                            color: typeColor,
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: typeColor,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          ResourceConstants.typeIcons[resource.type] ??
                              Icons.apps,
                          size: 26,
                          color: typeColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // 中间：信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 名称行
                  Text(
                    resource.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 描述（1行）
                  Text(
                    resource.description.isNotEmpty
                        ? resource.description
                        : resource.summary ?? '',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // 标签行：分类 + 游戏版本
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [
                      // 分类标签（最多2个）
                      ...resource.categories
                          .take(2)
                          .map(
                            (cat) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: BAColors.backgroundSecondaryOf(context),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                      // 游戏版本
                      if (resource.supportedGameVersions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: BAColors.primaryOf(
                              context,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource.supportedGameVersions.first,
                            style: TextStyle(
                              color: BAColors.primaryOf(context),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 右侧：作者 + 下载量
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 作者
                if (resource.authors.isNotEmpty)
                  Text(
                    resource.authors.first.name,
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // 下载量
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      size: 11,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      formatDownloads(resource.downloads),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 收藏按钮
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: BAAnimations.pulse(
                    isActive: isFavorite,
                    duration: const Duration(milliseconds: 1200),
                    scaleBegin: 1.0,
                    scaleEnd: 1.2,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? BAColors.dangerOf(context)
                          : textSecondary.withValues(alpha: 0.5),
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
