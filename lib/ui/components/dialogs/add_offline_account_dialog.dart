import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import '../../theme/colors.dart';

class AddOfflineAccountDialog {
  static Future<Account?> show(
      BuildContext context, AccountManager accountManager) async {
    final TextEditingController usernameController = TextEditingController();
    bool isLoading = false;

    return showDialog<Account>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: BamcColors.background,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: BamcColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '添加离线账户',
                style: TextStyle(
                  color: BamcColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '用户名',
                style: TextStyle(
                  color: BamcColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              BamcInput(
                controller: usernameController,
                hintText: '请输入离线账户用户名',
                prefixIcon: Icons.person,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BamcColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BamcColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '提示',
                      style: TextStyle(
                        color: BamcColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '离线账户仅用于本地游戏，无法获取正版皮肤和多人服务器认证。',
                      style: TextStyle(
                        color: BamcColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(color: BamcColors.textSecondary),
              ),
            ),
            BamcButton(
              text: '添加',
              onPressed: isLoading
                  ? null
                  : () async {
                      String username = usernameController.text.trim();
                      if (username.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('用户名不能为空'),
                            backgroundColor: BamcColors.error,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        Account account = await accountManager.login(
                          {'username': username},
                          AccountType.offline,
                        );
                        Navigator.pop(context, account);
                      } catch (e) {
                        logger.error('添加离线账户失败: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('添加失败: $e'),
                            backgroundColor: BamcColors.error,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              type: BamcButtonType.primary,
              size: BamcButtonSize.medium,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
