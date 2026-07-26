import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 账户列表页面顶部标题栏
///
/// 左侧展示"账户中心"图标和标题，右侧展示"添加账户"按钮
class AccountListHeader extends StatelessWidget {
  /// 点击"添加账户"按钮的回调
  final VoidCallback onAddAccount;

  const AccountListHeader({super.key, required this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person, color: BAColors.primaryOf(context), size: 28),
        const SizedBox(width: 12),
        Text(
          '账户中心',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onAddAccount,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加账户'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BAColors.primaryOf(context),
            foregroundColor: BAColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
