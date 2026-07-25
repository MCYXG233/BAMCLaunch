import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import 'empty_state.dart';

/// 截图Tab
class ScreenshotTab extends StatelessWidget {
  const ScreenshotTab({
    super.key,
    required this.isLoadingFiles,
    required this.detailFiles,
    required this.onOpenFile,
  });

  final bool isLoadingFiles;
  final List<FileSystemEntity> detailFiles;
  final void Function(String path) onOpenFile;

  @override
  Widget build(BuildContext context) {
    if (isLoadingFiles) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            BAColors.primaryLightOf(context),
          ),
        ),
      );
    }

    final imageFiles = detailFiles.where((f) {
      final name = f.path.toLowerCase();
      return name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg');
    }).toList();

    if (imageFiles.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_camera_rounded,
        message: '还没有截图',
        subMessage: '在游戏中按下 F2 截图后将在此显示',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        final entity = imageFiles[index];
        if (entity is! File) return const SizedBox.shrink();
        final file = entity;
        final name = file.path.split(Platform.pathSeparator).last;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onOpenFile(file.path),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BAColors.borderOf(context).withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.shadowOf(context).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: BAColors.surfaceOf(context),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: BAColors.textSecondaryOf(context),
                        size: 32,
                      ),
                    ),
                  ),
                  // 底部渐变遮罩 + 文件名
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
