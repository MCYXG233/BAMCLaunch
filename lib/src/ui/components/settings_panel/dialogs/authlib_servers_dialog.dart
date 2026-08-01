import 'package:flutter/material.dart';
import '../../../../ui/theme/colors.dart';
import '../../../components/ba_buttons.dart';
import '../../../components/ba_dialog.dart';
import '../../../components/ba_notification.dart';

/// 认证服务器管理对话框
///
/// 列出已添加的 Authlib 服务器，支持：
/// - 查看服务器详情（URL / 名称 / 描述）
/// - 删除单个服务器（带确认）
/// - 设为当前选中服务器
class AuthlibServersDialog extends StatefulWidget {
  /// 已保存的服务器列表（每项包含 url / name / description）
  final List<Map<String, dynamic>> servers;

  /// 当前选中的服务器 URL
  final String selectedServerUrl;

  /// 服务器列表变化回调（删除/选中时触发，传入更新后的列表与新的选中 URL）
  final ValueChanged<AuthlibServersChange>? onChanged;

  const AuthlibServersDialog({
    super.key,
    required this.servers,
    required this.selectedServerUrl,
    this.onChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> servers,
    required String selectedServerUrl,
    ValueChanged<AuthlibServersChange>? onChanged,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => AuthlibServersDialog(
        servers: servers,
        selectedServerUrl: selectedServerUrl,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<AuthlibServersDialog> createState() => _AuthlibServersDialogState();
}

class _AuthlibServersDialogState extends State<AuthlibServersDialog> {
  late List<Map<String, dynamic>> _list;
  late String _selectedUrl;
  int? _pendingDeleteIndex;

  @override
  void initState() {
    super.initState();
    _list = List<Map<String, dynamic>>.from(widget.servers);
    _selectedUrl = widget.selectedServerUrl;
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      AuthlibServersChange(servers: _list, selectedServerUrl: _selectedUrl),
    );
  }

  void _select(int index) {
    final url = _list[index]['url'] as String?;
    if (url == null) return;
    setState(() => _selectedUrl = url);
    _notifyChanged();
    NotificationManager().showSuccess('已切换到 ${_list[index]['name']}');
  }

  void _requestDelete(int index) {
    setState(() => _pendingDeleteIndex = index);
  }

  void _confirmDelete() {
    if (_pendingDeleteIndex == null) return;
    final removed = _list[_pendingDeleteIndex!];
    final removedUrl = removed['url'] as String?;
    setState(() {
      _list.removeAt(_pendingDeleteIndex!);
      _pendingDeleteIndex = null;
      if (removedUrl == _selectedUrl) {
        _selectedUrl = _list.isNotEmpty ? (_list.first['url'] as String? ?? '') : '';
      }
    });
    _notifyChanged();
    NotificationManager().showSuccess('已删除 ${removed['name']}');
  }

  void _cancelDelete() {
    setState(() => _pendingDeleteIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '管理认证服务器',
      titleIcon: Icons.dns_rounded,
      width: 540,
      onClose: () => Navigator.of(context).pop(),
      child: _list.isEmpty
          ? _buildEmpty()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '共 ${_list.length} 个服务器，单击可选择当前服务器',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                ..._list.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final url = item['url'] as String? ?? '';
                  final isSelected = url == _selectedUrl && url.isNotEmpty;
                  final isPendingDelete = _pendingDeleteIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildServerCard(
                      item,
                      isSelected: isSelected,
                      isPendingDelete: isPendingDelete,
                      onSelect: () => _select(i),
                      onDelete: () => _requestDelete(i),
                      onConfirmDelete: _confirmDelete,
                      onCancelDelete: _cancelDelete,
                    ),
                  );
                }),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.dns_outlined,
            size: 48,
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 12),
          Text(
            '尚未添加任何认证服务器',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请到"账号与档案"中点击"添加认证服务器"',
            style: TextStyle(
              color: BAColors.textDisabledOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(
    Map<String, dynamic> item, {
    required bool isSelected,
    required bool isPendingDelete,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required VoidCallback onConfirmDelete,
    required VoidCallback onCancelDelete,
  }) {
    final name = item['name'] as String? ?? '未知';
    final url = item['url'] as String? ?? '';
    final description = item['description'] as String?;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isPendingDelete
            ? _buildDeleteConfirm(name, onConfirmDelete, onCancelDelete)
            : Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BAColors.primaryOf(context).withValues(alpha: 0.18)
                          : BAColors.surfaceVariantOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 14,
                      color: isSelected
                          ? BAColors.primaryOf(context)
                          : BAColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: onSelect,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: BAColors.textPrimaryOf(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        BAColors.primaryOf(context),
                                        BAColors.primaryOf(context)
                                            .withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '当前',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            url,
                            style: TextStyle(
                              color: BAColors.textSecondaryOf(context),
                              fontSize: 12,
                            ),
                          ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: TextStyle(
                                color: BAColors.textDisabledOf(context),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: BAColors.dangerOf(context).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BAColors.dangerOf(context).withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: BAColors.dangerOf(context),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeleteConfirm(
    String name,
    VoidCallback onConfirm,
    VoidCallback onCancel,
  ) {
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: BAColors.dangerOf(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '确认删除「$name」？',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 13,
            ),
          ),
        ),
        BASecondaryButton(
          text: '取消',
          onPressed: onCancel,
          height: 30,
        ),
        const SizedBox(width: 8),
        BADangerButton(
          text: '删除',
          onPressed: onConfirm,
          height: 30,
        ),
      ],
    );
  }
}

/// 认证服务器列表变化结果
class AuthlibServersChange {
  final List<Map<String, dynamic>> servers;
  final String selectedServerUrl;

  const AuthlibServersChange({
    required this.servers,
    required this.selectedServerUrl,
  });
}
