import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/background_config.dart';
import '../../../config/config_keys.dart';
import '../../../config/config_manager.dart';
import '../../../core/constants.dart';
import '../../theme/background_manager.dart';
import '../../theme/colors.dart';
import '../../theme/theme_manager.dart';
import '../ba_background_selector.dart';
import '../ba_notification.dart';
import '../../../loader/java_selector_dialog.dart';
import 'widgets/sidebar_nav.dart';
import 'widgets/settings_content_area.dart';
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

  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;
  late TextEditingController _jvmArgsController;
  late TextEditingController _gameArgsController;

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
        return const AccountsSection();
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
        );
      case SettingsSectionId.personalization:
        return PersonalizationSection(
          themeMode: _themeMode,
          headNavStyle: _headNavStyle,
          fontSize: _fontSize,
          enableSoundEffects: _enableSoundEffects,
          enableSplashAnimation: _enableAnimation,
          onThemeModeChanged: _saveThemeMode,
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
        );
      case SettingsSectionId.about:
        return const AboutSection();
      default:
        return const AccountsSection();
    }
  }

  // ==================== 背景选择 / 开源对话框 ====================

  void _showBackgroundSelector() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('背景设置'),
        content: SizedBox(
          width: 400,
          child: BABackgroundSelector(
            currentConfig: _backgroundConfig,
            onConfigChanged: (config) async {
              await _backgroundManager.saveBackgroundConfig(config);
              if (!mounted) return;
              setState(() => _backgroundConfig = config);
            },
            onPickImage: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
              );
              if (!mounted) return;
              if (result != null && result.files.isNotEmpty) {
                final path = result.files.single.path;
                if (path != null) {
                  final config = BackgroundConfig(
                    type: BackgroundType.image,
                    imagePath: path,
                    opacity: 1.0,
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                  await _backgroundManager.saveBackgroundConfig(config);
                  if (!mounted) return;
                  setState(() => _backgroundConfig = config);
                  NotificationManager().showSuccess('背景已更新');
                }
              }
            },
            onPickVideo: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.video,
              );
              if (!mounted) return;
              if (result != null && result.files.isNotEmpty) {
                final path = result.files.single.path;
                if (path != null) {
                  final config = BackgroundConfig(
                    type: BackgroundType.video,
                    videoPath: path,
                    opacity: 1.0,
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                  await _backgroundManager.saveBackgroundConfig(config);
                  if (!mounted) return;
                  setState(() => _backgroundConfig = config);
                  NotificationManager().showSuccess('背景已更新');
                }
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  void _showOpenSourceDialog() {
    final openSourceProjects = [
      {
        'name': 'Flutter',
        'url': 'https://github.com/flutter/flutter',
        'license': 'BSD-3-Clause',
      },
      {'name': 'BMCLAPI', 'url': 'https://www.bmclapi.com/', 'license': '服务'},
      {'name': 'Modrinth', 'url': 'https://modrinth.com', 'license': 'API'},
      {
        'name': 'CurseForge',
        'url': 'https://www.curseforge.com/minecraft',
        'license': 'API',
      },
      {
        'name': 'url_launcher',
        'url':
            'https://github.com/flutter/packages/tree/main/packages/url_launcher',
        'license': 'BSD-3-Clause',
      },
      {
        'name': 'file_picker',
        'url': 'https://github.com/miguelpruivo/flutter_file_picker',
        'license': 'MIT',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: const Color(0xFFE668A8), size: 20),
            const SizedBox(width: 8),
            const Text('开源组件'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: openSourceProjects.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final project = openSourceProjects[index];
              return ListTile(
                leading: const Icon(Icons.code),
                title: Text(project['name']!),
                subtitle: Text(project['license']!),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () async {
                    final url = project['url']!;
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
                gradient: SettingsPalette.backgroundGradient,
                boxShadow: SettingsPalette.panelShadow,
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
