import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../account/account_manager.dart';
import '../../account/account_widgets.dart';
import '../../account/account.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
import '../../auth/auth_manager.dart';
import '../../auth/microsoft_auth.dart';
import '../../account/skin_manager.dart';
import '../../features/skin/skin_preview_3d.dart';
import '../../features/skin/cape_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/ba_buttons.dart';
import '../components/ba_dialog.dart';

/// 账户管理页面
/// 用于管理Minecraft账户的添加、编辑、删除和选择
class BAMCAccountPage extends StatefulWidget {
  const BAMCAccountPage({super.key});

  @override
  State<BAMCAccountPage> createState() => _BAMCAccountPageState();
}

class _BAMCAccountPageState extends State<BAMCAccountPage> {
  final AccountManager _accountManager = AccountManager();
  final AuthManager _authManager = AuthManager();
  final EventBus _eventBus = EventBus();
  final Logger _logger = Logger('BAMCAccountPage');
  final SkinManager _skinManager = SkinManager.instance;

  /// 账户列表
  List<Account> _accounts = [];

  /// 当前选中的账户ID
  String? _selectedAccountId;

  /// 是否正在加载
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _setupEventListeners();
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    _eventBus.on<AccountAddedEvent>((event) {
      if (mounted) {
        _loadAccounts();
        _showSnackBar('账户添加成功!', success: true);
      }
    });

    _eventBus.on<AccountUpdatedEvent>((event) {
      if (mounted) {
        _loadAccounts();
        _showSnackBar('账户更新成功!', success: true);
      }
    });

    _eventBus.on<AccountDeletedEvent>((event) {
      if (mounted) {
        _loadAccounts();
        _showSnackBar('账户已删除', success: true);
      }
    });

