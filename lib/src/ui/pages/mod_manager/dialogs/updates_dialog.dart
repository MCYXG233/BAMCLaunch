import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../../mod/mod_update_checker.dart';

/// 模组更新 Dialog
class UpdatesDialog extends StatelessWidget {
  final List<ModUpdateInfo> updates;
  final void Function(ModUpdateInfo) onUpdate;
  final VoidCallback onUpdateAll;

  const UpdatesDialog({
    super.key,
    required this.updates,
    required this.onUpdate,
    required this.onUpdateAll,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BAColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 500),
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
          Icon(
            Icons.system_update,
            color: BAColors.primaryOf(context),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可用更新',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '发现 ${updates.length} 个可用更新',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
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
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: BAColors.primaryOf(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.modName,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${update.currentVersion} → ${update.latestVersion}',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => onUpdate(update),
                child: const Text('更新'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (updates.length > 1)
            ElevatedButton(
              onPressed: onUpdateAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primaryOf(context),
                foregroundColor: Colors.white,
              ),
              child: Text('一键更新全部 (${updates.length})'),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
