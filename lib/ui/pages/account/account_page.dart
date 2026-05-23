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
    final currentContext = context;
    Account? account = await Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (context) => MicrosoftLoginPage(
          accountManager: widget.accountManager,
          logger: logger,
        ),
      ),
    );

    if (account != null && mounted) {
      await _loadAccounts();
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('微软账户登录成功: ${account.username}'),
          backgroundColor: BamcColors.success,
        ),
      );
    }
  }

  Future<void> _handleDeviceCodeLogin() async {
    final currentContext = context;
    Account? account = await Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (context) => MicrosoftDeviceLoginPage(
          accountManager: widget.accountManager,
          logger: logger,
        ),
      ),
    );

    if (account != null && mounted) {
      await _loadAccounts();
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('微软账户登录成功: ${account.username}'),
          backgroundColor: BamcColors.success,
        ),
      );
    }
  }

  Future<void> _handleAddOfflineAccount() async {
    final currentContext = context;
    Account? account =
        await AddOfflineAccountDialog.show(currentContext, widget.accountManager);

    if (account != null && mounted) {
      await _loadAccounts();
      ScaffoldMessenger.of(currentContext).showSnackBar(
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
    final currentContext = context;
    setState(() => _isLoading = true);
    try {
      final refreshedAccount =
          await widget.accountManager.refreshAccount(accountId);
      if (refreshedAccount != null && mounted) {
        await _loadAccounts();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('账户刷新成功')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('账户无法刷新')),
        );
      }
    } catch (e) {
      logger.error('刷新账户失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteAccount(String accountId) async {
    final currentContext = context;
    setState(() => _isLoading = true);
    try {
      await widget.accountManager.removeAccount(accountId);
      await _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('账户删除成功')),
        );
      }
    } catch (e) {
      logger.error('删除账户失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountStats(),
          const SizedBox(height: 24),
          _buildAddAccountSection(),
          const SizedBox(height: 24),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.surface,
                  BamcColors.surfaceDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BamcColors.border),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: BamcColors.statPrimaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_circle_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _accounts.length.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: BamcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '已添加账户',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.surface,
                  BamcColors.surfaceDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BamcColors.border),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: BamcColors.statSecondaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedAccount?.username ?? '未选择',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BamcColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Text(
                  '当前账户',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.primary.withOpacity(0.15),
            BamcColors.primaryDark.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BamcColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: BamcColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: BamcColors.statPrimaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BamcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '支持微软正版账户、离线账户登录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
            size: BamcButtonSize.large,
            isLoading: _isLoading,
            icon: Icons.account_circle_rounded,
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
            fontWeight: FontWeight.w700,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BamcColors.surface,
                          BamcColors.surfaceDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BamcColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                BamcColors.primary.withOpacity(0.2),
                                BamcColors.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.account_circle_rounded,
                            size: 48,
                            color: BamcColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无账户',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '点击上方按钮添加账户',
                          style: TextStyle(
                            fontSize: 14,
                            color: BamcColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BamcColors.surface,
                          BamcColors.surfaceDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BamcColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: BamcColors.shadowMedium,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.primary.withOpacity(0.1),
                  BamcColors.primary.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? BamcColors.primary.withOpacity(0.3)
              : BamcColors.borderLight,
          width: 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: BamcColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? BamcColors.statPrimaryGradient
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BamcColors.surfaceLight,
                        BamcColors.surface,
                      ],
                    ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? BamcColors.primary.withOpacity(0.4)
                    : BamcColors.borderLight,
                width: 1,
              ),
            ),
            child: account.profile?.skinUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      account.profile!.skinUrl ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 28,
                          color: BamcColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: BamcColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      account.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? BamcColors.primary
                            : BamcColors.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BamcColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BamcColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      account.type == AccountType.microsoft
                          ? Icons.cloud_rounded
                          : Icons.offline_bolt_rounded,
                      size: 14,
                      color: BamcColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      account.type == AccountType.microsoft
                          ? '微软账户'
                          : '离线账户',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: BamcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (!isCurrent)
                BamcButton(
                  text: '切换',
                  onPressed: () => _handleSelectAccount(account.id),
                  type: BamcButtonType.primary,
                  size: BamcButtonSize.small,
                  isLoading: _isLoading,
                ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: BamcColors.statPrimaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '当前账户',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: BamcColors.textSecondary,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('刷新令牌'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
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
