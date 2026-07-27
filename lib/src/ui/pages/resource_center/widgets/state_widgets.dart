import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../animations/ba_effects.dart';

/// 加载占位 Widget - 显示加载动画与提示
class ResourceLoadingPlaceholder extends StatelessWidget {
  const ResourceLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BAEffects.shimmer(
        isActive: true,
        baseColor: BAColors.surfaceVariantOf(context),
        highlightColor: BAColors.surfaceOf(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: BAColors.primaryOf(context),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '正在加载资源...',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 错误 Widget - 显示错误信息与重试按钮
class ResourceErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ResourceErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: BAColors.dangerOf(context),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            '加载失败',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primaryOf(context),
              foregroundColor: BAColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态 Widget - 显示标题与副标题
class ResourceEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const ResourceEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: BAColors.textSecondaryOf(context).withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// 网格底部"加载更多"指示器
class GridLoadingMore extends StatelessWidget {
  const GridLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: BAColors.primaryOf(context),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
