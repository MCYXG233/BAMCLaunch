import 'package:flutter/material.dart';

import '../../../../account/account.dart';
import '../../../animations/ba_animations.dart';
import '../../../theme/colors.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final Account account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? BAColors.primaryOf(context).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? BAColors.primaryOf(context).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
            child: Text(
              account.username.isNotEmpty
                  ? account.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            account.username,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          subtitle: Text(
            _accountTypeLabel(account.type),
            style: TextStyle(
              fontSize: 12,
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: BAColors.primaryOf(context),
                  size: 20,
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: BAColors.textSecondaryOf(context),
                size: 14,
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );

    if (isSelected) {
      tile = BAAnimations.glow(
        glowColor: BAColors.primaryOf(context),
        maxBlurRadius: 12,
        maxSpreadRadius: 2,
        child: tile,
      );
    }

    return tile;
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.microsoft:
        return 'Microsoft';
      case AccountType.offline:
        return '离线';
      case AccountType.authlib:
        return 'Authlib';
    }
  }
}
