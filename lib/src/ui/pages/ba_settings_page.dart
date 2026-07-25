import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/background_config.dart';
import '../../config/config_keys.dart';
import '../../config/config_manager.dart';
import '../../core/constants.dart';
import '../../game/backup_manager.dart';
import '../../game/game_statistics.dart';
import '../../loader/java_selector_dialog.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../updater/update_manager.dart';
import '../animations/ba_animations.dart';
import '../animations/ba_effects.dart';
import '../components/ba_notification.dart';
import '../theme/background_manager.dart';
import '../theme/colors.dart';
import '../theme/theme_manager.dart';
import 'settings/about_settings_page.dart';
import 'settings/background_settings_page.dart';
import 'settings/backup_settings_page.dart';
import 'settings/download_settings_page.dart';
import 'settings/game_settings_page.dart';
import 'settings/general_settings_page.dart';
import 'settings/statistics_settings_page.dart';

class BASettingsPage extends StatefulWidget {
  const BASettingsPage({super.key});

  @override
  State<BASettingsPage> createState() => _BASettingsPageState();
}

class _BASettingsPageState extends State<BASettingsPage> {
  /// 应用版本号(集中管理,与 pubspec.yaml 保持一致)
  static const String _appVersion = '1.0.0';

  /// 应用构建号
  static const String _appBuild = '1';

  /// 应用全版本显示
  String get _appVersionDisplay => 'v$_appVersion+$_appBuild';

  final ConfigManager _configManager = ConfigManager();
  final ThemeManager _themeManager = ThemeManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  final BackupManager _backupManager = BackupManager.instance;
  final GameStatisticsManager _statisticsManager =
      GameStatisticsManager.instance;

  String _selectedCategory = 'general';
  bool _notificationInitialized = false;
  bool _themeManagerInitialized = false;
  bool _managersInitialized = false;

  BackgroundConfig _backgroundConfig = BackgroundConfig.classic;

  String _gameDirectory = '';
  String _javaPath = '';
  double _memoryAllocation = BAMCConstants.recommendedMaxMemoryMB.toDouble();
  String _themeMode = 'dark';
  bool _autoUpdate = true;
  String _language = '简体中文';
  bool _isCheckingUpdate = false;
  bool _launchAtStartup = false;
  bool _minimizeToTray = true;
  bool _closeToTray = false;

