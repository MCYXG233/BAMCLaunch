import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// CurseForge 源 Tab - 占位页面，等待接入 CurseForge API
///
/// 风格与空状态组件保持一致，但定制橙色主题突出 CurseForge 品牌色
class CurseForgeTab extends StatelessWidget {
  const CurseForgeTab({super.key});

  static const _cfOrange = Color(0xFFF16436);
  static const _cfOrangeDark = Color(0xFFD94412);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        decoration: BoxDecoration(
          color: _cfOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cfOrange.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cfOrange, _cfOrangeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _cfOrange.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CurseForge 源',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '即将接入，敬请期待',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(
                  context,
                ).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 14,
                    color: BAColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '需要配置 CurseForge API Key 后启用',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
