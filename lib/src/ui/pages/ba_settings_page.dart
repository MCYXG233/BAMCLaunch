import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/ba_theme_colors.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../game/java/java_manager.dart';
import '../../updater/update_manager.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../theme/theme_manager.dart';
import '../components/ba_notification.dart';
import '../../loader/java_selector_dialog.dart';

class BASettingsPage extends StatefulWidget {
  const BASettingsPage({super.key});

  @override
  State<BASettingsPage> createState() => _BASettingsPageState();
}

class _BASettingsPageState extends State<BASettingsPage> {
  final ConfigManager _configManager = ConfigManager();

  String _selectedCategory = 'general';
  bool _notificationInitialized = false;

  String _gameDirectory = '';
  String _javaPath = '';
  double _memoryAllocation = 4096;
  String _themeMode = 'dark';
  bool _autoUpdate = true;
  String _language = '简体中文';
  String _downloadSource = 'official';
  int _concurrentDownloads = 3;
  String _downloadPath = '';
  bool _isCheckingUpdate = false;
  bool _launchAtStartup = false;
  bool _minimizeToTray = true;
  bool _closeToTray = false;
  bool _autoRetryDownload = true;
  String _proxyHost = '';
  int _proxyPort = 0;

  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;
  late FocusNode _proxyHostFocusNode;
  late FocusNode _proxyPortFocusNode;
  String _gameWindowSize = '1280x720';
  final TextEditingController _jvmArgsController = TextEditingController();
  final TextEditingController _gameArgsController = TextEditingController();
  final FocusNode _jvmArgsFocusNode = FocusNode();
  final FocusNode _gameArgsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
    _proxyHostFocusNode = FocusNode();
    _proxyPortFocusNode = FocusNode();
    _proxyHostFocusNode.addListener(_onProxyHostFocusChange);
    _proxyPortFocusNode.addListener(_onProxyPortFocusChange);
    _jvmArgsFocusNode.addListener(_onJvmArgsFocusChange);
    _gameArgsFocusNode.addListener(_onGameArgsFocusChange);
    _loadSettings();
  }

  @override
  void dispose() {
    _jvmArgsFocusNode.removeListener(_onJvmArgsFocusChange);
    _gameArgsFocusNode.removeListener(_onGameArgsFocusChange);
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyHostFocusNode.removeListener(_onProxyHostFocusChange);
    _proxyPortFocusNode.removeListener(_onProxyPortFocusChange);
    _proxyHostFocusNode.dispose();
    _proxyPortFocusNode.dispose();
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
      final memory = _configManager.getInt(ConfigKeys.memoryAllocation) ?? 4096;
      final themeMode = _configManager.getString(ConfigKeys.themeMode) ?? 'dark';
      final autoUpdate = _configManager.getBool(ConfigKeys.autoUpdate) ?? true;
      final language = _configManager.getString(ConfigKeys.language) ?? '简体中文';
      final downloadSource = _configManager.getString(ConfigKeys.downloadSource) ?? 'official';
      final concurrentDownloads = _configManager.getInt(ConfigKeys.concurrentDownloads) ?? 3;
      final downloadPath = _configManager.getString(ConfigKeys.downloadPath) ?? '';
      final launchAtStartup = _configManager.getBool(ConfigKeys.launchAtStartup) ?? false;
      final minimizeToTray = _configManager.getBool(ConfigKeys.minimizeToTray) ?? true;
      final closeToTray = _configManager.getBool(ConfigKeys.closeToTray) ?? false;
      final autoRetryDownload = _configManager.getBool(ConfigKeys.autoRetryDownload) ?? true;
      final proxyHost = _configManager.getString(ConfigKeys.proxyHost) ?? '';
      final proxyPort = _configManager.getInt(ConfigKeys.proxyPort) ?? 0;
      final gameWindowSize = _configManager.getString(ConfigKeys.gameWindowSize) ?? '1280x720';
      final jvmArguments = _configManager.getString(ConfigKeys.jvmArguments) ?? '';
      final gameArguments = _configManager.getString(ConfigKeys.gameArguments) ?? '';

      if (mounted) {
        setState(() {
          _gameDirectory = gameDir;
          _javaPath = javaPath;
          _memoryAllocation = memory.toDouble();
          _themeMode = themeMode;
          _autoUpdate = autoUpdate;
          _language = language;
          _downloadSource = downloadSource;
          _concurrentDownloads = concurrentDownloads;
          _downloadPath = downloadPath;
          _launchAtStartup = launchAtStartup;
          _minimizeToTray = minimizeToTray;
          _closeToTray = closeToTray;
          _autoRetryDownload = autoRetryDownload;
          _proxyHost = proxyHost;
          _proxyPort = proxyPort;
          _proxyHostController.text = proxyHost;
          _proxyPortController.text = proxyPort == 0 ? '' : proxyPort.toString();
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
      await ThemeManager().setThemeMode(themeMode);
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

  Future<void> _saveDownloadSource(String source) async {
    try {
      await _configManager.setString(ConfigKeys.downloadSource, source);
      if (!mounted) return;
      setState(() {
        _downloadSource = source;
      });
      NotificationManager().showSuccess('下载源已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载源失败', message: e.toString());
      }
    }
  }

  Future<void> _saveConcurrentDownloads(int count) async {
    try {
      await _configManager.setInt(ConfigKeys.concurrentDownloads, count);
      if (!mounted) return;
      setState(() {
        _concurrentDownloads = count;
      });
      NotificationManager().showSuccess('下载线程已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载线程失败', message: e.toString());
      }
    }
  }

  Future<void> _saveDownloadPath(String dir) async {
    try {
      await _configManager.setString(ConfigKeys.downloadPath, dir);
      if (!mounted) return;
      setState(() {
        _downloadPath = dir;
      });
      NotificationManager().showSuccess('下载目录已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载目录失败', message: e.toString());
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
        NotificationManager().showError('保存关闭时最小化到托盘设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveAutoRetryDownload(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.autoRetryDownload, value);
      if (!mounted) return;
      setState(() {
        _autoRetryDownload = value;
      });
      NotificationManager().showSuccess('下载失败自动重试设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载失败自动重试设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveProxyHost(String value) async {
    try {
      await _configManager.setString(ConfigKeys.proxyHost, value);
      if (!mounted) return;
      setState(() {
        _proxyHost = value;
      });
      NotificationManager().showSuccess('HTTP代理地址已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存HTTP代理地址失败', message: e.toString());
      }
    }
  }

  Future<void> _saveProxyPort(String value) async {
    try {
      final port = int.tryParse(value) ?? 0;
      await _configManager.setInt(ConfigKeys.proxyPort, port);
      if (!mounted) return;
      setState(() {
        _proxyPort = port;
      });
      NotificationManager().showSuccess('HTTP代理端口已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存HTTP代理端口失败', message: e.toString());
      }
    }
  }

  void _onProxyHostFocusChange() {
    if (!_proxyHostFocusNode.hasFocus) {
      _saveProxyHost(_proxyHostController.text);
    }
  }

  void _onProxyPortFocusChange() {
    if (!_proxyPortFocusNode.hasFocus) {
      _saveProxyPort(_proxyPortController.text);
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

  Future<void> _pickDownloadPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await _saveDownloadPath(result);
      }
    } catch (e) {
      NotificationManager().showError('选择目录失败', message: e.toString());
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      final release = await UpdateManager.instance.checkForUpdates(force: true);
      if (mounted) {
        if (release != null) {
          NotificationManager().showInfo('检查更新', message: '最新版本: ${release.version}');
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

  String _themeModeDisplayName(String mode) {
    switch (mode) {
      case 'light':
        return '浅色';
      case 'system':
        return '跟随系统';
      default:
        return '深色';
    }
  }

  String _downloadSourceDisplayName(String source) {
    switch (source) {
      case 'mirror':
        return '镜像源';
      default:
        return '官方源';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightBackground : BAColors.darkBackground;
    final textColor = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '设置',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                _buildCategoryList(context),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSettingsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;

    final categoryNames = {
      'general': '通用',
      'game': '游戏',
      'download': '下载',
      'about': '关于',
    };

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: BATheme.shadowsSmallOf(context),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: categoryNames.length,
        itemBuilder: (context, index) {
          final categoryId = categoryNames.keys.elementAt(index);
          final categoryName = categoryNames[categoryId]!;
          final isSelected = _selectedCategory == categoryId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = categoryId;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? BAColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? BAColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(categoryId),
                        color: isSelected ? BAColors.primary : textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected ? BAColors.primary : textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'general':
        return Icons.settings;
      case 'game':
        return Icons.games;
      case 'download':
        return Icons.download;
      case 'about':
        return Icons.info;
      default:
        return Icons.settings;
    }
  }

  Widget _buildSettingsList() {
    switch (_selectedCategory) {
      case 'general':
        return _buildGeneralSettings();
      case 'game':
        return _buildGameSettings();
      case 'download':
        return _buildDownloadSettings();
      case 'about':
        return _buildAboutSettings();
      default:
        return _buildGeneralSettings();
    }
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final dividerColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: BATheme.shadowsSmallOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: BAColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(children.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Divider(
                color: dividerColor.withOpacity(0.5),
                height: 1,
                indent: 20,
                endIndent: 20,
              );
            }
            return children[index ~/ 2];
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String description,
    required Widget control,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BAColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BAColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '外观',
          children: [
            _buildSettingsItem(
              icon: Icons.language,
              title: '语言',
              description: _language,
              control: _buildDropdown<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(value: '简体中文', child: Text('简体中文')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) _saveLanguage(value);
                },
              ),
            ),
            _buildSettingsItem(
              icon: Icons.palette,
              title: '主题',
              description: _themeModeDisplayName(_themeMode),
              control: _buildDropdown<String>(
                value: _themeMode,
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('深色')),
                  DropdownMenuItem(value: 'light', child: Text('浅色')),
                  DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                ],
                onChanged: (value) {
                  if (value != null) _saveThemeMode(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '行为',
          children: [
            _buildSettingsItem(
              icon: Icons.update,
              title: '自动更新',
              description: '启动时检查更新',
              control: Switch(
                value: _autoUpdate,
                onChanged: _saveAutoUpdate,
                activeColor: BAColors.primary,
              ),
            ),
            _buildSettingsItem(
              icon: Icons.power_settings_new,
              title: '开机自启动',
              description: '系统启动时自动运行',
              control: Switch(
                value: _launchAtStartup,
                onChanged: _saveLaunchAtStartup,
                activeColor: BAColors.primary,
              ),
            ),
            _buildSettingsItem(
              icon: Icons.minimize,
              title: '最小化到托盘',
              description: '最小化时隐藏到系统托盘',
              control: Switch(
                value: _minimizeToTray,
                onChanged: _saveMinimizeToTray,
                activeColor: BAColors.primary,
              ),
            ),
            _buildSettingsItem(
              icon: Icons.close_fullscreen,
              title: '关闭时最小化到托盘',
              description: '关闭窗口时最小化到系统托盘',
              control: Switch(
                value: _closeToTray,
                onChanged: _saveCloseToTray,
                activeColor: BAColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '更新',
          children: [
            _buildSettingsItem(
              icon: Icons.system_update,
              title: '检查更新',
              description: _isCheckingUpdate ? '正在检查...' : '手动检查新版本',
              control: ElevatedButton(
                onPressed: _isCheckingUpdate ? null : _checkForUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCheckingUpdate
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('检查', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '路径设置',
          children: [
            _buildSettingsItem(
              icon: Icons.folder,
              title: '游戏目录',
              description: _gameDirectory.isEmpty ? '未设置' : _gameDirectory,
              control: _buildPathSelector(
                path: _gameDirectory,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: _pickGameDirectory,
              ),
            ),
            _buildSettingsItem(
              icon: Icons.developer_mode,
              title: 'Java路径',
              description: _javaPath.isEmpty ? '自动检测' : _javaPath,
              control: ElevatedButton(
                onPressed: _pickJavaPath,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('选择', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '性能设置',
          children: [
            _buildSettingsItem(
              icon: Icons.memory,
              title: '最大内存',
              description: '${_memoryAllocation.toInt()} MB',
              control: SizedBox(
                width: 200,
                child: Slider(
                  value: _memoryAllocation,
                  min: 1024,
                  max: 16384,
                  divisions: 15,
                  label: '${_memoryAllocation.toInt()} MB',
                  activeColor: BAColors.primary,
                  onChanged: _saveMemoryAllocation,
                  onChangeEnd: _commitMemoryAllocation,
                ),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.aspect_ratio,
              title: '游戏窗口分辨率',
              description: _gameWindowSize,
              control: _buildDropdown<String>(
                value: _gameWindowSize,
                items: const [
                  DropdownMenuItem(value: '800x600', child: Text('800x600')),
                  DropdownMenuItem(value: '1280x720', child: Text('1280x720')),
                  DropdownMenuItem(value: '1920x1080', child: Text('1920x1080')),
                  DropdownMenuItem(value: '自定义', child: Text('自定义')),
                ],
                onChanged: (value) {
                  if (value != null) _saveGameWindowSize(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '高级参数',
          children: [
            _buildSettingsItem(
              icon: Icons.code,
              title: 'JVM额外参数',
              description: _jvmArgsController.text.isEmpty ? '无' : _jvmArgsController.text,
              control: _buildTextField(
                controller: _jvmArgsController,
                focusNode: _jvmArgsFocusNode,
                placeholder: '例如: -XX:+UseG1GC',
              ),
            ),
            _buildSettingsItem(
              icon: Icons.play_arrow,
              title: '游戏启动参数',
              description: _gameArgsController.text.isEmpty ? '无' : _gameArgsController.text,
              control: _buildTextField(
                controller: _gameArgsController,
                focusNode: _gameArgsFocusNode,
                placeholder: '例如: --fullscreen',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '下载设置',
          children: [
            _buildSettingsItem(
              icon: Icons.cloud_download,
              title: '下载源',
              description: _downloadSourceDisplayName(_downloadSource),
              control: _buildDropdown<String>(
                value: _downloadSource,
                items: const [
                  DropdownMenuItem(value: 'official', child: Text('官方源')),
                  DropdownMenuItem(value: 'mirror', child: Text('镜像源')),
                ],
                onChanged: (value) {
                  if (value != null) _saveDownloadSource(value);
                },
              ),
            ),
            _buildSettingsItem(
              icon: Icons.speed,
              title: '下载线程',
              description: '$_concurrentDownloads',
              control: _buildDropdown<int>(
                value: _concurrentDownloads,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 6, child: Text('6')),
                  DropdownMenuItem(value: 8, child: Text('8')),
                ],
                onChanged: (value) {
                  if (value != null) _saveConcurrentDownloads(value);
                },
              ),
            ),
            _buildSettingsItem(
              icon: Icons.download,
              title: '下载目录',
              description: _downloadPath.isEmpty ? '未设置' : _downloadPath,
              control: _buildPathSelector(
                path: _downloadPath,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: _pickDownloadPath,
              ),
            ),
            _buildSettingsItem(
              icon: Icons.refresh,
              title: '下载失败自动重试',
              description: '下载失败时自动重试',
              control: Switch(
                value: _autoRetryDownload,
                onChanged: _saveAutoRetryDownload,
                activeColor: BAColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '网络设置',
          children: [
            _buildSettingsItem(
              icon: Icons.language,
              title: 'HTTP代理地址',
              description: _proxyHost.isEmpty ? '未设置' : _proxyHost,
              control: SizedBox(
                width: 200,
                child: TextField(
                  controller: _proxyHostController,
                  focusNode: _proxyHostFocusNode,
                  style: const TextStyle(color: BAColors.darkTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '例如: 127.0.0.1',
                    hintStyle: const TextStyle(color: BAColors.darkTextDisabled, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: BAColors.darkSurfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.numbers,
              title: 'HTTP代理端口',
              description: _proxyPort == 0 ? '未设置' : '$_proxyPort',
              control: SizedBox(
                width: 200,
                child: TextField(
                  controller: _proxyPortController,
                  focusNode: _proxyPortFocusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: BAColors.darkTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '例如: 7890',
                    hintStyle: const TextStyle(color: BAColors.darkTextDisabled, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: BAColors.darkSurfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.darkBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BAColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('打开链接失败', message: e.toString());
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final platformAdapter = PlatformAdapterFactory.create();
      final tempDir = await platformAdapter.getTempDirectory();
      final directory = Directory(tempDir);
      if (await directory.exists()) {
        int count = 0;
        await for (final entity in directory.list(recursive: true)) {
          try {
            await entity.delete(recursive: true);
            count++;
          } catch (_) {}
        }
        if (mounted) {
          NotificationManager().showSuccess('缓存已清除', message: '已清理 $count 个临时文件');
        }
      } else {
        if (mounted) {
          NotificationManager().showInfo('缓存为空', message: '没有需要清理的临时文件');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('清除缓存失败', message: e.toString());
      }
    }
  }

  Widget _buildAboutSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '应用信息',
          children: [
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: '应用版本号',
              description: 'BAMC Launcher v1.0.0',
              control: const SizedBox(),
            ),
            _buildSettingsItem(
              icon: Icons.gavel,
              title: '开源许可证',
              description: 'GPL-3.0 License',
              control: const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '链接与反馈',
          children: [
            _buildSettingsItem(
              icon: Icons.code,
              title: 'GitHub链接',
              description: 'GitHub 仓库',
              control: ElevatedButton(
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('访问', style: TextStyle(fontSize: 12)),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.feedback,
              title: '反馈/问题报告',
              description: '提交反馈',
              control: ElevatedButton(
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch/issues'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('提交', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '维护',
          children: [
            _buildSettingsItem(
              icon: Icons.cleaning_services,
              title: '清除缓存',
              description: '清理临时文件释放存储空间',
              control: ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('清除', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceVariant = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;
    final borderColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textSecondary = isLight ? BAColors.lightTextSecondary : BAColors.darkTextSecondary;

    final validValues = items.map((item) => item.value).toList();
    final effectiveValue = validValues.contains(value) ? value : items.first.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue,
          icon: Icon(Icons.arrow_drop_down, color: textSecondary),
          style: TextStyle(color: textPrimary, fontSize: 13),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPathSelector({
    required String path,
    required String placeholder,
    required String buttonText,
    required VoidCallback onBrowse,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceVariant = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;
    final borderColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textDisabled = isLight ? BAColors.lightTextDisabled : BAColors.darkTextDisabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            path.isEmpty ? placeholder : path,
            style: TextStyle(
              color: path.isEmpty ? textDisabled : textPrimary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onBrowse,
          style: ElevatedButton.styleFrom(
            backgroundColor: BAColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(buttonText, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceVariant = isLight ? BAColors.lightSurfaceVariant : BAColors.darkSurfaceVariant;
    final borderColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final textPrimary = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;
    final textDisabled = isLight ? BAColors.lightTextDisabled : BAColors.darkTextDisabled;

    return SizedBox(
      width: 250,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: textDisabled, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: BAColors.primary),
          ),
          isDense: true,
        ),
      ),
    );
  }
}
