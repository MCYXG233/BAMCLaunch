import 'package:flutter/material.dart';
import '../../account/account.dart';
import '../../account/account_manager.dart';
import '../../auth/auth_manager.dart';
import '../../core/logger.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/account_card.dart';
import '../components/ba_buttons.dart';
import '../components/ba_dialog.dart';
import '../components/custom_title_bar.dart';
import 'app_router.dart';

/// 账户选择页面 - 显示所有账户并允许选择、删除和登出
class AccountSelectorPage extends StatefulWidget {
  const AccountSelectorPage({super.key});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  final AccountManager _accountManager = AccountManager();
  final AuthManager _authManager = AuthManager();
  List<Account> _accounts = [];
  String? _selectedAccountId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  /// 加载账户列表
  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountManager.getAccounts();
      final selectedAccount = await _accountManager.getSelectedAccount();

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _selectedAccountId = selectedAccount?.id;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger().error('Failed to load accounts', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('加载账户失败: $e');
      }
    }
  }

  /// 选择账户
  Future<void> _selectAccount(Account account) async {
    try {
      await _accountManager.selectAccount(account.id);
      if (mounted) {
        setState(() {
          _selectedAccountId = account.id;
        });
        _showSuccessSnackBar('已选择 ${account.username}');
      }
    } catch (e, stackTrace) {
      Logger().error('Failed to select account', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('选择账户失败: $e');
      }
    }
  }

  /// 删除账户
  Future<void> _deleteAccount(Account account) async {
    final confirmed = await _showConfirmDialog(
      '删除账户',
      '确定要删除账户 "${account.username}" 吗？此操作不可撤销。',
    );

    if (!confirmed) return;

    try {
      await _accountManager.removeAccount(account.id);
      
      // 如果是Microsoft账户，也清除凭据
      if (account.type == AccountType.microsoft) {
        await _authManager.clearCredentials();
      }

      if (mounted) {
        _showSuccessSnackBar('账户已删除');
        await _loadAccounts();
      }
    } catch (e, stackTrace) {
      Logger().error('Failed to delete account', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('删除账户失败: $e');
      }
    }
  }

  /// 登出账户
  Future<void> _logoutAccount(Account account) async {
    final confirmed = await _showConfirmDialog(
      '登出账户',
      '确定要登出账户 "${account.username}" 吗？',
    );

    if (!confirmed) return;

    try {
      // 清除凭据
      await _authManager.clearCredentials();
      
      if (mounted) {
        _showSuccessSnackBar('已登出');
        // 跳转到登录页面
        AppRouter.navigateToLogin(context);
      }
    } catch (e, stackTrace) {
      Logger().error('Failed to logout', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('登出失败: $e');
      }
    }
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await BAConfirmDialog.show(
      context: context,
      title: title,
      content: content,
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: Column(
        children: [
          CustomTitleBar(
            title: '账户管理',
            showWindowControls: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                    ? _buildEmptyState()
                    : _buildAccountList(),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有账户',
            style: BATypography.headlineSmall.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加一个账户以开始游戏',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 32),
          BAPrimaryButton(
            text: '添加账户',
            onPressed: () => AppRouter.navigateToLogin(context),
            height: 48,
            leadingIcon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建账户列表
  Widget _buildAccountList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的账户',
                style: BATypography.headlineSmall.copyWith(
                  color: BAColors.textPrimaryOf(context),
                ),
              ),
              BASecondaryButton(
                text: '添加账户',
                onPressed: () => AppRouter.navigateToLogin(context),
                height: 40,
                leadingIcon: Icon(
                  Icons.add,
                  color: BAColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._accounts.map((account) {
            final isSelected = account.id == _selectedAccountId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AccountCard(
                account: account,
                isSelected: isSelected,
                onTap: () => _selectAccount(account),
                onDelete: () => _deleteAccount(account),
                onLogout: account.type == AccountType.microsoft
                    ? () => _logoutAccount(account)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
