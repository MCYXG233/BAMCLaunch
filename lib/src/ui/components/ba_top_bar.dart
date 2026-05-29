import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 蔚蓝档案风格顶部信息栏（MC启动器版）
/// 显示账户信息、实例状态、通知、设置等
class BATopBar extends StatelessWidget {
  final String? userName;
  final String? accountType;
  final int? instanceCount;
  final int? activeDownloads;
  final bool hasNotification;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const BATopBar({
    super.key,
    this.userName,
    this.accountType,
    this.instanceCount,
    this.activeDownloads,
    this.hasNotification = false,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(color: BAColors.borderOf(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo区域
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: BAColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/BAMCLaunch_Logo.png',
                fit: BoxFit.contain,
                width: 32,
                height: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'BAMC Launcher',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // 实例统计
          _buildStatChip(
            icon: Icons.folder_outlined,
            label: '实例',
            value: '${instanceCount ?? 0}',
            color: BAColors.primaryOf(context),
          ),
          const SizedBox(width: 12),

          // 下载统计
          if (activeDownloads != null && activeDownloads! > 0) ...[
            _buildStatChip(
              icon: Icons.download_outlined,
              label: '下载中',
              value: '$activeDownloads',
              color: BAColors.successOf(context),
            ),
            const SizedBox(width: 12),
          ],

          // 分隔线
          Container(
            width: 1,
            height: 32,
            color: BAColors.borderOf(context),
          ),
          const SizedBox(width: 16),

          // 账户信息
          _buildAccountInfo(context),

          const SizedBox(width: 16),

          // 通知按钮
          _buildIconButton(
            icon: hasNotification ? Icons.notifications : Icons.notifications_outlined,
            hasNotification: hasNotification,
            onTap: onNotificationTap,
            context: context,
          ),
          const SizedBox(width: 8),

          // 设置按钮
          _buildIconButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: BAColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.person_outline,
              color: BAColors.secondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName ?? '未登录',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (accountType != null)
                Text(
                  accountType!,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    bool hasNotification = false,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: BAColors.textSecondaryOf(context),
                  size: 20,
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: BAColors.dangerOf(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
