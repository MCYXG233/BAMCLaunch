import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/error_codes.dart';
import '../../instance/instance_manager.dart';
import '../../version/version_manager.dart';
import '../../version/models.dart';
import '../../loader/loader_download_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_buttons.dart';
import 'ba_notification.dart';

enum _ModLoader { vanilla, forge, fabric, neoforge, quilt }

class BACreateInstanceDialog extends StatefulWidget {
  const BACreateInstanceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const BACreateInstanceDialog(),
    );
  }

  @override
  State<BACreateInstanceDialog> createState() => _BACreateInstanceDialogState();
}

class _BACreateInstanceDialogState extends State<BACreateInstanceDialog> {
  int _currentStep = 0;

  final _nameController = TextEditingController();
  String? _nameError;

  List<GameVersion> _versions = [];
  bool _versionsLoading = false;
  String? _versionsError;
  GameVersion? _selectedVersion;

  _ModLoader _selectedLoader = _ModLoader.vanilla;
  List<String> _loaderVersions = [];
  bool _loaderVersionsLoading = false;
  String? _loaderVersionsError;
  String? _selectedLoaderVersion;

  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = '请输入实例名称');
        return;
      }
      setState(() => _nameError = null);
    }
    if (_currentStep == 1 && _selectedVersion == null) {
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      if (_currentStep == 1) _fetchVersions();
      if (_currentStep == 3) _updateSummary();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _fetchVersions() async {
    if (_versions.isNotEmpty) return;
    setState(() {
      _versionsLoading = true;
      _versionsError = null;
    });
    try {
      final versions = await VersionManager().fetchVersionList();
      if (mounted) {
        setState(() {
          _versions = versions;
          _versionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _versionsLoading = false;
          _versionsError = '获取版本列表失败';
        });
      }
    }
  }

  Future<void> _fetchLoaderVersions() async {
    if (_selectedVersion == null) return;
    setState(() {
      _loaderVersionsLoading = true;
      _loaderVersionsError = null;
      _loaderVersions = [];
      _selectedLoaderVersion = null;
    });
    try {
      final service = LoaderDownloadService.instance;
      final mcVersion = _selectedVersion!.id;
      List<String> versions;
      switch (_selectedLoader) {
        case _ModLoader.forge:
          versions = await service.getForgeVersions(mcVersion);
          break;
        case _ModLoader.fabric:
          versions = await service.getFabricVersions(mcVersion);
          break;
        case _ModLoader.neoforge:
          versions = await service.getForgeVersions(mcVersion);
          break;
        case _ModLoader.quilt:
          versions = await service.getFabricVersions(mcVersion);
          break;
        default:
          versions = [];
      }
      if (mounted) {
        setState(() {
          _loaderVersions = versions;
          _loaderVersionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaderVersionsLoading = false;
          _loaderVersionsError = '获取加载器版本失败';
        });
      }
    }
  }

  String _summaryLoader = '';
  String _summaryLoaderVersion = '';

  void _updateSummary() {
    switch (_selectedLoader) {
      case _ModLoader.vanilla:
        _summaryLoader = 'Vanilla';
        _summaryLoaderVersion = '-';
        break;
      case _ModLoader.forge:
        _summaryLoader = 'Forge';
        _summaryLoaderVersion = _selectedLoaderVersion ?? '-';
        break;
      case _ModLoader.fabric:
        _summaryLoader = 'Fabric';
        _summaryLoaderVersion = _selectedLoaderVersion ?? '-';
        break;
      case _ModLoader.neoforge:
        _summaryLoader = 'NeoForge';
        _summaryLoaderVersion = _selectedLoaderVersion ?? '-';
        break;
      case _ModLoader.quilt:
        _summaryLoader = 'Quilt';
        _summaryLoaderVersion = _selectedLoaderVersion ?? '-';
        break;
    }
  }

  Future<void> _createInstance() async {
    setState(() => _creating = true);
    try {
      final manager = InstanceManager();
      final directoryId = manager.selectedDirectoryId;
      if (directoryId == null) {
        throw AppException.fromCode(ErrorCodes.instanceDirectoryNotSelected);
      }

      String? loader;
      String? loaderVersion;
      if (_selectedLoader != _ModLoader.vanilla) {
        loader = _selectedLoader.name;
        loaderVersion = _selectedLoaderVersion;
      }

      await manager.createInstance(
        name: _nameController.text.trim(),
        directoryId: directoryId,
        version: _selectedVersion!.id,
        loader: loader,
        loaderVersion: loaderVersion,
      );

      if (mounted) {
        NotificationManager().showSuccess(
          '创建成功',
          message: '实例 "${_nameController.text.trim()}" 已创建',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        NotificationManager().showError(
          '创建失败',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BATheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: BATheme.blurSigma,
            sigmaY: BATheme.blurSigma,
          ),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BATheme.borderRadius,
              border: Border.all(color: BAColors.borderOf(context), width: 1),
              boxShadow: BATheme.shadows,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Flexible(child: _buildContent()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const steps = ['基本信息', '版本选择', '模组加载器', '确认创建'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '创建实例',
                  style: BATypography.headlineMedium.copyWith(
                    color: BAColors.textPrimaryOf(context),
                  ),
                ),
              ),
              _CloseButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? BAColors.primaryOf(context)
                            : isActive
                                ? BAColors.primaryOf(context)
                                : BAColors.surfaceVariantOf(context),
                        border: Border.all(
                          color: isCompleted || isActive
                              ? BAColors.primaryOf(context)
                              : BAColors.borderOf(context),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: BATypography.labelSmall.copyWith(
                                  color: isActive ? Colors.white : BAColors.textSecondaryOf(context),
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        steps[index],
                        style: BATypography.labelSmall.copyWith(
                          color: isActive || isCompleted
                              ? BAColors.textPrimaryOf(context)
                              : BAColors.textSecondaryOf(context),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 16,
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isCompleted ? BAColors.primaryOf(context) : BAColors.borderOf(context),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Divider(color: BAColors.borderOf(context), height: 1),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasicInfo();
      case 1:
        return _buildStepVersionSelection();
      case 2:
        return _buildStepModLoader();
      case 3:
        return _buildStepConfirm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '实例名称',
          style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
        const SizedBox(height: 8),
        Text(
          '为你的新实例取一个名字',
          style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          style: BATypography.bodyMedium.copyWith(color: BAColors.textPrimaryOf(context)),
          decoration: InputDecoration(
            hintText: '输入实例名称',
            hintStyle: BATypography.bodyMedium.copyWith(color: BAColors.textDisabledOf(context)),
            filled: true,
            fillColor: BAColors.surfaceVariantOf(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusMedium,
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusMedium,
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BATheme.borderRadiusMedium,
              borderSide: BorderSide(color: BAColors.primaryOf(context), width: 2),
            ),
            errorText: _nameError,
            prefixIcon: Icon(Icons.edit, size: 20),
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
      ],
    );
  }

  Widget _buildStepVersionSelection() {
    if (_versionsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在获取版本列表...'),
          ],
        ),
      );
    }

    if (_versionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: BAColors.dangerOf(context)),
            const SizedBox(height: 12),
            Text(
              _versionsError!,
              style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),
            BAPrimaryButton(
              text: '重试',
              onPressed: _fetchVersions,
              height: 36,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择游戏版本',
          style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
        const SizedBox(height: 8),
        if (_selectedVersion != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '已选择: ${_selectedVersion!.id}',
              style: BATypography.bodySmall.copyWith(color: BAColors.primaryOf(context)),
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BATheme.borderRadiusMedium,
              border: Border.all(color: BAColors.borderOf(context)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _versions.length,
              itemBuilder: (context, index) {
                final version = _versions[index];
                final isSelected = _selectedVersion?.id == version.id;
                return _VersionTile(
                  version: version,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedVersion = version),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepModLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择模组加载器',
          style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
        const SizedBox(height: 8),
        Text(
          '选择 "Vanilla" 则不使用模组加载器',
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 12),
        ..._ModLoader.values.map((loader) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _LoaderRadioTile(
              loader: loader,
              groupValue: _selectedLoader,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedLoader = value;
                  _loaderVersions = [];
                  _selectedLoaderVersion = null;
                });
                if (value != _ModLoader.vanilla) {
                  _fetchLoaderVersions();
                }
              },
            ),
          );
        }),
        if (_selectedLoader != _ModLoader.vanilla) ...[
          const SizedBox(height: 12),
          Divider(color: BAColors.borderOf(context), height: 1),
          const SizedBox(height: 12),
          Text(
            '${_loaderDisplayName(_selectedLoader)} 版本',
            style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildLoaderVersionList()),
        ],
      ],
    );
  }

  String _loaderDisplayName(_ModLoader loader) {
    switch (loader) {
      case _ModLoader.vanilla:
        return 'Vanilla';
      case _ModLoader.forge:
        return 'Forge';
      case _ModLoader.fabric:
        return 'Fabric';
      case _ModLoader.neoforge:
        return 'NeoForge';
      case _ModLoader.quilt:
        return 'Quilt';
    }
  }

  Widget _buildLoaderVersionList() {
    if (_loaderVersionsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在获取加载器版本...'),
          ],
        ),
      );
    }

    if (_loaderVersionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 36, color: BAColors.dangerOf(context)),
            const SizedBox(height: 8),
            Text(
              _loaderVersionsError!,
              style: BATypography.bodySmall.copyWith(color: BAColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 12),
            BAPrimaryButton(
              text: '重试',
              onPressed: _fetchLoaderVersions,
              height: 32,
            ),
          ],
        ),
      );
    }

    if (_loaderVersions.isEmpty) {
      return Center(
        child: Text(
          '暂无可用版本',
          style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BATheme.borderRadiusMedium,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _loaderVersions.length,
        itemBuilder: (context, index) {
          final version = _loaderVersions[index];
          final isSelected = _selectedLoaderVersion == version;
          return ListTile(
            dense: true,
            title: Text(
              version,
              style: BATypography.bodyMedium.copyWith(
                color: isSelected ? BAColors.primaryOf(context) : BAColors.textPrimaryOf(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
              size: 20,
            ),
            onTap: () => setState(() => _selectedLoaderVersion = version),
            shape: RoundedRectangleBorder(
              borderRadius: BATheme.borderRadiusSmall,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }

  Widget _buildStepConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '确认创建信息',
          style: BATypography.titleSmall.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        if (_creating)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('正在创建实例...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BATheme.borderRadiusMedium,
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(Icons.label, '实例名称', _nameController.text.trim()),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.games, '游戏版本', _selectedVersion?.id ?? '-'),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.extension, '模组加载器', _summaryLoader),
          if (_selectedLoader != _ModLoader.vanilla) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(Icons.build, '加载器版本', _summaryLoaderVersion),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: BAColors.primaryOf(context)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
        ),
        Expanded(
          child: Text(
            value,
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep > 0) ...[
            BASecondaryButton(
              text: '上一步',
              onPressed: _prevStep,
            ),
            const SizedBox(width: 12),
          ],
          if (_currentStep < 3)
            BAPrimaryButton(
              text: '下一步',
              onPressed: _nextStep,
            )
          else
            BAPrimaryButton(
              text: '创建',
              onPressed: _creating ? null : _createInstance,
              loading: _creating,
            ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _CloseButton({this.onPressed});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? BAColors.surfaceVariantOf(context) : Colors.transparent,
            borderRadius: BATheme.borderRadiusSmall,
          ),
          child: Icon(
            Icons.close,
            color: _isHovered ? BAColors.textPrimaryOf(context) : BAColors.textSecondaryOf(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _VersionTile extends StatefulWidget {
  final GameVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionTile({
    required this.version,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  bool _isHovered = false;

  Color _typeColor() {
    switch (widget.version.type) {
      case VersionType.release:
        return BAColors.successOf(context);
      case VersionType.snapshot:
        return BAColors.warningOf(context);
      case VersionType.oldBeta:
        return BAColors.infoOf(context);
      case VersionType.oldAlpha:
        return BAColors.dangerOf(context);
    }
  }

  String _typeLabel() {
    switch (widget.version.type) {
      case VersionType.release:
        return '正式版';
      case VersionType.snapshot:
        return '快照';
      case VersionType.oldBeta:
        return 'Beta';
      case VersionType.oldAlpha:
        return 'Alpha';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? BAColors.primaryOf(context).withOpacity(0.15)
                : _isHovered
                    ? BAColors.surfaceTertiaryOf(context).withOpacity(0.5)
                    : Colors.transparent,
            borderRadius: BATheme.borderRadiusSmall,
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: widget.isSelected
                    ? BAColors.primaryOf(context)
                    : BAColors.textSecondaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.version.id,
                style: BATypography.bodyMedium.copyWith(
                  color: widget.isSelected
                      ? BAColors.primaryOf(context)
                      : BAColors.textPrimaryOf(context),
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _typeColor().withOpacity(0.3)),
                ),
                child: Text(
                  _typeLabel(),
                  style: BATypography.labelSmall.copyWith(
                    color: _typeColor(),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoaderRadioTile extends StatefulWidget {
  final _ModLoader loader;
  final _ModLoader groupValue;
  final ValueChanged<_ModLoader?> onChanged;

  const _LoaderRadioTile({
    required this.loader,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  State<_LoaderRadioTile> createState() => _LoaderRadioTileState();
}

class _LoaderRadioTileState extends State<_LoaderRadioTile> {
  bool _isHovered = false;

  String _label() {
    switch (widget.loader) {
      case _ModLoader.vanilla:
        return 'Vanilla';
      case _ModLoader.forge:
        return 'Forge';
      case _ModLoader.fabric:
        return 'Fabric';
      case _ModLoader.neoforge:
        return 'NeoForge';
      case _ModLoader.quilt:
        return 'Quilt';
    }
  }

  IconData _icon() {
    switch (widget.loader) {
      case _ModLoader.vanilla:
        return Icons.grass;
      case _ModLoader.forge:
        return Icons.build;
      case _ModLoader.fabric:
        return Icons.texture;
      case _ModLoader.neoforge:
        return Icons.construction;
      case _ModLoader.quilt:
        return Icons.layers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.loader == widget.groupValue;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(widget.loader),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? BAColors.primaryOf(context).withOpacity(0.15)
                : _isHovered
                    ? BAColors.surfaceTertiaryOf(context).withOpacity(0.5)
                    : Colors.transparent,
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(
              color: isSelected ? BAColors.primaryOf(context).withOpacity(0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 10),
              Icon(_icon(), size: 18, color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context)),
              const SizedBox(width: 8),
              Text(
                _label(),
                style: BATypography.bodyMedium.copyWith(
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textPrimaryOf(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
