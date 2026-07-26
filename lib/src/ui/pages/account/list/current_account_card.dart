import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../animations/ba_animations.dart';
import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/account.dart';
import '../../../../account/skin_manager.dart';

/// 当前账户突出展示卡片
///
/// 使用 [BAAnimations.gradientBorder] 包裹 [BASurfaceCard]，实现动态渐变边框效果。
/// 顶部展示大头像、用户名、UUID 和账号类型徽章，右侧提供刷新与查看详情按钮。
class CurrentAccountCard extends StatelessWidget {
  /// 当前账户
  final Account account;

  /// 当前账户的皮肤数据
  final SkinData? skin;

  /// 是否正在刷新皮肤
  final bool isRefreshingSkin;

  /// 点击整个卡片的回调（用于进入详情页）
  final VoidCallback? onTap;

  /// 刷新皮肤按钮的回调
  final VoidCallback? onRefreshSkin;

  /// 打开详情按钮的回调
  final VoidCallback? onOpenDetail;

  const CurrentAccountCard({
    super.key,
    required this.account,
    required this.skin,
    required this.isRefreshingSkin,
    required this.onTap,
    required this.onRefreshSkin,
    required this.onOpenDetail,
  });

  /// 获取账号类型对应的中文标签
  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.microsoft:
        return 'Microsoft';
      case AccountType.offline:
        return '离线';
      case AccountType.authlib:
        return 'Authlib';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BAAnimations.gradientBorder(
      borderRadius: 16,
      borderWidth: 2,
      gradientColors: [
        BAColors.primaryOf(context),
        BAColors.secondaryOf(context),
        BAColors.primaryOf(context).withValues(alpha: 0.5),
        BAColors.secondaryOf(context).withValues(alpha: 0.5),
        BAColors.primaryOf(context),
      ],
      child: BASurfaceCard(
        borderRadius: 14,
        showBorder: false,
        padding: const EdgeInsets.all(20),
        shadowColor: BAColors.primaryOf(context).withValues(alpha: 0.15),
        onTap: onTap,
        child: Row(
          children: [
            BAAnimations.pulse(
              scaleBegin: 1.0,
              scaleEnd: 1.05,
              glowColor: BAColors.primaryOf(context),
              glowRadius: 10,
              child: _buildAvatar(context, skin, 80),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BAColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (account.uuid != null)
                    Text(
                      'UUID: ${account.uuid}',
                      style: TextStyle(
                        fontSize: 12,
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: BAColors.primaryOf(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getAccountTypeLabel(account.type),
                      style: TextStyle(
                        fontSize: 11,
                        color: BAColors.primaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                BAIconButton(
                  icon: Icons.refresh,
                  tooltip: '刷新皮肤',
                  onTap: isRefreshingSkin ? null : onRefreshSkin,
                ),
                const SizedBox(width: 8),
                BAIconButton(
                  icon: Icons.arrow_forward_ios,
                  tooltip: '查看详情',
                  iconSize: 16,
                  onTap: onOpenDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建皮肤头像
  Widget _buildAvatar(BuildContext context, SkinData? skin, double size) {
    final skinTypeColor = skin?.type == SkinType.alex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skinTypeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skinTypeColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: skin != null
            ? Image.memory(
                Uint8List.fromList(skin.imageData),
                fit: BoxFit.cover,
                errorBuilder: (_, a, b) => _buildDefaultAvatar(context),
              )
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Icon(Icons.person, size: 40, color: BAColors.primaryOf(context)),
    );
  }
}
