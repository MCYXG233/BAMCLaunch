import 'package:flutter/material.dart';
import '../models.dart';
import '../instance_manager.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/ba_buttons.dart';
import '../../ui/components/ba_dialog.dart';
import '../../core/logger.dart';
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

  bool _isLoading = true;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    try {
      await _instanceManager.initialize();
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load instances', e, stackTrace);
      setState(() => _isLoading = false);
    }
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
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '输入实例名称',
              filled: true,
              fillColor: BAColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '游戏版本',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '1.20.4',
              filled: true,
              fillColor: BAColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primary, width: 2),
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
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '我的游戏',
              filled: true,
              fillColor: BAColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '目录路径',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'C:/Games/Minecraft',
              filled: true,
              fillColor: BAColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BAColors.primary, width: 2),
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
        setState(() {});
        _showSuccess('实例已删除');
      } catch (e) {
        _showError('删除失败: $e');
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
        backgroundColor: BAColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.background,
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

    return Column(
      children: [
        _buildHeader(),
        if (_instanceManager.directories.isNotEmpty) _buildDirectorySelector(),
        Expanded(
          child: instances.isEmpty
              ? _buildEmptyState()
              : _buildInstancesList(instances),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BAColors.surface,
        border: Border(bottom: BorderSide(color: BAColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 32, color: BAColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '实例管理',
                  style: BATypography.headlineMedium.copyWith(color: BAColors.textPrimary),
                ),
                Text(
                  '管理你的所有游戏实例',
                  style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_view : Icons.view_list,
              color: BAColors.textSecondary,
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

  Widget _buildDirectorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: BAColors.border)),
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
                  selectedColor: BAColors.primary.withOpacity(0.2),
                  checkmarkColor: BAColors.primary,
                  backgroundColor: BAColors.surface,
                  deleteIcon: isSelected
                      ? null
                      : Icon(Icons.close, color: BAColors.textDisabled),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primary.withOpacity(0.1) : BAColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BAColors.primary : BAColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: BAColors.primary.withOpacity(0.2),
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
                        color: BAColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.gamepad,
                          size: 48,
                          color: BAColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    instance.name,
                    style: BATypography.titleMedium.copyWith(color: BAColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${instance.version}${instance.loader != null ? ' • ${instance.loader}' : ''}',
                    style: BATypography.bodySmall.copyWith(color: BAColors.textSecondary),
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
                      IconButton(
                        icon: Icon(Icons.edit, color: BAColors.textSecondary),
                        onPressed: () => _editInstance(instance),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: BAColors.danger),
                        onPressed: () => _deleteInstance(instance),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primary.withOpacity(0.1) : BAColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BAColors.primary : BAColors.border,
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
                      color: BAColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gamepad,
                      size: 32,
                      color: BAColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.name,
                          style: BATypography.titleMedium.copyWith(color: BAColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${instance.version}${instance.loader != null ? ' • ${instance.loader}' : ''}',
                          style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
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
                  IconButton(
                    icon: Icon(Icons.edit, color: BAColors.textSecondary),
                    onPressed: () => _editInstance(instance),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: BAColors.danger),
                    onPressed: () => _deleteInstance(instance),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension,
            size: 80,
            color: BAColors.textDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            '还没有游戏实例',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '创建一个实例来开始游戏',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
          ),
          const SizedBox(height: 32),
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
