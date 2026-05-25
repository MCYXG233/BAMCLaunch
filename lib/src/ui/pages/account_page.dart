import 'package:flutter/material.dart';
import '../../account/account_manager.dart';
import '../../account/account_widgets.dart';
import '../../account/account.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
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
  final EventBus _eventBus = EventBus();
  final Logger _logger = Logger('BAMCAccountPage');

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
    final username = await showAddAccountDialog(context);

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
          text: '编辑',
          onPressed: () => _editAccount(account),
          leadingIcon: const Icon(Icons.edit, size: 18),
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
