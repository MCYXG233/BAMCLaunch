import 'package:flutter/material.dart';
import '../../../components/ba_common_widgets.dart';
import '../../../theme/colors.dart';
import '../../../../account/account.dart';
import '../../../../account/skin_manager.dart';
import '../widgets/account_action_button.dart';
import 'account_detail_header.dart';
import 'account_info_card.dart';
import 'skin_preview.dart';
import 'switchable_account_tile.dart';

/// 账户详情子页面
///
/// 容器视图，组合顶部栏、皮肤预览、信息卡片、
/// 一系列操作按钮以及切换账号区。
class AccountDetailPage extends StatelessWidget {
  /// 当前选中查看详情的账户
  final Account selectedAccount;

  /// 当前默认账户（可能与 selectedAccount 不同）
  final Account? currentAccount;

  /// 全部账户列表
  final List<Account> allAccounts;

  /// 详情皮肤是否正在加载
  final bool isLoadingDetailSkin;

  /// 是否正在刷新皮肤
  final bool isRefreshingSkin;

  /// 详情皮肤数据
  final SkinData? detailSkin;

  /// 返回列表回调
  final VoidCallback onBack;

  /// 添加账户回调
  final VoidCallback onAddAccount;

  /// 刷新皮肤回调
  final VoidCallback onRefreshSkin;

  /// 设为默认账号回调
  final VoidCallback onSetDefault;

  /// 打开微软官方皮肤管理器回调
  final VoidCallback onOpenMicrosoftSkinManager;

  /// 删除账号回调
  final VoidCallback onDelete;

  /// 切换到指定账号回调
  final void Function(Account account) onSwitchAccount;

  const AccountDetailPage({
    super.key,
    required this.selectedAccount,
    required this.currentAccount,
    required this.allAccounts,
    required this.isLoadingDetailSkin,
    required this.isRefreshingSkin,
    required this.detailSkin,
    required this.onBack,
    required this.onAddAccount,
    required this.onRefreshSkin,
    required this.onSetDefault,
    required this.onOpenMicrosoftSkinManager,
    required this.onDelete,
    required this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentAccount = selectedAccount.id == (currentAccount?.id ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：返回按钮 + 账号名称
          AccountDetailHeader(
            account: selectedAccount,
            onBack: onBack,
            onAddAccount: onAddAccount,
          ),
          const SizedBox(height: 20),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 皮肤预览区域
                  SkinPreview(isLoading: isLoadingDetailSkin, skin: detailSkin),
                  const SizedBox(height: 20),
                  // 账号信息卡片
                  AccountInfoCard(
                    account: selectedAccount,
                    isCurrentAccount: isCurrentAccount,
                  ),
                  const SizedBox(height: 20),
                  // 操作按钮
                  _buildActionSection(context, isCurrentAccount),
                  const SizedBox(height: 20),
                  // 切换账号区域
                  _buildSwitchAccountsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, bool isCurrentAccount) {
    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '操作',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          if (!isCurrentAccount) ...[
            AccountActionButton(
              icon: Icons.check_circle_outline,
              label: '设为默认账号',
              description: '切换到此账号作为默认启动账号',
              color: BAColors.primaryOf(context),
              onTap: onSetDefault,
            ),
            const SizedBox(height: 10),
          ],
          AccountActionButton(
            icon: Icons.refresh,
            label: '刷新皮肤',
            description: '重新从服务器获取皮肤数据',
            color: BAColors.infoOf(context),
            onTap: isRefreshingSkin ? null : onRefreshSkin,
            isLoading: isRefreshingSkin,
          ),
          if (selectedAccount.type == AccountType.microsoft) ...[
            const SizedBox(height: 10),
            AccountActionButton(
              icon: Icons.palette,
              label: '更换皮肤',
              description: '前往 Minecraft 官网更换皮肤',
              color: BAColors.primaryLightOf(context),
              onTap: onOpenMicrosoftSkinManager,
            ),
          ],
          const SizedBox(height: 10),
          AccountActionButton(
            icon: Icons.delete_outline,
            label: '删除账号',
            description: '永久删除此账号及其相关数据',
            color: BAColors.dangerOf(context),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchAccountsSection(BuildContext context) {
    // 过滤掉当前查看的账号
    final otherAccounts = allAccounts
        .where((a) => a.id != selectedAccount.id)
        .toList();

    if (otherAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return BASurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '切换账号',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          ...otherAccounts.map((account) {
            final isCurrent = account.id == currentAccount?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SwitchableAccountTile(
                account: account,
                isCurrent: isCurrent,
                onTap: () => onSwitchAccount(account),
              ),
            );
          }),
        ],
      ),
    );
  }
}