    _eventBus.on<SelectedAccountChangedEvent>((event) {
      if (mounted) {
        setState(() {
          _selectedAccountId = event.newAccountId;
        });
      }
    });
  }

  /// 加载账户列表
  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _accountManager.getAccounts();
      final selectedAccount = await _accountManager.getSelectedAccount();

      setState(() {
        _accounts = accounts;
        _selectedAccountId = selectedAccount?.id;
      });
    } catch (e, stackTrace) {
      _logger.error('加载账户列表失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('加载账户列表失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 添加账户
  Future<void> _addAccount() async {
    final result = await _showAddAccountTypeDialog();

    if (result == null) return;

    if (result == 'microsoft') {
      // 跳转到登录页面进行Microsoft登录
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const _MicrosoftLoginWrapper(),
          ),
        );
      }
    } else if (result == 'offline') {
      final username = await _showOfflineAccountDialog();
      if (username != null && username.isNotEmpty) {
        try {
          await _accountManager.addOfflineAccount(username);
        } catch (e, stackTrace) {
          _logger.error('添加账户失败', e, stackTrace);
          if (mounted) {
            _showSnackBar('添加账户失败: $e');
          }
        }
      }
    } else if (result == 'authlib') {
      // 跳转到Authlib登录页面
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const _AuthlibLoginWrapper(),
          ),
        );
      }
    }
  }

  /// 显示添加账户类型选择对话框
  Future<String?> _showAddAccountTypeDialog() async {
    return BAFrostedDialog.show<String>(
      context: context,
      title: '添加账户',
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择账户类型',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildAccountTypeOption(
            icon: Icons.window,
            title: 'Microsoft账户',
            description: '使用Microsoft账号登录Minecraft',
            color: BAColors.primary,
            onTap: () => Navigator.pop(context, 'microsoft'),
          ),
          const SizedBox(height: 12),
          _buildAccountTypeOption(
            icon: Icons.person_outline,
            title: '离线账户',
            description: '不需要网络，仅用于单机游戏',
            color: BAColors.secondary,
            onTap: () => Navigator.pop(context, 'offline'),
          ),
          const SizedBox(height: 12),
          _buildAccountTypeOption(
            icon: Icons.link,
            title: 'Authlib账户',
            description: '使用第三方皮肤站登录',
            color: BAColors.success,
            onTap: () => Navigator.pop(context, 'authlib'),
          ),
        ],
      ),
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// 构建账户类型选项
  Widget _buildAccountTypeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BAColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BATypography.bodyLarge.copyWith(
                        color: BAColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: BAColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示离线账户对话框
  Future<String?> _showOfflineAccountDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '添加离线账户',
      width: 400,
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '添加',
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, usernameController.text.trim());
            }
          },
        ),
      ],
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入用户名',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Player',
                filled: true,
                fillColor: BAColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BATheme.borderRadiusSmall,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BATheme.borderRadiusSmall,
                  borderSide: BorderSide(color: BAColors.border),
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
                  color: BAColors.textSecondary,
                ),
              ),
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textPrimary,
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '用户名不能为空';
                }
                if (value.length < 3) {
                  return '用户名至少3个字符';
                }
                if (value.length > 16) {
                  return '用户名最多16个字符';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return '用户名只能包含字母、数字和下划线';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    return result;
  }

  /// 编辑账户
  Future<void> _editAccount(Account account) async {
    final TextEditingController usernameController = TextEditingController(
      text: account.username,
    );

    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '编辑账户',
      width: 400,
      actions: [
        BASecondaryButton(text: '取消', onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '保存',
          onPressed: () {
            if (usernameController.text.trim().isNotEmpty) {
              Navigator.pop(context, usernameController.text.trim());
            }
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '编辑用户名',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: '输入用户名',
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: BAColors.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: BAColors.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedAccount = account.copyWith(username: result);
        await _accountManager.updateAccount(updatedAccount);
      } catch (e, stackTrace) {
        _logger.error('更新账户失败', e, stackTrace);
        if (mounted) {
          _showSnackBar('更新账户失败: $e');
        }
      }
    }

    usernameController.dispose();
  }

  /// 删除账户
  Future<void> _deleteAccount(Account account) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除账户',
      content: '确定要删除账户 "${account.username}" 吗？此操作不可撤销。',
      confirmText: '删除',
      cancelText: '取消',
    );

    if (confirmed) {
      try {
        await _accountManager.removeAccount(account.id);
      } catch (e, stackTrace) {
        _logger.error('删除账户失败', e, stackTrace);
        if (mounted) {
          _showSnackBar('删除账户失败: $e');
        }
      }
    }
  }

  /// 设置默认账户
  Future<void> _setDefaultAccount(Account account) async {
    try {
      await _accountManager.selectAccount(account.id);
      if (mounted) {
        _showSnackBar('已将 "${account.username}" 设为默认账户', success: true);
      }
    } catch (e, stackTrace) {
      _logger.error('设置默认账户失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('设置默认账户失败: $e');
      }
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? BAColors.success : BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildAccountList()),
        ],
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surface,
        border: Border(bottom: BorderSide(color: BAColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 32, color: BAColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '账户管理',
                  style: BATypography.headlineMedium.copyWith(
                    color: BAColors.textPrimary,
                  ),
                ),
                Text(
                  '管理Minecraft游戏账户',
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          BAPrimaryButton(
            text: '添加账户',
            onPressed: _addAccount,
            leadingIcon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 构建账户列表
  Widget _buildAccountList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: BAColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              '暂无账户',
              style: BATypography.bodyLarge.copyWith(
                color: BAColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮添加一个新账户',
              style: BATypography.bodySmall.copyWith(
                color: BAColors.textDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final isSelected = _selectedAccountId == account.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccountItem(account, isSelected),
        );
      },
    );
  }

  /// 构建单个账户项
  Widget _buildAccountItem(Account account, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surface,
        borderRadius: BATheme.borderRadius,
        border: Border.all(
          color: isSelected ? BAColors.primary : BAColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: BATheme.shadowsSmall,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BATheme.borderRadius,
        child: InkWell(
          onTap: () => _setDefaultAccount(account),
          borderRadius: BATheme.borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(account),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.username,
                            style: BATypography.headlineSmall.copyWith(
                              color: BAColors.textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BAColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: BAColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '默认',
                                style: BATypography.label.copyWith(
                                  color: BAColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BAColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: BAColors.secondary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getAccountTypeName(account.type),
                              style: BATypography.label.copyWith(
                                color: BAColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '创建于 ${_formatDate(account.createdAt)}',
                            style: BATypography.bodySmall.copyWith(
                              color: BAColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildActions(account),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(Account account) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: BAColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.person, color: BAColors.primary, size: 32),
    );
  }

  /// 构建操作按钮
  Widget _buildActions(Account account) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BASecondaryButton(
          text: '皮肤',
          onPressed: () => _openSkinManager(account),
          leadingIcon: const Icon(Icons.image, size: 18),
          height: 36,
        ),
        const SizedBox(width: 8),
        BASecondaryButton(
          text: '编辑',
          onPressed: () => _editAccount(account),
          leadingIcon: const Icon(Icons.edit, size: 18),
          height: 36,
        ),
        const SizedBox(width: 8),
        BASecondaryButton(
          text: account.type == AccountType.microsoft ? '登出' : '退出登录',
          onPressed: () => _logoutAccount(account),
          leadingIcon: const Icon(Icons.logout, size: 18),
          height: 36,
        ),
        const SizedBox(width: 8),
        BADangerButton(
          text: '删除',
          onPressed: () => _deleteAccount(account),
          leadingIcon: const Icon(Icons.delete_outline, size: 18),
          height: 36,
        ),
      ],
    );
  }

  /// 退出登录账户
  Future<void> _logoutAccount(Account account) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: account.type == AccountType.microsoft ? '登出账户' : '退出登录',
      content: account.type == AccountType.microsoft
          ? '确定要登出账户 "${account.username}" 吗？'
          : '确定要退出登录账户 "${account.username}" 吗？',
      confirmText: '确定',
      cancelText: '取消',
    );

    if (!confirmed) return;

    try {
      // 如果是Microsoft账户，清除凭据
      if (account.type == AccountType.microsoft) {
        await _authManager.clearCredentials();
      }

      // 如果是当前选中的账户，取消选中
      if (_selectedAccountId == account.id) {
        await _accountManager.selectAccount('');
      }

      if (mounted) {
        _showSnackBar(account.type == AccountType.microsoft ? '已登出' : '已退出登录', success: true);
        await _loadAccounts();
      }
    } catch (e, stackTrace) {
      _logger.error('退出登录失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('退出登录失败: $e');
      }
    }
  }

  /// 打开皮肤管理对话框
  Future<void> _openSkinManager(Account account) async {
    await showDialog(
      context: context,
      builder: (context) => _SkinManagerDialog(account: account),
    );
    await _loadAccounts();
  }

  /// 获取账户类型名称
  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.offline:
        return '离线账户';
      case AccountType.microsoft:
        return 'Microsoft账户';
      case AccountType.authlib:
        return 'Authlib账户';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Microsoft登录包装组件
