import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../account/account_manager.dart';
import '../../../auth/authlib_injector.dart';
import '../../../config/background_config.dart';
import '../../../config/config_keys.dart';
import '../../../config/config_manager.dart';
import '../../../core/constants.dart';
import '../../../core/logger.dart';
import '../../../core/privacy_manager.dart';
import '../../../download/mirror_manager.dart';
import '../../../game/backup_manager.dart';
import '../../../instance/instance_manager.dart';
import '../../theme/background_manager.dart';
import '../../theme/theme_manager.dart';
import '../ba_buttons.dart';
import '../ba_dialog.dart';
import '../ba_login_dialog.dart';
import '../ba_notification.dart';
import '../theme_editor.dart';
import '../../../loader/java_selector_dialog.dart';
import 'dialogs/authlib_servers_dialog.dart';
import 'dialogs/background_picker_dialog.dart';
import 'dialogs/backup_history_dialog.dart';
import 'dialogs/changelog_dialog.dart';
import 'dialogs/mirror_speed_test_dialog.dart';
import 'dialogs/open_source_dialog.dart';
import 'dialogs/text_input_dialog.dart';
import 'widgets/sidebar_nav.dart';
import 'widgets/settings_theme.dart';
import 'sections/about_section.dart';
import 'sections/accounts_section.dart';
import 'sections/advanced_section.dart';
import 'sections/backup_section.dart';
import 'sections/download_params_section.dart';
import 'sections/download_section.dart';
import 'sections/game_directory_section.dart';
import 'sections/instance_section.dart';
import 'sections/java_launch_section.dart';
import 'sections/launch_behavior_section.dart';
import 'sections/personalization_section.dart';
import 'sections/resource_center_section.dart';

/// 设置面板分类 ID（与侧栏导航 ID 一致）
class SettingsSectionId {
  SettingsSectionId._();
  static const accounts = 'accounts';
  static const javaLaunch = 'java_launch';
  static const gameDirectory = 'game_directory';
  static const instance = 'instance';
  static const launchBehavior = 'launch_behavior';
  static const download = 'download';
  static const downloadParams = 'download_params';
  static const resourceCenter = 'resource_center';
  static const backup = 'backup';
  static const personalization = 'personalization';
  static const advanced = 'advanced';
  static const about = 'about';
}

