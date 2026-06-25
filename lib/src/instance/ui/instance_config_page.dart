import 'package:flutter/material.dart';
import '../models.dart';
import '../instance_manager.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/ba_buttons.dart';
import '../../ui/components/ba_dialog.dart';
import '../../core/logger.dart';
import '../../loader/java_selector_dialog.dart';

/// 实例配置编辑页面
class InstanceConfigPage extends StatefulWidget {
  final String instanceId;

  const InstanceConfigPage({super.key, required this.instanceId});

  @override
  State<InstanceConfigPage> createState() => _InstanceConfigPageState();
}

class _InstanceConfigPageState extends State<InstanceConfigPage> {
  final Logger _logger = Logger('InstanceConfigPage');
  final InstanceManager _instanceManager = InstanceManager.instance;

  GameInstance? _instance;
  InstanceConfig? _config;
  bool _isLoading = true;
  bool _hasChanges = false;

  final TextEditingController _javaPathController = TextEditingController();
  final TextEditingController _jvmArgsController = TextEditingController();
  final TextEditingController _gameArgsController = TextEditingController();
  final TextEditingController _windowWidthController = TextEditingController();
  final TextEditingController _windowHeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstance();
  }

  Future<void> _loadInstance() async {
    try {
      await _instanceManager.initialize();
      _instance = _instanceManager.instances.firstWhere(
        (i) => i.id == widget.instanceId,
      );
      _config = _instance?.config;

      if (_config != null) {
        _javaPathController.text = _config!.javaPath ?? '';
        _jvmArgsController.text = _config!.jvmArgs?.join(' ') ?? '';
        _gameArgsController.text = _config!.gameArgs?.join(' ') ?? '';
        _windowWidthController.text = _config!.windowWidth ?? '';
        _windowHeightController.text = _config!.windowHeight ?? '';
      }

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load instance', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  void _markChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _selectJava() async {
    try {
      final javaPath = await JavaSelectorDialog.show(
        context,
        currentJavaPath: _javaPathController.text,
        recommendedVersion: 17,
      );

      if (javaPath != null) {
        setState(() {
          _javaPathController.text = javaPath;
          _hasChanges = true;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to select Java', e, stackTrace);
      if (mounted) {
        BAConfirmDialog.show(
          context: context,
          title: '错误',
          content: '选择 Java 失败: $e',
          confirmText: '确定',
          cancelText: '取消',
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_instance == null || _config == null) return;

    try {
      final updatedConfig = _config!.copyWith(
        javaPath: _javaPathController.text.trim().isEmpty ? null : _javaPathController.text.trim(),
        maxMemory: _maxMemory,
        minMemory: _minMemory,
        jvmArgs: _jvmArgsController.text.trim().isEmpty ? null : _jvmArgsController.text.trim().split(' '),
        gameArgs: _gameArgsController.text.trim().isEmpty ? null : _gameArgsController.text.trim().split(' '),
        windowWidth: _windowWidthController.text.trim().isEmpty ? null : _windowWidthController.text.trim(),
        windowHeight: _windowHeightController.text.trim().isEmpty ? null : _windowHeightController.text.trim(),
        fullscreen: _fullscreen,
        demo: _demo,
      );

      await _instanceManager.updateInstance(
        id: _instance!.id,
        config: updatedConfig,
      );

      setState(() => _hasChanges = false);
      _showSuccess('配置保存成功!');
    } catch (e, stackTrace) {
      _logger.error('Failed to save config', e, stackTrace);
      _showError('保存失败: $e');
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

  int? _maxMemory = 2048;
  int? _minMemory = 1024;
  bool _fullscreen = false;
  bool _demo = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_instance == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '实例不存�?,
              style: BATypography.headlineSmall,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: BAColors.surfaceOf(context),
        title: Text(
          '${_instance!.name} - 配置',
          style: BATypography.headlineMedium.copyWith(color: BAColors.textPrimaryOf(context)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BAColors.textPrimaryOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            BAPrimaryButton(
              text: '保存',
              onPressed: _saveConfig,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildJavaSection(),
          const SizedBox(height: 24),
          _buildMemorySection(),
          const SizedBox(height: 24),
          _buildArgumentsSection(),
          const SizedBox(height: 24),
          _buildWindowSection(),
          const SizedBox(height: 24),
          _buildMiscSection(),
        ],
      ),
    );
  }

  Widget _buildJavaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Java 设置',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 16),
          Text(
            'Java 路径',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _javaPathController,
                  onChanged: (_) => _markChanged(),
                  decoration: InputDecoration(
                    hintText: 'java.exe 的路径（留空使用系统默认�?,
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
              ),
              const SizedBox(width: 12),
              BASecondaryButton(
                text: '浏览',
                onPressed: _selectJava,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内存分配',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最大内�?(MB)',
                      style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxMemory = int.tryParse(value);
                        _markChanged();
                      },
                      decoration: InputDecoration(
                        hintText: '2048',
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
                      controller: TextEditingController(text: (_maxMemory ?? 2048).toString()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最小内�?(MB)',
                      style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minMemory = int.tryParse(value);
                        _markChanged();
                      },
                      decoration: InputDecoration(
                        hintText: '1024',
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
                      controller: TextEditingController(text: (_minMemory ?? 1024).toString()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArgumentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '启动参数',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 16),
          Text(
            'JVM 参数',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _jvmArgsController,
            onChanged: (_) => _markChanged(),
            decoration: InputDecoration(
              hintText: '-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions',
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
            '游戏参数',
            style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gameArgsController,
            onChanged: (_) => _markChanged(),
            decoration: InputDecoration(
              hintText: '--fullscreen',
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
  }

  Widget _buildWindowSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '窗口设置',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '窗口宽度',
                      style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _windowWidthController,
                      onChanged: (_) => _markChanged(),
                      decoration: InputDecoration(
                        hintText: '1280',
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
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '窗口高度',
                      style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _windowHeightController,
                      onChanged: (_) => _markChanged(),
                      decoration: InputDecoration(
                        hintText: '720',
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '全屏模式',
                style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
              ),
              Switch(
                value: _fullscreen,
                onChanged: (value) {
                  setState(() => _fullscreen = value);
                  _markChanged();
                },
                activeColor: BAColors.primaryOf(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiscSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '其他设置',
            style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '演示模式',
                style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondaryOf(context)),
              ),
              Switch(
                value: _demo,
                onChanged: (value) {
                  setState(() => _demo = value);
                  _markChanged();
                },
                activeColor: BAColors.primaryOf(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

