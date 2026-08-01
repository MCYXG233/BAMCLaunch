import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../mod/mod_manager.dart';
import '../../../mod/mod_info.dart';
import '../../../mod/dependency_resolver.dart';
import '../../../mod/mod_update_checker.dart';
import '../../../mod/conflict_detector.dart';
import '../../components/ba_notification.dart';
import '../../components/ba_dialog.dart';
import '../../components/ba_buttons.dart';
import 'widgets/warning_badge.dart';
import 'widgets/toolbar_widgets.dart';
import 'widgets/mod_item.dart';
import 'dialogs/mod_detail_dialog.dart';
import 'dialogs/conflicts_dialog.dart';
import 'dialogs/updates_dialog.dart';

/// 模组管理页面
///
/// 支持模组浏览、搜索、排序、启用/禁用切换、批量操作、冲突检测、更新检查
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
    try {
      final conflicts = _conflictDetector.detectConflicts(_mods);
      final missing = _dependencyResolver.findMissingDependencies(_mods);
      if (!mounted) return;
      setState(() {
        _conflicts = conflicts;
        _missingDependencies = missing;
      });
    } catch (_) {
      // 静默失败，不影响主要功能
    }
  }

  Future<void> _checkUpdates() async {
    try {
      final updates = await _updateChecker.checkUpdates(_mods);
      if (!mounted) return;
      setState(() => _updates = updates);
      if (updates.isEmpty) {
        NotificationManager().showSuccess('所有模组均为最新版本');
      } else {
        _showUpdatesDialog();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('检查更新失败', message: e.toString());
    }
  }

  Future<void> _toggleMod(ModInfo mod) async {
    try {
      await _modManager.toggleMod(mod);
      if (!mounted) return;
      setState(() {
        final index = _mods.indexWhere((m) => m.fileName == mod.fileName);
        if (index != -1) {
          _mods[index] = _mods[index].copyWith(isEnabled: !mod.isEnabled);
        }
      });
      NotificationManager().showSuccess(mod.isEnabled ? '已禁用' : '已启用');
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('操作失败', message: e.toString());
    }
  }

  Future<void> _deleteMod(ModInfo mod) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除模组',
      content: '确定要删除 "${mod.name}" 吗？此操作不可撤销。',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
    );

    if (confirmed != true) return;

    try {
      await _modManager.deleteMod(mod);
      if (!mounted) return;
      setState(() {
        _mods.removeWhere((m) => m.fileName == mod.fileName);
        _selectedModIds.remove(mod.fileName);
      });
      NotificationManager().showSuccess('模组已删除');
      _analyzeMods();
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
    showDialog(
      context: context,
      builder: (context) => ConflictsDialog(
        conflicts: _conflicts,
        missingDependencies: _missingDependencies,
        onResolve: (solution) {
          Navigator.pop(context);
          _analyzeMods();
        },
      ),
    );
  }

  void _showUpdatesDialog() {
    showDialog(
      context: context,
      builder: (context) => UpdatesDialog(
        updates: _updates,
        onUpdate: (update) {
          _downloadUpdate(update);
          Navigator.pop(context);
        },
        onUpdateAll: () {
          Navigator.pop(context);
          _downloadAllUpdates();
        },
      ),
    );
  }

  Future<void> _downloadUpdate(ModUpdateInfo update) async {
    try {
      final path = '${update.mod.filePath.replaceAll('.jar', '')}_updated.jar';
      final savedPath = await _updateChecker.downloadUpdate(update, path);
      if (!mounted) return;
      if (savedPath != null) {
        NotificationManager().showSuccess('${update.mod.name} 已更新');
      } else {
        NotificationManager().showError('更新失败');
      }
    } catch (e) {
      if (!mounted) return;
      NotificationManager().showError('更新失败', message: e.toString());
    }
  }

  Future<void> _downloadAllUpdates() async {
    if (_updates.isEmpty) return;
    var successCount = 0;
    for (final update in _updates) {
      try {
        final path =
            '${update.mod.filePath.replaceAll('.jar', '')}_updated.jar';
        final savedPath = await _updateChecker.downloadUpdate(update, path);
        if (savedPath != null) successCount++;
      } catch (_) {
        // 单个失败不影响其他
      }
    }
    if (!mounted) return;
    NotificationManager().showSuccess(
      '批量更新完成',
      message: '成功 $successCount/${_updates.length}',
    );
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      _selectedModIds.clear();
    });
  }

  void _toggleSelectAll() {
    final filtered = _getFilteredMods();
    setState(() {
      if (_selectedModIds.length == filtered.length) {
        _selectedModIds.clear();
      } else {
        _selectedModIds
          ..clear()
          ..addAll(filtered.map((m) => m.fileName));
      }
    });
  }

  void _toggleModSelection(ModInfo mod) {
    setState(() {
      if (_selectedModIds.contains(mod.fileName)) {
        _selectedModIds.remove(mod.fileName);
      } else {
        _selectedModIds.add(mod.fileName);
      }
    });
  }

  Future<void> _batchEnable() async {
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.fileName) && !m.isEnabled)
        .toList();
    for (final mod in selectedMods) {
      try {
        await _modManager.toggleMod(mod);
      } catch (_) {
        // 静默
      }
    }
    if (!mounted) return;
    NotificationManager().showSuccess('已启用 ${selectedMods.length} 个模组');
    setState(() => _selectedModIds.clear());
    _loadMods();
  }

  Future<void> _batchDisable() async {
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.fileName) && m.isEnabled)
        .toList();
    for (final mod in selectedMods) {
      try {
        await _modManager.toggleMod(mod);
      } catch (_) {
        // 静默
      }
    }
    if (!mounted) return;
    NotificationManager().showSuccess('已禁用 ${selectedMods.length} 个模组');
    setState(() => _selectedModIds.clear());
    _loadMods();
  }

  Future<void> _batchDelete() async {
    final selectedMods = _mods
        .where((m) => _selectedModIds.contains(m.fileName))
        .toList();

    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '批量删除',
      content: '确定要删除 ${selectedMods.length} 个模组吗？此操作不可撤销。',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
    );

    if (confirmed != true) return;

    for (final mod in selectedMods) {
      try {
        await _modManager.deleteMod(mod);
      } catch (_) {
        // 静默
      }
    }
    if (!mounted) return;
    NotificationManager().showSuccess('已删除 ${selectedMods.length} 个模组');
    setState(() => _selectedModIds.clear());
    _loadMods();
  }

  List<ModInfo> _getFilteredMods() {
    final query = _searchQuery.toLowerCase();
    var filtered = _mods.where((mod) {
      if (!_showDisabled && !mod.isEnabled) return false;
      if (query.isEmpty) return true;
      return mod.name.toLowerCase().contains(query) ||
          mod.modId?.toLowerCase().contains(query) == true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'version':
          return (a.version ?? '').compareTo(b.version ?? '');
        case 'date':
          return (b.lastModified ?? DateTime(0)).compareTo(
            a.lastModified ?? DateTime(0),
          );
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });
    return filtered;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          if (_conflicts.isNotEmpty || _missingDependencies.isNotEmpty)
            WarningBar(
              message: _buildWarningText(),
              onShowDetails: _showConflictsDialog,
            ),
          if (_isMultiSelectMode) ...[
            BatchActionBar(
              selectedCount: _selectedModIds.length,
              onSelectAll: _toggleSelectAll,
              onBatchEnable: _batchEnable,
              onBatchDisable: _batchDisable,
              onBatchDelete: _batchDelete,
            ),
          ],
          const SizedBox(height: 16),
          _buildToolbar(context),
          const SizedBox(height: 16),
          Expanded(child: _buildModList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // 副信息：模组总数 + 冲突 + 缺失依赖（如有）
    final parts = <String>['${_mods.length} 个模组'];
    if (_conflicts.isNotEmpty) {
      parts.add('${_conflicts.length} 冲突');
    }
    if (_missingDependencies.isNotEmpty) {
      parts.add('${_missingDependencies.length} 缺失');
    }
    final subtitle = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：图标 + 标题 + 副信息（与游戏库页统一格式）
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryLightOf(context),
                      BAColors.primaryOf(context),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: BAColors.primaryOf(context)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '模组管理',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _conflicts.isNotEmpty
                          ? BAColors.dangerOf(context)
                          : BAColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // 右侧：操作按钮组（紧凑、玻璃拟态）
          _buildHeaderButton(
            context,
            icon: Icons.refresh_rounded,
            label: '检查更新',
            onPressed: _checkUpdates,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            context,
            icon: Icons.warning_rounded,
            label: '冲突',
            onPressed: _showConflictsDialog,
            highlight: _conflicts.isNotEmpty,
            highlightColor: BAColors.dangerOf(context),
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            context,
            icon: _isMultiSelectMode ? Icons.close_rounded : Icons.checklist_rounded,
            label: _isMultiSelectMode ? '退出多选' : '多选',
            onPressed: _toggleMultiSelectMode,
            active: _isMultiSelectMode,
          ),
        ],
      ),
    );
  }

  /// 标题栏右侧的紧凑操作按钮
  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool highlight = false,
    bool active = false,
    Color? highlightColor,
  }) {
    final accent = highlightColor ?? BAColors.primaryOf(context);
    final bg = active
        ? accent.withValues(alpha: 0.18)
        : (highlight
            ? accent.withValues(alpha: 0.12)
            : BAColors.surfaceOf(context).withValues(alpha: 0.55));
    final border = active || highlight
        ? accent.withValues(alpha: 0.55)
        : BAColors.borderOf(context).withValues(alpha: 0.5);
    final fg = active || highlight ? accent : BAColors.textPrimaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ModSearchField(
            value: _searchQuery,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(width: 12),
          SortDropdown(
            value: _sortBy,
            onChanged: (v) => setState(() => _sortBy = v),
          ),
          const SizedBox(width: 12),
          ShowDisabledSwitch(
            value: _showDisabled,
            onChanged: (v) => setState(() => _showDisabled = v),
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
            Icon(
              Icons.error_outline,
              color: BAColors.dangerOf(context),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败：$_errorMessage',
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadMods, child: const Text('重试')),
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
              Icons.inbox,
              color: BAColors.textSecondaryOf(context),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有匹配的模组' : '暂无模组',
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
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
          isSelected: _selectedModIds.contains(mod.fileName),
          onTap: () => _showModDetail(mod),
          onToggle: () => _toggleMod(mod),
          onDelete: () => _deleteMod(mod),
          onSelect: () => _toggleModSelection(mod),
        );
      },
    );
  }
}
