import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../updater/update_manager.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../theme/theme_manager.dart';
import '../theme/background_manager.dart';
import '../components/ba_notification.dart';
import '../components/ba_background_selector.dart';
import '../../config/background_config.dart';
import '../../loader/java_selector_dialog.dart';
import '../../game/backup_manager.dart';
import '../../game/game_statistics.dart';
import '../../instance/instance_manager.dart';
import '../components/ba_backup_dialog.dart';
import '../components/ba_dialog.dart';
import '../../download/mirror_manager.dart';
import '../components/ba_settings_item.dart';
import '../../event/event_bus.dart';
import '../../event/event.dart';

class BASettingsPage extends StatefulWidget {
  const BASettingsPage({super.key});

  @override
  State<BASettingsPage> createState() => _BASettingsPageState();
}

class _BASettingsPageState extends State<BASettingsPage> {
  final ConfigManager _configManager = ConfigManager();
  final ThemeManager _themeManager = ThemeManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  final BackupManager _backupManager = BackupManager.instance;
  final GameStatisticsManager _statisticsManager = GameStatisticsManager.instance;

  String _selectedCategory = 'general';
  bool _notificationInitialized = false;
  bool _themeManagerInitialized = false;
  bool _managersInitialized = false;

  BackgroundConfig _backgroundConfig = BackgroundConfig.classic;

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

