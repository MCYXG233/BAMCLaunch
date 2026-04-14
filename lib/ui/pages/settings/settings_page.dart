import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/dialogs/update_dialog.dart';

class SettingsPage extends StatefulWidget {
  final IConfigManager configManager;

  const SettingsPage({super.key, required this.configManager});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _gamePathController;
  late TextEditingController _javaPathController;
  bool _autoUpdate = false;
  bool _autoLogin = false;
  bool _enableLogs = true;
  bool _isLoading = false;
  bool _isCheckingUpdate = false;
  String _currentVersion = '1.0.0';
  late UpdateManager _updateManager;

  @override
  void initState() {
    super.initState();
    _gamePathController = TextEditingController();
    _javaPathController = TextEditingController();
    
    // 初始化更新管理器
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
      padding: const EdgeInsets.all(20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('游戏设置'),
                  _buildGameSettings(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('启动设置'),
                  _buildLaunchSettings(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('高级设置'),
                  _buildAdvancedSettings(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('关于'),
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
        fontWeight: FontWeight.bold,
        color: BamcColors.textPrimary,
      ),
    );
  }

  Widget _buildGameSettings() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: '游戏路径',
            controller: _gamePathController,
            hintText: '选择游戏安装路径',
          ),
          const SizedBox(height: 16),
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
                onPressed: () {},
                type: BamcButtonType.outline,
                size: BamcButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchSettings() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: '自动更新',
            subtitle: '启动时检查更新',
            value: _autoUpdate,
            onChanged: (value) => setState(() => _autoUpdate = value),
          ),
          const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: BamcColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BamcColors.border),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: BamcColors.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: BamcColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: BamcColors.primary,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '版本信息',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                    Text(
                      '当前版本: $_currentVersion',
                      style: const TextStyle(
                        fontSize: 12,
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
                size: BamcButtonSize.small,
                isLoading: _isCheckingUpdate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BamcColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAMCLauncher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BamcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '一款跨平台的Minecraft启动器，支持多版本管理、模组加载器安装、整合包管理等功能。',
                  style: TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '© 2026 BAMCLauncher Team',
                  style: TextStyle(
                    fontSize: 12,
                    color: BamcColors.textSecondary,
                  ),
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