  String _gameWindowSize = '1280x720';
  final TextEditingController _jvmArgsController = TextEditingController();
  final TextEditingController _gameArgsController = TextEditingController();
  final FocusNode _jvmArgsFocusNode = FocusNode();
  final FocusNode _gameArgsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _jvmArgsFocusNode.addListener(_onJvmArgsFocusChange);
    _gameArgsFocusNode.addListener(_onGameArgsFocusChange);
    _initAllManagers();
    _loadSettings();
  }

  Future<void> _initAllManagers() async {
    await _themeManager.initialize();
    await _backupManager.initialize();
    await _statisticsManager.initialize();
    await _loadBackgroundConfig();
    if (mounted) {
      setState(() {
        _themeManagerInitialized = true;
        _managersInitialized = true;
      });
    }
  }

  Future<void> _initThemeManager() async {
    await _themeManager.initialize();
    await _loadBackgroundConfig();
    if (mounted) {
      setState(() {
        _themeManagerInitialized = true;
      });
    }
  }

  Future<void> _loadBackgroundConfig() async {
    // BackgroundManager 已在主页面初始化，直接读取当前配置即可
    if (mounted) {
      setState(() {
        _backgroundConfig = _backgroundManager.currentConfig;
      });
    }
  }

  @override
  void dispose() {
    _jvmArgsFocusNode.removeListener(_onJvmArgsFocusChange);
    _gameArgsFocusNode.removeListener(_onGameArgsFocusChange);
    _jvmArgsController.dispose();
    _gameArgsController.dispose();
    _jvmArgsFocusNode.dispose();
    _gameArgsFocusNode.dispose();
    super.dispose();
  }

  void _onJvmArgsFocusChange() {
    if (!_jvmArgsFocusNode.hasFocus) {
      _saveJvmArguments(_jvmArgsController.text);
    }
  }

  void _onGameArgsFocusChange() {
    if (!_gameArgsFocusNode.hasFocus) {
      _saveGameArguments(_gameArgsController.text);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationInitialized) {
      NotificationManager().init(context);
      _notificationInitialized = true;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final gameDir = _configManager.getString(ConfigKeys.gameDirectory) ?? '';
      final javaPath = _configManager.getString(ConfigKeys.javaPath) ?? '';
      final memory =
          _configManager.getInt(ConfigKeys.memoryAllocation) ??
          BAMCConstants.recommendedMaxMemoryMB;
      final autoUpdate = _configManager.getBool(ConfigKeys.autoUpdate) ?? true;
      final language = _configManager.getString(ConfigKeys.language) ?? '简体中文';
      final launchAtStartup =
          _configManager.getBool(ConfigKeys.launchAtStartup) ?? false;
      final minimizeToTray =
          _configManager.getBool(ConfigKeys.minimizeToTray) ?? true;
      final closeToTray =
          _configManager.getBool(ConfigKeys.closeToTray) ?? false;
      final gameWindowSize =
          _configManager.getString(ConfigKeys.gameWindowSize) ?? '1280x720';
      final jvmArguments =
          _configManager.getString(ConfigKeys.jvmArguments) ?? '';
      final gameArguments =
          _configManager.getString(ConfigKeys.gameArguments) ?? '';

      await _initThemeManager();

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
          _gameDirectory = gameDir;
          _javaPath = javaPath;
          _memoryAllocation = memory.toDouble();
          _themeMode = themeModeStr;
          _autoUpdate = autoUpdate;
          _language = language;
          _launchAtStartup = launchAtStartup;
          _minimizeToTray = minimizeToTray;
          _closeToTray = closeToTray;
          _gameWindowSize = gameWindowSize;
          _jvmArgsController.text = jvmArguments;
          _gameArgsController.text = gameArguments;
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('加载设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveGameDirectory(String dir) async {
    try {
      await _configManager.setString(ConfigKeys.gameDirectory, dir);
      if (!mounted) return;
      setState(() {
        _gameDirectory = dir;
      });
      NotificationManager().showSuccess('游戏目录已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存游戏目录失败', message: e.toString());
      }
    }
  }

  Future<void> _saveJavaPath(String path) async {
    try {
      await _configManager.setString(ConfigKeys.javaPath, path);
      if (!mounted) return;
      setState(() {
        _javaPath = path;
      });
      NotificationManager().showSuccess('Java路径已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存Java路径失败', message: e.toString());
      }
    }
  }

  Future<void> _saveMemoryAllocation(double value) async {
    if (!mounted) return;
    setState(() {
      _memoryAllocation = value;
    });
  }

  Future<void> _commitMemoryAllocation(double value) async {
    try {
      await _configManager.setInt(ConfigKeys.memoryAllocation, value.toInt());
      if (!mounted) return;
      NotificationManager().showSuccess('内存分配已保存: ${value.toInt()} MB');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存内存分配失败', message: e.toString());
      }
    }
  }

  Future<void> _saveThemeMode(String mode, ThemeManager themeManager) async {
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
      await themeManager.setThemeMode(themeMode);
      if (!mounted) return;
      setState(() {
        _themeMode = mode;
      });
      NotificationManager().showSuccess('主题已切换');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('切换主题失败', message: e.toString());
      }
    }
  }

  Future<void> _saveAutoUpdate(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.autoUpdate, value);
      if (!mounted) return;
      setState(() {
        _autoUpdate = value;
      });
      NotificationManager().showSuccess('自动更新设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存自动更新设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveLanguage(String lang) async {
    try {
      await _configManager.setString(ConfigKeys.language, lang);
      if (!mounted) return;
      setState(() {
        _language = lang;
      });
      NotificationManager().showSuccess('语言设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存语言设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveLaunchAtStartup(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.launchAtStartup, value);
      if (!mounted) return;
      setState(() {
        _launchAtStartup = value;
      });
      NotificationManager().showSuccess('开机自启动设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存开机自启动设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveMinimizeToTray(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.minimizeToTray, value);
      if (!mounted) return;
      setState(() {
        _minimizeToTray = value;
      });
      NotificationManager().showSuccess('最小化到托盘设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存最小化到托盘设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveCloseToTray(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.closeToTray, value);
      if (!mounted) return;
      setState(() {
        _closeToTray = value;
      });
      NotificationManager().showSuccess('关闭时最小化到托盘设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError(
          '保存关闭时最小化到托盘设置失败',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _saveGameWindowSize(String size) async {
    try {
      await _configManager.setString(ConfigKeys.gameWindowSize, size);
      if (!mounted) return;
      setState(() {
        _gameWindowSize = size;
      });
      NotificationManager().showSuccess('游戏窗口分辨率已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存游戏窗口分辨率失败', message: e.toString());
      }
    }
  }

  Future<void> _saveJvmArguments(String args) async {
    try {
      await _configManager.setString(ConfigKeys.jvmArguments, args);
      if (!mounted) return;
      setState(() {
        _jvmArgsController.text = args;
      });
      NotificationManager().showSuccess('JVM额外参数已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存JVM额外参数失败', message: e.toString());
      }
    }
  }

  Future<void> _saveGameArguments(String args) async {
    try {
      await _configManager.setString(ConfigKeys.gameArguments, args);
      if (!mounted) return;
      setState(() {
        _gameArgsController.text = args;
      });
      NotificationManager().showSuccess('游戏启动参数已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存游戏启动参数失败', message: e.toString());
      }
    }
  }

  Future<void> _pickGameDirectory() async {
    try {
      final IPlatformAdapter platformAdapter = PlatformAdapterFactory.create();
      String? initialDir;
      if (_gameDirectory.isNotEmpty) {
        initialDir = _gameDirectory;
      } else {
        initialDir = await platformAdapter.getDefaultGameDirectory();
      }
      final result = await FilePicker.platform.getDirectoryPath(
        initialDirectory: initialDir,
      );
      if (result != null) {
        await _saveGameDirectory(result);
      }
    } catch (e) {
      NotificationManager().showError('选择目录失败', message: e.toString());
    }
  }

  Future<void> _pickJavaPath() async {
    try {
      final selectedPath = await JavaSelectorDialog.show(
        context,
        currentJavaPath: _javaPath.isEmpty ? null : _javaPath,
      );
      if (selectedPath != null) {
        await _saveJavaPath(selectedPath);
      }
    } catch (e) {
      NotificationManager().showError('选择Java路径失败', message: e.toString());
    }
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      final release = await UpdateManager.instance.checkForUpdates(force: true);
      if (mounted) {
        if (release != null) {
          NotificationManager().showInfo(
            '检查更新',
            message: '最新版本: ${release.version}',
          );
        } else {
          NotificationManager().showSuccess('检查更新', message: '当前已是最新版本');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('检查更新失败', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildCategoryList(),
                Expanded(child: _buildSettingsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final cardBg = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);
    final primaryText = BAColors.textPrimaryOf(context);
    final secondaryText = BAColors.textSecondaryOf(context);
    final accentBlue = BAColors.primaryLightOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: BAColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设置',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '启动器参数与偏好设置',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: accentBlue, size: 18),
                const SizedBox(width: 6),
                Text(
                  _appVersionDisplay,
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categoryNames = {
      'general': '通用',
      'background': '背景',
      'backup': '备份',
      'statistics': '统计',
      'game': '游戏',
      'download': '下载',
      'about': '关于',
    };

    final categoryIcons = {
      'general': Icons.settings,
      'background': Icons.wallpaper,
      'backup': Icons.backup,
      'statistics': Icons.bar_chart,
      'game': Icons.games,
      'download': Icons.download,
      'about': Icons.info,
    };

    final bgColor = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);
    final selectedBgColor = BAColors.surfaceTertiaryOf(context);
    final unselectedText = BAColors.textSecondaryOf(context);
    final unselectedIcon = BAColors.primaryLightOf(context);
    final unselectedBgA = BAColors.surfaceTertiaryOf(context);
    final unselectedBgB = BAColors.surfaceOf(context);
    final primaryText = BAColors.textPrimaryOf(context);

    return BAAnimations.gradientBorder(
      isActive: true,
      duration: const Duration(milliseconds: 4000),
      gradientColors: [
        BAColors.primaryOf(context),
        BAColors.primaryOf(context).withValues(alpha: 0.3),
        BAColors.primaryLightOf(context).withValues(alpha: 0.2),
        BAColors.primaryOf(context),
      ],
      borderWidth: 1.5,
      borderRadius: 16,
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(left: 20, top: 8, bottom: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: categoryNames.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final categoryId = categoryNames.keys.elementAt(index);
            final categoryName = categoryNames[categoryId]!;
            final icon = categoryIcons[categoryId]!;
            final isSelected = _selectedCategory == categoryId;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = categoryId;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? BAColors.primaryOf(context)
                          : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: BAColors.primaryOf(
                                context,
                              ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: BAColors.primaryOf(
                                context,
                              ).withValues(alpha: 0.1),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      isSelected
                          ? BAEffects.neonGlow(
                              isActive: true,
                              glowColor: BAColors.primaryOf(context),
                              duration: const Duration(milliseconds: 2000),
                              blurRadius: 10,
                              spreadRadius: 1,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      BAColors.primaryOf(context),
                                      unselectedIcon,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BAColors.primaryOf(
                                        context,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [unselectedBgA, unselectedBgB],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : unselectedIcon,
                                size: 16,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected ? primaryText : unselectedText,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    if (!_managersInitialized) {
      return Center(
        child: CircularProgressIndicator(color: BAColors.primaryOf(context)),
      );
    }

    switch (_selectedCategory) {
      case 'general':
        return GeneralSettingsPage(
          themeManagerInitialized: _themeManagerInitialized,
          language: _language,
          themeMode: _themeMode,
          autoUpdate: _autoUpdate,
          launchAtStartup: _launchAtStartup,
          minimizeToTray: _minimizeToTray,
          closeToTray: _closeToTray,
          isCheckingUpdate: _isCheckingUpdate,
          themeManager: _themeManager,
          onLanguageChanged: _saveLanguage,
          onThemeModeChanged: (mode) => _saveThemeMode(mode, _themeManager),
          onAutoUpdateChanged: _saveAutoUpdate,
          onLaunchAtStartupChanged: _saveLaunchAtStartup,
          onMinimizeToTrayChanged: _saveMinimizeToTray,
          onCloseToTrayChanged: _saveCloseToTray,
          onCheckUpdate: _checkForUpdate,
        );
      case 'background':
        return BackgroundSettingsPage(
          backgroundConfig: _backgroundConfig,
          onConfigChanged: (config) =>
              setState(() => _backgroundConfig = config),
        );
      case 'backup':
        return const BackupSettingsPage();
      case 'statistics':
        return const StatisticsSettingsPage();
      case 'game':
        return GameSettingsPage(
          gameDirectory: _gameDirectory,
          javaPath: _javaPath,
          memoryAllocation: _memoryAllocation,
          gameWindowSize: _gameWindowSize,
          initialJvmArgs: _jvmArgsController.text,
          initialGameArgs: _gameArgsController.text,
          onPickGameDirectory: _pickGameDirectory,
          onPickJavaPath: _pickJavaPath,
          onMemoryAllocationChanged: _saveMemoryAllocation,
          onMemoryAllocationCommitted: _commitMemoryAllocation,
          onGameWindowSizeChanged: _saveGameWindowSize,
        );
      case 'download':
        return const DownloadSettingsPage();
      case 'about':
        return AboutSettingsPage(appVersionDisplay: _appVersionDisplay);
      default:
        return GeneralSettingsPage(
          themeManagerInitialized: _themeManagerInitialized,
          language: _language,
          themeMode: _themeMode,
          autoUpdate: _autoUpdate,
          launchAtStartup: _launchAtStartup,
          minimizeToTray: _minimizeToTray,
          closeToTray: _closeToTray,
          isCheckingUpdate: _isCheckingUpdate,
          themeManager: _themeManager,
          onLanguageChanged: _saveLanguage,
          onThemeModeChanged: (mode) => _saveThemeMode(mode, _themeManager),
          onAutoUpdateChanged: _saveAutoUpdate,
          onLaunchAtStartupChanged: _saveLaunchAtStartup,
          onMinimizeToTrayChanged: _saveMinimizeToTray,
          onCloseToTrayChanged: _saveCloseToTray,
          onCheckUpdate: _checkForUpdate,
        );
    }
  }
}
