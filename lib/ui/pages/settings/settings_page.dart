import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/dialogs/update_dialog.dart';

/// 设置页面组件
/// 提供游戏设置、启动设置、高级设置等功能
class SettingsPage extends StatefulWidget {
  /// 配置管理器实例
  final IConfigManager configManager;

  const SettingsPage({super.key, required this.configManager});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// 游戏路径输入控制器
  late TextEditingController _gamePathController;
  /// Java路径输入控制器
  late TextEditingController _javaPathController;
  /// 自动更新开关状态
  bool _autoUpdate = false;
  /// 自动登录开关状态
  bool _autoLogin = false;
  /// 启用日志开关状态
  bool _enableLogs = true;
  /// 是否正在加载
  bool _isLoading = false;
  /// 是否正在检查更新
  bool _isCheckingUpdate = false;
  /// 当前版本号
  String _currentVersion = '1.0.0';
  /// 更新管理器实例
  late UpdateManager _updateManager;

  @override
  void initState() {
    super.initState();
    _gamePathController = TextEditingController();
    _javaPathController = TextEditingController();
    
    _updateManager = UpdateManager(
      platformAdapter: PlatformAdapterFactory.getInstance(),
      configManager: widget.configManager,
      downloadEngine: DownloadEngine(),
      logger: logger,
    );
    
    _loadSettings();
    _loadVersionInfo();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final gamePath = await widget.configManager.loadConfig('gamePath');
      final javaPath = await widget.configManager.loadConfig('javaPath');
      final autoUpdate =
          await widget.configManager.loadConfig('autoUpdate') ?? false;
      final autoLogin =
          await widget.configManager.loadConfig('autoLogin') ?? false;
      final enableLogs =
          await widget.configManager.loadConfig('enableLogs') ?? true;

      _gamePathController.text = gamePath ?? '';
      _javaPathController.text = javaPath ?? '';
      _autoUpdate = autoUpdate;
      _autoLogin = autoLogin;
      _enableLogs = enableLogs;
    } catch (e) {
      logger.error('Failed to load settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await widget.configManager
          .saveConfig('gamePath', _gamePathController.text);
      await widget.configManager
          .saveConfig('javaPath', _javaPathController.text);
      await widget.configManager.saveConfig('autoUpdate', _autoUpdate);
      await widget.configManager.saveConfig('autoLogin', _autoLogin);
      await widget.configManager.saveConfig('enableLogs', _enableLogs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置已保存'),
            backgroundColor: BamcColors.success,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to save settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: BamcColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      String? version = await widget.configManager.loadConfig('app_version');
      setState(() {
        _currentVersion = version ?? '1.0.0';
      });
    } catch (e) {
      logger.error('Failed to load version info: $e');
    }
  }

  Future<void> _pickGamePath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择游戏目录',
      );
      if (selectedDirectory != null) {
        setState(() {
          _gamePathController.text = selectedDirectory;
        });
      }
    } catch (e) {
      logger.error('Failed to pick game path: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择目录失败: $e'),
            backgroundColor: BamcColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _pickJavaPath() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择Java可执行文件',
        type: Platform.isWindows ? FileType.custom : FileType.any,
        allowedExtensions: Platform.isWindows ? ['exe'] : null,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _javaPathController.text = result.files.single.path!;
        });
      }
    } catch (e) {
      logger.error('Failed to pick Java path: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择Java文件失败: $e'),
            backgroundColor: BamcColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      UpdateInfo? updateInfo = await _updateManager.checkForUpdates();
      if (updateInfo != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            updateManager: _updateManager,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前已是最新版本'),
            backgroundColor: BamcColors.success,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to check for updates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查更新失败: $e'),
            backgroundColor: BamcColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  void dispose() {
    _gamePathController.dispose();
    _javaPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('游戏设置'),
                  const SizedBox(height: 16),
                  _buildGameSettings(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('启动设置'),
                  const SizedBox(height: 16),
                  _buildLaunchSettings(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('高级设置'),
                  const SizedBox(height: 16),
                  _buildAdvancedSettings(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('关于'),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: BamcColors.textPrimary,
      ),
    );
  }

  Widget _buildGameSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BamcColors.border),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                label: '游戏路径',
                controller: _gamePathController,
                hintText: '选择游戏安装路径',
              )),
              const SizedBox(width: 16),
              BamcButton(
                text: '浏览',
                onPressed: _pickGamePath,
                type: BamcButtonType.primary,
                size: BamcButtonSize.medium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                label: 'Java路径',
                controller: _javaPathController,
                hintText: '可选，自动检测',
              )),
              const SizedBox(width: 16),
              BamcButton(
                text: '浏览',
                onPressed: _pickJavaPath,
                type: BamcButtonType.primary,
                size: BamcButtonSize.medium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BamcColors.border),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: '自动更新',
            subtitle: '启动时检查更新',
            value: _autoUpdate,
            onChanged: (value) => setState(() => _autoUpdate = value),
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: '自动登录',
            subtitle: '启动时自动登录上次使用的账户',
            value: _autoLogin,
            onChanged: (value) => setState(() => _autoLogin = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BamcColors.border),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: '启用日志',
            subtitle: '记录详细日志信息',
            value: _enableLogs,
            onChanged: (value) => setState(() => _enableLogs = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: BamcColors.statPrimaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BamcColors.surfaceLight,
                BamcColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BamcColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: BamcColors.textTertiary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(color: BamcColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: value
                ? BamcColors.statPrimaryGradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BamcColors.surfaceLight,
                      BamcColors.surface,
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            value ? Icons.check_rounded : Icons.settings_rounded,
            size: 22,
            color: value ? Colors.white : BamcColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: BamcColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 32,
          decoration: BoxDecoration(
            gradient: value
                ? BamcColors.statPrimaryGradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BamcColors.surfaceLight,
                      BamcColors.surface,
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value
                  ? BamcColors.primary.withOpacity(0.5)
                  : BamcColors.borderLight,
            ),
          ),
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: value
                          ? BamcColors.primary.withOpacity(0.3)
                          : BamcColors.shadowLight,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BamcColors.surface,
            BamcColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BamcColors.border),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: BamcColors.statAccentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BAMCLauncher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本: $_currentVersion',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BamcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              BamcButton(
                text: '检查更新',
                onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                type: BamcButtonType.primary,
                size: BamcButtonSize.medium,
                isLoading: _isCheckingUpdate,
                icon: Icons.update_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BamcColors.background,
                  BamcColors.surfaceDark,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BamcColors.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '关于',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '一款跨平台的Minecraft启动器，支持多版本管理、模组加载器安装、整合包管理等功能。',
                  style: TextStyle(
                    fontSize: 13,
                    color: BamcColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '开发者',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: BamcColors.textTertiary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'BAMCLauncher Team',
                            style: TextStyle(
                              fontSize: 13,
                              color: BamcColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '许可证',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: BamcColors.textTertiary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'MIT License',
                            style: TextStyle(
                              fontSize: 13,
                              color: BamcColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '版权',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: BamcColors.textTertiary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '© 2026',
                            style: TextStyle(
                              fontSize: 13,
                              color: BamcColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: BamcButton(
        text: '保存设置',
        onPressed: _saveSettings,
        type: BamcButtonType.primary,
        size: BamcButtonSize.large,
        isLoading: _isLoading,
      ),
    );
  }
}