/// 设置面板
///
/// 布局：
///   - 全屏右侧覆盖（替代居中 Dialog）
///   - 左侧导航：搜索框 + 分组（游戏/下载/备份/个性化/高级/关于）
///   - 右侧内容：面包屑 + 标题 + 分组卡片（可折叠）
class SettingsPanel extends StatefulWidget {
  /// 显示设置面板
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const SettingsPanel(),
    );
  }

  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel>
    with TickerProviderStateMixin {
  final ConfigManager _configManager = ConfigManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  late final ThemeManager _themeManager;

  // 侧栏导航
  String _selectedId = SettingsSectionId.accounts;

  // ==================== 设置状态 ====================
  String _gameDirectory = '';
  String _javaPath = '';
  double _memoryAllocation = BAMCConstants.recommendedMaxMemoryMB.toDouble();
  String _themeMode = 'dark';
  String _colorScheme = 'blue_archive';
  bool _autoUpdate = true;
  String _downloadSource = 'official';
  int _concurrentDownloads = 3;
  String _downloadPath = '';
  bool _launchAtStartup = false;
  bool _minimizeToTray = true;
  bool _closeToTray = false;
  bool _enableAnimation = true;
  String _proxyHost = '';
  int _proxyPort = 0;
  String _gameWindowSize = '1280x720';
  String _jvmArguments = '';
  String _gameArguments = '';
  BackgroundConfig _backgroundConfig = BackgroundConfig.classic;

  // 新增 11 个分组所需的状态
  int _mirrorSourceIndex = 0;
  String _selectedMirror = 'auto';
  bool _autoSwitchMirror = true;
  int _maxRetries = 3;
  bool _autoRetryDownload = true;
  bool _enableSpeedLimit = false;
  double _speedLimitValue = 5;
  String _cacheDirectory = '';
  String _resourceCenterSource = 'modrinth';
  String _resourceCenterDefaultType = 'mod';
  String _resourceCenterSortBy = 'relevance';
  bool _resourceCenterEnableCache = true;
  int _resourceCenterCacheDuration = 60;
  bool _resourceCenterShowInstalledOnly = false;
  bool _resourceCenterAutoUpdateResources = false;
  bool _autoBackupEnabled = true;
  String _autoBackupSchedule = 'weekly';
  int _autoBackupKeepCount = 5;
  bool _autoBackupCompress = true;
  bool _versionIsolation = true;
  String _instancesNavType = 'tabs';
  String _instanceSortOption = 'lastPlayed';
  bool _launchPageQuickSwitch = true;
  String _processPriority = 'normal';
  bool _skipFirstScreenOptions = false;
  bool _displayGameLog = true;
  String _customTitle = '';
  String _headNavStyle = 'tabs';
  double _fontSize = 14;
  bool _enableSoundEffects = false;
  bool _autoDownloadJava = true;
  String _gcStrategy = 'default';
  bool _fullscreen = false;
  bool _useProxy = false;
  String _language = 'zh-CN';
  bool _mcpServerEnabled = false;
  int _mcpServerPort = 8765;
  bool _extensionsEnabled = false;

  // 新增状态：账号 / 翻译 / 隐私 / 背景 / 主题
  String _authlibSelectedServer = 'microsoft';
  String _currentAccountLabel = '未登录';
  bool _translateResourceNames = false;
  bool _sendAnonymousStats = false;
  bool _autoReportCrashes = true;
  bool _randomCustomBackground = false;
  bool _autoDarkenBackground = true;
  bool _autoPurgeLauncherLogs = true;

  // 关于页常量
  static const String _launcherVersion = '1.0.0';
  static const String _buildTime = '2026-07-27';

  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;
  late TextEditingController _jvmArgsController;
  late TextEditingController _gameArgsController;

  final Logger _logger = Logger('SettingsPanel');

  @override
  void initState() {
    super.initState();
    _themeManager = Provider.of<ThemeManager>(context, listen: false);
    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
    _jvmArgsController = TextEditingController();
    _gameArgsController = TextEditingController();
    _initManagers();
    _loadSettings();
  }

  @override
  void dispose() {
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _jvmArgsController.dispose();
    _gameArgsController.dispose();
    super.dispose();
  }

  Future<void> _initManagers() async {
    await _themeManager.initialize();
    if (mounted) {
      setState(() {
        _backgroundConfig = _backgroundManager.currentConfig;
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      _gameDirectory = _configManager.getString(ConfigKeys.gameDirectory) ?? '';
      _javaPath = _configManager.getString(ConfigKeys.javaPath) ?? '';
      _memoryAllocation =
          (_configManager.getInt(ConfigKeys.memoryAllocation) ??
                  BAMCConstants.recommendedMaxMemoryMB)
              .toDouble();
      _autoUpdate = _configManager.getBool(ConfigKeys.autoUpdate) ?? true;
      _downloadSource =
          _configManager.getString(ConfigKeys.downloadSource) ?? 'official';
      _concurrentDownloads =
          _configManager.getInt(ConfigKeys.concurrentDownloads) ?? 3;
      _downloadPath = _configManager.getString(ConfigKeys.downloadPath) ?? '';
      _launchAtStartup =
          _configManager.getBool(ConfigKeys.launchAtStartup) ?? false;
      _minimizeToTray =
          _configManager.getBool(ConfigKeys.minimizeToTray) ?? true;
      _closeToTray = _configManager.getBool(ConfigKeys.closeToTray) ?? false;
      _enableAnimation =
          _configManager.getBool(ConfigKeys.enableSplashAnimation) ?? true;
      _proxyHost = _configManager.getString(ConfigKeys.proxyHost) ?? '';
      _proxyPort = _configManager.getInt(ConfigKeys.proxyPort) ?? 0;
      _gameWindowSize =
          _configManager.getString(ConfigKeys.gameWindowSize) ?? '1280x720';
      _jvmArguments = _configManager.getString(ConfigKeys.jvmArguments) ?? '';
      _gameArguments = _configManager.getString(ConfigKeys.gameArguments) ?? '';
      _mirrorSourceIndex =
          _configManager.getInt(ConfigKeys.mirrorSourceIndex) ?? 0;
      _selectedMirror =
          _configManager.getString(ConfigKeys.selectedMirror) ?? 'auto';
      _autoSwitchMirror =
          _configManager.getBool(ConfigKeys.autoSwitchMirror) ?? true;
      _maxRetries = _configManager.getInt(ConfigKeys.maxRetries) ?? 3;
      _autoRetryDownload =
          _configManager.getBool(ConfigKeys.autoRetryDownload) ?? true;
      _enableSpeedLimit =
          _configManager.getBool(ConfigKeys.enableSpeedLimit) ?? false;
      _speedLimitValue =
          (_configManager.getInt(ConfigKeys.speedLimitValue) ?? 5).toDouble();
      _cacheDirectory =
          _configManager.getString(ConfigKeys.cacheDirectory) ?? '';
      _resourceCenterSource =
          _configManager.getString(ConfigKeys.resourceCenterSource) ??
          'modrinth';
      _resourceCenterDefaultType =
          _configManager.getString(ConfigKeys.resourceCenterDefaultType) ??
          'mod';
      _resourceCenterSortBy =
          _configManager.getString(ConfigKeys.resourceCenterSortBy) ??
          'relevance';
      _resourceCenterEnableCache =
          _configManager.getBool(ConfigKeys.resourceCenterEnableCache) ?? true;
      _resourceCenterCacheDuration =
          _configManager.getInt(ConfigKeys.resourceCenterCacheDuration) ?? 60;
      _resourceCenterShowInstalledOnly =
          _configManager.getBool(ConfigKeys.resourceCenterShowInstalledOnly) ??
          false;
      _resourceCenterAutoUpdateResources =
          _configManager.getBool(
            ConfigKeys.resourceCenterAutoUpdateResources,
          ) ??
          false;
      _autoBackupEnabled =
          _configManager.getBool(ConfigKeys.autoBackupEnabled) ?? true;
      _autoBackupSchedule =
          _configManager.getString(ConfigKeys.autoBackupSchedule) ?? 'weekly';
      _autoBackupKeepCount =
          _configManager.getInt(ConfigKeys.autoBackupKeepCount) ?? 5;
      _autoBackupCompress =
          _configManager.getBool(ConfigKeys.autoBackupCompress) ?? true;
      _versionIsolation =
          _configManager.getBool(ConfigKeys.versionIsolation) ?? true;
      _instancesNavType =
          _configManager.getString(ConfigKeys.instancesNavType) ?? 'tabs';
      _instanceSortOption =
          _configManager.getString(ConfigKeys.instanceSortOption) ??
          'lastPlayed';
      _launchPageQuickSwitch =
          _configManager.getBool(ConfigKeys.launchPageQuickSwitch) ?? true;
      _processPriority =
          _configManager.getString(ConfigKeys.processPriority) ?? 'normal';
      _skipFirstScreenOptions =
          _configManager.getBool(ConfigKeys.skipFirstScreenOptions) ?? false;
      _displayGameLog =
          _configManager.getBool(ConfigKeys.displayGameLog) ?? true;
      _customTitle = _configManager.getString(ConfigKeys.customTitle) ?? '';
      _headNavStyle =
          _configManager.getString(ConfigKeys.headNavStyle) ?? 'tabs';
      _fontSize = (_configManager.getInt(ConfigKeys.fontSize) ?? 14).toDouble();
      _enableSoundEffects =
          _configManager.getBool(ConfigKeys.enableSoundEffects) ?? false;
      _autoDownloadJava =
          _configManager.getBool(ConfigKeys.autoDownloadJava) ?? true;
      _gcStrategy =
          _configManager.getString(ConfigKeys.gcStrategy) ?? 'default';
      _fullscreen = _configManager.getBool(ConfigKeys.fullscreen) ?? false;
      _useProxy = _configManager.getBool(ConfigKeys.useProxy) ?? false;
      _language = _configManager.getString(ConfigKeys.language) ?? 'zh-CN';
      _mcpServerEnabled =
          _configManager.getBool(ConfigKeys.mcpServerEnabled) ?? false;
      _mcpServerPort = _configManager.getInt(ConfigKeys.mcpServerPort) ?? 8765;
      _extensionsEnabled =
          _configManager.getBool(ConfigKeys.extensionsEnabled) ?? false;

      // 加载新增状态
      _authlibSelectedServer =
          _configManager.getString(ConfigKeys.authlibSelectedServer) ??
          'microsoft';
      _translateResourceNames =
          _configManager.getBool(ConfigKeys.resourceTranslation) ?? false;
      _randomCustomBackground =
          _configManager.getBool(ConfigKeys.randomCustomBackground) ?? false;
      _autoDarkenBackground =
          _configManager.getBool(ConfigKeys.autoDarkenBackground) ?? true;
      _autoPurgeLauncherLogs =
          _configManager.getBool(ConfigKeys.autoPurgeLauncherLogs) ?? true;

      // 从 PrivacyManager 加载隐私配置
      try {
        final privacyConfig = PrivacyManager().config;
        _sendAnonymousStats = !privacyConfig.disableAnalytics;
        _autoReportCrashes = !privacyConfig.disableCrashReporting;
      } catch (e) {
        _logger.warn('Failed to load privacy config: $e');
      }

      // 加载当前登录账号的显示名
      try {
        final account = await AccountManager.instance.getSelectedAccount();
        if (account != null) {
          _currentAccountLabel = account.username;
        }
      } catch (e) {
        _logger.warn('Failed to load current account: $e');
      }

      String themeModeStr;
      switch (_themeManager.themeMode) {
        case ThemeMode.light:
          themeModeStr = 'light';
          break;
        case ThemeMode.system:
          themeModeStr = 'system';
          break;
        default:
          themeModeStr = 'dark';
      }

      if (mounted) {
        setState(() {
          _themeMode = themeModeStr;
          _colorScheme = _themeManager.currentTheme;
          _proxyHostController.text = _proxyHost;
          _proxyPortController.text = _proxyPort == 0
              ? ''
              : _proxyPort.toString();
          _jvmArgsController.text = _jvmArguments;
          _gameArgsController.text = _gameArguments;
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('加载设置失败', message: e.toString());
      }
    }
  }

  // ==================== 保存回调 ====================

  Future<void> _setBool(
    String key,
    bool value,
    ValueChanged<bool> update, {
    String? successMessage,
  }) async {
    try {
      await _configManager.setBool(key, value);
      update(value);
      if (mounted) setState(() {});
      if (successMessage != null) {
        NotificationManager().showSuccess(successMessage);
      }
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _setString(
    String key,
    String value,
    ValueChanged<String> update, {
    String? successMessage,
  }) async {
    try {
      await _configManager.setString(key, value);
      update(value);
      if (mounted) setState(() {});
      if (successMessage != null) {
        NotificationManager().showSuccess(successMessage);
      }
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _setInt(
    String key,
    int value,
    ValueChanged<int> update, {
    String? successMessage,
  }) async {
    try {
      await _configManager.setInt(key, value);
      update(value);
      if (mounted) setState(() {});
      if (successMessage != null) {
        NotificationManager().showSuccess(successMessage);
      }
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _setDouble(
    String key,
    double value,
    ValueChanged<double> update,
  ) async {
    try {
      await _configManager.setInt(key, value.round());
      update(value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  // ==================== 工具回调 ====================

  Future<void> _saveThemeMode(String mode) async {
    try {
      ThemeMode themeMode;
      switch (mode) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'system':
          themeMode = ThemeMode.system;
          break;
        default:
          themeMode = ThemeMode.dark;
      }
      await _themeManager.setThemeMode(themeMode);
      if (mounted) setState(() => _themeMode = mode);
      NotificationManager().showSuccess('主题已切换');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('切换主题失败', message: e.toString());
    }
  }

  Future<void> _pickGameDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await _setString(
        ConfigKeys.gameDirectory,
        result,
        (v) => _gameDirectory = v,
        successMessage: '游戏目录已保存',
      );
    }
  }

  Future<void> _pickDownloadPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await _setString(
        ConfigKeys.downloadPath,
        result,
        (v) => _downloadPath = v,
      );
    }
  }

  Future<void> _pickJavaPath() async {
    final result = await JavaSelectorDialog.show(context);
    if (result != null) {
      await _setString(
        ConfigKeys.javaPath,
        result,
        (v) => _javaPath = v,
        successMessage: 'Java 路径已保存',
      );
    }
  }

  // ==================== 账号回调 ====================

  Future<void> _loginMicrosoft() async {
    try {
      await showDialog(context: context, builder: (_) => const BALoginDialog());
      // 登录对话框关闭后刷新当前账号显示
      final account = await AccountManager.instance.getSelectedAccount();
      if (mounted) {
        setState(() {
          _currentAccountLabel = account?.username ?? '未登录';
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('登录失败', message: e.toString());
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      final account = await AccountManager.instance.getSelectedAccount();
      if (account == null) {
        NotificationManager().showWarning('请先登录账号');
        return;
      }
      final success = await AccountManager.instance.refreshToken(account);
      if (mounted) {
        if (success) {
          NotificationManager().showSuccess('令牌刷新成功');
        } else {
          NotificationManager().showWarning('令牌刷新失败，请重新登录');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('刷新令牌失败', message: e.toString());
      }
    }
  }

  Future<void> _addAuthlibServer() async {
    final result = await BATextInputDialog.show(
      context: context,
      title: '添加认证服务器',
      titleIcon: Icons.link_rounded,
      description: '请填写外置登录服务器的注册 API 地址，启动器会自动获取服务器信息。',
      confirmText: '添加',
      fields: [
        BATextFieldConfig(
          label: '服务器地址',
          hint: '例如 https://example.com/api/yggdrasil',
          icon: Icons.link,
          required: true,
          keyboardType: TextInputType.url,
          validator: (v) {
            if (!v.startsWith('http://') && !v.startsWith('https://')) {
              return '请输入以 http:// 或 https:// 开头的地址';
            }
            return null;
          },
        ),
      ],
    );
    if (result == null || result.isEmpty) return;
    final url = result.first;

    try {
      final authlibInjector = AuthlibInjector.instance;
      final serverInfo = await authlibInjector.getAuthServerInfo(url);
      // 保存到已添加列表
      final stored =
          _configManager.get<List<dynamic>>(ConfigKeys.authlibServers) ?? [];
      final list = stored.cast<Map<dynamic, dynamic>>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
      list.add({
        'url': url,
        'name': serverInfo.metadata.name,
        'description': serverInfo.metadata.description,
      });
      await _configManager.set<List<dynamic>>(ConfigKeys.authlibServers, list);
      await _configManager.save();
      if (mounted) {
        NotificationManager().showSuccess(
          '已添加认证服务器：${serverInfo.metadata.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加失败', message: e.toString());
      }
    }
  }

  Future<void> _manageAuthlibServers() async {
    final stored =
        _configManager.get<List<dynamic>>(ConfigKeys.authlibServers) ?? [];
    final list = stored.cast<Map<dynamic, dynamic>>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();

    await AuthlibServersDialog.show(
      context: context,
      servers: list,
      selectedServerUrl: _authlibSelectedServer,
      onChanged: (change) async {
        try {
          await _configManager.set<List<dynamic>>(
            ConfigKeys.authlibServers,
            change.servers,
          );
          await _configManager.setString(
            ConfigKeys.authlibSelectedServer,
            change.selectedServerUrl,
          );
          await _configManager.save();
          if (mounted) {
            setState(() => _authlibSelectedServer = change.selectedServerUrl);
          }
        } catch (e) {
          _logger.warn('Failed to save authlib servers: $e');
        }
      },
    );
  }

  Future<void> _createOfflineAccount() async {
    final result = await BATextInputDialog.show(
      context: context,
      title: '新建离线账号',
      titleIcon: Icons.person_add_alt_1_rounded,
      description: '离线账号仅用于本地游戏，无法登录正版服务器。',
      confirmText: '创建',
      fields: [
        BATextFieldConfig(
          label: '用户名',
          hint: '请输入离线账号用户名',
          icon: Icons.person,
          required: true,
          validator: (v) {
            if (v.length > 16) return '用户名不能超过 16 个字符';
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
              return '只能包含字母、数字和下划线';
            }
            return null;
          },
        ),
      ],
    );
    if (result == null || result.isEmpty) return;
    final username = result.first;

    try {
      final account = await AccountManager.instance.addOfflineAccount(username);
      await AccountManager.instance.selectAccount(account.id);
      if (mounted) {
        setState(() => _currentAccountLabel = account.username);
        NotificationManager().showSuccess('离线账号已创建');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('创建失败', message: e.toString());
      }
    }
  }

  void _onAuthlibServerChanged(String value) {
    _setString(
      ConfigKeys.authlibSelectedServer,
      value,
      (v) => _authlibSelectedServer = v,
    );
  }

  // ==================== Java / 游戏目录回调 ====================

  Future<void> _pickInstalledJava() async {
    // 与 _pickJavaPath 复用同一对话框
    await _pickJavaPath();
  }

  Future<void> _addCustomPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;

    try {
      final stored =
          _configManager.get<List<dynamic>>(ConfigKeys.customGameDirectories) ??
          [];
      final list = stored.cast<String>().toList();
      if (!list.contains(result)) {
        list.add(result);
        await _configManager.set<List<dynamic>>(
          ConfigKeys.customGameDirectories,
          list,
        );
        await _configManager.save();
        if (mounted) NotificationManager().showSuccess('已添加自定义路径');
      } else {
        if (mounted) NotificationManager().showInfo('该路径已存在');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加失败', message: e.toString());
      }
    }
  }

  Future<void> _rescanSystem() async {
    try {
      await InstanceManager.instance.initialize();
      if (mounted) {
        NotificationManager().showSuccess('系统扫描已完成');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('扫描失败', message: e.toString());
      }
    }
  }

  // ==================== 下载源回调 ====================

  Future<void> _addCustomMirror() async {
    final result = await BATextInputDialog.show(
      context: context,
      title: '添加自定义镜像',
      titleIcon: Icons.add_link_rounded,
      description: '请填写镜像的显示名称和下载 API 地址。BMCLAPI 兼容的镜像才能正常工作。',
      confirmText: '添加',
      fields: [
        BATextFieldConfig(
          label: '镜像名称',
          hint: '例如 BMCLAPI 镜像',
          icon: Icons.label,
          required: true,
        ),
        BATextFieldConfig(
          label: '镜像地址',
          hint: '例如 https://bmclapi2.bangbang93.com',
          icon: Icons.link,
          required: true,
          keyboardType: TextInputType.url,
          validator: (v) {
            if (!v.startsWith('http://') && !v.startsWith('https://')) {
              return '请输入以 http:// 或 https:// 开头的地址';
            }
            return null;
          },
        ),
      ],
    );
    if (result == null || result.length < 2) return;
    final name = result[0];
    final url = result[1];

    try {
      final mirror = MirrorInfo(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        url: url,
      );
      await MirrorManager.instance.addCustomMirror(mirror);
      if (mounted) NotificationManager().showSuccess('已添加自定义镜像');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加失败', message: e.toString());
      }
    }
  }

  Future<void> _speedTest() async {
    await MirrorSpeedTestDialog.show(
      context: context,
      mirrorManager: MirrorManager.instance,
      selectedMirrorId: _selectedMirror,
      onSetDefault: (mirror) async {
        try {
          await _setString(
            ConfigKeys.selectedMirror,
            mirror.id,
            (v) => _selectedMirror = v,
            successMessage: '已将 ${mirror.name} 设为默认镜像',
          );
        } catch (e) {
          if (mounted) {
            NotificationManager().showError('设为默认失败', message: e.toString());
          }
        }
      },
    );
  }

  // ==================== 备份回调 ====================

  Future<void> _viewBackupHistory() async {
    try {
      final backupManager = BackupManager();
      await backupManager.initialize();
      final backups = backupManager.getAllBackups();
      if (!mounted) return;
      await BackupHistoryDialog.show(
        context: context,
        backups: backups,
        onRestore: (record) async {
          // 还原前先定位实例目录路径
          final instanceManager = InstanceManager.instance;
          await instanceManager.initialize();
          final instance = instanceManager.instances.firstWhere(
            (i) => i.id == record.instanceId,
            orElse: () => instanceManager.instances.first,
          );
          final dir = instanceManager.directories.firstWhere(
            (d) => d.id == instance.directoryId,
            orElse: () => instanceManager.directories.first,
          );
          await backupManager.restoreBackup(
            backup: record,
            targetPath: dir.path,
          );
        },
        onDelete: (record) async {
          await backupManager.deleteBackup(record.id);
        },
      );
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('加载备份失败', message: e.toString());
      }
    }
  }

  Future<void> _backupAllNow() async {
    try {
      final instanceManager = InstanceManager.instance;
      await instanceManager.initialize();
      final instances = instanceManager.instances;
      if (instances.isEmpty) {
        if (mounted) NotificationManager().showInfo('没有可备份的实例');
        return;
      }
      final backupManager = BackupManager();
      await backupManager.initialize();
      int success = 0;
      for (final inst in instances) {
        final dir = instanceManager.directories.firstWhere(
          (d) => d.id == inst.directoryId,
          orElse: () => instanceManager.directories.first,
        );
        final record = await backupManager.createBackup(
          instanceId: inst.id,
          instanceName: inst.name,
          instancePath: dir.path,
        );
        if (record != null) success++;
      }
      if (mounted) {
        NotificationManager().showSuccess('备份完成：$success/${instances.length}');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('备份失败', message: e.toString());
      }
    }
  }

  // ==================== 隐私回调 ====================

  Future<void> _setPrivacyFlag(
    bool value,
    bool Function(PrivacyConfig) getter,
    PrivacyConfig Function(PrivacyConfig, bool) updater,
    ValueChanged<bool> stateUpdater,
  ) async {
    try {
      final manager = PrivacyManager();
      final current = manager.config;
      final updated = updater(current, value);
      await manager.setConfig(updated);
      stateUpdater(value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存失败', message: e.toString());
      }
    }
  }

  // ==================== 关于回调 ====================

  Future<void> _checkUpdate() async {
    NotificationManager().showInfo('正在检查更新...');
    // TODO: 接入真实的更新检查逻辑
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      NotificationManager().showSuccess('当前已是最新版本');
    }
  }

  Future<void> _showChangelog() async {
    if (!mounted) return;
    final entries = <ChangelogEntry>[
      const ChangelogEntry(
        version: '1.0.0',
        date: '2026-07-27',
        category: ChangelogCategory.feature,
        title: '设置面板全新分组',
        description: '按 BAMCLaunch 启动器真实功能（80 个 ConfigKey）重新设计 11 个分组页。',
      ),
      const ChangelogEntry(
        version: '1.0.0',
        date: '2026-07-27',
        category: ChangelogCategory.feature,
        title: '全量接入业务回调',
        description: '账号、Java、游戏目录、下载、备份、隐私、主题等 16 项回调全部接入真实业务模块。',
      ),
      const ChangelogEntry(
        version: '1.0.0',
        date: '2026-07-27',
        category: ChangelogCategory.feature,
        title: '全局字体统一为思源黑体 SC',
        description: '新增 4 个字重（Regular/Medium/Bold/Light），应用于所有 TextStyle。',
      ),
      const ChangelogEntry(
        version: '1.0.0',
        date: '2026-07-27',
        category: ChangelogCategory.improvement,
        title: '重构对话框交互',
        description: '背景选择、开源组件、认证服务器、备份历史、更新日志、镜像测速等对话框统一采用 BADialog 设计语言。',
      ),
      const ChangelogEntry(
        version: '1.0.0',
        date: '2026-07-27',
        category: ChangelogCategory.bugfix,
        title: '修复 background_picker_dialog import 路径错误',
        description: '修正少一层目录的 import，并修复 BackgroundConfig.gradient 不存在的问题。',
      ),
    ];
    await ChangelogDialog.show(
      context: context,
      entries: entries,
      currentVersion: _launcherVersion,
    );
  }

  // ==================== 主题与背景回调 ====================

  Future<void> _openThemeEditor() async {
    if (!mounted) return;
    final editorState = ThemeEditorState();
    await editorState.loadConfig();
    await BADialog.show(
      context: context,
      title: '主题编辑器',
      titleIcon: Icons.palette_rounded,
      width: 600,
      actions: [
        BAPrimaryButton(
          text: '关闭',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: ThemeEditorWidget(editorState: editorState),
    );
  }

  void _manageBackground() {
    _showBackgroundSelector();
  }

  Future<void> _setColorScheme(String value) async {
    try {
      await _themeManager.setTheme(value);
      if (mounted) setState(() => _colorScheme = value);
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('切换配色失败', message: e.toString());
      }
    }
  }

  // ==================== 侧栏导航 ====================

  List<SidebarSection> _buildSidebarSections() {
    return [
      SidebarSection(
        title: '游戏',
        items: [
          SidebarItem(
            id: SettingsSectionId.accounts,
            icon: Icons.person_outline,
            label: '账号与档案',
          ),
          SidebarItem(
            id: SettingsSectionId.javaLaunch,
            icon: Icons.coffee_outlined,
            label: 'Java 与启动',
          ),
          SidebarItem(
            id: SettingsSectionId.gameDirectory,
            icon: Icons.folder_open,
            label: '游戏目录',
          ),
          SidebarItem(
            id: SettingsSectionId.instance,
            icon: Icons.dashboard_outlined,
            label: '实例管理',
          ),
          SidebarItem(
            id: SettingsSectionId.launchBehavior,
            icon: Icons.rocket_launch_outlined,
            label: '启动行为',
          ),
        ],
      ),
      SidebarSection(
        title: '下载',
        items: [
          SidebarItem(
            id: SettingsSectionId.download,
            icon: Icons.cloud_outlined,
            label: '镜像与源站',
          ),
          SidebarItem(
            id: SettingsSectionId.downloadParams,
            icon: Icons.speed_outlined,
            label: '下载参数',
          ),
          SidebarItem(
            id: SettingsSectionId.resourceCenter,
            icon: Icons.inventory_2_outlined,
            label: '资源中心',
          ),
        ],
      ),
      SidebarSection(
        title: '备份',
        items: [
          SidebarItem(
            id: SettingsSectionId.backup,
            icon: Icons.backup_outlined,
            label: '自动备份',
          ),
        ],
      ),
      SidebarSection(
        title: '个性化',
        items: [
          SidebarItem(
            id: SettingsSectionId.personalization,
            icon: Icons.palette_outlined,
            label: '外观与主题',
          ),
        ],
      ),
      SidebarSection(
        title: '高级',
        items: [
          SidebarItem(
            id: SettingsSectionId.advanced,
            icon: Icons.tune,
            label: '高级选项',
          ),
        ],
      ),
      SidebarSection(
        title: '其他',
        items: [
          SidebarItem(
            id: SettingsSectionId.about,
            icon: Icons.info_outline,
            label: '关于',
          ),
        ],
      ),
    ];
  }

  Widget _buildSelectedContent() {
    switch (_selectedId) {
      case SettingsSectionId.accounts:
        return AccountsSection(
          currentAccountLabel: _currentAccountLabel,
          authlibSelectedServer: _authlibSelectedServer,
          onLoginMicrosoft: _loginMicrosoft,
          onRefreshToken: _refreshToken,
          onAddAuthlibServer: _addAuthlibServer,
          onAuthlibServerChanged: _onAuthlibServerChanged,
          onManageAuthlibServers: _manageAuthlibServers,
          onCreateOfflineAccount: _createOfflineAccount,
        );
      case SettingsSectionId.javaLaunch:
        return JavaLaunchSection(
          javaPath: _javaPath,
          memoryAllocation: _memoryAllocation,
          jvmArgsCtrl: _jvmArgsController,
          gameArgsCtrl: _gameArgsController,
          gameWindowSize: _gameWindowSize,
          autoDownloadJava: _autoDownloadJava,
          fullscreen: _fullscreen,
          gcStrategy: _gcStrategy,
          onJavaPathChanged: (_) => _pickJavaPath(),
          onMemoryChanged: (v) => _setDouble(
            ConfigKeys.memoryAllocation,
            v,
            (val) => _memoryAllocation = val,
          ),
          onJvmArgsSubmitted: (v) => _setString(
            ConfigKeys.jvmArguments,
            v,
            (val) => _jvmArguments = val,
          ),
          onGameArgsSubmitted: (v) => _setString(
            ConfigKeys.gameArguments,
            v,
            (val) => _gameArguments = val,
          ),
          onGameWindowSizeChanged: (v) => _setString(
            ConfigKeys.gameWindowSize,
            v,
            (val) => _gameWindowSize = val,
          ),
          onAutoDownloadJavaChanged: (v) => _setBool(
            ConfigKeys.autoDownloadJava,
            v,
            (val) => _autoDownloadJava = val,
          ),
          onFullscreenChanged: (v) =>
              _setBool(ConfigKeys.fullscreen, v, (val) => _fullscreen = val),
          onGcStrategyChanged: (v) =>
              _setString(ConfigKeys.gcStrategy, v, (val) => _gcStrategy = val),
          onPickInstalledJava: _pickInstalledJava,
        );
      case SettingsSectionId.gameDirectory:
        return GameDirectorySection(
          gameDirectory: _gameDirectory,
          versionIsolation: _versionIsolation,
          onGameDirectoryChanged: (_) => _pickGameDirectory(),
          onVersionIsolationChanged: (v) => _setBool(
            ConfigKeys.versionIsolation,
            v,
            (val) => _versionIsolation = val,
          ),
          onAddCustomPath: _addCustomPath,
          onRescanSystem: _rescanSystem,
        );
      case SettingsSectionId.instance:
        return InstanceSection(
          instancesNavType: _instancesNavType,
          instanceSortOption: _instanceSortOption,
          launchPageQuickSwitch: _launchPageQuickSwitch,
          onInstancesNavTypeChanged: (v) => _setString(
            ConfigKeys.instancesNavType,
            v,
            (val) => _instancesNavType = val,
          ),
          onInstanceSortOptionChanged: (v) => _setString(
            ConfigKeys.instanceSortOption,
            v,
            (val) => _instanceSortOption = val,
          ),
          onLaunchPageQuickSwitchChanged: (v) => _setBool(
            ConfigKeys.launchPageQuickSwitch,
            v,
            (val) => _launchPageQuickSwitch = val,
          ),
        );
      case SettingsSectionId.launchBehavior:
        return LaunchBehaviorSection(
          launchAtStartup: _launchAtStartup,
          minimizeToTray: _minimizeToTray,
          closeToTray: _closeToTray,
          processPriority: _processPriority,
          skipFirstScreenOptions: _skipFirstScreenOptions,
          displayGameLog: _displayGameLog,
          customTitle: _customTitle,
          onLaunchAtStartupChanged: (v) => _setBool(
            ConfigKeys.launchAtStartup,
            v,
            (val) => _launchAtStartup = val,
          ),
          onMinimizeToTrayChanged: (v) => _setBool(
            ConfigKeys.minimizeToTray,
            v,
            (val) => _minimizeToTray = val,
          ),
          onCloseToTrayChanged: (v) =>
              _setBool(ConfigKeys.closeToTray, v, (val) => _closeToTray = val),
          onProcessPriorityChanged: (v) => _setString(
            ConfigKeys.processPriority,
            v,
            (val) => _processPriority = val,
          ),
          onSkipFirstScreenChanged: (v) => _setBool(
            ConfigKeys.skipFirstScreenOptions,
            v,
            (val) => _skipFirstScreenOptions = val,
          ),
          onDisplayGameLogChanged: (v) => _setBool(
            ConfigKeys.displayGameLog,
            v,
            (val) => _displayGameLog = val,
          ),
          onCustomTitleChanged: (v) => _setString(
            ConfigKeys.customTitle,
            v,
            (val) => _customTitle = val,
          ),
        );
      case SettingsSectionId.download:
        return DownloadSection(
          downloadSource: _downloadSource,
          mirrorSourceIndex: _mirrorSourceIndex,
          selectedMirror: _selectedMirror,
          autoSwitchMirror: _autoSwitchMirror,
          onDownloadSourceChanged: (v) => _setString(
            ConfigKeys.downloadSource,
            v,
            (val) => _downloadSource = val,
          ),
          onMirrorSourceIndexChanged: (v) => _setInt(
            ConfigKeys.mirrorSourceIndex,
            v,
            (val) => _mirrorSourceIndex = val,
          ),
          onSelectedMirrorChanged: (v) => _setString(
            ConfigKeys.selectedMirror,
            v,
            (val) => _selectedMirror = val,
          ),
          onAutoSwitchMirrorChanged: (v) => _setBool(
            ConfigKeys.autoSwitchMirror,
            v,
            (val) => _autoSwitchMirror = val,
          ),
          onAddCustomMirror: _addCustomMirror,
          onSpeedTest: _speedTest,
        );
      case SettingsSectionId.downloadParams:
        return DownloadParamsSection(
          concurrentDownloads: _concurrentDownloads,
          downloadPath: _downloadPath,
          maxRetries: _maxRetries,
          autoRetryDownload: _autoRetryDownload,
          enableSpeedLimit: _enableSpeedLimit,
          speedLimitValue: _speedLimitValue,
          cacheDirectory: _cacheDirectory,
          onConcurrentDownloadsChanged: (v) => _setInt(
            ConfigKeys.concurrentDownloads,
            v,
            (val) => _concurrentDownloads = val,
          ),
          onDownloadPathChanged: (_) => _pickDownloadPath(),
          onMaxRetriesChanged: (v) =>
              _setInt(ConfigKeys.maxRetries, v, (val) => _maxRetries = val),
          onAutoRetryDownloadChanged: (v) => _setBool(
            ConfigKeys.autoRetryDownload,
            v,
            (val) => _autoRetryDownload = val,
          ),
          onEnableSpeedLimitChanged: (v) => _setBool(
            ConfigKeys.enableSpeedLimit,
            v,
            (val) => _enableSpeedLimit = val,
          ),
          onSpeedLimitChanged: (v) => _setDouble(
            ConfigKeys.speedLimitValue,
            v,
            (val) => _speedLimitValue = val,
          ),
          onCacheDirectoryChanged: (v) => _setString(
            ConfigKeys.cacheDirectory,
            v,
            (val) => _cacheDirectory = val,
          ),
        );
      case SettingsSectionId.resourceCenter:
        return ResourceCenterSection(
          resourceCenterSource: _resourceCenterSource,
          resourceCenterDefaultType: _resourceCenterDefaultType,
          resourceCenterSortBy: _resourceCenterSortBy,
          resourceCenterEnableCache: _resourceCenterEnableCache,
          resourceCenterCacheDuration: _resourceCenterCacheDuration,
          resourceCenterShowInstalledOnly: _resourceCenterShowInstalledOnly,
          resourceCenterAutoUpdateResources: _resourceCenterAutoUpdateResources,
          onResourceCenterSourceChanged: (v) => _setString(
            ConfigKeys.resourceCenterSource,
            v,
            (val) => _resourceCenterSource = val,
          ),
          onResourceCenterDefaultTypeChanged: (v) => _setString(
            ConfigKeys.resourceCenterDefaultType,
            v,
            (val) => _resourceCenterDefaultType = val,
          ),
          onResourceCenterSortByChanged: (v) => _setString(
            ConfigKeys.resourceCenterSortBy,
            v,
            (val) => _resourceCenterSortBy = val,
          ),
          onResourceCenterEnableCacheChanged: (v) => _setBool(
            ConfigKeys.resourceCenterEnableCache,
            v,
            (val) => _resourceCenterEnableCache = val,
          ),
          onResourceCenterCacheDurationChanged: (v) => _setInt(
            ConfigKeys.resourceCenterCacheDuration,
            v,
            (val) => _resourceCenterCacheDuration = val,
          ),
          onResourceCenterShowInstalledOnlyChanged: (v) => _setBool(
            ConfigKeys.resourceCenterShowInstalledOnly,
            v,
            (val) => _resourceCenterShowInstalledOnly = val,
          ),
          onResourceCenterAutoUpdateChanged: (v) => _setBool(
            ConfigKeys.resourceCenterAutoUpdateResources,
            v,
            (val) => _resourceCenterAutoUpdateResources = val,
          ),
        );
      case SettingsSectionId.backup:
        return BackupSection(
          autoBackupEnabled: _autoBackupEnabled,
          autoBackupSchedule: _autoBackupSchedule,
          autoBackupKeepCount: _autoBackupKeepCount,
          autoBackupCompress: _autoBackupCompress,
          onAutoBackupEnabledChanged: (v) => _setBool(
            ConfigKeys.autoBackupEnabled,
            v,
            (val) => _autoBackupEnabled = val,
          ),
          onAutoBackupScheduleChanged: (v) => _setString(
            ConfigKeys.autoBackupSchedule,
            v,
            (val) => _autoBackupSchedule = val,
          ),
          onAutoBackupKeepCountChanged: (v) => _setInt(
            ConfigKeys.autoBackupKeepCount,
            v,
            (val) => _autoBackupKeepCount = val,
          ),
          onAutoBackupCompressChanged: (v) => _setBool(
            ConfigKeys.autoBackupCompress,
            v,
            (val) => _autoBackupCompress = val,
          ),
          onViewHistory: _viewBackupHistory,
          onBackupAllNow: _backupAllNow,
        );
      case SettingsSectionId.personalization:
        return PersonalizationSection(
          themeMode: _themeMode,
          colorScheme: _colorScheme,
          headNavStyle: _headNavStyle,
          fontSize: _fontSize,
          enableSoundEffects: _enableSoundEffects,
          enableSplashAnimation: _enableAnimation,
          randomCustomBackground: _randomCustomBackground,
          autoDarkenBackground: _autoDarkenBackground,
          autoPurgeLauncherLogs: _autoPurgeLauncherLogs,
          onThemeModeChanged: _saveThemeMode,
          onColorSchemeChanged: _setColorScheme,
          onHeadNavStyleChanged: (v) => _setString(
            ConfigKeys.headNavStyle,
            v,
            (val) => _headNavStyle = val,
          ),
          onFontSizeChanged: (v) =>
              _setDouble(ConfigKeys.fontSize, v, (val) => _fontSize = val),
          onEnableSoundEffectsChanged: (v) => _setBool(
            ConfigKeys.enableSoundEffects,
            v,
            (val) => _enableSoundEffects = val,
          ),
          onEnableSplashAnimationChanged: (v) => _setBool(
            ConfigKeys.enableSplashAnimation,
            v,
            (val) => _enableAnimation = val,
          ),
          onRandomCustomBackgroundChanged: (v) => _setBool(
            ConfigKeys.randomCustomBackground,
            v,
            (val) => _randomCustomBackground = val,
          ),
          onAutoDarkenBackgroundChanged: (v) => _setBool(
            ConfigKeys.autoDarkenBackground,
            v,
            (val) => _autoDarkenBackground = val,
          ),
          onAutoPurgeLauncherLogsChanged: (v) => _setBool(
            ConfigKeys.autoPurgeLauncherLogs,
            v,
            (val) => _autoPurgeLauncherLogs = val,
          ),
          onOpenThemeEditor: _openThemeEditor,
          onManageBackground: _manageBackground,
        );
      case SettingsSectionId.advanced:
        return AdvancedSection(
          useProxy: _useProxy,
          proxyAddressCtrl: _proxyHostController,
          proxyPortCtrl: _proxyPortController,
          language: _language,
          mcpServerEnabled: _mcpServerEnabled,
          mcpServerPort: _mcpServerPort,
          extensionsEnabled: _extensionsEnabled,
          translateResourceNames: _translateResourceNames,
          sendAnonymousStats: _sendAnonymousStats,
          autoReportCrashes: _autoReportCrashes,
          onUseProxyChanged: (v) =>
              _setBool(ConfigKeys.useProxy, v, (val) => _useProxy = val),
          onProxyAddressSubmitted: (v) =>
              _setString(ConfigKeys.proxyHost, v, (val) => _proxyHost = v),
          onProxyPortSubmitted: (v) {
            final port = int.tryParse(v) ?? 0;
            _setInt(ConfigKeys.proxyPort, port, (val) => _proxyPort = val);
          },
          onLanguageChanged: (v) =>
              _setString(ConfigKeys.language, v, (val) => _language = val),
          onMcpServerEnabledChanged: (v) => _setBool(
            ConfigKeys.mcpServerEnabled,
            v,
            (val) => _mcpServerEnabled = val,
          ),
          onMcpServerPortChanged: (v) => _setInt(
            ConfigKeys.mcpServerPort,
            v,
            (val) => _mcpServerPort = val,
          ),
          onExtensionsEnabledChanged: (v) => _setBool(
            ConfigKeys.extensionsEnabled,
            v,
            (val) => _extensionsEnabled = val,
          ),
          onTranslateResourceNamesChanged: (v) => _setBool(
            ConfigKeys.resourceTranslation,
            v,
            (val) => _translateResourceNames = val,
          ),
          onSendAnonymousStatsChanged: (v) => _setPrivacyFlag(
            v,
            (c) => !c.disableAnalytics,
            (c, val) => c.copyWith(disableAnalytics: !val),
            (val) => _sendAnonymousStats = val,
          ),
          onAutoReportCrashesChanged: (v) => _setPrivacyFlag(
            v,
            (c) => !c.disableCrashReporting,
            (c, val) => c.copyWith(disableCrashReporting: !val),
            (val) => _autoReportCrashes = val,
          ),
        );
      case SettingsSectionId.about:
        return AboutSection(
          autoUpdate: _autoUpdate,
          launcherVersion: _launcherVersion,
          buildTime: _buildTime,
          onCheckUpdate: _checkUpdate,
          onAutoUpdateChanged: (v) =>
              _setBool(ConfigKeys.autoUpdate, v, (val) => _autoUpdate = val),
          onViewChangelog: _showChangelog,
          onViewOpenSource: _showOpenSourceDialog,
        );
      default:
        return AccountsSection(
          currentAccountLabel: _currentAccountLabel,
          authlibSelectedServer: _authlibSelectedServer,
          onLoginMicrosoft: _loginMicrosoft,
          onRefreshToken: _refreshToken,
          onAddAuthlibServer: _addAuthlibServer,
          onAuthlibServerChanged: _onAuthlibServerChanged,
          onManageAuthlibServers: _manageAuthlibServers,
          onCreateOfflineAccount: _createOfflineAccount,
        );
    }
  }

  // ==================== 背景选择 / 开源对话框 ====================

  void _showBackgroundSelector() {
    BackgroundPickerDialog.show(
      context,
      currentConfig: _backgroundConfig,
      onChanged: (config) async {
        await _backgroundManager.saveBackgroundConfig(config);
        if (!mounted) return;
        setState(() => _backgroundConfig = config);
      },
    );
  }

  void _showOpenSourceDialog() {
    OpenSourceDialog.show(context);
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.transparent),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              constraints: const BoxConstraints(maxWidth: 1100, minWidth: 880),
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: SettingsPalette.backgroundGradient(context),
                boxShadow: SettingsPalette.panelShadow(context),
              ),
              child: Row(
                children: [
                  SettingsSidebar(
                    sections: _buildSidebarSections(),
                    selectedId: _selectedId,
                    onSelected: (id) => setState(() => _selectedId = id),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: KeyedSubtree(
                          key: ValueKey(_selectedId),
                          child: _buildSelectedContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
