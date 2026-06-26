import 'package:flutter/material.dart';
import '../models.dart';
import '../instance_manager.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/ba_buttons.dart';
import '../../ui/components/ba_dialog.dart';
import '../../core/logger.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../modpack/modpack_import_dialog.dart';
import 'instance_config_page.dart';

/// 实例管理主页面
class InstanceManagerPage extends StatefulWidget {
  const InstanceManagerPage({super.key});

  @override
  State<InstanceManagerPage> createState() => _InstanceManagerPageState();
}

class _InstanceManagerPageState extends State<InstanceManagerPage> {
  final Logger _logger = Logger('InstanceManagerPage');
  final InstanceManager _instanceManager = InstanceManager.instance;
  final ConfigManager _config = ConfigManager.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _showGrid = true;
  
  // 排序和搜索状态
  InstanceSortOption _sortOption = InstanceSortOption.lastPlayed;
  SortDirection _sortDirection = SortDirection.descending;
  String _searchQuery = '';
  Map<String, int> _instanceSizes = {};

  @override
  void initState() {
    super.initState();
    _loadInstances();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载用户偏好设置
  Future<void> _loadUserPreferences() async {
    try {
      final sortOptionStr = _config.getString(ConfigKeys.instanceSortOption);
      if (sortOptionStr != null) {
        _sortOption = InstanceSortOption.values.firstWhere(
          (e) => e.name == sortOptionStr,
          orElse: () => InstanceSortOption.lastPlayed,
        );
      }

      final sortDirectionStr = _config.getString(ConfigKeys.instanceSortDirection);
      if (sortDirectionStr != null) {
        _sortDirection = SortDirection.values.firstWhere(
          (e) => e.name == sortDirectionStr,
          orElse: () => SortDirection.descending,
        );
      }

      _searchQuery = _config.getString(ConfigKeys.instanceSearchQuery) ?? '';
      _searchController.text = _searchQuery;

      // 加载实例大小
      await _loadInstanceSizes();

      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      _logger.error('Failed to load user preferences', e, stackTrace);
    }
  }

  /// 保存用户偏好设置
  Future<void> _saveUserPreferences() async {
    try {
      await _config.setString(ConfigKeys.instanceSortOption, _sortOption.name);
      await _config.setString(ConfigKeys.instanceSortDirection, _sortDirection.name);
      await _config.setString(ConfigKeys.instanceSearchQuery, _searchQuery);
      await _config.save();
    } catch (e, stackTrace) {
      _logger.error('Failed to save user preferences', e, stackTrace);
    }
  }

  /// 加载所有实例的大小
  Future<void> _loadInstanceSizes() async {
    try {
      final instances = _instanceManager.instances;
      for (final instance in instances) {
        final size = await _instanceManager.getInstanceSize(instance.id);
        _instanceSizes[instance.id] = size;
      }
    } catch (e) {
      _logger.warning('Failed to load instance sizes', e);
    }
  }

  Future<void> _loadInstances() async {
    try {
      await _instanceManager.initialize();
      await _loadInstanceSizes();
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load instances', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  /// 模糊搜索匹配
  bool _matchesSearch(GameInstance instance, String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return instance.name.toLowerCase().contains(lowerQuery) ||
        instance.version.toLowerCase().contains(lowerQuery) ||
        (instance.loader?.toLowerCase().contains(lowerQuery) ?? false) ||
        (instance.description?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// 排序实例列表
  List<GameInstance> _sortInstances(List<GameInstance> instances) {
    final sorted = List<GameInstance>.from(instances);

    sorted.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case InstanceSortOption.name:
          comparison = a.name.compareTo(b.name);
        case InstanceSortOption.lastPlayed:
          final aTime = a.lastPlayed ?? DateTime(1970);
          final bTime = b.lastPlayed ?? DateTime(1970);
          comparison = aTime.compareTo(bTime);
        case InstanceSortOption.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
        case InstanceSortOption.size:
          final aSize = _instanceSizes[a.id] ?? 0;
          final bSize = _instanceSizes[b.id] ?? 0;
          comparison = aSize.compareTo(bSize);
      }

      return _sortDirection == SortDirection.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  /// 过滤和排序实例
  List<GameInstance> _filterAndSortInstances(List<GameInstance> instances) {
    // 先过滤
    final filtered = instances.where((i) => _matchesSearch(i, _searchQuery)).toList();
    // 再排序
    return _sortInstances(filtered);
  }

  void _createInstance() async {
    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '创建新实例',
      width: 500,
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '创建',
          onPressed: () {
            Navigator.pop(context, 'new_instance');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '实例名称',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '输入实例名称',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '游戏版本',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '1.20.4',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        if (_instanceManager.directories.isEmpty) {
          await _createDirectory();
          return;
        }

        final directoryId = _instanceManager.selectedDirectoryId ?? _instanceManager.directories.first.id;
        final instance = await _instanceManager.createInstance(
          name: 'New Instance',
          directoryId: directoryId,
          version: '1.20.4',
        );
        _instanceSizes[instance.id] = 0;
        setState(() {});
        _showSuccess('实例创建成功！');
      } catch (e) {
        _showError('创建失败: $e');
      }
    }
  }

  Future<void> _createDirectory() async {
    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '创建游戏目录',
      width: 500,
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '创建',
          onPressed: () => Navigator.pop(context, 'create'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '目录名称',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '我的游戏',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '目录路径',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'C:/Games/Minecraft',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await _instanceManager.createDirectory(
          name: '主目录',
          path: 'C:/Games/Minecraft',
        );
        setState(() {});
        _showSuccess('目录创建成功！');
      } catch (e) {
        _showError('创建失败: $e');
      }
    }
  }

  void _launchInstance(GameInstance instance) async {
    try {
      _showSuccess('正在启动: ${instance.name}');
    } catch (e) {
      _showError('启动失败: $e');
    }
  }

  void _editInstance(GameInstance instance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstanceConfigPage(instanceId: instance.id),
      ),
    );
  }

  void _deleteInstance(GameInstance instance) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除实例',
      content: '确定要删除实例 "${instance.name}" 吗？此操作不可撤销！',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
      cancelText: '取消',
    );

