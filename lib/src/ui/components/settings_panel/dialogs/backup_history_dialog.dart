import 'package:flutter/material.dart';
import '../../../../game/backup_manager.dart';
import '../../../../ui/theme/colors.dart';
import '../../../components/ba_buttons.dart';
import '../../../components/ba_dialog.dart';
import '../../../components/ba_notification.dart';

/// 备份历史对话框
///
/// 列出所有历史备份，支持：
/// - 按实例名筛选
/// - 按备份类型筛选（自动/手动/启动前）
/// - 查看备份详情（大小 / 游戏版本 / 标签 / 描述）
/// - 删除备份文件
/// - 还原备份（通过回调）
class BackupHistoryDialog extends StatefulWidget {
  /// 所有备份记录
  final List<BackupRecord> backups;

  /// 还原回调（传入备份记录）
  final Future<void> Function(BackupRecord)? onRestore;

  /// 删除回调（传入备份记录）
  final Future<void> Function(BackupRecord)? onDelete;

  const BackupHistoryDialog({
    super.key,
    required this.backups,
    this.onRestore,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required List<BackupRecord> backups,
    Future<void> Function(BackupRecord)? onRestore,
    Future<void> Function(BackupRecord)? onDelete,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => BackupHistoryDialog(
        backups: backups,
        onRestore: onRestore,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<BackupHistoryDialog> createState() => _BackupHistoryDialogState();
}

class _BackupHistoryDialogState extends State<BackupHistoryDialog> {
  String? _instanceFilter;
  BackupType? _typeFilter;
  BackupRecord? _selected;
  bool _busy = false;

  List<BackupRecord> get _filtered {
    return widget.backups.where((b) {
      if (_instanceFilter != null && b.instanceName != _instanceFilter) {
        return false;
      }
      if (_typeFilter != null && b.type != _typeFilter) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<String> get _instanceNames {
    final set = widget.backups.map((b) => b.instanceName).toSet().toList()
      ..sort();
    return set;
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '历史备份',
      titleIcon: Icons.history_rounded,
      width: 760,
      onClose: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 480,
        child: widget.backups.isEmpty
            ? _buildEmpty()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧：列表
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilters(),
                        const SizedBox(height: 12),
                        Expanded(child: _buildList()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 右侧：详情
                  Expanded(flex: 2, child: _buildDetail()),
                ],
              ),
      ),
      actions: [
        BASecondaryButton(
          text: '关闭',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 56,
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无历史备份',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '在"备份"中开启自动备份，或点击"立即备份所有实例"',
            style: TextStyle(
              color: BAColors.textDisabledOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildDropdown<String?>(
          label: '实例',
          value: _instanceFilter,
          items: [
            const DropdownMenuItem(value: null, child: Text('全部')),
            ..._instanceNames.map(
              (n) => DropdownMenuItem(value: n, child: Text(n)),
            ),
          ],
          onChanged: (v) => setState(() {
            _instanceFilter = v;
            _selected = null;
          }),
        ),
        _buildDropdown<BackupType?>(
          label: '类型',
          value: _typeFilter,
          items: [
            const DropdownMenuItem(value: null, child: Text('全部')),
            ...BackupType.values.map(
              (t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))),
            ),
          ],
          onChanged: (v) => setState(() {
            _typeFilter = v;
            _selected = null;
          }),
        ),
        Text(
          '共 ${_filtered.length} 条',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label：',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 12,
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            underline: Container(height: 1, color: BAColors.borderOf(context)),
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 12,
            ),
            dropdownColor: BAColors.surfaceVariantOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(
          '没有符合筛选条件的备份',
          style: TextStyle(
            color: BAColors.textDisabledOf(context),
            fontSize: 12,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final b = list[i];
        final isSelected = _selected?.id == b.id;
        return _buildListItem(b, isSelected: isSelected);
      },
    );
  }

  Widget _buildListItem(BackupRecord b, {required bool isSelected}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = b),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withValues(alpha: 0.10)
                : BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context).withValues(alpha: 0.55)
                  : BAColors.borderOf(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _buildTypeBadge(b.type),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.instanceName,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(b.createdAt),
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatSize(b.fileSize),
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BackupType type) {
    final (color, label) = switch (type) {
      BackupType.full => (BAColors.primaryOf(context), '完整'),
      BackupType.savesOnly => (BAColors.successOf(context), '存档'),
      BackupType.configOnly => (BAColors.warningOf(context), '配置'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final b = _selected;
    if (b == null) {
      return Container(
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 36,
                color: BAColors.textDisabledOf(context),
              ),
              const SizedBox(height: 8),
              Text(
                '从左侧选择备份以查看详情',
                style: TextStyle(
                  color: BAColors.textDisabledOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.instanceName,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildTypeBadge(b.type),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(b.createdAt),
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('备份 ID', b.id),
          _buildDetailRow('文件大小', _formatSize(b.fileSize)),
          if (b.gameVersion != null && b.gameVersion!.isNotEmpty)
            _buildDetailRow('游戏版本', b.gameVersion!),
          _buildDetailRow('压缩', b.isCompressed ? '是' : '否'),
          if (b.tags.isNotEmpty) _buildDetailRow('标签', b.tags.join(', ')),
          if (b.description != null && b.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '描述',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                b.description!,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (widget.onRestore != null || widget.onDelete != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.onRestore != null)
                  BAPrimaryButton(
                    text: '还原',
                    onPressed: _busy ? null : () => _restore(b),
                    height: 32,
                  ),
                if (widget.onRestore != null && widget.onDelete != null)
                  const SizedBox(width: 8),
                if (widget.onDelete != null)
                  BADangerButton(
                    text: '删除',
                    onPressed: _busy ? null : () => _delete(b),
                    height: 32,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BackupRecord b) async {
    setState(() => _busy = true);
    try {
      await widget.onRestore!(b);
      if (mounted) {
        NotificationManager().showSuccess('已还原 ${b.instanceName}');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('还原失败', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BackupRecord b) async {
    setState(() => _busy = true);
    try {
      await widget.onDelete!(b);
      if (mounted) {
        setState(() => _selected = null);
        NotificationManager().showSuccess('已删除备份');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('删除失败', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _typeLabel(BackupType t) {
    return switch (t) {
      BackupType.full => '完整',
      BackupType.savesOnly => '存档',
      BackupType.configOnly => '配置',
    };
  }
}
