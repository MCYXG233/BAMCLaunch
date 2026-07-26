import 'package:flutter/material.dart';

import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/account.dart';

/// 详情页底部"切换账号"区域中的单个账户条目
///
/// 使用 [BASurfaceCard] 包裹一个圆形头像首字母 + 用户名 + 类型标签，
/// 当 [isCurrent] 为 true 时额外展示「默认」徽章。
class SwitchableAccountTile extends StatelessWidget {
  /// 账户数据
  final Account account;

  /// 是否是当前默认账户
  final bool isCurrent;

  /// 点击回调
  final VoidCallback? onTap;

  const SwitchableAccountTile({
    super.key,
    required this.account,
    required this.isCurrent,
    required this.onTap,
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
    return BASurfaceCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
            child: Text(
              account.username.isNotEmpty
                  ? account.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.username,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _getAccountTypeLabel(account.type),
                      style: TextStyle(
                        fontSize: 11,
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: BAColors.successOf(
                            context,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '默认',
                          style: TextStyle(
                            fontSize: 10,
                            color: BAColors.successOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: BAColors.textSecondaryOf(context),
            size: 14,
          ),
        ],
      ),
    );
  }
}
