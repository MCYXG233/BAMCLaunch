import 'package:flutter/material.dart';
import '../theme/colors.dart';
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
      color: BAColors.backgroundOf(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildToolbar(context),
          const SizedBox(height: 16),
          Expanded(child: _buildModList(context)),
        ],
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
      ],
    );
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
        ],
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
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: mod.isEnabled ? BAColors.borderOf(context) : BAColors.textDisabledOf(context).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Switch(
                value: mod.isEnabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: BAColors.primaryOf(context),
              ),
              const SizedBox(width: 12),
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
                        color: mod.isEnabled ? BAColors.textPrimaryOf(context) : BAColors.textDisabledOf(context),
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
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.delete_outline, color: BAColors.textDisabledOf(context)),
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
          if (mod.lastModified != null)
            _InfoRow(label: '更新日期', value: mod.lastModified!.toString().split(' ')[0], context: context),
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
