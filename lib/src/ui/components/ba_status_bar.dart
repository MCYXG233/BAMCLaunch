import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';

/// 底部状态栏组件
/// 显示游戏版本、Java状态、内存使用、联机状态
class BAStatusBar extends StatelessWidget {
  final String gameVersion;
  final String javaVersion;
  final bool javaAvailable;
  final int memoryUsedMB;
  final int memoryTotalMB;
  final bool isOnline;
  final String? onlineStatus;

  const BAStatusBar({
    super.key,
    this.gameVersion = '1.20.4',
    this.javaVersion = '17.0.8',
    this.javaAvailable = true,
    this.memoryUsedMB = 2048,
    this.memoryTotalMB = 4096,
    this.isOnline = false,
    this.onlineStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.8)
            : const Color(0xFF1A1A2E).withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: isLight
                ? Colors.grey.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 游戏版本
          _buildStatusItem(
            icon: Icons.gamepad,
            text: gameVersion,
            isLight: isLight,
          ),
          const SizedBox(width: 16),

          // Java状态
          _buildStatusItem(
            icon: javaAvailable ? Icons.check_circle : Icons.error,
            text: 'Java ${javaVersion.split('.').first}',
            color: javaAvailable ? BAThemeColors.success : BAThemeColors.danger,
            isLight: isLight,
          ),
          const SizedBox(width: 16),

          // 内存使用
          _buildMemoryIndicator(isLight),
          const SizedBox(width: 16),

          // 联机状态
          _buildOnlineStatus(isLight),

          const Spacer(),

          // 版本信息
          Text(
            'BAMCLauncher v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    Color? color,
    required bool isLight,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color ?? (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryIndicator(bool isLight) {
    final usagePercent = memoryTotalMB > 0 ? (memoryUsedMB / memoryTotalMB * 100).round() : 0;
    final isHighUsage = usagePercent > 80;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.memory,
          size: 14,
          color: isHighUsage ? BAThemeColors.warning : (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          '${memoryUsedMB ~/ 1024}GB/${memoryTotalMB ~/ 1024}GB',
          style: TextStyle(
            fontSize: 11,
            color: isHighUsage ? BAThemeColors.warning : (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
          ),
        ),
        const SizedBox(width: 4),
        // 内存使用进度条
        SizedBox(
          width: 40,
          height: 4,
          child: LinearProgressIndicator(
            value: memoryTotalMB > 0 ? memoryUsedMB / memoryTotalMB : 0,
            backgroundColor: isLight ? Colors.grey[300] : Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              isHighUsage ? BAThemeColors.warning : BAThemeColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineStatus(bool isLight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          size: 14,
          color: isOnline ? BAThemeColors.success : (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? (onlineStatus ?? '在线') : '离线',
          style: TextStyle(
            fontSize: 11,
            color: isOnline ? BAThemeColors.success : (isLight ? BAThemeColors.textSecondary : BAThemeColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
