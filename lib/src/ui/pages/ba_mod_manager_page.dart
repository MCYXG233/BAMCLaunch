import 'package:flutter/material.dart';
import '../theme/ba_theme_colors.dart';
import '../../mod/mod_manager.dart';
import '../../mod/mod_info.dart';
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
  bool _notificationInitialized = false;
  
  List<ModInfo> _mods = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _showDisabled = true;
  String _sortBy = 'name';

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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    return Container(
      color: BAThemeColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: _buildModList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '模组管理',
          style: TextStyle(
            color: BAThemeColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: BAThemeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_mods.length} 个模组',
            style: TextStyle(
              color: BAThemeColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: BAThemeColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BAThemeColors.border.withValues(alpha: 0.5)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              style: const TextStyle(
                color: BAThemeColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: '搜索模组...',
                hintStyle: const TextStyle(color: BAThemeColors.textDisabled),
                prefixIcon: const Icon(
                  Icons.search,
                  color: BAThemeColors.textSecondary,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSortDropdown(),
        const SizedBox(width: 12),
        _buildShowDisabledSwitch(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAThemeColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          dropdownColor: BAThemeColors.surface,
          style: const TextStyle(
            color: BAThemeColors.textPrimary,
            fontSize: 13,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: BAThemeColors.textSecondary),
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
    );
  }

  Widget _buildShowDisabledSwitch() {
    return Row(
      children: [
        const Text(
          '显示禁用',
          style: TextStyle(
            color: BAThemeColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _showDisabled,
          onChanged: (value) => setState(() => _showDisabled = value),
          activeThumbColor: BAThemeColors.primary,
        ),
      ],
    );
  }

  Widget _buildModList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: BAThemeColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: BAThemeColors.textSecondary),
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
              color: BAThemeColors.textDisabled,
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无模组',
              style: TextStyle(
                color: BAThemeColors.textSecondary,
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
          onToggle: () => _toggleMod(mod),
          onDelete: () => _deleteMod(mod),
          onTap: () => _showModDetail(mod),
        );
      },
    );
  }
}

class _ModItem extends StatelessWidget {
  final ModInfo mod;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ModItem({
    required this.mod,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BAThemeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: mod.isEnabled ? BAThemeColors.border : BAThemeColors.textDisabled.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Switch(
                value: mod.isEnabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: BAThemeColors.primary,
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BAThemeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: BAThemeColors.primary,
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
                        color: mod.isEnabled ? BAThemeColors.textPrimary : BAThemeColors.textDisabled,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (mod.version != null)
                          Text(
                            'v${mod.version}',
                            style: TextStyle(
                              color: BAThemeColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        if (mod.modId != null) ...[
                          const Text(' · ', style: TextStyle(color: BAThemeColors.textDisabled)),
                          Text(
                            mod.modId!,
                            style: TextStyle(
                              color: BAThemeColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: BAThemeColors.textDisabled),
                onPressed: onDelete,
              ),
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
      backgroundColor: BAThemeColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: BAThemeColors.border),
            Expanded(child: _buildContent()),
            const Divider(height: 1, color: BAThemeColors.border),
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
              color: BAThemeColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.extension, color: BAThemeColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mod.name,
                  style: const TextStyle(
                    color: BAThemeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (mod.version != null)
                  Text(
                    '版本: ${mod.version}',
                    style: TextStyle(color: BAThemeColors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: BAThemeColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mod.description != null && mod.description!.isNotEmpty) ...[
            const Text(
              '描述',
              style: TextStyle(
                color: BAThemeColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mod.description!,
              style: TextStyle(color: BAThemeColors.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            '模组信息',
            style: TextStyle(
              color: BAThemeColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: '模组ID', value: mod.modId ?? '未知'),
          _InfoRow(label: '作者', value: mod.author ?? '未知'),
          _InfoRow(label: '文件名', value: mod.fileName),
          _InfoRow(label: '文件大小', value: _formatSize(mod.fileSize)),
          if (mod.lastModified != null)
            _InfoRow(label: '更新日期', value: mod.lastModified!.toString().split(' ')[0]),
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

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(color: BAThemeColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: BAThemeColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}