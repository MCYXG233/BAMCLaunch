import 'package:flutter/material.dart';

import '../../../mod/mod_manager.dart';
import '../../../mod/mod_info.dart';
import '../../../mod/dependency_resolver.dart';
import '../../../mod/mod_update_checker.dart';
import '../../../mod/conflict_detector.dart';
import '../../components/ba_notification.dart';
import '../../components/ba_dialog.dart';
import '../../theme/colors.dart';
import 'dialogs/conflicts_dialog.dart';
import 'dialogs/mod_detail_dialog.dart';
import 'dialogs/updates_dialog.dart';
import 'widgets/batch_action_bar.dart';
import 'widgets/mod_header.dart';
import 'widgets/mod_item.dart';
import 'widgets/mod_toolbar.dart';
import 'widgets/warning_bar.dart';

/// 蔚蓝档案风格模组管理页
///
/// 主入口，负责：
/// - 持有模组列表、搜索/筛选/排序/多选/分析状态
/// - 编排业务方法（toggle/delete/batch/update/check conflicts）
/// - 在 Header/Toolbar/BatchBar/WarningBar/ModList 之间分发
class BAModManagerPage extends StatefulWidget {
  final String instanceId;

  const BAModManagerPage({super.key, required this.instanceId});

  @override
  State<BAModManagerPage> createState() => _BAModManagerPageState();
}

class _BAModManagerPageState extends State<BAModManagerPage> {
  final ModManager _modManager = ModManager();
  final DependencyResolver _dependencyResolver = DependencyResolver();
  final ModUpdateChecker _updateChecker = ModUpdateChecker();
  final ConflictDetector _conflictDetector = ConflictDetector();

  bool _notificationInitialized = false;

  // 搜索/筛选/排序状态
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showDisabled = true;
  String _sortBy = 'name';

  // 多选状态
  bool _isMultiSelectMode = false;
  final Set<String> _selectedModIds = {};

  // 数据
  List<ModInfo> _mods = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<ModConflict> _conflicts = [];
  List<ModUpdateInfo> _updates = [];
  List<MissingDependency> _missingDependencies = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() => _searchQuery = _searchController.text);
    }
  }

  Future<void> _loadMods() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mods = await _modManager.getMods(widget.instanceId);
      if (!mounted) return;
      setState(() {
        _mods = mods;
        _isLoading = false;
      });
      _analyzeMods();
    } catch (e) {
      if (!mounted) return;
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

  /// 检查更新: 拿到结果后自动弹出 [_showUpdatesDialog](updates 不为空时)
  Future<void> _checkUpdates() async {
    try {
      final updates = await _updateChecker.checkUpdates(_mods);
      if (!mounted) return;
      setState(() {
        _updates = updates;
      });
      if (updates.isEmpty) {
        NotificationManager().showSuccess('所有模组已更新到最新版本');
        return;
      }
      _showUpdatesDialog();
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('检查更新失败', message: e.toString());
    }
  }

  Future<void> _toggleMod(ModInfo mod) async {
    try {
      await _modManager.toggleMod(mod);
      await _loadMods();
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      NotificationManager().showSuccess('删除成功');
      _loadMods();
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('删除失败', message: e.toString());
    }
  }

  void _showModDetail(ModInfo mod) {
    showDialog(
      context: context,
      builder: (context) => ModDetailDialog(mod: mod),
    );
  }

  void _showConflictsDialog() {
    if (_conflicts.isEmpty && _missingDependencies.isEmpty) {
      NotificationManager().showSuccess('未检测到冲突');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ConflictsDialog(
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
      builder: (context) => UpdatesDialog(
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
        if (!mounted) return;
        NotificationManager().showSuccess('${update.mod.name} 更新成功');
        _loadMods();
      }
    } catch (e) {
      if (!mounted) return;
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
    setState(() {
      if (_selectedModIds.length == filtered.length) {
        _selectedModIds.clear();
      } else {
        _selectedModIds.addAll(filtered.map((m) => m.id));
      }
    });
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
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.id) && !m.isEnabled)
        .toList();
    for (final mod in selectedMods) {
      await _modManager.toggleMod(mod);
    }
    if (!mounted) return;
    NotificationManager().showSuccess('已启用 ${selectedMods.length} 个模组');
    _loadMods();
    setState(() => _selectedModIds.clear());
  }

  Future<void> _batchDisable() async {
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.id) && m.isEnabled)
        .toList();
    for (final mod in selectedMods) {
      await _modManager.toggleMod(mod);
    }
    if (!mounted) return;
    NotificationManager().showSuccess('已禁用 ${selectedMods.length} 个模组');
    _loadMods();
    setState(() => _selectedModIds.clear());
  }

  Future<void> _batchDelete() async {
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.id))
        .toList();
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
    if (!mounted) return;
    NotificationManager().showSuccess('已删除 ${selectedMods.length} 个模组');
    _loadMods();
    setState(() => _selectedModIds.clear());
  }

  List<ModInfo> _getFilteredMods() {
    var list = _mods;

    if (!_showDisabled) {
      list = list.where((m) => m.isEnabled).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where(
            (m) =>
                m.name.toLowerCase().contains(query) ||
                m.modId?.toLowerCase().contains(query) == true,
          )
          .toList();
    }

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'version':
        list.sort((a, b) => (b.version ?? '').compareTo(a.version ?? ''));
        break;
      case 'date':
        list.sort(
          (a, b) => (b.lastModified ?? DateTime.now()).compareTo(
            a.lastModified ?? DateTime.now(),
          ),
        );
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMods();
    final canEnable =
        _selectedModIds.isNotEmpty &&
        _mods
            .where((m) => _selectedModIds.contains(m.id) && !m.isEnabled)
            .isNotEmpty;
    final canDisable =
        _selectedModIds.isNotEmpty &&
        _mods
            .where((m) => _selectedModIds.contains(m.id) && m.isEnabled)
            .isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ModHeader(
              modCount: _mods.length,
              conflictCount: _conflicts.length,
              missingDepCount: _missingDependencies.length,
            ),
            const SizedBox(height: 16),
            ModToolbar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              sortBy: _sortBy,
              onSortChanged: (v) => setState(() => _sortBy = v),
              showDisabled: _showDisabled,
              onShowDisabledChanged: (v) => setState(() => _showDisabled = v),
              isMultiSelectMode: _isMultiSelectMode,
              conflictCount: _conflicts.length,
              onCheckUpdates: _checkUpdates,
              onShowConflicts: _showConflictsDialog,
              onToggleMultiSelect: _toggleMultiSelectMode,
            ),
            const SizedBox(height: 16),
            if (_isMultiSelectMode)
              BatchActionBar(
                selectedCount: _selectedModIds.length,
                canEnable: canEnable,
                canDisable: canDisable,
                onSelectAll: _toggleSelectAll,
                onBatchEnable: _batchEnable,
                onBatchDisable: _batchDisable,
                onBatchDelete: _batchDelete,
              ),
            if (!_isMultiSelectMode &&
                (_conflicts.isNotEmpty || _missingDependencies.isNotEmpty))
              WarningBar(
                conflictCount: _conflicts.length,
                missingDepCount: _missingDependencies.length,
                onShowDetail: _showConflictsDialog,
              ),
            Expanded(child: _buildModList(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildModList(List<ModInfo> filtered) {
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
            ElevatedButton(onPressed: _loadMods, child: const Text('重试')),
          ],
        ),
      );
    }

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
        return ModItem(
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
