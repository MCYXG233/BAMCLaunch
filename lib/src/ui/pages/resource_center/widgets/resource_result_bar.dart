import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 结果统计行 - 显示"共 X 个结果"和刷新按钮
///
/// 参考 BakaXL 笨蛋广场设计：
/// - 左侧：资源数量统计
/// - 右侧：刷新按钮
class ResourceResultBar extends StatelessWidget {
  /// 资源总数
  final int totalCount;

  /// 加载更多中
  final bool loadingMore;

  /// 是否正在搜索
  final bool loading;

  /// 刷新回调
  final VoidCallback? onRefresh;

  /// 标签（"资源" / "整合包"等）
  final String label;

  const ResourceResultBar({
    super.key,
    required this.totalCount,
    this.loadingMore = false,
    this.loading = false,
    this.onRefresh,
    this.label = '资源',
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 16, 8),
      child: Row(
        children: [
          // 左侧：统计
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '资源列表',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '共 $totalCount 个$label',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (loadingMore) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    color: BAColors.primaryOf(context),
                    strokeWidth: 1.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '加载中',
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // 右侧：刷新按钮
          if (onRefresh != null)
            _buildRefreshButton(context, textPrimary),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, Color textPrimary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: loading ? null : onRefresh,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BAColors.borderOf(context).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 13,
                color: loading
                    ? textPrimary.withValues(alpha: 0.4)
                    : textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                '刷新',
                style: TextStyle(
                  color: loading
                      ? textPrimary.withValues(alpha: 0.4)
                      : textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
