import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../animations/ba_animations.dart';

/// 蔚蓝档案风格浮动按钮 - 呼吸灯效�?class GameLibraryFloatingButton extends StatelessWidget {
  final VoidCallback onTap;

  const GameLibraryFloatingButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BAAnimations.breathe(
      isActive: true,
      duration: const Duration(milliseconds: 2500),
      minOpacity: 0.85,
      maxOpacity: 1.0,
      glowRadius: 12.0,
      glowColor: BAColors.primaryLightOf(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BAColors.primaryLightOf(context),
                  BAColors.primaryOf(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: BAColors.primaryLightOf(context)
                      .withValues(alpha: 0.2),
                  blurRadius: 48,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFFFFFFFF),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
