import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../resource_center/models.dart';
import '../resource_constants.dart';
import 'hover_scale_card.dart';

/// 资源网格卡片 - 展示单个资源条目
///
/// 参考 BakaXL 笨蛋广场卡片设计：
/// - 左上大图 + 来源徽章
/// - 标题/描述/分类/加载器/版本 多维信息
/// - 右下角下载量 + 收藏
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

  /// 获取来源颜色
  Color _sourceColor() {
    switch (resource.source.toLowerCase()) {
      case 'modrinth':
        return const Color(0xFF1BD96A);
      case 'curseforge':
        return const Color(0xFFF16436);
      default:
        return const Color(0xFF7B68EE);
    }
  }

  /// 获取来源显示名
  String _sourceLabel() {
    switch (resource.source.toLowerCase()) {
      case 'modrinth':
        return 'Modrinth';
      case 'curseforge':
        return 'CurseForge';
      default:
        return resource.source;
    }
  }

  /// 加载器显示名映射
  String _loaderLabel(String loader) {
    final entry = ResourceConstants.loaders.firstWhere(
      (e) => e.value.toLowerCase() == loader.toLowerCase(),
      orElse: () => MapEntry(loader, loader),
    );
    return entry.key;
  }

  @override
  Widget build(BuildContext context) {
    final typeColors = ResourceConstants.typeColorsOf(context);
    final typeColor = typeColors[resource.type] ?? BAColors.primaryOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);
    final sourceColor = _sourceColor();

    return HoverScaleCard(
      onTap: onTap,
      hoverBorderColor: typeColor,
      defaultBorderColor: BAColors.borderOf(context).withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BAColors.borderOf(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：大图标 + 来源徽章
            _buildIconWithBadge(context, typeColor, sourceColor),
            const SizedBox(width: 10),

            // 中间：信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    resource.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 描述
                  Text(
                    resource.description.isNotEmpty
                        ? resource.description
                        : resource.summary ?? '',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // 标签行：分类 + 加载器
                  _buildTagRow(context, typeColor),
                  const SizedBox(height: 5),
                  // 底部：游戏版本 + 下载量
                  _buildBottomRow(context),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // 右上角：收藏按钮
            _buildFavoriteButton(context),
          ],
        ),
      ),
    );
  }

  /// 构建带来源徽章的图标
  Widget _buildIconWithBadge(
    BuildContext context,
    Color typeColor,
    Color sourceColor,
  ) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 渐变背景
          Container(
            width: 60,
            height: 60,
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
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          ResourceConstants.typeIcons[resource.type] ??
                              Icons.apps,
                          size: 28,
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
                        size: 28,
                        color: typeColor,
                      ),
                    ),
            ),
          ),
          // 来源徽章（左上角）
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: sourceColor,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: sourceColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                _sourceLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签行
  Widget _buildTagRow(BuildContext context, Color typeColor) {
    final tags = <Widget>[];

    // 分类标签（最多 2 个）
    for (final cat in resource.categories.take(2)) {
      tags.add(
        _buildTag(
          context,
          cat,
          typeColor.withValues(alpha: 0.18),
          typeColor,
          isAccent: false,
        ),
      );
    }

    // 加载器标签
    for (final loader in resource.supportedLoaders.take(2)) {
      final label = _loaderLabel(loader);
      // 跳过与分类重复的加载器
      if (resource.categories.contains(loader.toLowerCase())) continue;
      tags.add(
        _buildTag(
          context,
          label,
          BAColors.primaryOf(context).withValues(alpha: 0.12),
          BAColors.primaryOf(context),
          isAccent: true,
        ),
      );
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 3, children: tags);
  }

  /// 单个 tag
  Widget _buildTag(
    BuildContext context,
    String label,
    Color bg,
    Color fg, {
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: isAccent
            ? Border.all(color: fg.withValues(alpha: 0.3), width: 0.5)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: isAccent ? FontWeight.w600 : FontWeight.w500,
          height: 1.1,
        ),
      ),
    );
  }

  /// 底部行：游戏版本 + 作者 + 下载量
  Widget _buildBottomRow(BuildContext context) {
    final textSecondary = BAColors.textSecondaryOf(context);

    return Row(
      children: [
        // 游戏版本徽章
        if (resource.supportedGameVersions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 9, color: textSecondary),
                const SizedBox(width: 3),
                Text(
                  resource.supportedGameVersions.first,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        // 作者
        if (resource.authors.isNotEmpty)
          Flexible(
            child: Text(
              resource.authors.first.name,
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.85),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        // 下载量
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              size: 11,
              color: textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 2),
            Text(
              formatDownloads(resource.downloads),
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 收藏按钮
  Widget _buildFavoriteButton(BuildContext context) {
    return GestureDetector(
      onTap: onToggleFavorite,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite
              ? BAColors.dangerOf(context)
              : BAColors.textSecondaryOf(context).withValues(alpha: 0.5),
          size: 16,
        ),
      ),
    );
  }
}
