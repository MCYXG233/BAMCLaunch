import 'package:flutter/material.dart';
import '../extension_manager.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/ba_buttons.dart';
import '../../ui/components/ba_dialog.dart';
import '../../core/logger.dart';

/// 扩展管理页面
class ExtensionManagerPage extends StatefulWidget {
  const ExtensionManagerPage({super.key});

  @override
  State<ExtensionManagerPage> createState() => _ExtensionManagerPageState();
}

class _ExtensionManagerPageState extends State<ExtensionManagerPage> {
  final Logger _logger = Logger('ExtensionManagerPage');
  final ExtensionManager _extensionManager = ExtensionManager.instance;

  bool _isLoading = true;
  bool _showOnlyEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  Future<void> _loadExtensions() async {
    try {
      await _extensionManager.initialize();
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load extensions', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  void _installExtension() async {
    final result = await BAFrostedDialog.show<String>(
      context: context,
      title: '安装扩展',
      width: 500,
      actions: [
        BASecondaryButton(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: '选择文件',
          onPressed: () => Navigator.pop(context, 'select'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '扩展路径',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '选择扩展文件�?..',
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
              prefixIcon: Icon(Icons.folder_open, color: BAColors.textSecondaryOf(context)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '支持的格�?,
            style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 4),
          Text(
            '�?.zip 扩展�?,
            style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          Text(
            '�?包含 manifest.json 的文件夹',
            style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _showSuccess('请选择扩展文件');
    }
  }

  void _toggleExtension(ExtensionInfo extension) async {
    try {
      if (extension.status == ExtensionStatus.enabled) {
        await _extensionManager.disableExtension(extension.id);
        _showSuccess('已禁�? ${extension.name}');
      } else {
        await _extensionManager.enableExtension(extension.id);
        _showSuccess('已启�? ${extension.name}');
      }
      setState(() {});
    } catch (e) {
      _showError('操作失败: $e');
    }
  }

  void _uninstallExtension(ExtensionInfo extension) async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '卸载扩展',
      content: '确定要卸载扩�?"${extension.name}" 吗？此操作不可撤销�?,
      confirmText: '卸载',
      confirmButtonStyle: BAButtonStyle.danger,
      cancelText: '取消',
    );

    if (confirmed == true && mounted) {
      try {
        await _extensionManager.uninstallExtension(extension.id);
        setState(() {});
        _showSuccess('已卸�? ${extension.name}');
      } catch (e) {
        _showError('卸载失败: $e');
      }
    }
  }

  void _showExtensionDetails(ExtensionInfo extension) {
    showDialog(
      context: context,
      builder: (context) => BAFrostedDialog(
        title: extension.name,
        width: 600,
        actions: [
          BASecondaryButton(
            text: '关闭',
            onPressed: () => Navigator.pop(context),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              extension.description,
              style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: '版本',
                    value: extension.version,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    label: '作�?,
                    value: extension.author,
                  ),
                ),
              ],
            ),
            if (extension.homepage != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.link, color: BAColors.primaryOf(context), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    extension.homepage!,
                    style: BATypography.bodyMedium.copyWith(color: BAColors.primaryOf(context)),
                  ),
                ],
              ),
            ],
            if (extension.license != null) ...[
              const SizedBox(height: 16),
              _DetailItem(
                label: '许可�?,
                value: extension.license!,
              ),
            ],
            if (extension.permissions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '权限',
                style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: extension.permissions.map((permission) {
                  return Chip(
                    label: Text(permission),
                    backgroundColor: BAColors.surfaceVariantOf(context),
                    labelStyle: BATypography.bodySmall.copyWith(
                      color: BAColors.textSecondaryOf(context),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BAColors.dangerOf(context),
        duration: const Duration(seconds: 3),
      ),
    );
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
    var extensions = _extensionManager.extensions;
    if (_showOnlyEnabled) {
      extensions = extensions.where((e) => e.status == ExtensionStatus.enabled).toList();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: extensions.isEmpty
              ? _buildEmptyState()
              : _buildExtensionsList(extensions),
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
          Icon(Icons.extension, size: 32, color: BAColors.primaryOf(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '扩展管理',
                  style: BATypography.headlineMedium.copyWith(color: BAColors.textPrimaryOf(context)),
                ),
                Text(
                  '管理和扩展启动器功能',
                  style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          FilterChip(
            selected: _showOnlyEnabled,
            label: const Text('仅显示已启用'),
            onSelected: (selected) => setState(() => _showOnlyEnabled = selected),
            selectedColor: BAColors.primaryOf(context).withOpacity(0.2),
            checkmarkColor: BAColors.primaryOf(context),
            backgroundColor: BAColors.surfaceVariantOf(context),
          ),
          const SizedBox(width: 12),
          BAPrimaryButton(
            text: '安装扩展',
            onPressed: _installExtension,
            leadingIcon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionsList(List<ExtensionInfo> extensions) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: extensions.length,
      itemBuilder: (context, index) => _buildExtensionCard(extensions[index]),
    );
  }

  Widget _buildExtensionCard(ExtensionInfo extension) {
    final isEnabled = extension.status == ExtensionStatus.enabled;
    final hasError = extension.status == ExtensionStatus.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasError ? BAColors.dangerOf(context).withOpacity(0.05) : BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? BAColors.dangerOf(context).withOpacity(0.3) : BAColors.borderOf(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isEnabled
                  ? BAColors.primaryOf(context).withOpacity(0.15)
                  : BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.extension,
              size: 32,
              color: isEnabled ? BAColors.primaryOf(context) : BAColors.textDisabledOf(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      extension.name,
                      style: BATypography.titleMedium.copyWith(
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? BAColors.successOf(context).withOpacity(0.1)
                            : BAColors.surfaceVariantOf(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEnabled ? '已启�? : '已禁�?,
                        style: BATypography.label.copyWith(
                          color: isEnabled ? BAColors.successOf(context) : BAColors.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  extension.description,
                  style: BATypography.bodyMedium.copyWith(
                    color: BAColors.textSecondaryOf(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: BAColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      extension.author,
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.label,
                      size: 16,
                      color: BAColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v${extension.version}',
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                if (hasError && extension.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    extension.error!,
                    style: BATypography.bodySmall.copyWith(color: BAColors.dangerOf(context)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: BAColors.textSecondaryOf(context),
            ),
            onPressed: () => _showExtensionDetails(extension),
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => _toggleExtension(extension),
            activeColor: BAColors.primaryOf(context),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: BAColors.dangerOf(context),
            ),
            onPressed: () => _uninstallExtension(extension),
          ),
        ],
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
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有安装扩�?,
            style: BATypography.headlineSmall.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            '安装扩展来增强启动器功能',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 32),
          BAPrimaryButton(
            text: '安装扩展',
            onPressed: _installExtension,
            leadingIcon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: BATypography.bodyMedium.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
      ],
    );
  }
}
