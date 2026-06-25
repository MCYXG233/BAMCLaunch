import 'package:flutter/material.dart';
import '../../game/backup_manager.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../theme/colors.dart';
import 'ba_dialog.dart';
import 'ba_buttons.dart';
import 'ba_notification.dart';

/// 备份管理对话框
class BABackupDialog extends StatefulWidget {
  final GameInstance instance;

  const BABackupDialog({
    super.key,
    required this.instance,
  });

  static Future<void> show({
    required BuildContext context,
    required GameInstance instance,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BABackupDialog(instance: instance),
    );
  }

  @override
  State<BABackupDialog> createState() => _BABackupDialogState();
}

class _BABackupDialogState extends State<BABackupDialog> {
  final BackupManager _backupManager = BackupManager.instance;
  List<BackupRecord> _backups = [];
  bool _isLoading = true;
  bool _isBackingUp = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initBackupManager();
  }

  Future<void> _initBackupManager() async {
    await _backupManager.initialize();
    _loadBackups();
  }

  void _loadBackups() {
    setState(() {
      _backups = _backupManager.getBackupsForInstance(widget.instance.id);
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getBackupTypeLabel(BackupType type) {
    switch (type) {
      case BackupType.full:
        return '完整备份';
      case BackupType.savesOnly:
        return '仅存档';
      case BackupType.configOnly:
        return '仅配置';
    }
  }

  Future<void> _createBackup(BackupType type) async {
    if (_isBackingUp) return;

    setState(() => _isBackingUp = true);

    try {
      final manager = InstanceManager();
      final directory = manager.directories.firstWhere(
        (d) => d.id == widget.instance.directoryId,
      );

      final backup = await _backupManager.createBackup(
        instanceId: widget.instance.id,
        instanceName: widget.instance.name,
        instancePath: directory.path,
        type: type,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text,
        gameVersion: widget.instance.version,
      );

      if (mounted) {
        if (backup != null) {
          NotificationManager().showSuccess('备份成功');
          _descriptionController.clear();
          _loadBackups();
        } else {
          NotificationManager().showError('备份失败');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('备份失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreBackup(BackupRecord backup) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '恢复备份',
      content: '确定要恢复这个备份吗？当前游戏实例的内容将被替换。',
      confirmText: '恢复',
    );

    if (!confirmed) return;

    try {
      final manager = InstanceManager();
      final directory = manager.directories.firstWhere(
        (d) => d.id == widget.instance.directoryId,
      );

      final success = await _backupManager.restoreBackup(
        backup: backup,
        targetPath: directory.path,
      );

      if (mounted) {
        if (success) {
          NotificationManager().showSuccess('恢复成功');
        } else {
          NotificationManager().showError('恢复失败');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('恢复失败: $e');
      }
    }
  }

  Future<void> _deleteBackup(BackupRecord backup) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除备份',
      content: '确定要删除这个备份吗？此操作不可撤销。',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
    );

    if (!confirmed) return;

    try {
      await _backupManager.deleteBackup(backup.id);
      if (mounted) {
        NotificationManager().showSuccess('删除成功');
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('删除失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '备份管理 - ${widget.instance.name}',
      width: 800,
      height: 560,
      onClose: () => Navigator.of(context).pop(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 创建备份区域
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BAColors.surfaceOf(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BAColors.borderOf(context).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建新备份',
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        style: TextStyle(color: BAColors.textPrimaryOf(context)),
                        decoration: InputDecoration(
                          hintText: '添加备份描述（可选）',
                          hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
                          filled: true,
                          fillColor: BAColors.surfaceOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: BAColors.borderOf(context).withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: BAColors.borderOf(context).withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: BAColors.primaryOf(context),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: BASecondaryButton(
                              text: '完整备份',
                              onPressed: _isBackingUp
                                  ? null
                                  : () => _createBackup(BackupType.full),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BASecondaryButton(
                              text: '仅存档',
                              onPressed: _isBackingUp
                                  ? null
                                  : () => _createBackup(BackupType.savesOnly),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 备份列表标题
                Row(
                  children: [
                    Text(
                      '备份历史 (${_backups.length})',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 备份列表
                Expanded(
                  child: _backups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: BAColors.textDisabledOf(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '还没有备份',
                                style: TextStyle(
                                  color: BAColors.textSecondaryOf(context),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BAColors.surfaceOf(context).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: BAColors.borderOf(context).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: BAColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.backup,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getBackupTypeLabel(backup.type),
                                          style: TextStyle(
                                            color: BAColors.textPrimaryOf(context),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(backup.createdAt),
                                          style: TextStyle(
                                            color: BAColors.textSecondaryOf(context),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (backup.description != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            backup.description!,
                                            style: TextStyle(
                                              color: BAColors.textSecondaryOf(context),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    backup.formattedFileSize,
                                    style: TextStyle(
                                      color: BAColors.textSecondaryOf(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.restore, size: 18),
                                    color: BAColors.primaryOf(context),
                                    onPressed: () => _restoreBackup(backup),
                                    tooltip: '恢复备份',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    color: BAColors.primaryOf(context),
                                    onPressed: () => _deleteBackup(backup),
                                    tooltip: '删除备份',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
