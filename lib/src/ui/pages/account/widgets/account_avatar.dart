import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../account/skin_manager.dart';
import '../../../theme/colors.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, this.skin, this.size = 80});

  final SkinData? skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skinTypeColor = skin?.type == SkinType.alex
        ? BAColors.secondaryOf(context)
        : BAColors.primaryOf(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skinTypeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skinTypeColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: skin != null
            ? Image.memory(
                skin!.imageData.asUint8List(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _DefaultAvatar(),
              )
            : const _DefaultAvatar(),
      ),
    );
  }
}

class DefaultAvatarLarge extends StatelessWidget {
  const DefaultAvatarLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.person, size: 80, color: BAColors.primaryOf(context)),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.primaryOf(context).withValues(alpha: 0.1),
      child: Icon(Icons.person, size: 40, color: BAColors.primaryOf(context)),
    );
  }
}

extension SkinImageBytes on List<int> {
  Uint8List asUint8List() => Uint8List.fromList(this);
}
