import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 通用空状�?- BakaXL 风格
///
/// 视觉要点：渐变圆 + 副色"虚线�?装饰 + 主副文案�?/// 整体尺寸较克制（图标 56px），避免大块渐变抢戏�?class GameLibraryEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const GameLibraryEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 双层圆：外圈虚线，内圈实心渐�?          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          BAColors.primaryOf(context).withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BAColors.primaryLightOf(context).withValues(alpha: 0.9),
                        BAColors.primaryOf(context).withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BAColors.primaryOf(context)
                            .withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child:
                      Icon(icon, size: 28, color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subMessage,
            style: TextStyle(
              color:
                  BAColors.textSecondaryOf(context).withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
