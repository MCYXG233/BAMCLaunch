import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';

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
        color: BAThemeColors.surface,
        border: Border(
          bottom: BorderSide(color: BAThemeColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo区域
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: BAThemeColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.extension,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'BAMC Launcher',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
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
            color: BAThemeColors.primary,
          ),
          const SizedBox(width: 12),

          // 下载统计
          if (activeDownloads != null && activeDownloads! > 0) ...[
            _buildStatChip(
              icon: Icons.download_outlined,
              label: '下载中',
              value: '$activeDownloads',
              color: BAThemeColors.success,
            ),
            const SizedBox(width: 12),
          ],

          // 分隔线
          Container(
            width: 1,
            height: 32,
            color: BAThemeColors.border,
          ),
          const SizedBox(width: 16),

          // 账户信息
          _buildAccountInfo(),

          const SizedBox(width: 16),

          // 通知按钮
          _buildIconButton(
            icon: hasNotification ? Icons.notifications : Icons.notifications_outlined,
            hasNotification: hasNotification,
            onTap: onNotificationTap,
          ),
          const SizedBox(width: 8),

          // 设置按钮
          _buildIconButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
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

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BAThemeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: BAThemeColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline,
              color: BAThemeColors.secondary,
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
                style: const TextStyle(
                  color: BAThemeColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (accountType != null)
                Text(
                  accountType!,
                  style: const TextStyle(
                    color: BAThemeColors.textSecondary,
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
            color: BAThemeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: BAThemeColors.textSecondary,
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
                    decoration: const BoxDecoration(
                      color: BAThemeColors.danger,
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
