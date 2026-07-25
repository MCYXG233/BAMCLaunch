import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/logger.dart';
import '../../../../core/utils.dart';
import '../../../theme/colors.dart';
import 'empty_state.dart';

/// 文件列表Tab(存档/模组/资源包/光影共用)
class FileListTab extends StatelessWidget {
  const FileListTab({
    super.key,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.isLoadingFiles,
    required this.detailFiles,
    required this.onOpenFile,
  });

  final String emptyMessage;
  final IconData emptyIcon;
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

    if (detailFiles.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subMessage: '将文件放入对应文件夹即可在此显示',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: detailFiles.length,
      itemBuilder: (context, index) {
        final entity = detailFiles[index];
        return _buildFileItem(context, entity);
      },
    );
  }

  /// 文件列表项
  Widget _buildFileItem(BuildContext context, FileSystemEntity entity) {
    final isDir = entity is Directory;
    final name = entity.path.split(Platform.pathSeparator).last;

    int size = 0;
    DateTime? modified;
    try {
      final stat = entity.statSync();
      size = stat.size;
      modified = stat.modified;
    } catch (e, st) {
      Logger.instance.error('获取文件信息失败', e, st);
    }

    IconData fileIcon;
    if (isDir) {
      fileIcon = Icons.folder_rounded;
    } else if (name.endsWith('.jar')) {
      fileIcon = Icons.extension_rounded;
    } else if (name.endsWith('.zip')) {
      fileIcon = Icons.archive_rounded;
    } else if (name.endsWith('.png') || name.endsWith('.jpg')) {
      fileIcon = Icons.image_rounded;
    } else {
      fileIcon = Icons.insert_drive_file_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BAColors.primaryOf(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              fileIcon,
              color: isDir
                  ? BAColors.warningOf(context)
                  : BAColors.primaryLightOf(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${isDir ? '文件夹' : formatBytes(size)}${modified != null ? ' · ${_formatDateTime(modified)}' : ''}',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(
                      context,
                    ).withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
