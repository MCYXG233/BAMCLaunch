import 'package:flutter/material.dart';

import '../../../../account/skin_manager.dart';
import '../../../theme/colors.dart';

class SkinTypeChip extends StatelessWidget {
  const SkinTypeChip({super.key, required this.skinType});

  final SkinType skinType;

  @override
  Widget build(BuildContext context) {
    final isAlex = skinType == SkinType.alex;
    final color = isAlex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAlex ? 'Alex 模型' : 'Steve 模型',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CachedChip extends StatelessWidget {
  const CachedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final color = BAColors.successOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '已缓存',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
