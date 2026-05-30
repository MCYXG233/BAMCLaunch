import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_manager.dart';
import '../../auth/microsoft_auth.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../pages/authlib_login_page.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

/// 登录状态枚举
enum LoginState {
  initial,
  gettingDeviceCode,
  waitingForUser,
  authenticating,
  success,
  error,
}

/// 蔚蓝档案风格账户登录对话框
class BALoginDialog extends StatefulWidget {
  const BALoginDialog({super.key});

  @override
  State<BALoginDialog> createState() => _BALoginDialogState();
}

class _BALoginDialogState extends State<BALoginDialog> {
  final AuthManager _authManager = AuthManager();
  final AccountManager _accountManager = AccountManager();
  final MicrosoftAuthService _microsoftAuth = MicrosoftAuthService();

  /// 当前登录状态
  LoginState _loginState = LoginState.initial;
  
  /// 错误信息
  String? _errorMessage;
  
  /// 设备代码响应
  DeviceCodeResponse? _deviceCodeResponse;
  
  /// 轮询定时器
  Timer? _pollingTimer;
  
  /// 剩余时间（秒）
  int _remainingSeconds = 0;

  /// 账户列表
  List<Account> _accounts = [];

  /// 离线登录控制器
  final TextEditingController _offlineUsernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _offlineUsernameController.dispose();
    super.dispose();
  }

  /// 加载账户列表
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

  /// 开始设备代码流登录
  Future<void> _startDeviceCodeLogin() async {
    setState(() {
      _loginState = LoginState.gettingDeviceCode;
      _errorMessage = null;
    });

    try {
      final deviceCode = await _microsoftAuth.getDeviceCode();
      setState(() {
        _loginState = LoginState.waitingForUser;
        _deviceCodeResponse = deviceCode;
        _remainingSeconds = deviceCode.expiresIn;
      });

      // 打开浏览器
      final uri = Uri.parse(deviceCode.verificationUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // 开始轮询
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 1),
        _pollForToken,
      );
    } catch (e) {
      Logger.instance.error('获取设备代码失败', e);
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 轮询获取令牌
  Future<void> _pollForToken(Timer timer) async {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      _remainingSeconds = _remainingSeconds - 1;
    });

    if (_remainingSeconds <= 0) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = '设备代码已过期';
        });
      }
      return;
    }

    try {
      final credentials = await _authManager.authenticateWithDeviceCode(
        _deviceCodeResponse!.deviceCode,
      );

      timer.cancel();

      if (!mounted) return;

      setState(() {
        _loginState = LoginState.authenticating;
      });

      // 保存账户
      final profile = credentials.minecraftProfile;
      if (profile == null) {
        if (mounted) {
          setState(() {
            _loginState = LoginState.error;
            _errorMessage = '无法获取Minecraft档案';
          });
        }
        return;
      }

      final account = await _accountManager.addMicrosoftAccount(
        profile.name,
        profile.id,
      );

      await _accountManager.selectAccount(account.id);

      setState(() {
        _loginState = LoginState.success;
      });

      // 延迟关闭并返回账户
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, account);
        }
      });
    } catch (e) {
      // 忽略未授权等待的错误
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('authorization_pending') || 
          errorStr.contains('slow_down')) {
        return;
      }

      timer.cancel();
      
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 重置登录状态
  void _resetLoginState() {
    _pollingTimer?.cancel();
    setState(() {
      _loginState = LoginState.initial;
      _errorMessage = null;
      _deviceCodeResponse = null;
      _remainingSeconds = 0;
    });
  }

  /// 离线登录
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

  /// 打开外置登录页面
  void _openAuthlibLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthlibLoginPage()),
    );
  }

  /// 选择已有账户
  Future<void> _selectAccount(Account account) async {
    await _accountManager.selectAccount(account.id);
    if (mounted) {
      Navigator.pop(context, account);
    }
  }

  /// 显示错误提示
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Container(
        width: 800,
        height: 480,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: BATheme.shadowsLargeOf(context),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  // 左侧：已登录账户列表
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: BAColors.borderOf(context)),
                        ),
                      ),
                      child: _buildAccountPanel(),
                    ),
                  ),
                  // 右侧：登录新账户
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: _buildLoginPanel(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已有账户',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _accounts.isEmpty
              ? Center(
                  child: Text(
                    '暂无账户',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AccountTile(
                        account: account,
                        onTap: () => _selectAccount(account),
                        onLogout: account.type == AccountType.microsoft
                            ? () => _logoutAccount(account)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoginPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '登录新账户',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_loginState == LoginState.initial) ...[
            _buildMicrosoftLogin(),
            const SizedBox(height: 16),
            _buildOfflineLogin(),
            const SizedBox(height: 16),
            _buildAuthlibLogin(),
          ] else if (_loginState == LoginState.gettingDeviceCode) ...[
            _buildLoadingState('正在获取设备代码...'),
          ] else if (_loginState == LoginState.waitingForUser) ...[
            _buildDeviceCodeWaitingState(),
          ] else if (_loginState == LoginState.authenticating) ...[
            _buildLoadingState('正在完成认证...'),
          ] else if (_loginState == LoginState.success) ...[
            _buildSuccessState(),
          ] else if (_loginState == LoginState.error) ...[
            _buildErrorState(),
          ],
        ],
      ),
    );
  }

  /// 登出账户
  Future<void> _logoutAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '登出账户',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要登出账户 "${account.username}" 吗？',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      '登出',
                      style: TextStyle(color: BAColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _authManager.clearCredentials();
      if (mounted) {
        await _loadAccounts();
      }
    } catch (e) {
      Logger.instance.error('登出失败', e);
    }
  }

  /// 构建头部
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
            child: const Icon(Icons.person, color: BAColors.textOnPrimary, size: 28),
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

  /// 构建已有账户列表
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

  /// 构建微软登录卡片
  Widget _buildMicrosoftLogin() {
    return InkWell(
      onTap: _startDeviceCodeLogin,
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
                gradient: BAColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.web, color: BAColors.textOnPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Microsoft登录',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '使用Microsoft账户登录正版Minecraft',
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

  /// 构建离线登录卡片
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
                foregroundColor: BAColors.textOnPrimary,
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

  /// 构建外置登录卡片
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

  /// 构建加载状态
  Widget _buildLoadingState(String message) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 构建设备代码等待状态
  Widget _buildDeviceCodeWaitingState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BAColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BAColors.primary),
          ),
          child: Column(
            children: [
              Text(
                '打开浏览器并输入',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _deviceCodeResponse?.verificationUri ?? '',
                style: const TextStyle(
                  color: BAColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '然后输入代码',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BAColors.borderOf(context)),
                ),
                child: Text(
                  _deviceCodeResponse?.userCode ?? '',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '剩余 $_remainingSeconds 秒',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _resetLoginState,
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }

  /// 构建成功状态
  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '登录成功！',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: BAColors.danger.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: BAColors.danger,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '登录失败',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? '未知错误',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetLoginState,
            child: const Text('重试'),
          ),
        ),
      ],
    );
  }
}

/// 账户列表项
class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback? onLogout;

  const _AccountTile({
    required this.account,
    required this.onTap,
    this.onLogout,
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
                    _getAccountTypeLabel(account.type),
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onLogout != null) ...[
              IconButton(
                onPressed: onLogout,
                icon: Icon(Icons.logout, color: BAColors.danger, size: 18),
                padding: const EdgeInsets.all(4),
              ),
            ],
            Icon(Icons.arrow_forward_ios, color: BAColors.textSecondaryOf(context), size: 14),
          ],
        ),
      ),
    );
  }

  /// 获取账户类型标签
  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.microsoft:
        return 'Microsoft账户';
      case AccountType.offline:
        return '离线账户';
      case AccountType.authlib:
        return '外置账户';
    }
  }
}