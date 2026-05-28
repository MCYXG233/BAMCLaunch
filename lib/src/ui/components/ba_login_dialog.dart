import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_manager.dart';
import '../../auth/models.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../pages/authlib_login_page.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

class BALoginDialog extends StatefulWidget {
  const BALoginDialog({super.key});

  @override
  State<BALoginDialog> createState() => _BALoginDialogState();
}

class _BALoginDialogState extends State<BALoginDialog> {
  final AuthManager _authManager = AuthManager();
  final AccountManager _accountManager = AccountManager();

  LoginState _loginState = LoginState.initial;
  String? _errorMessage;

  List<Account> _accounts = [];
  final TextEditingController _offlineUsernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _offlineUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountManager.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
        });
      }
    } catch (e) {
      Logger.instance.error('加载账户失败', e);
    }
  }

  Future<void> _loginOffline() async {
    final username = _offlineUsernameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnackBar('请输入用户名');
      return;
    }

    try {
      final account = await _accountManager.addOfflineAccount(username);
      await _accountManager.selectAccount(account.id);

      if (mounted) {
        Navigator.pop(context, account);
      }
    } catch (e) {
      Logger.instance.error('创建离线账户失败', e);
      _showErrorSnackBar('创建账户失败: $e');
    }
  }

  void _openAuthlibLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthlibLoginPage()),
    );
  }

  Future<void> _selectAccount(Account account) async {
    await _accountManager.selectAccount(account.id);
    if (mounted) {
      Navigator.pop(context, account);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: BAColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: BATheme.shadowsLargeOf(context),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccountList(),
                    const SizedBox(height: 24),
                    _buildOfflineLogin(),
                    const SizedBox(height: 16),
                    _buildAuthlibLogin(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: BAColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择账户',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '登录或选择一个已有账户',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    if (_accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已有账户',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_accounts.length, (index) {
          final account = _accounts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccountTile(
              account: account,
              onTap: () => _selectAccount(account),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOfflineLogin() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BAColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: BAColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '离线登录',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '离线账户无需连接网络',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offlineUsernameController,
            style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: '输入用户名',
              hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
              filled: true,
              fillColor: BAColors.surfaceOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loginOffline,
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('离线登录', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthlibLogin() {
    return InkWell(
      onTap: _openAuthlibLogin,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BAColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.extension, color: BAColors.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '外置登录',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '使用Authlib Injector或第三方登录',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: BAColors.textSecondaryOf(context), size: 16),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const _AccountTile({
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BAColors.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: account.type == AccountType.microsoft
                    ? BAColors.primary.withOpacity(0.15)
                    : BAColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                account.type == AccountType.microsoft ? Icons.account_circle : Icons.person,
                color: account.type == AccountType.microsoft ? BAColors.primary : BAColors.secondary,
                size: 22,
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
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.type == AccountType.microsoft ? 'Microsoft账户' : '离线账户',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: BAColors.textSecondaryOf(context), size: 14),
          ],
        ),
      ),
    );
  }
}