  final MirrorManager _mirrorManager = MirrorManager();
  List<MirrorSpeedTestResult> _speedTestResults = [];
  bool _isSpeedTesting = false;
  bool _autoSelectMirror = true;
  bool _enableSpeedLimit = false;
  double _speedLimitValue = 1024;
  int _speedLimitUnit = 0;
  final TextEditingController _customMirrorUrlController = TextEditingController();
  final TextEditingController _customMirrorNameController = TextEditingController();

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
    _initAllManagers();
    _loadSettings();
  }

  Future<void> _initAllManagers() async {
    await _themeManager.initialize();
    await _backgroundManager.initialize();
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
    await _backgroundManager.initialize();
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
    _customMirrorUrlController.dispose();
    _customMirrorNameController.dispose();
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

      final autoSelectMirror = _configManager.getBool(ConfigKeys.autoSelectMirror) ?? true;
      final enableSpeedLimit = _configManager.getBool(ConfigKeys.enableSpeedLimit) ?? false;
      final speedLimitValue = _configManager.getInt(ConfigKeys.speedLimitValue) ?? 1024;
      final speedLimitUnit = _configManager.getInt('speedLimitUnit') ?? 0;

      await _mirrorManager.loadConfig();
      final speedTestResults = _mirrorManager.speedTestResults;

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
          _autoSelectMirror = autoSelectMirror;
          _enableSpeedLimit = enableSpeedLimit;
          _speedLimitValue = speedLimitValue.toDouble();
          _speedLimitUnit = speedLimitUnit;
          _speedTestResults = speedTestResults;
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

  Future<void> _saveAutoSelectMirror(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.autoSelectMirror, value);
      if (!mounted) return;
      setState(() {
        _autoSelectMirror = value;
      });
      NotificationManager().showSuccess('自动选择最快镜像已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveEnableSpeedLimit(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.enableSpeedLimit, value);
      if (!mounted) return;
      setState(() {
        _enableSpeedLimit = value;
      });
      NotificationManager().showSuccess('限速设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveSpeedLimitValue(double value, int unit) async {
    try {
      await _configManager.setInt(ConfigKeys.speedLimitValue, value.toInt());
      await _configManager.setInt('speedLimitUnit', unit);
      if (!mounted) return;
      setState(() {
        _speedLimitValue = value;
        _speedLimitUnit = unit;
      });
      NotificationManager().showSuccess('限速值已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _speedTestMirrors() async {
    setState(() {
      _isSpeedTesting = true;
    });
    try {
      final results = await _mirrorManager.speedTestAllMirrors();
      if (mounted) {
        setState(() {
          _speedTestResults = results;
          _isSpeedTesting = false;
        });
        NotificationManager().showSuccess('测速完成');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showError('测速失败', message: e.toString());
      }
    }
  }

  Future<void> _autoSelectFastestMirror() async {
    setState(() {
      _isSpeedTesting = true;
    });
    try {
      final fastest = await _mirrorManager.autoSelectFastestMirror();
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showSuccess('已自动切换到最快镜像: ${fastest.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showError('自动选择失败', message: e.toString());
      }
    }
  }

  Future<void> _addCustomMirror() async {
    final url = _customMirrorUrlController.text.trim();
    final name = _customMirrorNameController.text.trim();

    if (url.isEmpty) {
      NotificationManager().showError('请输入镜像地址');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      NotificationManager().showError('镜像地址必须以 http:// 或 https:// 开头');
      return;
    }

    try {
      final mirror = MirrorInfo(
        id: '',
        name: name.isEmpty ? Uri.parse(url).host : name,
        url: url,
      );
      await _mirrorManager.addCustomMirror(mirror);
      _customMirrorUrlController.clear();
      _customMirrorNameController.clear();
      await _loadSettings();
      if (mounted) {
        NotificationManager().showSuccess('自定义镜像已添加');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加镜像失败', message: e.toString());
      }
    }
  }

  Future<void> _removeCustomMirror(String mirrorId) async {
    try {
      await _mirrorManager.removeCustomMirror(mirrorId);
      await _loadSettings();
      if (mounted) {
        NotificationManager().showSuccess('镜像已移除');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('移除镜像失败', message: e.toString());
      }
    }
  }

  void _selectMirror(String mirrorId) {
    _mirrorManager.setCurrentMirror(mirrorId);
    setState(() {});
    NotificationManager().showSuccess('已选择镜像');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF141C33),
          Color(0xFF0A0F1E),
        ],
      ),
      ),
        child: SafeArea(
        child: Column(
        children: [
          _buildTopBar(),
          Expanded(
          child: Row(
            children: [
            _buildCategoryList(),
            Expanded(
              child: _buildSettingsList(),
            ),
            ],
          ),
          ),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                EventBus.instance.publish(NavigateHomeEvent());
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2747),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A4D7A), width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF8EAAFF),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B8EFF),
                  Color(0xFF8EAAFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B8EFF).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '设置',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '启动器参数与偏好设置',
                  style: TextStyle(
                    color: Color(0xFFA0B0C8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2747),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A4D7A), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF8EAAFF),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Color(0xFFA0B0C8),
                    fontSize: 12,
                  ),
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

    return Container(
      width: 210,
      margin: const EdgeInsets.only(left: 20, top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2747),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A4D7A), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: categoryNames.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2A3766)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6B8EFF)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isSelected
                              ? const [
                                  Color(0xFF6B8EFF),
                                  Color(0xFF8EAAFF),
                                ]
                              : [
                                  const Color(0xFF2A3766),
                                  const Color(0xFF1E2747),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : const Color(0xFF8EAAFF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      categoryName,
                      style: TextStyle(
                        color: isSelected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFA0B0C8),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsList() {
    if (!_managersInitialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6B8EFF)));
    }

    switch (_selectedCategory) {
      case 'general':
        return _buildGeneralSettings();
      case 'background':
        return _buildBackgroundSettings();
      case 'backup':
        return _buildBackupSettings();
      case 'statistics':
        return _buildStatisticsSettings();
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2747),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A4D7A),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6B8EFF),
                        Color(0xFF8EAAFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(children.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 1,
                  color: const Color(0xFF3A4D7A),
                ),
              );
            }
            return children[index ~/ 2];
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget control,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (iconColor ?? const Color(0xFF6B8EFF)).withOpacity(0.25),
                  (iconColor ?? const Color(0xFF8EAAFF)).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF8EAAFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFA0B0C8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [
                    Color(0xFF6B8EFF),
                    Color(0xFF8EAAFF),
                  ],
                )
              : null,
          color: value
              ? null
              : const Color(0xFF2A3766),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Colors.transparent
                : const Color(0xFF3A4D7A),
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B8EFF).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final validValues = items.map((item) => item.value).toList();
    final effectiveValue = validValues.contains(value) ? value : items.first.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1733),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A4D7A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA0B0C8), size: 20),
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 13,
          ),
          dropdownColor: const Color(0xFF1E2747),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    double width = 200,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0xFFA0B0C8), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: const Color(0xFF0F1733),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3A4D7A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3A4D7A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6B8EFF)),
          ),
          isDense: true,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1733),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A4D7A)),
          ),
          child: Text(
            path.isEmpty ? placeholder : path,
            style: TextStyle(
              color: path.isEmpty ? const Color(0xFFA0B0C8) : const Color(0xFFFFFFFF),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildPrimaryButton(
          text: buttonText,
          onPressed: onBrowse,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color ?? const Color(0xFF6B8EFF),
                color ?? const Color(0xFF8EAAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF6B8EFF)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF2A3766),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A4D7A)),
          ),
          child: isLoading
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8EAAFF)),
                ),
              )
              : Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF8EAAFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildBackgroundSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '背景设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: BABackgroundSelector(
                currentConfig: _backgroundConfig,
                onConfigChanged: (config) async {
                  await _backgroundManager.saveBackgroundConfig(config);
                  setState(() {
                    _backgroundConfig = config;
                  });
                  NotificationManager().showSuccess('背景设置已保存');
                },
                onPickImage: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.path != null) {
                      final customConfig = BackgroundConfig(
                        type: BackgroundType.image,
                        imagePath: file.path,
                        blur: _backgroundConfig.blur,
                        opacity: _backgroundConfig.opacity,
                      );
                      await _backgroundManager.saveBackgroundConfig(customConfig);
                      setState(() {
                        _backgroundConfig = customConfig;
                      });
                      NotificationManager().showSuccess('已选择图片: ${file.name}');
                    }
                  }
                },
                onPickVideo: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp4', 'avi', 'mov', 'mkv'],
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.path != null) {
                      final customConfig = BackgroundConfig(
                        type: BackgroundType.video,
                        videoPath: file.path,
                        blur: _backgroundConfig.blur,
                        opacity: _backgroundConfig.opacity,
                      );
                      await _backgroundManager.saveBackgroundConfig(customConfig);
                      setState(() {
                        _backgroundConfig = customConfig;
                      });
                      NotificationManager().showSuccess('已选择视频: ${file.name}');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    if (!_themeManagerInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B8EFF)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '外观',
          children: [
            _buildSettingsRow(
              icon: Icons.language,
              title: '语言',
              subtitle: _language,
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
            _buildSettingsRow(
              icon: Icons.palette,
              title: '主题',
              subtitle: _themeModeDisplayName(_themeMode),
              control: _buildDropdown<String>(
                value: _themeMode,
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('深色')),
                  DropdownMenuItem(value: 'light', child: Text('浅色')),
                  DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                ],
                onChanged: (value) {
                  if (value != null) _saveThemeMode(value, _themeManager);
                },
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '行为',
          children: [
            _buildSettingsRow(
              icon: Icons.update,
              title: '自动更新',
              subtitle: '启动时检查更新',
              control: _buildSwitch(_autoUpdate, _saveAutoUpdate),
            ),
            _buildSettingsRow(
              icon: Icons.power_settings_new,
              title: '开机自启动',
              subtitle: '系统启动时自动运行',
              control: _buildSwitch(_launchAtStartup, _saveLaunchAtStartup),
            ),
            _buildSettingsRow(
              icon: Icons.minimize,
              title: '最小化到托盘',
              subtitle: '最小化时隐藏到系统托盘',
              control: _buildSwitch(_minimizeToTray, _saveMinimizeToTray),
            ),
            _buildSettingsRow(
              icon: Icons.close_fullscreen,
              title: '关闭时最小化到托盘',
              subtitle: '关闭窗口时最小化到系统托盘',
              control: _buildSwitch(_closeToTray, _saveCloseToTray),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '更新',
          children: [
            _buildSettingsRow(
              icon: Icons.system_update,
              title: '检查更新',
              subtitle: _isCheckingUpdate ? '正在检查...' : '手动检查新版本',
              control: _buildPrimaryButton(
                text: _isCheckingUpdate ? '' : '检查',
                onPressed: _checkForUpdate,
                isLoading: _isCheckingUpdate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '路径设置',
          children: [
            _buildSettingsRow(
              icon: Icons.folder,
              title: '游戏目录',
              subtitle: _gameDirectory.isEmpty ? '未设置' : _gameDirectory,
              control: _buildPathSelector(
                path: _gameDirectory,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: _pickGameDirectory,
              ),
            ),
            _buildSettingsRow(
              icon: Icons.developer_mode,
              title: 'Java路径',
              subtitle: _javaPath.isEmpty ? '自动检测' : _javaPath,
              control: _buildPrimaryButton(
                text: '选择',
                onPressed: _pickJavaPath,
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '性能设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6B8EFF).withOpacity(0.25),
                          const Color(0xFF8EAAFF).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.memory,
                      color: Color(0xFF8EAAFF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最大内存',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_memoryAllocation.toInt()} MB',
                          style: const TextStyle(
                            color: Color(0xFFA0B0C8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF6B8EFF),
                            inactiveTrackColor: const Color(0xFF2A3766),
                            thumbColor: Colors.white,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayColor: const Color(0xFF6B8EFF).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _memoryAllocation,
                            min: 1024,
                            max: 16384,
                            divisions: 15,
                            label: '${_memoryAllocation.toInt()} MB',
                            onChanged: _saveMemoryAllocation,
                            onChangeEnd: _commitMemoryAllocation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSettingsRow(
              icon: Icons.aspect_ratio,
              title: '游戏窗口分辨率',
              subtitle: _gameWindowSize,
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
        _buildSettingsCard(
          title: '高级参数',
          children: [
            _buildSettingsRow(
              icon: Icons.code,
              title: 'JVM额外参数',
              subtitle: _jvmArgsController.text.isEmpty ? '无' : _jvmArgsController.text,
              control: _buildTextField(
                controller: _jvmArgsController,
                focusNode: _jvmArgsFocusNode,
                placeholder: '例如: -XX:+UseG1GC',
              ),
            ),
            _buildSettingsRow(
              icon: Icons.play_arrow,
              title: '游戏启动参数',
              subtitle: _gameArgsController.text.isEmpty ? '无' : _gameArgsController.text,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '下载设置',
          children: [
            _buildSettingsRow(
              icon: Icons.cloud_download,
              title: '下载源',
              subtitle: _downloadSourceDisplayName(_downloadSource),
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
            _buildSettingsRow(
              icon: Icons.download,
              title: '下载目录',
              subtitle: _downloadPath.isEmpty ? '未设置' : _downloadPath,
              control: _buildPathSelector(
                path: _downloadPath,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: _pickDownloadPath,
              ),
            ),
            _buildSettingsRow(
              icon: Icons.refresh,
              title: '下载失败自动重试',
              subtitle: '下载失败时自动重试',
              control: _buildSwitch(_autoRetryDownload, _saveAutoRetryDownload),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '并发下载设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6B8EFF).withOpacity(0.25),
                          const Color(0xFF8EAAFF).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.speed,
                      color: Color(0xFF8EAAFF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '并发下载数',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$_concurrentDownloads 个线程',
                          style: const TextStyle(
                            color: Color(0xFFA0B0C8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF6B8EFF),
                            inactiveTrackColor: const Color(0xFF2A3766),
                            thumbColor: Colors.white,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayColor: const Color(0xFF6B8EFF).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _concurrentDownloads.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_concurrentDownloads',
                            onChanged: (value) {
                              setState(() {
                                _concurrentDownloads = value.toInt();
                              });
                            },
                            onChangeEnd: (value) {
                              _saveConcurrentDownloads(value.toInt());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSettingsRow(
              icon: Icons.data_usage,
              title: '限速设置',
              subtitle: _enableSpeedLimit
                  ? '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}'
                  : '未启用',
              control: _buildSwitch(_enableSpeedLimit, _saveEnableSpeedLimit),
            ),
            if (_enableSpeedLimit) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6B8EFF).withOpacity(0.25),
                            const Color(0xFF8EAAFF).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.speed,
                        color: Color(0xFF8EAAFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '限速值',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}',
                            style: const TextStyle(
                              color: Color(0xFFA0B0C8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF6B8EFF),
                              inactiveTrackColor: const Color(0xFF2A3766),
                              thumbColor: Colors.white,
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayColor: const Color(0xFF6B8EFF).withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _speedLimitValue,
                              min: 1,
                              max: _speedLimitUnit == 0 ? 10240 : 10,
                              divisions: _speedLimitUnit == 0 ? 100 : 9,
                              label: '${_speedLimitValue.toInt()}',
                              onChanged: (value) {
                                setState(() {
                                  _speedLimitValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                _saveSpeedLimitValue(value, _speedLimitUnit);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildSettingsRow(
                icon: Icons.timer,
                title: '限速单位',
                subtitle: _speedLimitUnit == 0 ? 'KB/s' : 'MB/s',
                control: _buildDropdown<int>(
                  value: _speedLimitUnit,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('KB/s')),
                    DropdownMenuItem(value: 1, child: Text('MB/s')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _speedLimitUnit = value;
                        if (value == 1 && _speedLimitValue > 10) {
                          _speedLimitValue = 10;
                        } else if (value == 0 && _speedLimitValue < 1) {
                          _speedLimitValue = 1024;
                        }
                      });
                      _saveSpeedLimitValue(_speedLimitValue, value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        _buildSettingsCard(
          title: '镜像源管理',
          children: [
            _buildSettingsRow(
              icon: Icons.auto_fix_high,
              title: '自动选择最快镜像',
              subtitle: '测速所有镜像并自动切换',
              control: _buildSwitch(_autoSelectMirror, _saveAutoSelectMirror),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPrimaryButton(
                      text: _isSpeedTesting ? '' : '测速所有镜像',
                      onPressed: _speedTestMirrors,
                      isLoading: _isSpeedTesting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryButton(
                      text: _isSpeedTesting ? '' : '自动选择最快',
                      onPressed: _autoSelectFastestMirror,
                      isLoading: _isSpeedTesting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '镜像列表',
          children: [
            ..._buildMirrorList(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加自定义镜像',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTextField(
                          controller: _customMirrorNameController,
                          focusNode: FocusNode(),
                          placeholder: '名称（可选）',
                          width: 120,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          controller: _customMirrorUrlController,
                          focusNode: FocusNode(),
                          placeholder: 'https://example.com',
                          width: 250,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPrimaryButton(
                        text: '添加',
                        onPressed: _addCustomMirror,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '网络设置',
          children: [
            _buildSettingsRow(
              icon: Icons.language,
              title: 'HTTP代理地址',
              subtitle: _proxyHost.isEmpty ? '未设置' : _proxyHost,
              control: _buildTextField(
                controller: _proxyHostController,
                focusNode: _proxyHostFocusNode,
                placeholder: '例如: 127.0.0.1',
              ),
            ),
            _buildSettingsRow(
              icon: Icons.numbers,
              title: 'HTTP代理端口',
              subtitle: _proxyPort == 0 ? '未设置' : '$_proxyPort',
              control: _buildTextField(
                controller: _proxyPortController,
                focusNode: _proxyPortFocusNode,
                placeholder: '例如: 7890',
                width: 120,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMirrorList() {
    final mirrors = _mirrorManager.allMirrors;
    final currentMirrorId = _mirrorManager.currentMirror.id;

    return mirrors.map((mirror) {
      final isSelected = mirror.id == currentMirrorId;
      final speedResult = _speedTestResults.where((r) => r.mirror.id == mirror.id).firstOrNull;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _selectMirror(mirror.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2A3766)
                    : const Color(0xFF141C33),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6B8EFF)
                      : const Color(0xFF3A4D7A),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6B8EFF)
                            : const Color(0xFFA0B0C8),
                        width: 2,
                      ),
                      color: isSelected ? const Color(0xFF6B8EFF) : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              mirror.name,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (mirror.isOfficial) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B8EFF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '官方',
                                  style: TextStyle(
                                    color: Color(0xFF8EAAFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (mirror.isBuiltIn && !mirror.isOfficial) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF96B5).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '内置',
                                  style: TextStyle(
                                    color: Color(0xFFFF96B5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mirror.url,
                          style: const TextStyle(
                            color: Color(0xFFA0B0C8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (speedResult != null) ...[
                    if (speedResult.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BCB77).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${speedResult.latencyMs}ms',
                          style: const TextStyle(
                            color: Color(0xFF6BCB77),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF96B5).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '不可用',
                          style: TextStyle(
                            color: Color(0xFFFF96B5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  if (!mirror.isBuiltIn) ...[
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _removeCustomMirror(mirror.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF96B5).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF96B5),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAboutSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '应用信息',
          children: [
            _buildSettingsRow(
              icon: Icons.info_outline,
              title: '应用版本号',
              subtitle: 'BAMC Launcher v1.0.0',
              control: const SizedBox.shrink(),
            ),
            _buildSettingsRow(
              icon: Icons.gavel,
              title: '开源许可证',
              subtitle: 'GPL-3.0 License',
              control: const SizedBox.shrink(),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '链接与反馈',
          children: [
            _buildSettingsRow(
              icon: Icons.code,
              title: 'GitHub链接',
              subtitle: 'GitHub 仓库',
              control: _buildPrimaryButton(
                text: '访问',
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch'),
              ),
            ),
            _buildSettingsRow(
              icon: Icons.feedback,
              title: '反馈/问题报告',
              subtitle: '提交反馈',
              control: _buildPrimaryButton(
                text: '提交',
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch/issues'),
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          title: '维护',
          children: [
            _buildSettingsRow(
              icon: Icons.cleaning_services,
              title: '清除缓存',
              subtitle: '清理临时文件释放存储空间',
              control: _buildPrimaryButton(
                text: '清除',
                onPressed: _clearCache,
                color: const Color(0xFFFF96B5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackupSettings() {
    final allBackups = _backupManager.getAllBackups();
    final instanceManager = InstanceManager();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildSettingsCard(
          title: '备份管理',
          children: [
            _buildSettingsRow(
              icon: Icons.folder,
              title: '查看所有备份',
              subtitle: '${allBackups.length} 个备份',
              control: _buildPrimaryButton(
                text: '管理',
                onPressed: () {
                  if (instanceManager.instances.isNotEmpty) {
                    BABackupDialog.show(
                      context: context,
                      instance: instanceManager.instances.first,
                    );
                  } else {
                    NotificationManager().showInfo('暂无游戏实例', message: '请先创建一个游戏实例');
                  }
                },
              ),
            ),
            _buildSettingsRow(
              icon: Icons.storage,
              title: '备份存储',
              subtitle: '管理所有备份文件',
              control: const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSettings() {
    final totalPlayTime = _statisticsManager.getTotalPlayTime();
    final totalLaunchCount = _statisticsManager.getTotalLaunchCount();
    final todayPlayTime = _statisticsManager.getTodayPlayTime();
    final mostPlayed = _statisticsManager.getMostPlayedInstance();

    String formatDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        return '$hours小时$minutes分钟';
      } else {
        return '$minutes分钟';
      }
    }

    final children = <Widget>[
      _buildSettingsCard(
        title: '总统计',
        children: [
          _buildSettingsRow(
            icon: Icons.access_time,
            title: '总游戏时长',
            subtitle: formatDuration(totalPlayTime),
            control: const SizedBox.shrink(),
          ),
          _buildSettingsRow(
            icon: Icons.casino,
            title: '总启动次数',
            subtitle: '$totalLaunchCount 次',
            control: const SizedBox.shrink(),
          ),
          _buildSettingsRow(
            icon: Icons.calendar_today,
            title: '今日游戏',
            subtitle: formatDuration(todayPlayTime),
            control: const SizedBox.shrink(),
          ),
        ],
      ),
    ];

    if (mostPlayed != null) {
      children.add(
        _buildSettingsCard(
          title: '最常玩的实例',
          children: [
            _buildSettingsRow(
              icon: Icons.star,
              title: mostPlayed.instanceName,
              subtitle:
                  '${formatDuration(Duration(seconds: mostPlayed.totalPlayTimeSeconds))} / ${mostPlayed.launchCount}次',
              control: const SizedBox.shrink(),
              iconColor: const Color(0xFFFF96B5),
            ),
          ],
        ),
      );
    }

    children.add(
      _buildSettingsCard(
        title: '数据管理',
        children: [
          _buildSettingsRow(
            icon: Icons.delete_outline,
            title: '清除统计数据',
            subtitle: '清除所有游戏统计数据',
            control: _buildPrimaryButton(
              text: '清除',
              onPressed: () async {
                final confirmed = await BAConfirmDialog.show(
                  context: context,
                  title: '清除统计数据',
                  content: '确定要清除所有统计数据吗？此操作不可撤销',
                  confirmText: '清除',
                );
                if (confirmed) {
                  await _statisticsManager.clearAllData();
                  if (mounted) setState(() {});
                  NotificationManager().showSuccess('统计数据已清除');
                }
              },
              color: const Color(0xFFFF96B5),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: children,
    );
  }
}
