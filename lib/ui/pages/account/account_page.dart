import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/dialogs/add_offline_account_dialog.dart';
import 'microsoft_login_page.dart';
import 'microsoft_device_login_page.dart';

class AccountPage extends StatefulWidget {
  final AccountManager accountManager;

  const AccountPage({super.key, required this.accountManager});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = false;
  List<Account> _accounts = [];
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      await widget.accountManager.initialize();
      setState(() {
        _accounts = widget.accountManager.accounts;
        _selectedAccount = widget.accountManager.selectedAccount;
      });
    } catch (e) {
      logger.error('加载账户失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddAccount() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BamcColors.background,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BamcColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '选择账户类型',
              style: TextStyle(
                color: BamcColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            BamcButton(
              text: '微软账户',
              onPressed: () async {
                Navigator.pop(context);
                await _handleMicrosoftLogin();
              },
              type: BamcButtonType.primary,
              size: BamcButtonSize.large,
              icon: Icons.account_circle,
            ),
            const SizedBox(height: 12),
            BamcButton(
              text: '离线账户',
              onPressed: () async {
                Navigator.pop(context);
                await _handleAddOfflineAccount();
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.large,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMicrosoftLogin() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BamcColors.background,
        title: const Text(
          '选择登录方式',
          style: TextStyle(
            color: BamcColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            BamcButton(
              text: '网页登录',
              onPressed: () async {
                Navigator.pop(context);
                await _handleWebLogin();
              },
              type: BamcButtonType.primary,
              size: BamcButtonSize.large,
              icon: Icons.open_in_browser,
            ),
            const SizedBox(height: 12),
            BamcButton(
              text: '设备代码登录',
              onPressed: () async {
                Navigator.pop(context);
                await _handleDeviceCodeLogin();
              },
              type: BamcButtonType.outline,
              size: BamcButtonSize.large,
              icon: Icons.qr_code_scanner,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWebLogin() async {
    Account? account = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MicrosoftLoginPage(
          accountManager: widget.accountManager,
          logger: logger,
        ),
      ),
    );

    if (account != null) {
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('微软账户登录成功: ${account.username}'),
          backgroundColor: BamcColors.success,
        ),
      );
    }
  }

  Future<void> _handleDeviceCodeLogin() async {
    Account? account = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MicrosoftDeviceLoginPage(
          accountManager: widget.accountManager,
          logger: logger,
        ),
      ),
    );

    if (account != null) {
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('微软账户登录成功: ${account.username}'),
          backgroundColor: BamcColors.success,
        ),
      );
    }
  }

  Future<void> _handleAddOfflineAccount() async {
    Account? account =
        await AddOfflineAccountDialog.show(context, widget.accountManager);

    if (account != null) {
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('离线账户添加成功: ${account.username}'),
          backgroundColor: BamcColors.success,
        ),
      );
    }
  }

  Future<void> _handleSelectAccount(String accountId) async {
    setState(() => _isLoading = true);
    try {
      await widget.accountManager.selectAccount(accountId);
      await _loadAccounts();
    } catch (e) {
      logger.error('切换账户失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefreshAccount(String accountId) async {
    setState(() => _isLoading = true);
    try {
      final refreshedAccount =
          await widget.accountManager.refreshAccount(accountId);
      if (refreshedAccount != null) {
        await _loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账户刷新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账户无法刷新')),
        );
      }
    } catch (e) {
      logger.error('刷新账户失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAccount(String accountId) async {
    setState(() => _isLoading = true);
    try {
      await widget.accountManager.removeAccount(accountId);
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账户删除成功')),
      );
    } catch (e) {
      logger.error('删除账户失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账户统计
          _buildAccountStats(),
          const SizedBox(height: 20),

          // 添加账户按钮
          _buildAddAccountSection(),
          const SizedBox(height: 20),

          // 账户列表
          _buildAccountList(),
        ],
      ),
    );
  }

  Widget _buildAccountStats() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BamcColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BamcColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _accounts.length.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: BamcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '已添加账户',
                  style: TextStyle(
                    fontSize: 14,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BamcColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BamcColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _selectedAccount?.username ?? '未选择',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: BamcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '当前账户',
                  style: TextStyle(
                    fontSize: 14,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.1),
            BamcColors.primaryDark.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: BamcColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加新账户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BamcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '支持微软正版、离线账户和第三方登录',
                  style: TextStyle(
                    fontSize: 14,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          BamcButton(
            text: '添加账户',
            onPressed: _handleAddAccount,
            type: BamcButtonType.primary,
            size: BamcButtonSize.medium,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '账户列表',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: BamcColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BamcColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.account_circle,
                            size: 64, color: BamcColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          '暂无账户',
                          style: TextStyle(color: BamcColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: BamcColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BamcColors.border),
                    ),
                    child: Column(
                      children: _accounts
                          .map((account) => _buildAccountItem(account))
                          .toList(),
                    ),
                  ),
      ],
    );
  }

  Widget _buildAccountItem(Account account) {
    final isCurrent = _selectedAccount?.id == account.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BamcColors.border)),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BamcColors.background,
              borderRadius: BorderRadius.circular(28),
            ),
            child: account.profile?.skinUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      account.profile!.skinUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: BamcColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: BamcColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // 账户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.type == AccountType.microsoft ? '微软账户' : '离线账户',
                  style: const TextStyle(
                    fontSize: 14,
                    color: BamcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            children: [
              if (!isCurrent)
                BamcButton(
                  text: '切换',
                  onPressed: () => _handleSelectAccount(account.id),
                  type: BamcButtonType.outline,
                  size: BamcButtonSize.small,
                  isLoading: _isLoading,
                ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BamcColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '当前',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: BamcColors.textSecondary),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Text('刷新令牌'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      _handleRefreshAccount(account.id);
                      break;
                    case 'delete':
                      _handleDeleteAccount(account.id);
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
