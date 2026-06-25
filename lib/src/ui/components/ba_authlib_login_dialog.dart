import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/ba_buttons.dart';
import '../components/ba_dialog.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../components/ba_notification.dart';

/// 外置登录对话框
class BAAuthlibLoginDialog extends StatefulWidget {
  const BAAuthlibLoginDialog({super.key});

  static Future<Account?> show(BuildContext context) {
    return showDialog<Account>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => const BAAuthlibLoginDialog(),
    );
  }

  @override
  State<BAAuthlibLoginDialog> createState() => _BAAuthlibLoginDialogState();
}

class _BAAuthlibLoginDialogState extends State<BAAuthlibLoginDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '请输入用户名和密码';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    try {
      final accountManager = AccountManager();
      final account = await accountManager.addOfflineAccount(_usernameController.text);
      await accountManager.selectAccount(account.id);

      if (mounted) {
        NotificationManager().showSuccess('登录成功');
        Navigator.of(context).pop(account);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '登录失败：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '外置登录',
      width: 480,
      onClose: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildServerUrlField(),
            const SizedBox(height: 16),
            _buildUsernameField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '登录',
          onPressed: _isLoggingIn ? null : _login,
          loading: _isLoggingIn,
        ),
      ],
    );
  }

  Widget _buildServerUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '认证服务器',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _serverUrlController,
          decoration: InputDecoration(
            filled: true,
            fillColor: BAColors.surfaceOf(context),
            hintText: '留空使用默认服务器',
            hintStyle: TextStyle(
              color: BAColors.textDisabledOf(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '用户名',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: BAColors.surfaceOf(context),
            hintText: '请输入用户名',
            hintStyle: TextStyle(
              color: BAColors.textDisabledOf(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '密码',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: BAColors.surfaceOf(context),
            hintText: '请输入密码',
            hintStyle: TextStyle(
              color: BAColors.textDisabledOf(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.dangerOf(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.dangerOf(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: BAColors.dangerOf(context), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: BAColors.dangerOf(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}