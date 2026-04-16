import 'dart:io';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/auth/implementations/microsoft_authenticator.dart';
import '../../../core/auth/models/account.dart';
import '../../../core/auth/account_manager.dart';
import '../../../core/logger/i_logger.dart';
import '../../../core/platform/platform.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/progress/pixel_loading_animation.dart';
import '../../theme/colors.dart';

class MicrosoftLoginPage extends StatefulWidget {
  final AccountManager accountManager;
  final ILogger logger;

  const MicrosoftLoginPage({
    super.key,
    required this.accountManager,
    required this.logger,
  });

  @override
  State<MicrosoftLoginPage> createState() => _MicrosoftLoginPageState();
}

class _MicrosoftLoginPageState extends State<MicrosoftLoginPage> {
  late WebViewController _controller;
  bool _isLoading = false;
  bool _isLoginComplete = false;
  Map<String, String>? _authData;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  late MicrosoftAuthenticator _authenticator;

  void _initializeWebView() {
    _authenticator = MicrosoftAuthenticator();
    _authData = _authenticator.generateAuthorizationUrl();
    final String authUrl = _authData!['url']!;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BamcColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url
                .startsWith('https://login.live.com/oauth20_desktop.srf')) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            widget.logger.error('WebView加载错误: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('网页加载失败: ${error.description}'),
                  backgroundColor: BamcColors.error,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: '重试',
                    onPressed: () {
                      _controller.reload();
                    },
                    textColor: Colors.white,
                  ),
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  Future<void> _handleRedirect(String url) async {
    if (_isLoginComplete) return;
    _isLoginComplete = true;

    setState(() => _isLoading = true);

    try {
      // 从URL中提取授权码
      final Uri uri = Uri.parse(url);
      final String? code = uri.queryParameters['code'];
      final String? state = uri.queryParameters['state'];
      final String? error = uri.queryParameters['error'];
      final String? errorDescription = uri.queryParameters['error_description'];

      // 检查是否有错误参数
      if (error != null) {
        throw Exception('登录被取消或失败: ${errorDescription ?? error}');
      }

      if (code == null) {
        throw Exception('未能获取授权码，请重试');
      }

      // 使用授权码登录
      Account account = await _authenticator.login(
        {
          'authorizationCode': code,
          'state': state,
        },
      );

      // 将账户添加到账户管理器
      Account savedAccount = await widget.accountManager.addAccount(account);

      // 选择新添加的账户
      await widget.accountManager.selectAccount(savedAccount.id);

      // 登录成功，返回账户信息
      if (mounted) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录成功！欢迎回来，${savedAccount.username}'),
            backgroundColor: BamcColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        // 延迟一下再返回，让用户看到成功提示
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, savedAccount);
      }
    } catch (e) {
      widget.logger.error('微软登录失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        // 分析错误类型，提供更具体的错误信息
        String errorMessage = '登录失败';
        if (e.toString().contains('网络')) {
          errorMessage = '网络连接失败，请检查您的网络连接';
        } else if (e.toString().contains('授权')) {
          errorMessage = '授权失败，请检查您的账户信息';
        } else if (e.toString().contains('Minecraft')) {
          errorMessage = 'Minecraft账户验证失败，请确保您的微软账户已绑定Minecraft账号';
        } else if (e.toString().contains('取消')) {
          errorMessage = '登录已取消';
        } else {
          errorMessage = '登录失败: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: BamcColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '重试',
              onPressed: () {
                setState(() {
                  _isLoginComplete = false;
                  _initializeWebView();
                });
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isMobile;
    final isWeb = Platform.isWeb;

    // 根据平台调整布局参数
    final headerHeight = isMobile ? 56.0 : 64.0;
    final padding = isMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: BamcColors.background,
      body: Column(
        children: [
          // 风格化标题栏
          Container(
            height: headerHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BamcColors.primary, BamcColors.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadow,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: padding),
                BamcButton(
                  text: '返回',
                  onPressed: () => Navigator.pop(context),
                  type: BamcButtonType.outline,
                  size: isMobile ? BamcButtonSize.small : BamcButtonSize.medium,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      '微软账户登录',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 50.0 : 60.0),
              ],
            ),
          ),

          // 加载指示器
          if (_isLoading)
            SizedBox(
              height: 4,
              child: const LinearProgressIndicator(
                backgroundColor: BamcColors.surface,
                color: BamcColors.secondary,
              ),
            ),

          // WebView内容
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: BamcColors.border,
                  width: 1,
                ),
              ),
              child: WebViewWidget(
                  controller: _controller,
                  // 为不同平台提供适当的配置
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory(() => EagerGestureRecognizer()),
                  }),
            ),
          ),

          // 底部提示
          Container(
            padding: EdgeInsets.all(padding),
            decoration: const BoxDecoration(
              color: BamcColors.card,
              border: Border(top: BorderSide(color: BamcColors.border)),
              boxShadow: [
                BoxShadow(
                  color: BamcColors.shadow,
                  offset: Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Minecraft风格图标
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: BamcColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '登录提示',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isMobile
                      ? '请在浏览器中完成微软账户登录，登录成功后将自动返回启动器。'
                      : '请在上方窗口中完成微软账户登录，登录成功后将自动返回启动器。',
                  style: const TextStyle(
                    fontSize: 14,
                    color: BamcColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BamcColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BamcColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '提示：请确保您的微软账户已绑定Minecraft账号，否则无法完成登录。',
                    style: TextStyle(
                      fontSize: 13,
                      color: BamcColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
                // 平台特定提示
                if (isWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BamcColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: BamcColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Web版提示：如果登录后没有自动返回，请手动关闭此窗口并返回启动器。',
                        style: TextStyle(
                          fontSize: 12,
                          color: BamcColors.accentDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
