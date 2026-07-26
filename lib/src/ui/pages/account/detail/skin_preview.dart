import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../animations/ba_animations.dart';
import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/skin_manager.dart';
import '../widgets/skin_chip.dart';

/// 皮肤预览卡片
///
/// 显示皮肤大图，加载中显示进度指示器，加载完成后
/// 用弹性缩放动画包裹大头像，附加类型标签与"已缓存"标记。
class SkinPreview extends StatelessWidget {
  /// 是否正在加载皮肤
  final bool isLoading;

  /// 皮肤数据
  final SkinData? skin;

  const SkinPreview({super.key, required this.isLoading, this.skin});

  @override
  Widget build(BuildContext context) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '皮肤预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          // 皮肤图片
          Center(
            child: isLoading
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: BAColors.primaryOf(context),
                      ),
                    ),
                  )
                : BAAnimations.elasticScale(child: LargeSkinAvatar(skin: skin)),
          ),
          const SizedBox(height: 16),
          // 皮肤信息
          if (skin != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkinTypeChip(skinType: skin!.type),
                if (skin!.skinUrl != null) ...[
                  const SizedBox(width: 8),
                  const CachedChip(),
                ],
              ],
            ),
          ] else if (!isLoading) ...[
            Text(
              '暂无皮肤数据',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 大尺寸皮肤头像（180x180）
///
/// 加载失败或未提供皮肤数据时显示默认头像占位。
class LargeSkinAvatar extends StatelessWidget {
  /// 皮肤数据
  final SkinData? skin;

  const LargeSkinAvatar({super.key, this.skin});

  @override
  Widget build(BuildContext context) {
    final skinTypeColor = skin?.type == SkinType.alex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skinTypeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skinTypeColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: skin != null
            ? Image.memory(
                Uint8List.fromList(skin!.imageData),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DefaultAvatarLarge(),
              )
            : DefaultAvatarLarge(),
      ),
    );
  }
}

/// 大尺寸默认头像占位
class DefaultAvatarLarge extends StatelessWidget {
  const DefaultAvatarLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.person, size: 80, color: BAColors.primaryOf(context)),
      ),
    );
  }
}
