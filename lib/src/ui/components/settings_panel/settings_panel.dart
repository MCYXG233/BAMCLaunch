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
import 'widgets/sidebar_nav_item.dart';
import 'widgets/settings_content_area.dart';
import 'widgets/settings_theme.dart';
import 'sections/account_settings.dart';
import 'sections/advanced_settings.dart';
import 'sections/audio_settings.dart';
import 'sections/accessibility_settings.dart';
import 'sections/about_settings.dart';
import 'sections/download_settings.dart';
import 'sections/game_directory_settings.dart';
import 'sections/general_settings.dart';
import 'sections/home_interface_settings.dart';
import 'sections/java_settings.dart';
import 'sections/language_settings.dart';
import 'sections/theme_settings.dart';

/// 设置面板分类 ID（与侧栏导航 ID 一致）
class SettingsSectionId {
  SettingsSectionId._();
  static const general = 'general';
  static const account = 'account';
  static const java = 'java';
  static const gameDir = 'game_dir';
  static const advanced = 'advanced';
  static const theme = 'theme';
  static const homeInterface = 'home_interface';
  static const language = 'language';
  static const audio = 'audio';
  static const accessibility = 'accessibility';
  static const download = 'download';
  static const about = 'about';
}

/// 设置面板
///
/// 布局：
///   - 全屏覆盖（替代居中 Dialog）
///   - 左侧导航：搜索框 + 分组（游戏/个性化/网络/其他）
///   - 右侧内容：面包屑 + 标题 + 分组卡片（可折叠）
///   - 浅色磨砂亚克力风格
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
  String _selectedId = SettingsSectionId.account;

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
  double _volume = 0.2;

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

  Future<void> _saveGameDirectory(String dir) async {
    try {
      await _configManager.setString(ConfigKeys.gameDirectory, dir);
      if (mounted) setState(() => _gameDirectory = dir);
      NotificationManager().showSuccess('游戏目录已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveJavaPath(String path) async {
    try {
      await _configManager.setString(ConfigKeys.javaPath, path);
      if (mounted) setState(() => _javaPath = path);
      NotificationManager().showSuccess('Java路径已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveMemoryAllocation(double value) async {
    try {
      await _configManager.setInt(ConfigKeys.memoryAllocation, value.toInt());
      if (mounted) setState(() => _memoryAllocation = value);
      NotificationManager().showSuccess('内存分配已保存: ${value.toInt()} MB');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

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

  Future<void> _saveColorScheme(String scheme) async {
    try {
      await _themeManager.setTheme(scheme);
      if (mounted) setState(() => _colorScheme = scheme);
      NotificationManager().showSuccess(
        scheme == 'blue_archive' ? '已切换到蔚蓝档案配色' : '已切换到 Minecraft 配色',
      );
    } catch (e) {
      if (mounted)
        NotificationManager().showError('切换配色方案失败', message: e.toString());
    }
  }

  Future<void> _saveDownloadSource(String source) async {
    try {
      await _configManager.setString(ConfigKeys.downloadSource, source);
      if (mounted) setState(() => _downloadSource = source);
      NotificationManager().showSuccess('下载源已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveConcurrentDownloads(int count) async {
    try {
      await _configManager.setInt(ConfigKeys.concurrentDownloads, count);
      if (mounted) setState(() => _concurrentDownloads = count);
      NotificationManager().showSuccess('下载线程已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveGameWindowSize(String value) async {
    try {
      await _configManager.setString(ConfigKeys.gameWindowSize, value);
      if (mounted) setState(() => _gameWindowSize = value);
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveProxyHost(String value) async {
    try {
      await _configManager.setString(ConfigKeys.proxyHost, value);
      if (mounted) setState(() => _proxyHost = value);
      NotificationManager().showSuccess('代理主机已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveProxyPort(String value) async {
    try {
      final port = int.tryParse(value) ?? 0;
      await _configManager.setInt(ConfigKeys.proxyPort, port);
      if (mounted) setState(() => _proxyPort = port);
      NotificationManager().showSuccess('代理端口已保存');
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveJvmArguments(String value) async {
    try {
      await _configManager.setString(ConfigKeys.jvmArguments, value);
      if (mounted) setState(() => _jvmArguments = value);
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _saveGameArguments(String value) async {
    try {
      await _configManager.setString(ConfigKeys.gameArguments, value);
      if (mounted) setState(() => _gameArguments = value);
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _setBool(
    String key,
    bool value,
    ValueChanged<bool> update,
  ) async {
    try {
      await _configManager.setBool(key, value);
      update(value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _pickGameDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) _saveGameDirectory(result);
  }

  Future<void> _pickDownloadPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      try {
        await _configManager.setString(ConfigKeys.downloadPath, result);
        if (!mounted) return;
        setState(() => _downloadPath = result);
      } catch (e) {
        if (mounted)
          NotificationManager().showError('保存失败', message: e.toString());
      }
    }
  }

  Future<void> _pickJavaPath() async {
    final result = await JavaSelectorDialog.show(context);
    if (result != null) _saveJavaPath(result);
  }

  // ==================== 侧栏导航 ====================

  List<SidebarSection> _buildSidebarSections() {
    return [
      SidebarSection(
        title: '游戏',
        items: [
          SidebarItem(
            id: SettingsSectionId.account,
            icon: Icons.person_outline,
            label: '账户与档案',
          ),
          SidebarItem(
            id: SettingsSectionId.java,
            icon: Icons.coffee_outlined,
            label: 'Java 虚拟机与内存',
          ),
          SidebarItem(
            id: SettingsSectionId.gameDir,
            icon: Icons.folder_outlined,
            label: '游戏目录',
          ),
          SidebarItem(
            id: SettingsSectionId.advanced,
            icon: Icons.tune,
            label: '高级',
          ),
        ],
      ),
      SidebarSection(
        title: '个性化',
        items: [
          SidebarItem(
            id: SettingsSectionId.theme,
            icon: Icons.palette_outlined,
            label: '主题与背景',
          ),
          SidebarItem(
            id: SettingsSectionId.homeInterface,
            icon: Icons.dashboard_outlined,
            label: '主界面',
          ),
          SidebarItem(
            id: SettingsSectionId.language,
            icon: Icons.translate,
            label: '语言 / Language',
          ),
          SidebarItem(
            id: SettingsSectionId.audio,
            icon: Icons.volume_up_outlined,
            label: '音频',
          ),
          SidebarItem(
            id: SettingsSectionId.accessibility,
            icon: Icons.accessibility_new,
            label: '辅助功能',
          ),
        ],
      ),
      SidebarSection(
        title: '网络',
        items: [
          SidebarItem(
            id: SettingsSectionId.download,
            icon: Icons.cloud_download_outlined,
            label: '下载',
          ),
        ],
      ),
      SidebarSection(
        title: '其他',
        items: [
          SidebarItem(
            id: SettingsSectionId.general,
            icon: Icons.tune,
            label: '通用',
          ),
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
      case SettingsSectionId.general:
        return GeneralSettings(
          launchAtStartup: _launchAtStartup,
          minimizeToTray: _minimizeToTray,
          closeToTray: _closeToTray,
          autoUpdate: _autoUpdate,
          enableAnimation: _enableAnimation,
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
          onAutoUpdateChanged: (v) =>
              _setBool(ConfigKeys.autoUpdate, v, (val) => _autoUpdate = val),
          onEnableAnimationChanged: (v) => _setBool(
            ConfigKeys.enableSplashAnimation,
            v,
            (val) => _enableAnimation = val,
          ),
        );
      case SettingsSectionId.account:
        return const AccountSettings();
      case SettingsSectionId.java:
        return JavaSettings(
          gameDirectory: _gameDirectory,
          javaPath: _javaPath,
          memoryAllocation: _memoryAllocation,
          onGameDirectoryChanged: _saveGameDirectory,
          onJavaPathChanged: (v) => _saveJavaPath(v),
          onMemoryChanged: _saveMemoryAllocation,
        );
      case SettingsSectionId.gameDir:
        return GameDirectorySettings(
          gameDirectory: _gameDirectory,
          onGameDirectoryChanged: _saveGameDirectory,
        );
      case SettingsSectionId.advanced:
        return AdvancedSettings(
          proxyHostCtrl: _proxyHostController,
          proxyPortCtrl: _proxyPortController,
          jvmArgsCtrl: _jvmArgsController,
          gameArgsCtrl: _gameArgsController,
          gameWindowSize: _gameWindowSize,
          onGameWindowSizeChanged: _saveGameWindowSize,
          onProxyHostSubmitted: _saveProxyHost,
          onProxyPortSubmitted: _saveProxyPort,
          onJvmArgsSubmitted: _saveJvmArguments,
          onGameArgsSubmitted: _saveGameArguments,
        );
      case SettingsSectionId.theme:
        return ThemeSettings(
          themeMode: _themeMode,
          colorScheme: _colorScheme,
          onThemeModeChanged: _saveThemeMode,
          onColorSchemeChanged: _saveColorScheme,
          onBackgroundSettingsTap: _showBackgroundSelector,
        );
      case SettingsSectionId.homeInterface:
        return const HomeInterfaceSettings();
      case SettingsSectionId.language:
        return const LanguageSettings();
      case SettingsSectionId.audio:
        return AudioSettings(
          volume: _volume,
          onVolumeChanged: (v) => setState(() => _volume = v),
        );
      case SettingsSectionId.accessibility:
        return const AccessibilitySettings();
      case SettingsSectionId.download:
        return DownloadSettings(
          downloadSource: _downloadSource,
          concurrentDownloads: _concurrentDownloads,
          downloadPath: _downloadPath,
          onDownloadSourceChanged: _saveDownloadSource,
          onConcurrentDownloadsChanged: _saveConcurrentDownloads,
          onPickDownloadPath: _pickDownloadPath,
        );
      case SettingsSectionId.about:
        return const AboutSettings();
      default:
        return const AccountSettings();
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
      {
        'name': 'PCL',
        'url': 'https://github.com/Meloong-Git/PCL',
        'license': 'MIT',
      },
      {
        'name': 'HMCL',
        'url': 'https://github.com/HMCL-dev/HMCL',
        'license': 'GPL-3.0',
      },
      {
        'name': 'SJMCL',
        'url': 'https://github.com/UNIkeEN/SJMCL',
        'license': 'MIT',
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
              width: MediaQuery.of(context).size.width * 0.75,
              constraints: const BoxConstraints(maxWidth: 1100, minWidth: 850),
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