    if (confirmed == true && mounted) {
      try {
        await _instanceManager.deleteInstance(instance.id);
        _instanceSizes.remove(instance.id);
        setState(() {});
        _showSuccess('实例已删除');
      } catch (e) {
        _showError('删除失败: $e');
      }
    }
  }

  void _duplicateInstance(GameInstance instance) async {
    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '复制实例',
      width: 500,
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '复制',
          onPressed: () => Navigator.pop(context, 'duplicate'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '新实例名称',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '${instance.name} (副本)',
              filled: true,
              fillColor: BAColors.surfaceVariantOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final newInstance = await _instanceManager.duplicateInstance(
          instance.id,
          '${instance.name} (副本)',
        );
        _instanceSizes[newInstance.id] = _instanceSizes[instance.id] ?? 0;
        setState(() {});
        _showSuccess('实例已复制');
      } catch (e) {
        _showError('复制失败: $e');
      }
    }
  }

  void _selectInstance(GameInstance instance) async {
    try {
      await _instanceManager.selectInstance(instance.id);
      setState(() {});
    } catch (e) {
      _showError('选择失败: $e');
    }
  }

  void _editDirectory(GameDirectory directory) {
    _showSuccess('编辑目录: ${directory.name}');
  }

  void _deleteDirectory(GameDirectory directory) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除目录',
      content: '确定要删除目录 "${directory.name}" 吗？此操作不可撤销！',
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
      cancelText: '取消',
    );

    if (confirmed == true && mounted) {
      try {
        await _instanceManager.deleteDirectory(directory.id);
        setState(() {});
        _showSuccess('目录已删除');
      } catch (e) {
        _showError('删除失败: $e');
      }
    }
  }

  Future<void> _importModpack() async {
    try {
      final instanceId = await ModpackImportDialog.show(context);
      if (instanceId != null && mounted) {
        await _loadInstanceSizes();
        setState(() {});
        _showSuccess('整合包导入成功！');
      }
    } catch (e) {
      _showError('导入失败: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.successOf(context),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.dangerOf(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示排序选项菜单
  void _showSortMenu() async {
    final selected = await showMenu<InstanceSortOption>(
      context: context,
      position: RelativeRect.fromLTRB(200, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: InstanceSortOption.name,
          child: Row(
            children: [
              if (_sortOption == InstanceSortOption.name)
                Icon(Icons.check, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('名称'),
            ],
          ),
        ),
        PopupMenuItem(
          value: InstanceSortOption.lastPlayed,
          child: Row(
            children: [
              if (_sortOption == InstanceSortOption.lastPlayed)
                Icon(Icons.check, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('最近启动'),
            ],
          ),
        ),
        PopupMenuItem(
          value: InstanceSortOption.createdAt,
          child: Row(
            children: [
              if (_sortOption == InstanceSortOption.createdAt)
                Icon(Icons.check, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('创建时间'),
            ],
          ),
        ),
        PopupMenuItem(
          value: InstanceSortOption.size,
          child: Row(
            children: [
              if (_sortOption == InstanceSortOption.size)
                Icon(Icons.check, size: 18, color: BAColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('大小'),
            ],
          ),
        ),
      ],
    );

    if (selected != null) {
      setState(() {
        _sortOption = selected;
      });
      _saveUserPreferences();
    }
  }

  /// 切换排序方向
  void _toggleSortDirection() {
    setState(() {
      _sortDirection = _sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    });
    _saveUserPreferences();
  }

  /// 获取排序选项显示文本
  String _getSortOptionText() {
    switch (_sortOption) {
      case InstanceSortOption.name:
        return '名称';
      case InstanceSortOption.lastPlayed:
        return '最近启动';
      case InstanceSortOption.createdAt:
        return '创建时间';
      case InstanceSortOption.size:
        return '大小';
    }
  }

  /// 格式化文件大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedDirectory = _instanceManager.selectedDirectory;
    final instances = selectedDirectory != null
        ? _instanceManager.getDirectoryInstances(selectedDirectory.id)
        : <GameInstance>[];

    final filteredInstances = _filterAndSortInstances(instances);

    return Column(
      children: [
        _buildHeader(),
        if (_instanceManager.directories.isNotEmpty) _buildDirectorySelector(),
        _buildSearchAndSortBar(),
        Expanded(
          child: filteredInstances.isEmpty
              ? _buildEmptyState()
              : _buildInstancesList(filteredInstances),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(bottom: BorderSide(color: BAColors.borderOf(context))),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 32, color: BAColors.primaryOf(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '实例管理',
                  style: BATypography.headlineMedium.copyWith(color: BAColors.textPrimaryOf(context)),
                ),
                Text(
                  '管理你的所有游戏实例',
                  style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_view : Icons.view_list,
              color: BAColors.textSecondaryOf(context),
            ),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          const SizedBox(width: 12),
          BASecondaryButton(
            text: '导入整合包',
            onPressed: _importModpack,
            leadingIcon: const Icon(Icons.archive, size: 18),
          ),
          const SizedBox(width: 12),
          BAPrimaryButton(
            text: '创建实例',
            onPressed: _createInstance,
            leadingIcon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        border: Border(bottom: BorderSide(color: BAColors.borderOf(context))),
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索实例...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _saveUserPreferences();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: BAColors.surfaceOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: BAColors.borderOf(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _saveUserPreferences();
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 排序选项
          Container(
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BAColors.borderOf(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _showSortMenu,
                  icon: const Icon(Icons.sort, size: 18),
                  label: Text(_getSortOptionText()),
                  style: TextButton.styleFrom(
                    foregroundColor: BAColors.textPrimaryOf(context),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: BAColors.borderOf(context))),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _sortDirection == SortDirection.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 18,
                    ),
                    onPressed: _toggleSortDirection,
                    tooltip: _sortDirection == SortDirection.ascending ? '升序' : '降序',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        border: Border(bottom: BorderSide(color: BAColors.borderOf(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _instanceManager.directories.map((dir) {
                final isSelected = _instanceManager.selectedDirectoryId == dir.id;
                return FilterChip(
                  selected: isSelected,
                  label: Text(dir.name),
                  onSelected: (_) => _selectDirectory(dir),
                  selectedColor: BAColors.primaryOf(context).withOpacity(0.2),
                  checkmarkColor: BAColors.primaryOf(context),
                  backgroundColor: BAColors.surfaceOf(context),
                  deleteIcon: isSelected
                      ? null
                      : Icon(Icons.close, color: BAColors.textDisabledOf(context)),
                  onDeleted: isSelected ? null : () => _deleteDirectory(dir),
                );
              }).toList(),
            ),
          ),
          BASecondaryButton(
            text: '添加目录',
            onPressed: _createDirectory,
            leadingIcon: const Icon(Icons.create_new_folder, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInstancesList(List<GameInstance> instances) {
    if (_showGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: instances.length,
        itemBuilder: (context, index) => _buildInstanceCard(instances[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: instances.length,
      itemBuilder: (context, index) => _buildInstanceListItem(instances[index]),
    );
  }

  Widget _buildInstanceCard(GameInstance instance) {
    final isSelected = _instanceManager.selectedInstanceId == instance.id;
    final size = _instanceSizes[instance.id] ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primaryOf(context).withOpacity(0.1) : BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BAColors.primaryOf(context) : BAColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: BAColors.primaryOf(context).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _selectInstance(instance),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: BAColors.primaryOf(context).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.gamepad,
                          size: 48,
                          color: BAColors.primaryOf(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    instance.name,
                    style: BATypography.titleMedium.copyWith(color: BAColors.textPrimaryOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${instance.version}${instance.loader != null ? ' • ${instance.loader}' : ''}',
                          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (size > 0)
                        Text(
                          _formatSize(size),
                          style: BATypography.bodySmall.copyWith(color: BAColors.textDisabledOf(context)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: BAPrimaryButton(
                          text: '启动',
                          onPressed: () => _launchInstance(instance),
                          leadingIcon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: BAColors.textSecondaryOf(context)),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editInstance(instance);
                            case 'duplicate':
                              _duplicateInstance(instance);
                            case 'delete':
                              _deleteInstance(instance);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('编辑'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 18),
                                SizedBox(width: 8),
                                Text('复制'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: BAColors.dangerOf(context)),
                                const SizedBox(width: 8),
                                Text('删除', style: TextStyle(color: BAColors.dangerOf(context))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstanceListItem(GameInstance instance) {
    final isSelected = _instanceManager.selectedInstanceId == instance.id;
    final size = _instanceSizes[instance.id] ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primaryOf(context).withOpacity(0.1) : BAColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BAColors.primaryOf(context) : BAColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _selectInstance(instance),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: BAColors.primaryOf(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gamepad,
                      size: 32,
                      color: BAColors.primaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.name,
                          style: BATypography.titleMedium.copyWith(color: BAColors.textPrimaryOf(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${instance.version}${instance.loader != null ? ' • ${instance.loader}' : ''}',
                          style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                        ),
                        if (size > 0)
                          Text(
                            _formatSize(size),
                            style: BATypography.bodySmall.copyWith(color: BAColors.textDisabledOf(context)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  BAPrimaryButton(
                    text: '启动',
                    onPressed: () => _launchInstance(instance),
                    leadingIcon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: BAColors.textSecondaryOf(context)),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editInstance(instance);
                        case 'duplicate':
                          _duplicateInstance(instance);
                        case 'delete':
                          _deleteInstance(instance);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18),
                            SizedBox(width: 8),
                            Text('复制'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: BAColors.dangerOf(context)),
                            const SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: BAColors.dangerOf(context))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off : Icons.extension,
            size: 80,
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            hasSearchQuery ? '没有找到匹配的实例' : '还没有游戏实例',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery ? '尝试修改搜索关键词' : '创建一个实例来开始游戏',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 32),
          if (hasSearchQuery)
            BASecondaryButton(
              text: '清除搜索',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _saveUserPreferences();
              },
            )
          else
            BAPrimaryButton(
              text: '创建实例',
              onPressed: _createInstance,
              leadingIcon: const Icon(Icons.add, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDirectory(GameDirectory directory) async {
    try {
      await _instanceManager.selectDirectory(directory.id);
      setState(() {});
    } catch (e) {
      _showError('选择失败: $e');
    }
  }
}
