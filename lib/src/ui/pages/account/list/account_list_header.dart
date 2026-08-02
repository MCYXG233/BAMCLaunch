import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 账户列表页面顶部标题栏
///
/// 左侧展示"账户中心"渐变图标、标题、账户数量副信息，
/// 右侧展示紧凑的"添加账户"按钮。与游戏库/资源中心页保持统一格式。
class AccountListHeader extends StatelessWidget {
  /// 点击"添加账户"按钮的回调
  final VoidCallback onAddAccount;

  /// 副信息：账户总数（可选），用于标题下方
  final int? accountCount;

  const AccountListHeader({
    super.key,
    required this.onAddAccount,
    this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：图标 + 标题 + 副信息
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(
                        context,
                      ).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '账户中心',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (accountCount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$accountCount 个账户',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          // 右侧：添加账户按钮（紧凑玻璃拟态风格）
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddAccount,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(context).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFFFFFFFF),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '添加账户',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
