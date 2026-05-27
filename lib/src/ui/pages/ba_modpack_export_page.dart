import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/ba_theme_colors.dart';
import '../../instance/instance_manager.dart';
import '../../instance/models.dart';
import '../../modpack/modpack_exporter.dart';
import '../components/ba_notification.dart';

class BAModpackExportPage extends StatefulWidget {
  final String instanceId;

  const BAModpackExportPage({
    super.key,
    required this.instanceId,
  });

  @override
  State<BAModpackExportPage> createState() => _BAModpackExportPageState();
}

class _BAModpackExportPageState extends State<BAModpackExportPage> {
  final InstanceManager _instanceManager = InstanceManager.instance;
  bool _notificationInitialized = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _versionController;
  late TextEditingController _authorController;

  GameInstance? _instance;
  bool _isLoading = true;
  bool _isExporting = false;
  double _exportProgress = 0;
  String? _exportStatus;

  ModpackExportFormat _selectedFormat = ModpackExportFormat.bamc;
  bool _includeMods = true;
  bool _includeConfig = true;
  bool _includeSaves = true;
  bool _includeResourcePacks = true;
  bool _includeShaderPacks = true;
  bool _includeScreenshots = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _versionController = TextEditingController(text: '1.0.0');
    _authorController = TextEditingController();
    _loadInstance();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationInitialized) {
      NotificationManager().init(context);
      _notificationInitialized = true;
    }
  }

  Future<void> _loadInstance() async {
    try {
      if (!_instanceManager.isInitialized) {
        await _instanceManager.initialize();
      }

      final instance = _instanceManager.instances.firstWhere(
        (i) => i.id == widget.instanceId,
        orElse: () => throw Exception('实例不存在'),
      );

      if (mounted) {
        setState(() {
          _instance = instance;
          _nameController.text = instance.name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationManager().showError('加载实例失败', message: e.toString());
      }
    }
  }

  Future<void> _startExport() async {
    if (_instance == null) return;
    if (_nameController.text.trim().isEmpty) {
      NotificationManager().showWarning('请输入整合包名称');
      return;
    }

    final options = ModpackExportOptions(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      version: _versionController.text.trim().isEmpty
          ? '1.0.0'
          : _versionController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      format: _selectedFormat,
      includeMods: _includeMods,
      includeConfig: _includeConfig,
      includeSaves: _includeSaves,
      includeResourcePacks: _includeResourcePacks,
      includeShaderPacks: _includeShaderPacks,
      includeScreenshots: _includeScreenshots,
    );

    String extension;
    String formatName;
    switch (_selectedFormat) {
      case ModpackExportFormat.curseforge:
        extension = 'zip';
        formatName = 'CurseForge';
      case ModpackExportFormat.modrinth:
        extension = 'mrpack';
        formatName = 'Modrinth';
      case ModpackExportFormat.bamc:
        extension = 'zip';
        formatName = 'BAMC';
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '导出整合包 - $formatName格式',
      fileName: '${_nameController.text.trim()}.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
    );

    if (outputPath == null) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0;
      _exportStatus = '准备导出...';
    });

    try {
      await ModpackExporter.exportModpack(
        instanceId: widget.instanceId,
        outputPath: outputPath,
        options: options,
        onProgress: (completed, total, currentTask) {
          if (mounted && total > 0) {
            setState(() {
              _exportProgress = completed / total;
              _exportStatus = currentTask;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 1.0;
          _exportStatus = null;
        });
        NotificationManager().showSuccess(
          '导出成功',
          message: '整合包已导出到: $outputPath',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0;
          _exportStatus = null;
        });
        NotificationManager().showError('导出失败', message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: BAThemeColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BAThemeColors.primary),
          ),
        ),
      );
    }

    return Container(
      color: BAThemeColors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 16),
                  _buildFormatSection(),
                  const SizedBox(height: 16),
                  _buildContentSection(),
                  const SizedBox(height: 24),
                  _buildExportButton(),
                  if (_isExporting) ...[
                    const SizedBox(height: 16),
                    _buildProgressSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BAThemeColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BAThemeColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: BAThemeColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          '导出整合包',
          style: TextStyle(
            color: BAThemeColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BAThemeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: BAThemeColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: BAThemeColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: BAThemeColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: BAThemeColors.border.withOpacity(0.5),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: '基本信息',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          label: '整合包名称',
          controller: _nameController,
          placeholder: '输入整合包名称',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: '描述',
          controller: _descriptionController,
          placeholder: '输入整合包描述（可选）',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: '版本号',
                controller: _versionController,
                placeholder: '1.0.0',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: '作者',
                controller: _authorController,
                placeholder: '输入作者名（可选）',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return _buildSectionCard(
      title: '导出格式',
      icon: Icons.folder_zip,
      children: [
        _buildFormatOption(
          format: ModpackExportFormat.bamc,
          title: 'BAMC 格式',
          subtitle: 'BAMC Launcher 原生格式，ZIP + instance.json',
          icon: Icons.rocket_launch,
        ),
        const SizedBox(height: 8),
        _buildFormatOption(
          format: ModpackExportFormat.curseforge,
          title: 'CurseForge 格式',
          subtitle: '兼容 CurseForge，使用 manifest.json',
          icon: Icons.public,
        ),
        const SizedBox(height: 8),
        _buildFormatOption(
          format: ModpackExportFormat.modrinth,
          title: 'Modrinth 格式',
          subtitle: '兼容 Modrinth，使用 modrinth.index.json',
          icon: Icons.hexagon,
        ),
      ],
    );
  }

  Widget _buildFormatOption({
    required ModpackExportFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFormat = format;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? BAThemeColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? BAThemeColors.primary : BAThemeColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<ModpackExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFormat = value;
                    });
                  }
                },
                activeColor: BAThemeColors.primary,
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? BAThemeColors.primary.withOpacity(0.2)
                      : BAThemeColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? BAThemeColors.primary
                      : BAThemeColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? BAThemeColors.textPrimary
                            : BAThemeColors.textSecondary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: BAThemeColors.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return _buildSectionCard(
      title: '包含内容',
      icon: Icons.checklist,
      children: [
        _buildSwitchItem(
          icon: Icons.extension,
          title: '模组',
          value: _includeMods,
          onChanged: (value) => setState(() => _includeMods = value),
        ),
        Divider(
          color: BAThemeColors.border.withOpacity(0.3),
          height: 1,
          indent: 48,
        ),
        _buildSwitchItem(
          icon: Icons.settings,
          title: '配置文件',
          value: _includeConfig,
          onChanged: (value) => setState(() => _includeConfig = value),
        ),
        Divider(
          color: BAThemeColors.border.withOpacity(0.3),
          height: 1,
          indent: 48,
        ),
        _buildSwitchItem(
          icon: Icons.map,
          title: '存档',
          value: _includeSaves,
          onChanged: (value) => setState(() => _includeSaves = value),
        ),
        Divider(
          color: BAThemeColors.border.withOpacity(0.3),
          height: 1,
          indent: 48,
        ),
        _buildSwitchItem(
          icon: Icons.palette,
          title: '资源包',
          value: _includeResourcePacks,
          onChanged: (value) => setState(() => _includeResourcePacks = value),
        ),
        Divider(
          color: BAThemeColors.border.withOpacity(0.3),
          height: 1,
          indent: 48,
        ),
        _buildSwitchItem(
          icon: Icons.brightness_7,
          title: '光影包',
          value: _includeShaderPacks,
          onChanged: (value) => setState(() => _includeShaderPacks = value),
        ),
        Divider(
          color: BAThemeColors.border.withOpacity(0.3),
          height: 1,
          indent: 48,
        ),
        _buildSwitchItem(
          icon: Icons.photo_camera,
          title: '截图',
          value: _includeScreenshots,
          onChanged: (value) => setState(() => _includeScreenshots = value),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: MouseRegion(
        cursor: _isExporting ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _isExporting ? null : _startExport,
          child: Container(
            decoration: BoxDecoration(
              gradient: _isExporting
                  ? LinearGradient(
                      colors: [
                        BAThemeColors.textDisabled,
                        BAThemeColors.textDisabled,
                      ],
                    )
                  : BAThemeColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isExporting
                  ? []
                  : [
                      BoxShadow(
                        color: BAThemeColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_upload, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '导出整合包',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading,
                color: BAThemeColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _exportStatus ?? '正在导出...',
                style: const TextStyle(
                  color: BAThemeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _exportProgress,
              backgroundColor: BAThemeColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(BAThemeColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(_exportProgress * 100).toInt()}%',
              style: const TextStyle(
                color: BAThemeColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BAThemeColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: BAThemeColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: BAThemeColors.textDisabled,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: BAThemeColors.surfaceVariant.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: BAThemeColors.border.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: BAThemeColors.border.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: BAThemeColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value
                  ? BAThemeColors.primary.withOpacity(0.15)
                  : BAThemeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? BAThemeColors.primary : BAThemeColors.textDisabled,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: value
                    ? BAThemeColors.textPrimary
                    : BAThemeColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BAThemeColors.primary,
          ),
        ],
      ),
    );
  }
}
