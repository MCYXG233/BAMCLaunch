import 'package:flutter/material.dart';
import '../../../components/ba_buttons.dart' show BAIconButton;
import '../../../theme/colors.dart';
import '../../../../account/account.dart';

/// 账户详情页顶部标题栏
///
/// 显示返回按钮、账户用户名、账户类型标签和右侧的"添加账户"按钮。
class AccountDetailHeader extends StatelessWidget {
  /// 当前查看的账户
  final Account account;

  /// 返回列表回调
  final VoidCallback onBack;

  /// 添加账户回调
  final VoidCallback onAddAccount;

  const AccountDetailHeader({
    super.key,
    required this.account,
    required this.onBack,
    required this.onAddAccount,
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 返回按钮
        BAIconButton(
          icon: Icons.arrow_back,
          tooltip: '返回账户列表',
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        // 账号名称 + 类型
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.username,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: BAColors.textPrimaryOf(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getAccountTypeLabel(account.type),
                style: TextStyle(
                  fontSize: 13,
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        // 添加账户按钮
        ElevatedButton.icon(
          onPressed: onAddAccount,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加账户'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BAColors.primaryOf(context),
            foregroundColor: BAColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
