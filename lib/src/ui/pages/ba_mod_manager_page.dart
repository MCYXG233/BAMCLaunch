import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../mod/mod_manager.dart';
import '../../mod/mod_info.dart';
import '../../mod/dependency_resolver.dart';
import '../../mod/mod_update_checker.dart';
import '../../mod/conflict_detector.dart';
import '../components/ba_notification.dart';
import '../components/ba_dialog.dart';

class BAModManagerPage extends StatefulWidget {
  final String instanceId;

  const BAModManagerPage({
    super.key,
    required this.instanceId,
  });

  @override
  State<BAModManagerPage> createState() => _BAModManagerPageState();
}

class _BAModManagerPageState extends State<BAModManagerPage> {
  final ModManager _modManager = ModManager();
  final DependencyResolver _dependencyResolver = DependencyResolver();
  final ModUpdateChecker _updateChecker = ModUpdateChecker();
  final ConflictDetector _conflictDetector = ConflictDetector();
  
  bool _notificationInitialized = false;
  
  List<ModInfo> _mods = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _showDisabled = true;
  String _sortBy = 'name';

  bool _isMultiSelectMode = false;
  final Set<String> _selectedModIds = {};

  List<ModConflict> _conflicts = [];
  List<ModUpdateInfo> _updates = [];
  List<MissingDependency> _missingDependencies = [];

