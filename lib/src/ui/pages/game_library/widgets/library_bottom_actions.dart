import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// 底部操作区(导入实例)
class LibraryBottomActions extends StatelessWidget {
  const LibraryBottomActions({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 导入实例按钮
          InkWell(
            onTap: onImport,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_rounded,
                    color: BAColors.primaryLightOf(
                      context,
                    ).withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '导入实例',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(
                        context,
                      ).withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
