import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_manager.dart';
import '../../auth/microsoft_auth.dart';
import '../../auth/models.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../core/logger.dart';

/// 蔚蓝档案风格的Microsoft账户登录弹窗（设备代码流）
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
  bool _isLoadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountManager.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      Logger().error('加载账户失败', e);
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  /// 开始设备代码流登录
  Future<void> _startDeviceCodeLogin() async {
    setState(() {
      _loginState = LoginState.gettingDeviceCode;
      _errorMessage = null;
    });

    try {
      // 获取设备代码
      final deviceCode = await _microsoftAuth.getDeviceCode();
      
      if (!mounted) return;
      
      setState(() {
        _deviceCodeResponse = deviceCode;
        _remainingSeconds = deviceCode.expiresIn;
        _loginState = LoginState.waitingForUser;
      });

      // 打开浏览器
      await launchUrl(
        Uri.parse(deviceCode.verificationUri),
        mode: LaunchMode.externalApplication,
      );

      // 开始轮询
      _startPolling(deviceCode.deviceCode);
    } catch (e) {
      Logger().error('获取设备代码失败', e);
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = '获取设备代码失败: $e';
        });
      }
    }
  }

  /// 开始轮询获取令牌
  void _startPolling(String deviceCode) {
    _pollingTimer?.cancel();
    
    // 减少倒计时
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });

    // 轮询令牌
    _pollForToken(deviceCode);
  }

  /// 轮询获取令牌
  Future<void> _pollForToken(String deviceCode) async {
    setState(() {
      _loginState = LoginState.polling;
    });

    while (true) {
      try {
        // 使用设备代码获取令牌
        final token = await _microsoftAuth.pollForToken(deviceCode);
        
        if (!mounted) return;
        
        // 使用令牌完成Microsoft登录
        await _completeMicrosoftLogin(token);
        return;
      } catch (e) {
        Logger().error('轮询令牌失败', e);
        
        if (!mounted) return;
        
        final errorStr = e.toString();
        
        if (errorStr.contains('expired') || errorStr.contains('超时')) {
          setState(() {
            _loginState = LoginState.error;
            _errorMessage = '登录已过期，请重新尝试';
          });
          return;
        }
        
        if (errorStr.contains('denied')) {
          setState(() {
            _loginState = LoginState.error;
            _errorMessage = '登录被拒绝';
          });
          return;
        }
        
        // 继续等待
        await Future.delayed(const Duration(seconds: 5));
        
        if (!mounted) return;
        
        if (_remainingSeconds <= 0) {
          setState(() {
            _loginState = LoginState.error;
            _errorMessage = '登录超时，请重新尝试';
          });
          return;
        }
      }
    }
  }

  /// 完成Microsoft登录流程
  Future<void> _completeMicrosoftLogin(OAuthToken token) async {
    setState(() {
      _loginState = LoginState.authenticating;
    });

    try {
      final credentials = await _authManager.authenticate(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _errorMessage = progress;
            });
          }
        },
      );

      if (credentials.minecraftProfile == null) {
        throw Exception('无法获取Minecraft档案');
      }

      // 创建账户
      final profile = credentials.minecraftProfile!;
      final account = await _accountManager.addMicrosoftAccount(
        profile.name,
        profile.id,
      );

      // 选中账户
      await _accountManager.selectAccount(account.id);

      if (mounted) {
        _showSuccessSnackBar('登录成功！欢迎，${profile.name}');
        Navigator.pop(context, account);
      }
    } catch (e, stackTrace) {
      Logger().error('Microsoft登录失败', e, stackTrace);
      if (mounted) {
        setState(() {
          _loginState = LoginState.error;
          _errorMessage = '登录失败: $e';
        });
      }
    }
  }

  /// 选择已有账户
  Future<void> _selectAccount(Account account) async {
    try {
      await _accountManager.selectAccount(account.id);
      if (mounted) {
        _showSuccessSnackBar('已切换账户: ${account.username}');
        Navigator.pop(context, account);
      }
    } catch (e) {
      Logger().error('选择账户失败', e);
      if (mounted) {
        _showErrorSnackBar('选择账户失败: $e');
      }
    }
  }

  /// 删除账户
  Future<void> _deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15152E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          '确认删除',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要删除账户 "${account.username}" 吗？',
          style: const TextStyle(
            color: Color(0xFFA8A8C0),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFFA8A8C0)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _accountManager.removeAccount(account.id);
        await _loadAccounts();
      } catch (e) {
        Logger().error('删除账户失败', e);
        if (mounted) {
          _showErrorSnackBar('删除账户失败: $e');
        }
      }
    }
  }

  /// 取消登录
  void _cancelLogin() {
    _pollingTimer?.cancel();
    setState(() {
      _loginState = LoginState.initial;
      _deviceCodeResponse = null;
      _errorMessage = null;
    });
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF5BD38D),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B6B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: const Color(0xFF15152E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '登录Microsoft账户',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFA8A8C0),
                      ),
                    ),
                  ],
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
                const Divider(color: Color(0xFF2A2A4A)),
                const SizedBox(height: 20),
                const Text(
                  '或选择已有账户',
                  style: TextStyle(
                    color: Color(0xFFA8A8C0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ..._accounts.map((account) => _buildAccountItem(account)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 初始状态
  Widget _buildInitialContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5B8DEF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF5B8DEF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.window,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microsoft 登录',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '使用设备代码在浏览器中完成登录',
                      style: TextStyle(
                        color: Color(0xFFA8A8C0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loginState == LoginState.gettingDeviceCode
                ? null
                : _startDeviceCodeLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              disabledBackgroundColor: const Color(0xFF5B8DEF).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      ],
    );
  }

  /// 等待用户输入代码
  Widget _buildWaitingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 提示信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5BD38D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF5BD38D).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chrome_reader_mode,
                color: Color(0xFF5BD38D),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '请在浏览器中输入代码',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_deviceCodeResponse != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _deviceCodeResponse!.userCode,
                              style: const TextStyle(
                                color: Color(0xFFFFD93D),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 状态信息
        if (_loginState == LoginState.polling) ...[
          Center(
            child: Column(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFF5B8DEF),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? '等待登录确认...',
                  style: const TextStyle(
                    color: Color(0xFFA8A8C0),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(
            child: Text(
              '正在打开浏览器...',
              style: TextStyle(
                color: Color(0xFFA8A8C0),
                fontSize: 14,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // 倒计时
        Center(
          child: Text(
            '代码有效期: ${_formatTime(_remainingSeconds)}',
            style: const TextStyle(
              color: Color(0xFF5C5C70),
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 取消按钮
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _cancelLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Color(0xFF2A2A4A)),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(0xFFA8A8C0),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 认证中状态
  Widget _buildAuthenticatingContent() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: Color(0xFF5B8DEF),
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '正在完成登录...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? '获取Minecraft档案',
          style: const TextStyle(
            color: Color(0xFFA8A8C0),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 错误状态
  Widget _buildErrorContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _errorMessage ?? '登录失败',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _startDeviceCodeLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '重新尝试',
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

  /// 账户项
  Widget _buildAccountItem(Account account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAccount(account),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Microsoft账户',
                        style: const TextStyle(
                          color: Color(0xFFA8A8C0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                  onPressed: () => _deleteAccount(account),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 登录状态枚举
enum LoginState {
  initial,
  gettingDeviceCode,
  waitingForUser,
  polling,
  authenticating,
  error,
}