class _MicrosoftLoginWrapper extends StatefulWidget {
  const _MicrosoftLoginWrapper();

  @override
  State<_MicrosoftLoginWrapper> createState() => _MicrosoftLoginWrapperState();
}

class _MicrosoftLoginWrapperState extends State<_MicrosoftLoginWrapper> {
  final AuthManager _authManager = AuthManager();
  final AccountManager _accountManager = AccountManager();
  bool _isAuthenticating = false;
  String? _authProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: BAColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    Icons.window,
                    size: 64,
                    color: BAColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Microsoft登录',
                  style: BATypography.headlineMedium.copyWith(
                    color: BAColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '使用Microsoft账号登录Minecraft',
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                if (_isAuthenticating) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _authProgress ?? '登录中...',
                    style: BATypography.bodyMedium.copyWith(
                      color: BAColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  BAPrimaryButton(
                    text: '开始登录',
                    onPressed: _startMicrosoftLogin,
                    height: 56,
                    width: double.infinity,
                    leadingIcon: const Icon(Icons.login, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  BASecondaryButton(
                    text: '返回',
                    onPressed: () => Navigator.pop(context),
                    height: 56,
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startMicrosoftLogin() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authProgress = '正在获取设备代码...';
    });

    try {
      final deviceCodeResponse = await _authManager.getDeviceCode();
      
      if (mounted) {
        setState(() {
          _authProgress = '请在浏览器中完成登录';
        });
      }

      final loginResult = await _showDeviceCodeLoginDialog(deviceCodeResponse);
      if (!loginResult) {
        setState(() {
          _isAuthenticating = false;
          _authProgress = null;
        });
        return;
      }

      setState(() {
        _authProgress = '等待用户授权...';
      });

      final credentials = await _authManager.authenticateWithDeviceCode(
        deviceCodeResponse.deviceCode,
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

      final profile = credentials.minecraftProfile!;
      await _accountManager.addMicrosoftAccount(profile.name, profile.id);
      await _accountManager.selectAccount(profile.id);

      if (mounted) {
        _showSuccessSnackBar('登录成功！欢迎，${profile.name}');
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      Logger().error('Microsoft登录失败', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('登录失败: $e');
      }
      setState(() {
        _isAuthenticating = false;
        _authProgress = null;
      });
    }
  }

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
              color: BAColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: redirectController,
            decoration: InputDecoration(
              hintText: '粘贴重定向URL...',
              filled: true,
              fillColor: BAColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BATheme.borderRadiusSmall,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BATheme.borderRadiusSmall,
                borderSide: BorderSide(color: BAColors.border),
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
              color: BAColors.textPrimary,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showDeviceCodeLoginDialog(DeviceCodeResponse deviceCode) async {
    bool result = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: BAColors.surface,
        title: Text(
          'Microsoft登录',
          style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              '请按照以下步骤完成登录:',
              style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Text('1')),
              title: Text(
                '打开浏览器访问:',
                style: BATypography.bodyMedium.copyWith(color: BAColors.textPrimary),
              ),
              subtitle: SelectableText(
                deviceCode.verificationUri,
                style: BATypography.bodySmall.copyWith(color: BAColors.primary),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('2')),
              title: Text(
                '输入代码:',
                style: BATypography.bodyMedium.copyWith(color: BAColors.textPrimary),
              ),
              subtitle: SelectableText(
                deviceCode.userCode,
                style: BATypography.bodyLarge.copyWith(color: BAColors.success),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('3')),
              title: Text(
                '完成登录后点击继续',
                style: BATypography.bodyMedium.copyWith(color: BAColors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              '取消',
              style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              result = true;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primary,
            ),
            child: Text(
              '继续',
              style: BATypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result;
  }
}

/// Authlib登录包装组件
class _AuthlibLoginWrapper extends StatefulWidget {
  const _AuthlibLoginWrapper();

  @override
  State<_AuthlibLoginWrapper> createState() => _AuthlibLoginWrapperState();
}

class _AuthlibLoginWrapperState extends State<_AuthlibLoginWrapper> {
  final AccountManager _accountManager = AccountManager();
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: BAColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.link,
                      size: 64,
                      color: BAColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Authlib登录',
                    style: BATypography.headlineMedium.copyWith(
                      color: BAColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用第三方皮肤站登录',
                    style: BATypography.bodyMedium.copyWith(
                      color: BAColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildServerInput(),
                  const SizedBox(height: 16),
                  _buildEmailInput(),
                  const SizedBox(height: 16),
                  _buildPasswordInput(),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    BAPrimaryButton(
                      text: '登录',
                      onPressed: _login,
                      height: 56,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    BASecondaryButton(
                      text: '返回',
                      onPressed: () => Navigator.pop(context),
                      height: 56,
                      width: double.infinity,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerInput() {
    return TextFormField(
      controller: _serverController,
      decoration: InputDecoration(
        hintText: 'https://example.com',
        labelText: '皮肤站地址',
        filled: true,
        fillColor: BAColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(Icons.public, color: BAColors.textSecondary),
      ),
      style: BATypography.bodyMedium.copyWith(
        color: BAColors.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入皮肤站地址';
        }
        try {
          Uri.parse(value.trim());
        } catch (_) {
          return '请输入有效的URL';
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'you@example.com',
        labelText: '邮箱',
        filled: true,
        fillColor: BAColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(Icons.email_outlined, color: BAColors.textSecondary),
      ),
      style: BATypography.bodyMedium.copyWith(
        color: BAColors.textPrimary,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入邮箱';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return '请输入有效的邮箱地址';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordInput() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: '••••••••',
        labelText: '密码',
        filled: true,
        fillColor: BAColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BATheme.borderRadiusSmall,
          borderSide: BorderSide(color: BAColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: BAColors.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: BAColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      style: BATypography.bodyMedium.copyWith(
        color: BAColors.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入密码';
        }
        if (value.length < 6) {
          return '密码至少6个字符';
        }
        return null;
      },
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 实现Authlib登录逻辑
      // 这里是一个简化的示例，实际实现需要与Authlib服务器通信
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _showErrorSnackBar('Authlib登录功能尚未完全实现');
      }
    } catch (e, stackTrace) {
      Logger().error('Authlib登录失败', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('登录失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// 皮肤管理对话框
class _SkinManagerDialog extends StatefulWidget {
  final Account account;

  const _SkinManagerDialog({required this.account});

  @override
  State<_SkinManagerDialog> createState() => _SkinManagerDialogState();
}

class _SkinManagerDialogState extends State<_SkinManagerDialog> {
  final SkinManager _skinManager = SkinManager.instance;
  final CapeManager _capeManager = CapeManager();
  final AccountManager _accountManager = AccountManager();

  Uint8List? _currentSkinImage;
  Uint8List? _currentCapeImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkinData();
  }

  Future<void> _loadSkinData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final skinData = await _skinManager.getSkin(widget.account);
      if (skinData != null) {
        _currentSkinImage = Uint8List.fromList(skinData.imageData);
      }

      if (widget.account.capeUrl != null) {
        final capeData = await _capeManager.getCape(widget.account.id);
        _currentCapeImage = capeData?.imageData;
      }
    } catch (e) {
      // 忽略加载失败不影响其他功能
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectCustomSkin() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final skinData = await file.readAsBytes();
        await _skinManager.setCustomSkin(widget.account, skinData);
        await _loadSkinData();
        if (mounted) {
          NotificationManager().showSuccess('皮肤已更新');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('上传失败', message: e.toString());
      }
    }
  }

  Future<void> _resetToDefaultSkin() async {
    try {
      await _skinManager.removeCustomSkin(widget.account);
      await _loadSkinData();
      if (mounted) {
        NotificationManager().showSuccess('已恢复默认皮肤');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('恢复失败', message: e.toString());
      }
    }
  }

  Future<void> _setModelType(SkinType type) async {
    try {
      final updatedAccount = widget.account.copyWith(modelType: type);
      await _accountManager.updateAccount(updatedAccount);
      await _loadSkinData();
      if (mounted) {
        NotificationManager().showSuccess('模型已切换为 ${type == SkinType.alex ? "Alex" : "Steve"}');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('切换失败', message: e.toString());
      }
    }
  }

  Future<void> _showCapeUploadDialog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['png'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final capeData = await file.readAsBytes();
        await _capeManager.setCustomCape(widget.account.id, capeData);
        await _loadSkinData();
        if (mounted) {
          NotificationManager().showSuccess('披风已更新');
        }
      } catch (e) {
        if (mounted) {
          NotificationManager().showError('上传失败', message: e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceColor = isLight ? BAColors.lightSurface : BAColors.darkSurface;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLight ? BAColors.lightBorder : BAColors.darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Divider(height: 1, color: isLight ? BAColors.lightBorder : BAColors.darkBorder),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSkinPreview(),
                          const SizedBox(height: 16),
                          _buildModelSelector(),
                          const SizedBox(height: 16),
                          _buildSkinActions(),
                          const SizedBox(height: 16),
                          _buildCapeManagement(),
                        ],
                      ),
                    ),
            ),
            Divider(height: 1, color: isLight ? BAColors.lightBorder : BAColors.darkBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.image, color: BAColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '皮肤管理',
                  style: BATypography.headlineSmall.copyWith(
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  '${widget.account.username} 的皮肤设置',
                  style: BATypography.bodySmall.copyWith(
                    color: BAColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Text(
            '3D皮肤预览',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SkinPreview3D(
              skinImage: _currentSkinImage,
              capeImage: _currentCapeImage,
              skinType: widget.account.modelType,
              width: 200,
              height: 280,
              backgroundColor: BAColors.surfaceVariantOf(context).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: 14,
                color: BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                '拖拽旋转 | 滚轮缩放 | 双击重置',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '当前模型: ${widget.account.modelType == SkinType.alex ? "Alex (细臂)" : "Steve (标准)"}',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    final isAlex = widget.account.modelType == SkinType.alex;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: BAColors.primaryOf(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '角色模型',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '选择Steve或Alex模型',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildModelToggle(),
        ],
      ),
    );
  }

  Widget _buildModelToggle() {
    final isAlex = widget.account.modelType == SkinType.alex;

    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModelOption(
            label: 'Steve',
            isSelected: !isAlex,
            onTap: () => _setModelType(SkinType.steve),
          ),
          _buildModelOption(
            label: 'Alex',
            isSelected: isAlex,
            onTap: () => _setModelType(SkinType.alex),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primaryOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? BAColors.textOnPrimary
                : BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSkinActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BAColors.borderOf(context).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.image,
                color: BAColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '上传自定义皮肤',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '选择本地PNG皮肤文件',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _selectCustomSkin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('选择文件', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.account.skinUrl != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BAColors.dangerOf(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BAColors.dangerOf(context).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restore,
                  color: BAColors.dangerOf(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '恢复默认皮肤',
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '移除自定义皮肤，使用默认皮肤',
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetToDefaultSkin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BAColors.danger,
                    foregroundColor: BAColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('恢复', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCapeManagement() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers,
            color: BAColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '披风管理',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '上传自定义披风 (64x32 PNG)',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showCapeUploadDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.secondary,
              foregroundColor: BAColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('上传披风', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BASecondaryButton(
            text: '关闭',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
