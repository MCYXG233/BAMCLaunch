import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../theme/colors.dart';
import '../../../components/ba_common_widgets.dart';
import '../main_page_providers.dart';

/// 顶部栏 - Logo + 账号 + 实例数 + 设置 + 窗口控制
class AppTopBar extends ConsumerWidget {
  final VoidCallback onAccountTap;
  final VoidCallback onSettingsTap;
  final bool isMaximized;
  final Future<void> Function() onToggleMaximize;

  const AppTopBar({
    super.key,
    required this.onAccountTap,
    required this.onSettingsTap,
    required this.isMaximized,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAccountName = ref.watch(selectedAccountNameProvider);
    final instanceCount = ref.watch(instancesProvider).length;
    return BAGlassContainer(
      borderRadius: 20,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 启动器 Logo
          _buildLogo(context),
          const SizedBox(width: 16),

          // 当前账号（可点击弹出登录对话框）
          _buildAccountChip(context, selectedAccountName, onAccountTap),

          const Spacer(),

          // 实例数量指示器
          _buildInstanceIndicator(context, instanceCount),
          const SizedBox(width: 12),

          // 设置按钮
          _buildSettingsButton(context, onSettingsTap),

          // 窗口控制按钮
          _buildWindowControls(),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.primaryOf(context).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports,
            color: BAColors.primaryOf(context),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'BAMCLaunch',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: BAColors.primaryOf(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v1.0',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(
    BuildContext context,
    String? accountName,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BAColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                color: BAColors.textPrimaryOf(context).withValues(alpha: 0.85),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                accountName ?? '加载中...',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context).withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: BAColors.textPrimaryOf(context).withValues(alpha: 0.5),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstanceIndicator(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            color: BAColors.textPrimaryOf(context).withValues(alpha: 0.85),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$count 个实例',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context).withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      tooltip: '设置',
      icon: Icon(
        Icons.settings,
        color: BAColors.textPrimaryOf(context).withValues(alpha: 0.7),
        size: 18,
      ),
    );
  }

  Widget _buildWindowControls() {
    return Row(
      children: [
        BAWindowButton(
          icon: Icons.minimize,
          onTap: () => windowManager.minimize(),
        ),
        const SizedBox(width: 6),
        BAWindowButton(
          icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
          onTap: onToggleMaximize,
        ),
        const SizedBox(width: 6),
        BAWindowButton(
          icon: Icons.close,
          isClose: true,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}
