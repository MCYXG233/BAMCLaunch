import 'package:flutter/material.dart';
import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/account.dart';
import '../widgets/account_action_button.dart';

/// 账户详情信息卡片
///
/// 展示用户名、UUID、账号类型、是否默认、创建时间、最近使用与登录状态等信息。
class AccountInfoCard extends StatelessWidget {
  /// 当前账户
  final Account account;

  /// 是否为当前默认账号
  final bool isCurrentAccount;

  const AccountInfoCard({
    super.key,
    required this.account,
    required this.isCurrentAccount,
  });

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

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账号信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          AccountInfoRow(label: '用户名', value: account.username),
          if (account.uuid != null) ...[
            const SizedBox(height: 12),
            AccountInfoRow(label: 'UUID', value: account.uuid!),
          ],
          const SizedBox(height: 12),
          AccountInfoRow(
            label: '账号类型',
            value: _getAccountTypeLabel(account.type),
          ),
          const SizedBox(height: 12),
          AccountInfoRow(
            label: '默认账号',
            value: isCurrentAccount ? '是' : '否',
            valueColor: isCurrentAccount ? BAColors.successOf(context) : null,
          ),
          const SizedBox(height: 12),
          AccountInfoRow(
            label: '创建时间',
            value: _formatDateTime(account.createdAt),
          ),
          const SizedBox(height: 12),
          AccountInfoRow(
            label: '最近使用',
            value: _formatDateTime(account.lastUsedAt),
          ),
          if (account.type != AccountType.offline) ...[
            const SizedBox(height: 12),
            AccountInfoRow(
              label: '登录状态',
              value:
                  account.accessToken != null && account.accessToken!.isNotEmpty
                  ? '已登录'
                  : '未登录',
              valueColor:
                  account.accessToken != null && account.accessToken!.isNotEmpty
                  ? BAColors.successOf(context)
                  : BAColors.warningOf(context),
            ),
          ],
        ],
      ),
    );
  }
}
