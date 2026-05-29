import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_manager.dart';
import '../../account/account_manager.dart';
import '../../core/logger.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/ba_buttons.dart';
import '../components/ba_dialog.dart';
import '../components/custom_title_bar.dart';
import 'app_router.dart';

/// 登录页面 - 包含Microsoft登录和离线账户登录选项
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthManager _authManager = AuthManager();
  final AccountManager _accountManager = AccountManager();
  bool _isAuthenticating = false;
  String? _authProgress;
  final TextEditingController _offlineUsernameController = TextEditingController();
  bool _showOfflineLogin = false;
  StreamSubscription<String>? _redirectSubscription;

  @override
  void dispose() {
    _offlineUsernameController.dispose();
    _redirectSubscription?.cancel();
    super.dispose();
  }

  /// 启动Microsoft登录流程
  Future<void> _startMicrosoftLogin() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authProgress = '正在打开登录页面...';
    });

    try {
      // 生成授权URL
      final authData = _authManager.generateAuthorizationUrl();
      final authUrl = authData['url']!;
      final state = authData['state']!;
      final codeVerifier = authData['codeVerifier']!;

      Logger().info('Opening Microsoft login URL: $authUrl');

      // 在浏览器中打开授权URL
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );

        // 显示对话框等待用户输入重定向URL
        if (mounted) {
          final redirectUrl = await _showRedirectUrlDialog();
          if (redirectUrl == null) {
            setState(() {
              _isAuthenticating = false;
              _authProgress = null;
            });
            return;
          }

          // 验证状态
          if (!_authManager.verifyState(redirectUrl, state)) {
            if (mounted) {
              _showErrorSnackBar('授权失败：无效的状态参数');
            }
            setState(() {
              _isAuthenticating = false;
              _authProgress = null;
            });
            return;
          }

          // 提取授权代码
          final authorizationCode = _authManager.extractAuthorizationCode(redirectUrl);
          if (authorizationCode == null) {
            if (mounted) {
              _showErrorSnackBar('授权失败：无法提取授权代码');
            }
            setState(() {
              _isAuthenticating = false;
              _authProgress = null;
            });
            return;
          }

          // 完成认证流程
          await _completeAuthentication(authorizationCode, codeVerifier);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('无法打开浏览器');
        }
        setState(() {
          _isAuthenticating = false;
          _authProgress = null;
        });
      }
    } catch (e, stackTrace) {
      Logger().error('Microsoft login failed', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('登录失败: $e');
      }
      setState(() {
        _isAuthenticating = false;
        _authProgress = null;
      });
    }
  }

  /// 显示重定向URL输入对话框
  Future<String?> _showRedirectUrlDialog() async {
    final TextEditingController redirectController = TextEditingController();
    String? result;

    await BAFrostedDialog.show<String>(
      context: context,
      title: '完成授权',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '请在浏览器中完成登录后，将浏览器地址栏中的完整URL粘贴到下方：',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: redirectController,
            decoration: InputDecoration(
              hintText: '粘贴重定向URL...',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BATheme.borderRadiusSmall,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BATheme.borderRadiusSmall,
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BATheme.borderRadiusSmall,
                borderSide: BorderSide(color: BAColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        BAPrimaryButton(
          text: '确认',
          onPressed: () {
            result = redirectController.text;
            Navigator.pop(context);
          },
        ),
      ],
      showCloseButton: false,
      barrierDismissible: false,
    );

    return result?.trim().isEmpty == true ? null : result;
  }

  /// 完成认证流程
  Future<void> _completeAuthentication(
    String authorizationCode,
    String codeVerifier,
  ) async {
    setState(() {
      _authProgress = '正在验证授权...';
    });

    try {
      final credentials = await _authManager.authenticate(
        authorizationCode: authorizationCode,
        codeVerifier: codeVerifier,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _authProgress = progress;
            });
          }
        },
      );

      if (credentials.minecraftProfile == null) {
        throw Exception('无法获取Minecraft档案');
      }

      // 创建或更新账户
      final profile = credentials.minecraftProfile!;

      // 使用新的 addMicrosoftAccount 方法
      final account = await _accountManager.addMicrosoftAccount(
        profile.name,
        profile.id,
      );

      // 选中这个账户
      await _accountManager.selectAccount(account.id);

      if (mounted) {
        _showSuccessSnackBar('登录成功！欢迎，${profile.name}');
        AppRouter.navigateToHome(context);
      }
    } catch (e, stackTrace) {
      Logger().error('Authentication failed', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('认证失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authProgress = null;
        });
      }
    }
  }

  /// 创建离线账户
  Future<void> _createOfflineAccount() async {
    final username = _offlineUsernameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnackBar('请输入用户名');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authProgress = '正在创建账户...';
    });

    try {
      final account = await _accountManager.addOfflineAccount(username);
      await _accountManager.selectAccount(account.id);

      if (mounted) {
        _showSuccessSnackBar('账户创建成功！');
        AppRouter.navigateToHome(context);
      }
    } catch (e, stackTrace) {
      Logger().error('Failed to create offline account', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('创建账户失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authProgress = null;
        });
      }
    }
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
            title: '登录',
            showWindowControls: true,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      if (!_showOfflineLogin) ...[
                        _buildMicrosoftLoginButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildOfflineLoginToggle(),
                      ] else ...[
                        _buildOfflineLoginForm(),
                        const SizedBox(height: 24),
                        _buildBackToMicrosoftButton(),
                      ],
                      if (_authProgress != null) ...[
                        const SizedBox(height: 24),
                        _buildProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Logo
  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: BAColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(
            Icons.sports_esports,
            size: 64,
            color: BAColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'BAMC Launcher',
          style: BATypography.headlineMedium.copyWith(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '登录以开始游戏',
          style: BATypography.bodyMedium.copyWith(
            color: BAColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  /// 构建Microsoft登录按钮
  Widget _buildMicrosoftLoginButton() {
    return BAPrimaryButton(
      text: '使用 Microsoft 登录',
      onPressed: _isAuthenticating ? null : _startMicrosoftLogin,
      loading: _isAuthenticating && !_showOfflineLogin,
      height: 56,
      width: double.infinity,
      leadingIcon: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Icon(
            Icons.window,
            size: 18,
            color: BAColors.primary,
          ),
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: BAColors.borderOf(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或者',
            style: BATypography.caption.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: BAColors.borderOf(context),
          ),
        ),
      ],
    );
  }

  /// 构建离线登录切换按钮
  Widget _buildOfflineLoginToggle() {
    return BASecondaryButton(
      text: '使用离线账户',
      onPressed: _isAuthenticating
          ? null
          : () {
              setState(() {
                _showOfflineLogin = true;
              });
            },
      height: 56,
      width: double.infinity,
      leadingIcon: Icon(
        Icons.person_outline,
        color: BAColors.secondary,
      ),
    );
  }

  /// 构建离线登录表单
  Widget _buildOfflineLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '输入玩家名称',
          style: BATypography.bodyLarge.copyWith(
            color: BAColors.textPrimaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _offlineUsernameController,
          decoration: InputDecoration(
            hintText: 'Player',
            filled: true,
            fillColor: BAColors.surfaceVariantOf(context),
            border: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusSmall,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusSmall,
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusSmall,
              borderSide: BorderSide(color: BAColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          style: BATypography.bodyMedium.copyWith(
            color: BAColors.textPrimaryOf(context),
          ),
          onSubmitted: (_) => _createOfflineAccount(),
          enabled: !_isAuthenticating,
        ),
        const SizedBox(height: 24),
        BAPrimaryButton(
          text: '创建离线账户',
          onPressed: _isAuthenticating ? null : _createOfflineAccount,
          loading: _isAuthenticating && _showOfflineLogin,
          height: 56,
          width: double.infinity,
        ),
      ],
    );
  }

  /// 构建返回Microsoft登录按钮
  Widget _buildBackToMicrosoftButton() {
    return TextButton(
      onPressed: _isAuthenticating
          ? null
          : () {
              setState(() {
                _showOfflineLogin = false;
              });
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back,
            size: 16,
            color: BAColors.textSecondaryOf(context),
          ),
          const SizedBox(width: 8),
          Text(
            '返回 Microsoft 登录',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          _authProgress ?? '',
          style: BATypography.bodyMedium.copyWith(
            color: BAColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}
