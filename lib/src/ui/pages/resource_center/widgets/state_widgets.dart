import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 加载占位 Widget - 居中显示加载动画与提示
class ResourceLoadingPlaceholder extends StatelessWidget {
  final String? hint;
  const ResourceLoadingPlaceholder({super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              color: BAColors.primaryOf(context),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hint ?? '正在加载资源...',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: BAColors.dangerOf(context).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BAColors.dangerOf(context).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BAColors.dangerOf(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: BAColors.dangerOf(context),
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '加载失败',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onRetry,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                            BAColors.primaryOf(context).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '重新加载',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态 Widget - 居中显示标题与副标题
class ResourceEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const ResourceEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              icon ?? Icons.search_off_rounded,
              color: BAColors.textSecondaryOf(context).withValues(alpha: 0.55),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
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
              fontSize: 11.5,
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