  @override
  void initState() {
    super.initState();
    _loadMods();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationInitialized) {
      NotificationManager().init(context);
      _notificationInitialized = true;
    }
  }

  Future<void> _loadMods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mods = await _modManager.getMods(widget.instanceId);
      setState(() {
        _mods = mods;
        _isLoading = false;
      });
      _analyzeMods();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _analyzeMods() {
    _conflicts = _conflictDetector.detectConflicts(_mods);
    _missingDependencies = _dependencyResolver.findMissingDependencies(_mods);
  }

  Future<void> _checkUpdates() async {
    try {
      final updates = await _updateChecker.checkUpdates(_mods);
      setState(() {
        _updates = updates;
      });
      if (updates.isEmpty) {
        NotificationManager().showSuccess('所有模组已更新到最新版本');
      }
    } catch (e) {
      NotificationManager().showError('检查更新失败', message: e.toString());
    }
  }

  Future<void> _toggleMod(ModInfo mod) async {
    try {
      await _modManager.toggleMod(mod);
      _loadMods();
    } catch (e) {
      NotificationManager().showError('操作失败', message: e.toString());
    }
  }

  Future<void> _deleteMod(ModInfo mod) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除模组',
      content: '确定要删除模组 "${mod.name}" 吗？此操作不可撤销。',
      confirmText: '删除',
    );

    if (!confirmed) return;

    try {
      await _modManager.deleteMod(mod);
      NotificationManager().showSuccess('删除成功');
      _loadMods();
    } catch (e) {
      NotificationManager().showError('删除失败', message: e.toString());
    }
  }

  void _showModDetail(ModInfo mod) {
    showDialog(
      context: context,
      builder: (context) => _ModDetailDialog(mod: mod),
    );
  }

  void _showConflictsDialog() {
    if (_conflicts.isEmpty && _missingDependencies.isEmpty) {
      NotificationManager().showSuccess('未检测到冲突');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ConflictsDialog(
        conflicts: _conflicts,
        missingDependencies: _missingDependencies,
        onResolve: (solution) async {
          for (final mod in solution.removeMods) {
            await _modManager.deleteMod(mod);
          }
          for (final mod in solution.removeMods) {
            await _modManager.toggleMod(mod);
          }
          if (mounted) {
            Navigator.pop(context);
            _loadMods();
          }
        },
      ),
    );
  }

  void _showUpdatesDialog() {
    if (_updates.isEmpty) {
      NotificationManager().showSuccess('所有模组已更新到最新版本');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _UpdatesDialog(
        updates: _updates,
        onUpdate: (update) async {
          Navigator.pop(context);
          await _downloadUpdate(update);
        },
        onUpdateAll: () async {
          Navigator.pop(context);
          await _downloadAllUpdates();
        },
      ),
    );
  }

  Future<void> _downloadUpdate(ModUpdateInfo update) async {
    try {
      final path = '${update.mod.filePath.replaceAll('.jar', '')}_updated.jar';
      final result = await _updateChecker.downloadUpdate(update, path);
      if (result != null) {
        NotificationManager().showSuccess('${update.mod.name} 更新成功');
        _loadMods();
      }
    } catch (e) {
      NotificationManager().showError('更新失败', message: e.toString());
    }
  }

  Future<void> _downloadAllUpdates() async {
    for (final update in _updates) {
      await _downloadUpdate(update);
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedModIds.clear();
      }
    });
  }

  void _toggleSelectAll() {
    final filtered = _getFilteredMods();
    if (_selectedModIds.length == filtered.length) {
      _selectedModIds.clear();
    } else {
      _selectedModIds.addAll(filtered.map((m) => m.id));
    }
    setState(() {});
  }

  void _toggleModSelection(ModInfo mod) {
    setState(() {
      if (_selectedModIds.contains(mod.id)) {
        _selectedModIds.remove(mod.id);
      } else {
        _selectedModIds.add(mod.id);
      }
    });
  }

  Future<void> _batchEnable() async {
    final selectedMods = _mods.where((m) => _selectedModIds.contains(m.id) && !m.isEnabled).toList();
    for (final mod in selectedMods) {
      await _modManager.toggleMod(mod);
    }
    NotificationManager().showSuccess('已启用 ${selectedMods.length} 个模组');
    _loadMods();
    _selectedModIds.clear();
    setState(() {});
  }

  Future<void> _batchDisable() async {
    final selectedMods = _mods.where((m) => _selectedModIds.contains(m.id) && m.isEnabled).toList();
    for (final mod in selectedMods) {
      await _modManager.toggleMod(mod);
    }
    NotificationManager().showSuccess('已禁用 ${selectedMods.length} 个模组');
    _loadMods();
    _selectedModIds.clear();
    setState(() {});
  }

  Future<void> _batchDelete() async {
    final selectedMods = _mods.where((m) => _selectedModIds.contains(m.id)).toList();
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '批量删除模组',
      content: '确定要删除选中的 ${selectedMods.length} 个模组吗？此操作不可撤销。',
      confirmText: '删除',
    );

    if (!confirmed) return;

    for (final mod in selectedMods) {
      await _modManager.deleteMod(mod);
    }
    NotificationManager().showSuccess('已删除 ${selectedMods.length} 个模组');
    _loadMods();
    _selectedModIds.clear();
    setState(() {});
  }

  List<ModInfo> _getFilteredMods() {
    var list = _mods;
    
    if (!_showDisabled) {
      list = list.where((m) => m.isEnabled).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((m) => 
        m.name.toLowerCase().contains(query) ||
        m.modId?.toLowerCase().contains(query) == true
      ).toList();
    }

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'version':
        list.sort((a, b) => (b.version ?? '').compareTo(a.version ?? ''));
        break;
      case 'date':
        list.sort((a, b) => (b.lastModified ?? DateTime.now()).compareTo(a.lastModified ?? DateTime.now()));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: BAColors.backgroundOf(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildToolbar(context),
            const SizedBox(height: 16),
            if (_isMultiSelectMode) _buildBatchActionBar(context),
            if (_conflicts.isNotEmpty || _missingDependencies.isNotEmpty)
              _buildWarningBar(context),
            Expanded(child: _buildModList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: BAColors.secondaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: BAColors.secondary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.extension,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '模组管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BAColors.borderOf(context).withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.extension,
                color: BAColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_mods.length}',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' 个模组',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (_conflicts.isNotEmpty)
          _buildWarningBadge(context, '${_conflicts.length} 冲突', BAColors.dangerOf(context)),
        if (_missingDependencies.isNotEmpty)
          _buildWarningBadge(context, '${_missingDependencies.length} 缺失依赖', Colors.orange),
      ],
    );
  }

  Widget _buildWarningBadge(BuildContext context, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.dangerOf(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.dangerOf(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: BAColors.dangerOf(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _buildWarningText(),
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
          TextButton(
            onPressed: _showConflictsDialog,
            child: Text('查看详情'),
          ),
        ],
      ),
    );
  }

  String _buildWarningText() {
    final parts = <String>[];
    if (_conflicts.isNotEmpty) {
      parts.add('检测到 ${_conflicts.length} 个冲突');
    }
    if (_missingDependencies.isNotEmpty) {
      parts.add('${_missingDependencies.length} 个缺失依赖');
    }
    return parts.join('，');
  }

  Widget _buildToolbar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 300),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BAColors.surfaceOf(context).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BAColors.borderOf(context).withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: BAColors.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '搜索模组...',
                  hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: BAColors.textSecondaryOf(context),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSortDropdown(context),
          const SizedBox(width: 12),
          _buildShowDisabledSwitch(context),
          const SizedBox(width: 12),
          _buildToolbarButton(
            context,
            icon: Icons.refresh,
            label: '检查更新',
            onPressed: _checkUpdates,
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.warning,
            label: '冲突检测',
            onPressed: _showConflictsDialog,
            color: _conflicts.isNotEmpty ? BAColors.dangerOf(context) : null,
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: _isMultiSelectMode ? Icons.close : Icons.checklist,
            label: _isMultiSelectMode ? '取消选择' : '多选',
            onPressed: _toggleMultiSelectMode,
            color: _isMultiSelectMode ? BAColors.primaryOf(context) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? BAColors.surfaceOf(context),
          foregroundColor: color ?? BAColors.textPrimaryOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: BAColors.borderOf(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BAColors.borderOf(context)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: _sortBy,
            dropdownColor: BAColors.surfaceOf(context),
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 13,
            ),
            icon: Icon(Icons.arrow_drop_down, color: BAColors.textSecondaryOf(context)),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('按名称')),
              DropdownMenuItem(value: 'version', child: Text('按版本')),
              DropdownMenuItem(value: 'date', child: Text('按日期')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShowDisabledSwitch(BuildContext context) {
    return Row(
      children: [
        Text(
          '显示禁用',
          style: TextStyle(
            color: BAColors.textSecondaryOf(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _showDisabled,
          onChanged: (value) => setState(() => _showDisabled = value),
          activeThumbColor: BAColors.primaryOf(context),
        ),
      ],
    );
  }

  Widget _buildBatchActionBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.primaryOf(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.primaryOf(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            '已选择 ${_selectedModIds.length} 个模组',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text('全选'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedModIds.isEmpty ? null : _batchEnable,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('批量启用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedModIds.isEmpty ? null : _batchDisable,
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('批量禁用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedModIds.isEmpty ? null : _batchDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('批量删除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.dangerOf(context),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: BAColors.dangerOf(context), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMods,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final filtered = _getFilteredMods();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 64,
              color: BAColors.textDisabledOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无模组',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final mod = filtered[index];
        return _ModItem(
          mod: mod,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: _selectedModIds.contains(mod.id),
          onToggle: () => _toggleMod(mod),
          onDelete: () => _deleteMod(mod),
          onTap: () => _showModDetail(mod),
          onSelect: _isMultiSelectMode ? () => _toggleModSelection(mod) : null,
        );
      },
    );
  }
}

class _ModItem extends StatelessWidget {
  final ModInfo mod;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback? onSelect;

  const _ModItem({
    required this.mod,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isMultiSelectMode ? onSelect : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withOpacity(0.1)
                : BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context)
                  : mod.isEnabled
                      ? BAColors.borderOf(context)
                      : BAColors.textDisabledOf(context).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isMultiSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect?.call(),
                  activeColor: BAColors.primaryOf(context),
                ),
                const SizedBox(width: 8),
              ],
              if (!isMultiSelectMode) ...[
                Switch(
                  value: mod.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: BAColors.primaryOf(context),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BAColors.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: BAColors.primaryOf(context),
                  size: 24,
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
                        color: mod.isEnabled
                            ? BAColors.textPrimaryOf(context)
                            : BAColors.textDisabledOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mod.version != null)
                            Text(
                              'v${mod.version}',
                              style: TextStyle(
                                color: BAColors.textSecondaryOf(context),
                                fontSize: 12,
                              ),
                            ),
                          if (mod.modId != null) ...[
                            Text(' · ', style: TextStyle(color: BAColors.textDisabledOf(context))),
                            Flexible(
                              child: Text(
                                mod.modId!,
                                style: TextStyle(
                                  color: BAColors.textSecondaryOf(context),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMultiSelectMode) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: BAColors.textDisabledOf(context)),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModDetailDialog extends StatelessWidget {
  final ModInfo mod;

  const _ModDetailDialog({required this.mod});

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
            child: Icon(Icons.extension, color: BAColors.primaryOf(context), size: 28),
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
          _InfoRow(label: '模组ID', value: mod.modId ?? '未知', context: context),
          _InfoRow(label: '作者', value: mod.author ?? '未知', context: context),
          _InfoRow(label: '文件名', value: mod.fileName, context: context),
          _InfoRow(label: '文件大小', value: _formatSize(mod.fileSize), context: context),
          if (mod.modLoader != null)
            _InfoRow(label: '加载器', value: mod.modLoader!, context: context),
          if (mod.lastModified != null)
            _InfoRow(label: '更新日期', value: mod.lastModified!.toString().split(' ')[0], context: context),
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
              children: mod.dependencies.map((dep) => Chip(
                label: Text(dep, style: const TextStyle(fontSize: 12)),
                backgroundColor: BAColors.surfaceVariantOf(context),
              )).toList(),
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

  String _formatSize(int size) {
    if (size <= 0) return '未知';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _InfoRow({required this.label, required this.value, required this.context});

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

class _ConflictsDialog extends StatelessWidget {
  final List<ModConflict> conflicts;
  final List<MissingDependency> missingDependencies;
  final void Function(ConflictSolution) onResolve;

  const _ConflictsDialog({
    required this.conflicts,
    required this.missingDependencies,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BAColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 600,
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
          Icon(Icons.warning, color: BAColors.dangerOf(context), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '冲突检测结果',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${conflicts.length} 个冲突，${missingDependencies.length} 个缺失依赖',
                  style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 14),
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
          if (conflicts.isNotEmpty) ...[
            Text(
              '冲突',
              style: TextStyle(
                color: BAColors.dangerOf(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...conflicts.map((c) => _ConflictCard(conflict: c)),
            const SizedBox(height: 20),
          ],
          if (missingDependencies.isNotEmpty) ...[
            Text(
              '缺失依赖',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...missingDependencies.map((d) => _MissingDependencyCard(dep: d)),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final ModConflict conflict;

  const _ConflictCard({required this.conflict});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (conflict.isError ? BAColors.dangerOf(context) : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (conflict.isError ? BAColors.dangerOf(context) : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conflict.isError ? Icons.error : Icons.warning,
                color: conflict.isError ? BAColors.dangerOf(context) : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                conflict.title,
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflict.description,
            style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '建议: ${conflict.suggestion}',
            style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MissingDependencyCard extends StatelessWidget {
  final MissingDependency dep;

  const _MissingDependencyCard({required this.dep});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_off, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${dep.dependentModName} 需要 ${dep.missingModId}',
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesDialog extends StatelessWidget {
  final List<ModUpdateInfo> updates;
  final void Function(ModUpdateInfo) onUpdate;
  final VoidCallback onUpdateAll;

  const _UpdatesDialog({
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
          Icon(Icons.system_update, color: BAColors.primaryOf(context), size: 28),
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
                  style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 14),
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
                  color: BAColors.primaryOf(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.extension, color: BAColors.primaryOf(context), size: 20),
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
                      style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 13),
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
