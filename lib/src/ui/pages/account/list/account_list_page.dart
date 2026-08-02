import 'package:flutter/material.dart';

import '../../../animations/ba_animations.dart';
import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/account.dart';
import '../../../../account/skin_manager.dart';
import 'account_list_header.dart';
import 'current_account_card.dart';

/// 账户列表页面
///
/// 自上而下排列：[AccountListHeader] → 可选的 [CurrentAccountCard] → 账户列表。
/// 账户列表使用 [BAAnimations.staggeredEntry] 实现错落入场动画。
/// 列表为空时显示空状态提示。
class AccountListPage extends StatelessWidget {
  /// 当前默认账户
  final Account? currentAccount;

  /// 当前默认账户的皮肤数据
  final SkinData? currentSkin;

  /// 是否正在刷新皮肤
  final bool isRefreshingSkin;

  /// 全部账户列表
  final List<Account> accounts;

  /// 点击"添加账户"按钮的回调
  final VoidCallback onAddAccount;

  /// 点击当前账户卡的回调（当前 UI 未使用，保留接口以便后续扩展）
  // ignore: unused_field
  final VoidCallback? onTapCurrent;

  /// 刷新当前账户皮肤的回调
  final VoidCallback? onRefreshSkin;

  /// 打开某个账户详情页的回调
  final void Function(Account account) onOpenAccount;

  const AccountListPage({
    super.key,
    required this.currentAccount,
    required this.currentSkin,
    required this.isRefreshingSkin,
    required this.accounts,
    required this.onAddAccount,
    required this.onTapCurrent,
    required this.onRefreshSkin,
    required this.onOpenAccount,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountListHeader(
            onAddAccount: onAddAccount,
            accountCount: accounts.length,
          ),
          const SizedBox(height: 20),
          if (currentAccount != null) ...[
            CurrentAccountCard(
              account: currentAccount!,
              skin: currentSkin,
              isRefreshingSkin: isRefreshingSkin,
              onTap: () => onOpenAccount(currentAccount!),
              onRefreshSkin: onRefreshSkin,
              onOpenDetail: () => onOpenAccount(currentAccount!),
            ),
            const SizedBox(height: 20),
          ],
          Expanded(child: _buildAccountList(context)),
        ],
      ),
    );
  }

  /// 构建账户列表（含空状态）
  Widget _buildAccountList(BuildContext context) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 48,
              color: BAColors.textSecondaryOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无账户，点击"添加账户"开始',
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
          ],
        ),
      );
    }

    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所有账户',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: BAAnimations.staggeredEntry(
                children: accounts.map((account) {
                  final isSelected = account.uuid == currentAccount?.uuid;
                  return _buildAccountTile(context, account, isSelected);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 渲染单个账户条目
  Widget _buildAccountTile(
    BuildContext context,
    Account account,
    bool isSelected,
  ) {
    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? BAColors.primaryOf(context).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? BAColors.primaryOf(context).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
            child: Text(
              account.username.isNotEmpty
                  ? account.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            account.username,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          subtitle: Text(
            _getAccountTypeLabel(account.type),
            style: TextStyle(
              fontSize: 12,
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: BAColors.primaryOf(context),
                  size: 20,
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: BAColors.textSecondaryOf(context),
                size: 14,
              ),
            ],
          ),
          onTap: () => onOpenAccount(account),
        ),
      ),
    );

    if (isSelected) {
      tile = BAAnimations.glow(
        glowColor: BAColors.primaryOf(context),
        maxBlurRadius: 12,
        maxSpreadRadius: 2,
        child: tile,
      );
    }

    return tile;
  }
}
