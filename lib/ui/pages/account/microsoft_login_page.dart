import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/auth/implementations/microsoft_authenticator.dart';
import '../../../core/auth/models/account.dart';
import '../../../core/auth/account_manager.dart';
import '../../../core/logger/i_logger.dart';
import '../../components/buttons/bamc_button.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final MicrosoftAuthenticator authenticator = MicrosoftAuthenticator();
    final Map<String, String> authData = authenticator.generateAuthorizationUrl();
    final String authUrl = authData['url']!;

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

      if (code == null) {
        throw Exception('未能获取授权码');
      }

      // 使用授权码登录
      Account account = await widget.accountManager.login(
        {'authorizationCode': code},
        AccountType.microsoft,
      );

      // 登录成功，返回账户信息
      if (mounted) {
        Navigator.pop(context, account);
      }
    } catch (e) {
      widget.logger.error('微软登录失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BamcColors.background,
      body: Column(
        children: [
          // 自定义标题栏
          Container(
            height: 56,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BamcColors.border)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                BamcButton(
                  text: '返回',
                  onPressed: () => Navigator.pop(context),
                  type: BamcButtonType.outline,
                  size: BamcButtonSize.small,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      '微软账户登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          // 加载指示器
          if (_isLoading)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: BamcColors.surface,
                color: BamcColors.primary,
              ),
            ),

          // WebView内容
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),

          // 底部提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BamcColors.border)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '登录提示',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '请在浏览器中完成微软账户登录，登录成功后将自动返回启动器。',
                  style: TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                    height: 1.4,
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
