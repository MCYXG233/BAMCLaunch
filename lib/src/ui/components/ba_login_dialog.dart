import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_manager.dart';
import '../../auth/microsoft_auth.dart';
import '../../auth/models.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';
import '../pages/authlib_login_page.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

/// 蔚蓝档案风格的账户登录弹窗（支持多种登录方式）
class BALoginDialog extends StatefulWidget {
  const BALoginDialog({super.key});

  @override
  State<BALoginDialog> createState() => _BALoginDialogState();
}

class _BALoginDialogState extends State<BALoginDialog> {
  final AuthManager _authManager = AuthManager();
  final AccountManager _accountManager = AccountManager();
  final MicrosoftAuthService _microsoftAuth = MicrosoftAuthService();

  // 登录状态
  LoginState _loginState = LoginState.initial;
  String? _errorMessage;

  // 设备代码相关
  DeviceCodeResponse? _deviceCodeResponse;
  Timer? _pollingTimer;
  int _remainingSeconds = 0;

  // 账户列表
  List<Account> _accounts = [];

  // 离线登录
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

  /// 轮询获取token
  Future<void> _pollForToken(Timer timer) async {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      _remainingSeconds--;
    });

    if (_remainingSeconds <= 0) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = '登录超时，请重新尝试';
        });
      }
      return;
    }

    try {
      final result = await _microsoftAuth.pollForDeviceCode();

      if (result != null) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _loginState = LoginState.authenticating;
          });
        }

        // 保存账户
        final account = Account(
          id: result.profile.id,
          username: result.profile.name,
          email: null,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresAt: result.expiresAt,
          type: AccountType.microsoft,
        );

        await _accountManager.addAccount(account);
        await _accountManager.setSelectedAccountId(account.id);

        // 关闭对话框并返回成功
        if (mounted) {
          Navigator.pop(context, account);
        }
      }
    } catch (e) {
      // 授权待决是正常的，继续轮询
      if (e.toString().contains('authorization_pending')) {
        return;
      }

      // 其他错误
      Logger.instance.error('轮询token失败', e);
      timer.cancel();
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 离线登录
  Future<void> _loginOffline() async {
    final username = _offlineUsernameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnackBar('请输入用户名');
      return;
    }

    try {
      // 生成简单的UUID
      final id = List.generate(
          16, (i) => i == 12 ? '4' : i == 16 ? '8' : (0xf & Random().nextInt(16)).toRadixString(16))
          .join('');

      final account = Account(
        id: id,
        username: username,
        email: null,
        accessToken: null,
        refreshToken: null,
        expiresAt: null,
        type: AccountType.offline,
      );

      await _accountManager.addAccount(account);
      await _accountManager.setSelectedAccountId(account.id);

      if (mounted) {
        Navigator.pop(context, account);
      }
    } catch (e) {
      Logger.instance.error('创建离线账户失败', e);
      _showErrorSnackBar('创建账户失败: $e');
    }
  }

  /// 外置登录
  void _openAuthlibLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthlibLoginPage()),
    );
  }

  /// 选择已有账户
  Future<void> _selectAccount(Account account) async {
    if (account.isMicrosoft && account.isExpired) {
      // 刷新token
      try {
        final refreshed = await _microsoftAuth.refreshToken(account.refreshToken!);
        if (refreshed != null) {
          final updated = account.copyWith(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken,
            expiresAt: refreshed.expiresAt,
          );
          await _accountManager.updateAccount(updated);
          account = updated;
        } else {
          // 刷新失败，重新登录
          _showErrorSnackBar('Token已过期，请重新登录');
          return;
        }
      } catch (e) {
        _showErrorSnackBar('刷新Token失败: $e');
        return;
      }
    }

    await _accountManager.setSelectedAccountId(account.id);
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

  /// 重置状态
  void _reset() {
    _pollingTimer?.cancel();
    setState(() {
      _loginState = LoginState.initial;
      _deviceCodeResponse = null;
      _errorMessage = null;
    });
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          width: 520,
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: BATheme.shadowsLargeOf(context),
            border: Border.all(
              color: BAColors.borderOf(context),
            ),
          ),
          child: Stack(
            children: [
              // 装饰背景
              _buildBackgroundDecoration(),

              // 内容
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 标题栏
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 进度条/装饰条
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: BAColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 标题
                    Text(
                      '账户登录',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 根据状态显示不同内容
                    if (_loginState == LoginState.initial ||
                        _loginState == LoginState.gettingDeviceCode) ...[
                      _buildInitialContent(),
                    ] else if (_loginState == LoginState.waitingForUser ||
                        _loginState == LoginState.polling) ...[
                      _buildWaitingContent(),
                    ] else if (_loginState == LoginState.authenticating) ...[
                      _buildAuthenticatingContent(),
                    ] else if (_loginState == LoginState.error) ...[
                      _buildErrorContent(),
                    ],

                    // 已有账户列表
                    if (_accounts.isNotEmpty &&
                        _loginState == LoginState.initial) ...[
                      const SizedBox(height: 20),
                      Divider(color: BAColors.borderOf(context)),
                      const SizedBox(height: 20),
                      Text(
                        '或选择已有账户',
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._accounts.map((account) => _buildAccountItem(account)),
                    ],
                  ],
                ),
              ),

              // 关闭按钮
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BAColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: BAColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建背景装饰
  Widget _buildBackgroundDecoration() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundGradient = isLight
        ? LinearGradient(
            colors: [
              BAColors.primaryLight.withOpacity(0.06),
              BAColors.primary.withOpacity(0.02),
            ],
          )
        : LinearGradient(
            colors: [
              BAColors.primary.withOpacity(0.08),
              BAColors.primaryDark.withOpacity(0.03),
            ],
          );

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: backgroundGradient,
        ),
        child: Stack(
          children: [
            // 左上角几何装饰
            Positioned(
              top: -40,
              left: -60,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BAColors.primaryLight.withOpacity(0.3),
                        BAColors.primary.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
            // 右下角几何装饰
            Positioned(
              bottom: -50,
              right: -40,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BAColors.primaryLight.withOpacity(0.25),
                        BAColors.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
              ),
            ),
            // 左下角小图标装饰
            Positioned(
              bottom: 16,
              left: 16,
              child: Row(
                children: [
                  Icon(Icons.change_circle, size: 14, color: BAColors.textSecondaryOf(context).withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Icon(Icons.close, size: 14, color: BAColors.textSecondaryOf(context).withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Icon(Icons.add, size: 14, color: BAColors.textSecondaryOf(context).withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 14, color: BAColors.textSecondaryOf(context).withOpacity(0.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 初始状态 - 多种登录方式
  Widget _buildInitialContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Microsoft登录
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BAColors.borderOf(context),
            ),
            boxShadow: BATheme.shadowsSmallOf(context),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BAColors.primary, BAColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.window,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microsoft 登录',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '使用设备代码在浏览器中完成登录',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loginState == LoginState.gettingDeviceCode
                ? null
                : _startDeviceCodeLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primary,
              disabledBackgroundColor: BAColors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: BAColors.primary.withOpacity(0.3),
              elevation: 4,
            ),
            child: _loginState == LoginState.gettingDeviceCode
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '准备中...',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  )
                : const Text(
                    '使用 Microsoft 账户登录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: BAColors.borderOf(context)),
        const SizedBox(height: 20),

        // 离线登录
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BAColors.borderOf(context),
            ),
            boxShadow: BATheme.shadowsSmallOf(context),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BAColors.success, Color(0xFF7DE8A8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: BAColors.success.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '离线登录',
                          style: TextStyle(
                            color: BAColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '无需联网即可玩单人游戏',
                          style: TextStyle(
                            color: BAColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _offlineUsernameController,
                decoration: InputDecoration(
                  hintText: '输入用户名',
                  hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
                  filled: true,
                  fillColor: BAColors.surfaceVariantOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: BAColors.borderOf(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: BAColors.borderOf(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BAColors.success),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 14),
                onSubmitted: (_) => _loginOffline(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loginOffline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BAColors.primary.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: BAColors.primary.withOpacity(0.15),
                    elevation: 3,
                  ),
                  child: const Text(
                    '离线登录',
                    style: TextStyle(
                      color: BAColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: BAColors.borderOf(context)),
        const SizedBox(height: 20),

        // Authlib Injector登录
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BAColors.borderOf(context),
            ),
            boxShadow: BATheme.shadowsSmallOf(context),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BAColors.primary, BAColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.extension,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '外置登录',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持 Authlib Injector 协议的外置服务器',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _openAuthlibLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: BAColors.primary.withOpacity(0.3),
              elevation: 4,
            ),
            child: const Text(
              '使用外置账户登录',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 等待用户在浏览器中登录
  Widget _buildWaitingContent() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BAColors.primary, BAColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: BAColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '打开浏览器登录',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '访问 ${_deviceCodeResponse?.verificationUri}',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _deviceCodeResponse?.userCode ?? '',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '剩余时间: $_remainingSeconds秒',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                '取消',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                if (_deviceCodeResponse != null) {
                  final uri = Uri.parse(_deviceCodeResponse!.verificationUri);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '重新打开',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 正在认证
  Widget _buildAuthenticatingContent() {
    return Column(
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: BAColors.primary,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '正在认证...',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请稍候',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 错误状态
  Widget _buildErrorContent() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BAColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.error_outline,
            color: BAColors.danger,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '登录失败',
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? '未知错误',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                '关闭',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 账户项
  Widget _buildAccountItem(Account account) {
    final isMicrosoft = account.isMicrosoft;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAccount(account),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isMicrosoft
                        ? const LinearGradient(
                            colors: [BAColors.primary, BAColors.primaryLight],
                          )
                        : const LinearGradient(
                            colors: [BAColors.success, Color(0xFF7DE8A8)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMicrosoft ? Icons.window : Icons.person,
                    color: Colors.white,
                    size: 24,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMicrosoft ? 'Microsoft 账户' : '离线账户',
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: BAColors.textSecondaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
