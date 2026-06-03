import 'package:flutter/material.dart';
import '../../account/account.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_buttons.dart';

/// 账户卡片组件 - 显示账户信息的卡片
class AccountCard extends StatefulWidget {
  /// 账户数据
  final Account account;

  /// 是否为当前选中的账户
  final bool isSelected;

  /// 点击回调
  final VoidCallback? onTap;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 登出回调
  final VoidCallback? onLogout;

  const AccountCard({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.onLogout,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? BAColors.primary.withOpacity(0.1)
                : BAColors.surfaceOf(context),
            borderRadius: BATheme.borderRadius,
            border: Border.all(
              color: widget.isSelected
                  ? BAColors.primary
                  : (_isHovered
                      ? BAColors.borderOf(context)
                      : BAColors.borderOf(context)),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.account.username,
                                style: BATypography.bodyLarge.copyWith(
                                  color: BAColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: BAColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '使用中',
                                  style: BATypography.caption.copyWith(
                                    color: BAColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildAccountTypeBadge(),
                            const SizedBox(width: 8),
                            Text(
                              '最后使用: ${_formatLastUsed()}',
                              style: BATypography.caption.copyWith(
                                color: BAColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.onDelete != null || widget.onLogout != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onLogout != null)
                      BASecondaryButton(
                        text: widget.account.type == AccountType.microsoft ? '登出' : '退出登录',
                        onPressed: widget.onLogout,
                        height: 36,
                        trailingIcon: Icon(
                          Icons.logout,
                          size: 16,
                          color: BAColors.secondary,
                        ),
                      ),
                    if (widget.onLogout != null)
                      const SizedBox(width: 8),
                    if (widget.onDelete != null)
                      BADangerButton(
                        text: '删除',
                        onPressed: widget.onDelete,
                        height: 36,
                        trailingIcon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: widget.isSelected ? BAColors.primary : BAColors.borderOf(context),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.network(
          widget.account.avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 32,
              color: BAColors.textSecondaryOf(context),
            );
          },
        ),
      ),
    );
  }

  /// 构建账户类型标签
  Widget _buildAccountTypeBadge() {
    Color badgeColor;
    String label;
    IconData icon;

    switch (widget.account.type) {
      case AccountType.microsoft:
        badgeColor = BAColors.primary;
        label = 'Microsoft';
        icon = Icons.window;
        break;
      case AccountType.authlib:
        badgeColor = BAColors.secondary;
        label = 'Authlib';
        icon = Icons.public;
        break;
      case AccountType.offline:
      default:
        badgeColor = BAColors.textSecondary;
        label = '离线';
        icon = Icons.person_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: BATypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化最后使用时间
  String _formatLastUsed() {
    final now = DateTime.now();
    final difference = now.difference(widget.account.lastUsedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${widget.account.lastUsedAt.month}/${widget.account.lastUsedAt.day}';
    }
  }
}
