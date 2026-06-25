import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../ui/theme/colors.dart';
import '../ui/theme/typography.dart';
import '../ui/components/ba_buttons.dart';
import '../core/logger.dart';
import 'modpack_parser.dart';
import 'modpack_installer.dart';

/// 整合包导入对话框
class ModpackImportDialog extends StatefulWidget {
  const ModpackImportDialog({super.key});

  /// 显示对话�?
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ModpackImportDialog(),
    );
  }

  @override
  State<ModpackImportDialog> createState() => _ModpackImportDialogState();
}

class _ModpackImportDialogState extends State<ModpackImportDialog> {
  static final Logger _logger = Logger('ModpackImportDialog');

  /// 步骤
  int _step = 0;

  /// 选中的文件路�?
  String? _zipPath;

  /// 解析的整合包信息
  ModpackInfo? _modpack;

  /// 实例名称
  final _nameController = TextEditingController();

  /// 是否正在安装
  bool _isInstalling = false;

  /// 安装进度
  int _completed = 0;
  int _total = 0;
  String? _currentTask;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 选择文件
  Future<void> _pickFile() async {
    try {
      setState(() {
        _error = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'mrpack'],
      );

      if (result == null) return;

      setState(() {
        _zipPath = result.files.single.path;
      });

      // 解析整合�?
      await _parseModpack();
    } catch (e, stackTrace) {
      _logger.error('Failed to pick file', e, stackTrace);
      setState(() {
        _error = '选择文件失败: $e';
      });
    }
  }

  /// 解析整合�?
  Future<void> _parseModpack() async {
    if (_zipPath == null) return;

    try {
      setState(() {
        _isInstalling = true;
        _error = null;
      });

      final modpack = await ModpackParser.parseZip(_zipPath!);

      setState(() {
        _modpack = modpack;
        _nameController.text = modpack.name;
        _step = 1;
        _isInstalling = false;
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to parse modpack', e, stackTrace);
      setState(() {
        _isInstalling = false;
        _error = '解析整合包失�? $e';
      });
    }
  }

  /// 安装整合�?
  Future<void> _installModpack() async {
    if (_zipPath == null || _modpack == null) return;

    final instanceName = _nameController.text.trim();
    if (instanceName.isEmpty) {
      setState(() {
        _error = '请输入实例名�?;
      });
      return;
    }

    try {
      setState(() {
        _isInstalling = true;
        _error = null;
        _step = 2;
      });

      final instanceId = await ModpackInstaller.installModpack(
        zipPath: _zipPath!,
        instanceName: instanceName,
        onProgress: (completed, total, currentTask) {
          setState(() {
            _completed = completed;
            _total = total;
            _currentTask = currentTask;
          });
        },
        onStatus: (status) {
          setState(() {
            _currentTask = status;
          });
        },
      );

      setState(() {
        _step = 3;
      });

      // 延迟关闭
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(instanceId);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to install modpack', e, stackTrace);
      setState(() {
        _isInstalling = false;
        _error = '安装整合包失�? $e';
        _step = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            _buildHeader(context),

            // 内容
            Expanded(
              child: _buildContent(context),
            ),

            // 按钮
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.primaryOf(context).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive, color: BAColors.primaryOf(context), size: 28),
          const SizedBox(width: 16),
          Text(
            '导入整合�?,
            style: BATypography.headlineSmall.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildStep0(context);
      case 1:
        return _buildStep1(context);
      case 2:
        return _buildStep2(context);
      case 3:
        return _buildStep3(context);
      default:
        return _buildStep0(context);
    }
  }

  Widget _buildStep0(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file,
            size: 80,
            color: BAColors.textSecondaryOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            '选择整合包文�?,
            style: BATypography.titleLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '支持 CurseForge �?Modrinth 格式的整合包',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          BAPrimaryButton(
            text: '选择文件',
            onPressed: _pickFile,
            leadingIcon: const Icon(Icons.file_open, color: Colors.white),
          ),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BAColors.dangerOf(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.dangerOf(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: BAColors.dangerOf(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: BATypography.bodyMedium.copyWith(
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '确认整合包信�?,
            style: BATypography.titleLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 24),

          // 整合包信�?
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BAColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow('名称', _modpack?.name),
                _buildInfoRow('版本', _modpack?.version),
                _buildInfoRow('Minecraft', _modpack?.minecraftVersion),
                _buildInfoRow(
                  'Mod 加载�?,
                  _modpack?.modLoader != null && _modpack?.modLoaderVersion != null
                      ? '${_modpack!.modLoader} ${_modpack!.modLoaderVersion}'
                      : null,
                ),
                _buildInfoRow('Mod数量', _modpack?.mods.length.toString()),
                _buildInfoRow('资源包数�?, _modpack?.resourcePacks.length.toString()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 实例名称
          Text(
            '实例名称',
            style: BATypography.titleMedium.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BAColors.dangerOf(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.dangerOf(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: BAColors.dangerOf(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: BATypography.bodyMedium.copyWith(
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final progress = _total > 0 ? (_completed / _total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.downloading,
            size: 80,
            color: BAColors.primaryOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            _currentTask ?? '正在安装...',
            style: BATypography.titleLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                ),
              ),
              if (progress > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: BATypography.headlineMedium,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_total > 0)
            Text(
              '$_completed / $_total',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: BAColors.successOf(context),
          ),
          const SizedBox(height: 24),
          Text(
            '安装完成�?,
            style: BATypography.titleLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '整合包已成功导入到新实例',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: BAColors.borderOf(context)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_step != 2 && _step != 3)
            BASecondaryButton(
              text: _step == 0 ? '取消' : '上一�?,
              onPressed: _isInstalling
                  ? null
                  : () {
                      if (_step == 0) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _step--);
                      }
                    },
            ),
          if (_step == 1) const SizedBox(width: 12),
          if (_step == 1)
            BAPrimaryButton(
              text: '安装',
              onPressed: _isInstalling ? null : _installModpack,
            ),
        ],
      ),
    );
  }
}
