import 'package:flutter/material.dart';
import '../models.dart';
import '../instance_manager.dart';
import '../resource_manager.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/ba_buttons.dart';
import '../../ui/components/ba_dialog.dart';
import '../../core/logger.dart';

/// 实例管理页面
class InstancePage extends StatefulWidget {
  const InstancePage({super.key});

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  final Logger _logger = Logger('InstancePage');
  final InstanceManager _instanceManager = InstanceManager.instance;
  final ResourceManager _resourceManager = ResourceManager.instance;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _instanceManager.initialize();
      await _resourceManager.initialize();
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize instance managers', e, stackTrace);
      if (mounted) {
        _showError('初始化失�? $e');
      }
      setState(() => _isLoading = false);
    }
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.successOf(context),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createInstance() async {
    final nameController = TextEditingController();
    final versionController = TextEditingController(text: '1.20.4');

    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '创建游戏实例',
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
            if (nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, nameController.text.trim());
            }
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '实例名称',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: '我的游戏实例',
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
            controller: versionController,
            decoration: InputDecoration(
              hintText: '例如: 1.20.4',
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

    if (result != null) {
      try {
        final directoryId = _instanceManager.selectedDirectory?.id;
        if (directoryId == null && _instanceManager.directories.isEmpty) {
          await _createDirectory();
          return;
        }

        final directory = directoryId ?? _instanceManager.directories.first.id;

        await _instanceManager.createInstance(
          name: result,
          directoryId: directory,
          version: versionController.text.trim(),
        );

        setState(() {});
        _showSuccess('实例创建成功!');
      } catch (e, stackTrace) {
        _logger.error('Failed to create instance', e, stackTrace);
        _showError('创建失败: $e');
      }
    }
  }

  Future<void> _createDirectory() async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    final result = await BAFrostedDialog.show<Map<String, String>>(
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
          onPressed: () {
            if (nameController.text.trim().isNotEmpty && pathController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'path': pathController.text.trim(),
              });
            }
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目录名称',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: '主游戏目�?,
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
            controller: pathController,
            decoration: InputDecoration(
              hintText: 'C:\\Games\\Minecraft\\Instances',
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

    if (result != null) {
      try {
        await _instanceManager.createDirectory(
          name: result['name']!,
          path: result['path']!,
        );
        setState(() {});
        _showSuccess('目录创建成功!');
      } catch (e, stackTrace) {
        _logger.error('Failed to create directory', e, stackTrace);
        _showError('创建失败: $e');
      }
    }
  }

  Future<void> _deleteInstance(GameInstance instance) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除实例',
      content: '确定要删除实�?${instance.name}"�? 此操作不可撤销�?,
      confirmText: '删除',
      confirmButtonStyle: BAButtonStyle.danger,
      cancelText: '取消',
    );

    if (confirmed == true) {
      try {
        await _instanceManager.deleteInstance(instance.id);
        setState(() {});
        _showSuccess('实例已删�?');
      } catch (e, stackTrace) {
        _logger.error('Failed to delete instance', e, stackTrace);
        _showError('删除失败: $e');
      }
    }
  }

  Future<void> _selectInstance(GameInstance instance) async {
    try {
      await _instanceManager.selectInstance(instance.id);
      setState(() {});
    } catch (e, stackTrace) {
      _logger.error('Failed to select instance', e, stackTrace);
      _showError('选择失败: $e');
    }
  }

  Widget _buildInstanceCard(GameInstance instance, bool isSelected) {
    final instanceResources = _resourceManager.getInstanceResources(instance.id);

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
                      color: BAColors.primaryOf(context).withOpacity(0.1),
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
                          style: BATypography.headlineSmall.copyWith(
                            color: BAColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${instance.version}${instance.loader != null ? ' �?${instance.loader}' : ''}',
                          style: BATypography.bodyMedium.copyWith(
                            color: BAColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: BAColors.secondaryOf(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${instanceResources.length} 个资�?,
                                style: BATypography.label.copyWith(
                                  color: BAColors.secondaryOf(context),
                                ),
                              ),
                            ),
                            if (instance.lastPlayed != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '上次游玩: ${_formatDate(instance.lastPlayed!)}',
                                style: BATypography.bodySmall.copyWith(
                                  color: BAColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isSelected)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: BAColors.dangerOf(context)),
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

  Widget _buildDirectorySelector() {
    if (_instanceManager.directories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
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
                  onSelected: (_) async {
                    try {
                      await _instanceManager.selectDirectory(dir.id);
                      setState(() {});
                    } catch (e) {
                      _showError('切换目录失败: $e');
                    }
                  },
                  selectedColor: BAColors.primaryOf(context).withOpacity(0.2),
                  checkmarkColor: BAColors.primaryOf(context),
                  backgroundColor: BAColors.surfaceVariantOf(context),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          BASecondaryButton(
            text: '新建目录',
            onPressed: _createDirectory,
            leadingIcon: const Icon(Icons.create_new_folder, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_instanceManager.directories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: BAColors.textDisabledOf(context)),
            const SizedBox(height: 16),
            Text(
              '还没有游戏目�?,
              style: BATypography.headlineSmall.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建一个游戏目录来开始使用实例管�?,
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 24),
            BAPrimaryButton(
              text: '创建游戏目录',
              onPressed: _createDirectory,
              leadingIcon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      );
    }

    final directoryInstances = _instanceManager.selectedDirectoryId != null
        ? _instanceManager.getDirectoryInstances(_instanceManager.selectedDirectoryId!)
        : <GameInstance>[];

    if (directoryInstances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gamepad, size: 64, color: BAColors.textDisabledOf(context)),
            const SizedBox(height: 16),
            Text(
              '还没有游戏实�?,
              style: BATypography.headlineSmall.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建一个实例来开始游�?,
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 24),
            BAPrimaryButton(
              text: '创建实例',
              onPressed: _createInstance,
              leadingIcon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: directoryInstances.map((instance) {
        final isSelected = _instanceManager.selectedInstanceId == instance.id;
        return _buildInstanceCard(instance, isSelected);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: Column(
        children: [
          Container(
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
                        style: BATypography.headlineMedium.copyWith(
                          color: BAColors.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        '管理游戏实例和集中资�?,
                        style: BATypography.bodyMedium.copyWith(
                          color: BAColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_instanceManager.directories.isNotEmpty)
                  BAPrimaryButton(
                    text: '创建实例',
                    onPressed: _createInstance,
                    leadingIcon: const Icon(Icons.add, color: Colors.white),
                  ),
              ],
            ),
          ),
          _buildDirectorySelector(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

