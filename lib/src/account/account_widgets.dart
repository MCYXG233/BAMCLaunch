import 'package:flutter/material.dart';
import '../ui/components/index.dart';
import 'account.dart';

/// 账户卡片组件
class AccountCard extends StatelessWidget {
  /// 账户数据
  final Account account;

  /// 是否被选中
  final bool isSelected;

  /// 选中回调
  final VoidCallback? onTap;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 创建账户卡片
  const AccountCard({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
        color: theme.cardColor,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 头像
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    account.avatarUrl,
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: theme.dividerColor,
                        child: const Icon(Icons.person, size: 24),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 账户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.username,
                        style: theme.textTheme.titleMedium,
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
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getAccountTypeName(account.type),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
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
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '当前使用',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 删除按钮
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取账户类型名称
  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.offline:
        return '离线';
      case AccountType.microsoft:
        return 'Microsoft';
      case AccountType.authlib:
        return 'Authlib';
    }
  }
}

/// 添加账户对话框
class AddAccountDialog extends StatefulWidget {
  /// 创建添加账户对话框
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.dialogBackgroundColor,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('添加离线账户', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '请输入用户名',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context, _usernameController.text.trim());
                      }
                    },
                    child: const Text('添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示添加账户对话框
Future<String?> showAddAccountDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const AddAccountDialog(),
  );
}
