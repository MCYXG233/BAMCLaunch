import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../animations/ba_animations.dart';

/// CurseForge 源 Tab - 占位页面，等待接入 CurseForge API
class CurseForgeTab extends StatelessWidget {
  const CurseForgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BAAnimations.breathe(
            isActive: true,
            duration: const Duration(milliseconds: 3000),
            minOpacity: 0.7,
            maxOpacity: 1.0,
            glowRadius: 14,
            glowColor: const Color(0xFFF16436),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF16436), Color(0xFFD94412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF16436).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CurseForge 源',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '即将接入，敬请期待',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BAColors.borderOf(context).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: BAColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 8),
                Text(
                  '需要配置 CurseForge API Key 后启用',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
