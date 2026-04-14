import 'package:flutter/material.dart';
import '../../../core/auth/implementations/microsoft_authenticator.dart';
import '../../../core/auth/models/account.dart';
import '../../../core/auth/account_manager.dart';
import '../../../core/logger/i_logger.dart';
import '../../components/buttons/bamc_button.dart';
import '../../theme/colors.dart';

class MicrosoftDeviceLoginPage extends StatefulWidget {
  final AccountManager accountManager;
  final ILogger logger;

  const MicrosoftDeviceLoginPage({
    super.key,
    required this.accountManager,
    required this.logger,
  });

  @override
  State<MicrosoftDeviceLoginPage> createState() =>
      _MicrosoftDeviceLoginPageState();
}

class _MicrosoftDeviceLoginPageState extends State<MicrosoftDeviceLoginPage> {
  final MicrosoftAuthenticator _authenticator = MicrosoftAuthenticator();
  bool _isLoading = false;
  bool _isPolling = false;
  String? _userCode;
  String? _verificationUrl;
  String? _message;
  int _expiresIn = 0;
  int _countdown = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initDeviceCodeFlow();
  }

  Future<void> _initDeviceCodeFlow() async {
    setState(() {
      _isLoading = true;
      _status = '正在获取设备代码...';
    });

    try {
      // 获取设备代码
      final deviceCodeData = await _authenticator.getDeviceCode();

      setState(() {
        _userCode = deviceCodeData['user_code'];
        _verificationUrl = deviceCodeData['verification_uri'];
        _message = deviceCodeData['message'];
        _expiresIn = deviceCodeData['expires_in'];
        _countdown = _expiresIn;
        _status = '请在浏览器中完成登录';
        _isLoading = false;
      });

      // 开始轮询令牌
      _startPolling();
    } catch (e) {
      widget.logger.error('获取设备代码失败: $e');
      setState(() {
        _isLoading = false;
        _status = '获取设备代码失败';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取设备代码失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startPolling() async {
    setState(() {
      _isPolling = true;
    });

    // 启动倒计时
    _startCountdown();

    try {
      // 轮询令牌
      final account = await _authenticator.loginWithDeviceCode();

      if (mounted) {
        setState(() {
          _isPolling = false;
          _status = '登录成功';
        });
        Navigator.pop(context, account);
      }
    } catch (e) {
      widget.logger.error('设备代码登录失败: $e');
      if (mounted) {
        setState(() {
          _isPolling = false;
          _status = '登录失败';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: BamcColors.error,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0 && _isPolling) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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

          // 主要内容
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 状态信息
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 设备代码
                    if (_userCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: BamcColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BamcColors.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '设备代码',
                              style: TextStyle(
                                fontSize: 14,
                                color: BamcColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userCode!,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: BamcColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // 验证 URL
                    if (_verificationUrl != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: BamcColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BamcColors.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '请在浏览器中访问',
                              style: TextStyle(
                                fontSize: 14,
                                color: BamcColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              _verificationUrl!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: BamcColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '并输入上方设备代码',
                              style: TextStyle(
                                fontSize: 14,
                                color: BamcColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // 倒计时
                    if (_countdown > 0)
                      Text(
                        '剩余时间: ${_countdown ~/ 60}:${(_countdown % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: BamcColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 32),

                    // 提示信息
                    if (_message != null)
                      Text(
                        _message!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: BamcColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 底部操作
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BamcColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: BamcButton(
                    text: '取消',
                    onPressed: () => Navigator.pop(context),
                    type: BamcButtonType.outline,
                    size: BamcButtonSize.medium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BamcButton(
                    text: '重新获取代码',
                    onPressed:
                        !_isLoading && !_isPolling ? _initDeviceCodeFlow : null,
                    type: BamcButtonType.primary,
                    size: BamcButtonSize.medium,
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
