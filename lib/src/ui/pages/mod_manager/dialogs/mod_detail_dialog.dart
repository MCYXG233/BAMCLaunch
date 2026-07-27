import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../mod/mod_info.dart';

/// 信息行 - 模组详情中的标签-值对
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模组详情 Dialog
class ModDetailDialog extends StatelessWidget {
  final ModInfo mod;

  const ModDetailDialog({super.key, required this.mod});

  String _formatSize(int size) {
    if (size <= 0) return '未知';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BAColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          children: [
            _buildHeader(context),
            Divider(height: 1, color: BAColors.borderOf(context)),
            Expanded(child: _buildContent(context)),
            Divider(height: 1, color: BAColors.borderOf(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BAColors.primaryOf(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.extension,
              color: BAColors.primaryOf(context),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mod.name,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (mod.version != null)
                  Text(
                    '版本: ${mod.version}',
                    style: TextStyle(color: BAColors.textSecondaryOf(context)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mod.description != null && mod.description!.isNotEmpty) ...[
            Text(
              '描述',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mod.description!,
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            '模组信息',
            style: TextStyle(
              color: BAColors.primaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InfoRow(label: '模组ID', value: mod.modId ?? '未知'),
          InfoRow(label: '作者', value: mod.author ?? '未知'),
          InfoRow(label: '文件名', value: mod.fileName),
          InfoRow(label: '文件大小', value: _formatSize(mod.fileSize)),
          if (mod.modLoader != null)
            InfoRow(label: '加载器', value: mod.modLoader!),
          if (mod.lastModified != null)
            InfoRow(
              label: '更新日期',
              value: mod.lastModified!.toString().split(' ')[0],
            ),
          if (mod.dependencies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '依赖',
              style: TextStyle(
                color: BAColors.primaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mod.dependencies
                  .map(
                    (dep) => Chip(
                      label: Text(dep, style: const TextStyle(fontSize: 12)),
                      backgroundColor: BAColors.surfaceVariantOf(context),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ),
        ],
      ),
    );
  }
}
