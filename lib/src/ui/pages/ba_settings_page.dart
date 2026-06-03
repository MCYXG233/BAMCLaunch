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
import '../../account/skin_manager.dart';
import '../../account/account_manager.dart';
import '../../account/account.dart';
import '../../game/backup_manager.dart';
import '../../game/game_statistics.dart';
import '../../instance/instance_manager.dart';
import '../components/ba_backup_dialog.dart';
import '../components/ba_dialog.dart';
import 'dart:typed_data';
import '../../features/skin/skin_preview_3d.dart';
import '../../features/skin/cape_manager.dart';
import '../../download/mirror_manager.dart';
import '../components/ba_settings_item.dart';

class BASettingsPage extends StatefulWidget {
  const BASettingsPage({super.key});

  @override
  State<BASettingsPage> createState() => _BASettingsPageState();
}

class _BASettingsPageState extends State<BASettingsPage> {
  final ConfigManager _configManager = ConfigManager();
  final ThemeManager _themeManager = ThemeManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  final SkinManager _skinManager = SkinManager.instance;
  final BackupManager _backupManager = BackupManager.instance;
  final GameStatisticsManager _statisticsManager = GameStatisticsManager.instance;
  final AccountManager _accountManager = AccountManager();
  
  Account? _selectedAccount;
  Uint8List? _currentSkinImage;
  Uint8List? _currentCapeImage;

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

  // 镜像管理相关
  final MirrorManager _mirrorManager = MirrorManager();
  List<MirrorSpeedTestResult> _speedTestResults = [];
  bool _isSpeedTesting = false;
  bool _autoSelectMirror = true;
  bool _enableSpeedLimit = false;
  double _speedLimitValue = 1024;
  int _speedLimitUnit = 0; // 0: KB/s, 1: MB/s
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
    await _skinManager.initialize();
    await _backupManager.initialize();
    await _statisticsManager.initialize();
    await _loadBackgroundConfig();
    await _loadSelectedAccount();
    if (mounted) {
      setState(() {
        _themeManagerInitialized = true;
        _managersInitialized = true;
      });
    }
  }
  
  Future<void> _loadSelectedAccount() async {
    final account = await _accountManager.getSelectedAccount();
    
    Uint8List? skinImage;
    Uint8List? capeImage;
    
    if (account != null) {
      try {
        final skinData = await _skinManager.getSkin(account);
        if (skinData != null) {
          skinImage = Uint8List.fromList(skinData.imageData);
        }
        
        if (account.capeUrl != null) {
          final capeManager = CapeManager();
          final capeData = await capeManager.getCape(account.id);
          capeImage = capeData?.imageData;
        }
      } catch (e) {
        // 皮肤加载失败不影响其他功能
      }
    }
    
    if (mounted) {
      setState(() {
        _selectedAccount = account;
        _currentSkinImage = skinImage;
        _currentCapeImage = capeImage;
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

      // 加载镜像和限速配置
      final autoSelectMirror = _configManager.getBool(ConfigKeys.autoSelectMirror) ?? true;
      final enableSpeedLimit = _configManager.getBool(ConfigKeys.enableSpeedLimit) ?? false;
      final speedLimitValue = _configManager.getInt(ConfigKeys.speedLimitValue) ?? 1024;
      final speedLimitUnit = _configManager.getInt('speedLimitUnit') ?? 0;

      // 加载镜像管理器配置
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

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? BAColors.lightBackground : BAColors.darkBackground;
    final textColor = isLight ? BAColors.lightTextPrimary : BAColors.darkTextPrimary;

    return Container(
      color: Colors.transparent,
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
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    final categoryNames = {
      'general': '通用',
      'background': '背景',
      'skin': '皮肤',
      'backup': '备份',
      'statistics': '统计',
      'game': '游戏',
      'download': '下载',
      'about': '关于',
    };

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: isSelected 
                          ? BAColors.primaryOf(context).withOpacity(0.15) 
                          : BAColors.surfaceOf(context).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected 
                            ? BAColors.primaryOf(context).withOpacity(0.5) 
                            : Colors.transparent,
                      ),
                    ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(categoryId),
                        color: isSelected ? BAColors.primaryOf(context) : textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected ? BAColors.primaryOf(context) : textPrimary,
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
      case 'background':
        return Icons.wallpaper;
      case 'skin':
        return Icons.face;
      case 'backup':
        return Icons.backup;
      case 'statistics':
        return Icons.bar_chart;
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
    if (!_managersInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    switch (_selectedCategory) {
      case 'general':
        return _buildGeneralSettings();
      case 'background':
        return _buildBackgroundSettings();
      case 'skin':
        return _buildSkinSettings();
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? BAColors.lightSurface : BAColors.darkSurface;
    final cardBorder = isLight ? BAColors.lightBorder : BAColors.darkBorder;
    final dividerColor = isLight ? BAColors.lightBorder : BAColors.darkBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                color: BAColors.primaryOf(context),
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

  Widget _buildBackgroundSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '背景设置',
          children: [
            BABackgroundSelector(
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
                  allowedExtensions: ['webm', 'mp4', 'avi', 'mov', 'mkv'],
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
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    if (!_themeManagerInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '外观',
          children: [
            BASettingsItem(
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
            BASettingsItem(
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
                  if (value != null) _saveThemeMode(value, _themeManager);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '行为',
          children: [
            BASettingsItem(
              icon: Icons.update,
              title: '自动更新',
              description: '启动时检查更新',
              control: Switch(
                value: _autoUpdate,
                onChanged: _saveAutoUpdate,
              ),
            ),
            BASettingsItem(
              icon: Icons.power_settings_new,
              title: '开机自启动',
              description: '系统启动时自动运行',
              control: Switch(
                value: _launchAtStartup,
                onChanged: _saveLaunchAtStartup,
              ),
            ),
            BASettingsItem(
              icon: Icons.minimize,
              title: '最小化到托盘',
              description: '最小化时隐藏到系统托盘',
              control: Switch(
                value: _minimizeToTray,
                onChanged: _saveMinimizeToTray,
              ),
            ),
            BASettingsItem(
              icon: Icons.close_fullscreen,
              title: '关闭时最小化到托盘',
              description: '关闭窗口时最小化到系统托盘',
              control: Switch(
                value: _closeToTray,
                onChanged: _saveCloseToTray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '更新',
          children: [
            BASettingsItem(
              icon: Icons.system_update,
              title: '检查更新',
              description: _isCheckingUpdate ? '正在检查...' : '手动检查新版本',
              control: ElevatedButton(
                onPressed: _isCheckingUpdate ? null : _checkForUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: BAColors.textOnPrimary,
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
            BASettingsItem(
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
            BASettingsItem(
              icon: Icons.developer_mode,
              title: 'Java路径',
              description: _javaPath.isEmpty ? '自动检测' : _javaPath,
              control: ElevatedButton(
                onPressed: _pickJavaPath,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: BAColors.textOnPrimary,
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
            BASettingsItem(
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
                  onChanged: _saveMemoryAllocation,
                  onChangeEnd: _commitMemoryAllocation,
                ),
              ),
            ),
            BASettingsItem(
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
            BASettingsItem(
              icon: Icons.code,
              title: 'JVM额外参数',
              description: _jvmArgsController.text.isEmpty ? '无' : _jvmArgsController.text,
              control: _buildTextField(
                controller: _jvmArgsController,
                focusNode: _jvmArgsFocusNode,
                placeholder: '例如: -XX:+UseG1GC',
              ),
            ),
            BASettingsItem(
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
            BASettingsItem(
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
            BASettingsItem(
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
            BASettingsItem(
              icon: Icons.refresh,
              title: '下载失败自动重试',
              description: '下载失败时自动重试',
              control: Switch(
                value: _autoRetryDownload,
                onChanged: _saveAutoRetryDownload,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '并发下载设置',
          children: [
            BASettingsItem(
              icon: Icons.speed,
              title: '并发下载数',
              description: '$_concurrentDownloads 个线程',
              control: SizedBox(
                width: 200,
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
            ),
            BASettingsItem(
              icon: Icons.data_usage,
              title: '限速设置',
              description: _enableSpeedLimit
                  ? '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}'
                  : '未启用',
              control: Switch(
                value: _enableSpeedLimit,
                onChanged: _saveEnableSpeedLimit,
              ),
            ),
            if (_enableSpeedLimit) ...[
              BASettingsItem(
                icon: Icons.speed,
                title: '限速值',
                description: '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}',
                control: SizedBox(
                  width: 200,
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
              ),
              BASettingsItem(
                icon: Icons.timer,
                title: '限速单位',
                description: _speedLimitUnit == 0 ? 'KB/s' : 'MB/s',
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
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '镜像源管理',
          children: [
            BASettingsItem(
              icon: Icons.auto_fix_high,
              title: '自动选择最快镜像',
              description: '测速所有镜像并自动切换',
              control: Switch(
                value: _autoSelectMirror,
                onChanged: _saveAutoSelectMirror,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSpeedTesting ? null : _speedTestMirrors,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BAColors.primaryOf(context),
                        foregroundColor: BAColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSpeedTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.speed, size: 18),
                      label: Text(_isSpeedTesting ? '测速中...' : '测速所有镜像'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSpeedTesting ? null : _autoSelectFastestMirror,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BAColors.secondary,
                        foregroundColor: BAColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('自动选择最快'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '镜像列表',
          children: [
            ..._buildMirrorList(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '添加自定义镜像',
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _customMirrorNameController,
                          style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '名称（可选）',
                            hintStyle: TextStyle(color: BAColors.textDisabledOf(context), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: BAColors.surfaceVariantOf(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.borderOf(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.primaryOf(context)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _customMirrorUrlController,
                          style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: TextStyle(color: BAColors.textDisabledOf(context), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: BAColors.surfaceVariantOf(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.borderOf(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: BAColors.primaryOf(context)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addCustomMirror,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BAColors.primaryOf(context),
                          foregroundColor: BAColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '网络设置',
          children: [
            BASettingsItem(
              icon: Icons.language,
              title: 'HTTP代理地址',
              description: _proxyHost.isEmpty ? '未设置' : _proxyHost,
              control: SizedBox(
                width: 200,
                child: TextField(
                  controller: _proxyHostController,
                  focusNode: _proxyHostFocusNode,
                  style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '例如: 127.0.0.1',
                    hintStyle: TextStyle(color: BAColors.textDisabledOf(context), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: BAColors.surfaceVariantOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BAColors.borderOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BAColors.borderOf(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BAColors.primaryOf(context)),
                    ),
                  ),
                ),
              ),
            ),
            BASettingsItem(
              icon: Icons.numbers,
              title: 'HTTP代理端口',
              description: _proxyPort == 0 ? '未设置' : '$_proxyPort',
              control: SizedBox(
                width: 200,
                child: TextField(
                  controller: _proxyPortController,
                  focusNode: _proxyPortFocusNode,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '例如: 7890',
                    hintStyle: TextStyle(color: BAColors.textDisabledOf(context), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: BAColors.surfaceVariantOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BAColors.borderOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: BAColors.borderOf(context)),
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

  List<Widget> _buildMirrorList() {
    final mirrors = _mirrorManager.allMirrors;
    final currentMirrorId = _mirrorManager.currentMirror.id;

    return mirrors.map((mirror) {
      final isSelected = mirror.id == currentMirrorId;
      final speedResult = _speedTestResults.where((r) => r.mirror.id == mirror.id).firstOrNull;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectMirror(mirror.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? BAColors.primaryOf(context).withOpacity(0.15)
                    : BAColors.surfaceVariantOf(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? BAColors.primaryOf(context).withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                    size: 20,
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
                              style: TextStyle(
                                color: BAColors.textPrimaryOf(context),
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (mirror.isOfficial) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BAColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '官方',
                                  style: TextStyle(
                                    color: BAColors.primaryOf(context),
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
                                  color: BAColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '内置',
                                  style: TextStyle(
                                    color: BAColors.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mirror.url,
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
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
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${speedResult.latencyMs}ms',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '不可用',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  if (!mirror.isBuiltIn) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: BAColors.danger,
                        size: 20,
                      ),
                      onPressed: () => _removeCustomMirror(mirror.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
            BASettingsItem(
              icon: Icons.info_outline,
              title: '应用版本号',
              description: 'BAMC Launcher v1.0.0',
              control: const SizedBox(),
            ),
            BASettingsItem(
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
            BASettingsItem(
              icon: Icons.code,
              title: 'GitHub链接',
              description: 'GitHub 仓库',
              control: ElevatedButton(
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('访问', style: TextStyle(fontSize: 12)),
              ),
            ),
            BASettingsItem(
              icon: Icons.feedback,
              title: '反馈/问题报告',
              description: '提交反馈',
              control: ElevatedButton(
                onPressed: () => _launchURL('https://github.com/TSSForsunshine/BAMCLaunch/issues'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
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
            BASettingsItem(
              icon: Icons.cleaning_services,
              title: '清除缓存',
              description: '清理临时文件释放存储空间',
              control: ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
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
    final textPrimary = BAColors.textPrimaryOf(context);
    final textSecondary = BAColors.textSecondaryOf(context);

    final validValues = items.map((item) => item.value).toList();
    final effectiveValue = validValues.contains(value) ? value : items.first.value;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200, minWidth: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            value: effectiveValue,
            icon: Icon(Icons.arrow_drop_down, color: textSecondary),
            style: TextStyle(color: textPrimary, fontSize: 13),
            items: items,
            onChanged: onChanged,
          ),
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
    final textPrimary = BAColors.textPrimaryOf(context);
    final textDisabled = isLight ? BAColors.lightTextDisabled : BAColors.darkTextDisabled;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250, minWidth: 100),
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
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onBrowse,
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.primaryOf(context),
              foregroundColor: BAColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
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
    final textPrimary = BAColors.textPrimaryOf(context);
    final textDisabled = isLight ? BAColors.lightTextDisabled : BAColors.darkTextDisabled;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250, minWidth: 100),
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
            borderSide: BorderSide(color: BAColors.primaryOf(context)),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSkinSettings() {
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '当前账户皮肤',
          children: [
            if (_selectedAccount == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '请先选择一个账户',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              _buildSkinPreviewWith3D(),
              const SizedBox(height: 16),
              _buildModelSelector(),
              const SizedBox(height: 16),
              BASettingsItem(
                icon: Icons.image,
                title: '上传自定义皮肤',
                description: '选择本地PNG皮肤文件',
                control: ElevatedButton(
                  onPressed: _selectCustomSkin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BAColors.primaryOf(context),
                    foregroundColor: BAColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('选择文件', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              _buildCapeManagement(),
              if (_selectedAccount?.skinUrl != null)
                BASettingsItem(
                  icon: Icons.restore,
                  title: '恢复默认皮肤',
                  description: '移除自定义皮肤，使用默认皮肤',
                  control: ElevatedButton(
                    onPressed: _resetToDefaultSkin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BAColors.danger,
                      foregroundColor: BAColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('恢复', style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '皮肤缓存',
          children: [
            BASettingsItem(
              icon: Icons.refresh,
              title: '刷新皮肤缓存',
              description: '清除过期的皮肤缓存文件',
              control: ElevatedButton(
                onPressed: () async {
                  await _skinManager.cleanExpiredCache();
                  NotificationManager().showSuccess('缓存已清理');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('清理', style: TextStyle(fontSize: 12)),
              ),
            ),
            BASettingsItem(
              icon: Icons.delete_outline,
              title: '清除所有皮肤缓存',
              description: '删除所有已缓存的皮肤文件',
              control: ElevatedButton(
                onPressed: () async {
                  final confirmed = await BAConfirmDialog.show(
                    context: context,
                    title: '清除缓存',
                    content: '确定要清除所有皮肤缓存吗？',
                    confirmText: '清除',
                  );
                  
                  if (confirmed) {
                    await _skinManager.clearAllCache();
                    NotificationManager().showSuccess('缓存已清除');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primary,
                  foregroundColor: BAColors.textOnPrimary,
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

  Widget _buildSkinPreviewWith3D() {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Text(
            '3D皮肤预览',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SkinPreview3D(
              skinImage: _currentSkinImage,
              capeImage: _currentCapeImage,
              skinType: _selectedAccount!.modelType,
              width: 200,
              height: 280,
              backgroundColor: BAColors.surfaceVariantOf(context).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: 14,
                color: BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                '拖拽旋转 | 滚轮缩放 | 双击重置',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '当前模型: ${_selectedAccount!.modelType == SkinType.alex ? "Alex (细臂)" : "Steve (标准)"}',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: BAColors.primaryOf(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '角色模型',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '选择Steve或Alex模型',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildModelToggle(),
        ],
      ),
    );
  }

  Widget _buildModelToggle() {
    final isAlex = _selectedAccount!.modelType == SkinType.alex;

    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModelOption(
            label: 'Steve',
            isSelected: !isAlex,
            onTap: () => _setModelType(SkinType.steve),
          ),
          _buildModelOption(
            label: 'Alex',
            isSelected: isAlex,
            onTap: () => _setModelType(SkinType.alex),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primaryOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? BAColors.textOnPrimary
                : BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _setModelType(SkinType type) async {
    if (_selectedAccount == null) return;

    try {
      final updatedAccount = _selectedAccount!.copyWith(modelType: type);
      await _accountManager.updateAccount(updatedAccount);
      await _loadSelectedAccount();
      NotificationManager().showSuccess('模型已切换为 ${type == SkinType.alex ? "Alex" : "Steve"}');
    } catch (e) {
      NotificationManager().showError('切换模型失败', message: e.toString());
    }
  }

  Widget _buildCapeManagement() {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BAColors.borderOf(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers,
            color: BAColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '披风管理',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '上传自定义披风 (64x32 PNG)',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showCapeUploadDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.secondary,
              foregroundColor: BAColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('管理披风', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCapeUploadDialog() async {
    NotificationManager().showInfo('披风功能开发中');
  }

  Widget _buildSkinImage(String skinUrl) {
    if (skinUrl.startsWith('http')) {
      return Image.network(
        skinUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: BAColors.danger,
              size: 48,
            ),
          );
        },
      );
    } else if (File(skinUrl).existsSync()) {
      return Image.file(
        File(skinUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: BAColors.danger,
              size: 48,
            ),
          );
        },
      );
    }
    return Center(
      child: Icon(
        Icons.person,
        size: 64,
        color: BAColors.textDisabledOf(context),
      ),
    );
  }
  
  Future<void> _selectCustomSkin() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['png'],
    );
    
    if (result == null || result.files.isEmpty) return;
    
    final file = result.files.first;
    if (file.path == null) return;
    
    try {
      // 复制皮肤文件到应用数据目录
      final platform = PlatformAdapterFactory.create();
      final appDir = await platform.getApplicationSupportDirectory();
      final skinsDir = Directory(path.join(appDir, 'custom_skins'));
      
      if (!await skinsDir.exists()) {
        await skinsDir.create(recursive: true);
      }
      
      final extension = path.extension(file.path!);
      final newFileName = '${_selectedAccount!.id}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final newFile = File(path.join(skinsDir.path, newFileName));
      
      await File(file.path!).copy(newFile.path);
      
      // 更新账户皮肤
      final updatedAccount = _selectedAccount!.copyWith(
        skinUrl: newFile.path,
      );
      
      await _accountManager.updateAccount(updatedAccount);
      await _skinManager.clearAllCache();
      await _loadSelectedAccount();
      
      NotificationManager().showSuccess('皮肤已更新');
    } catch (e) {
      NotificationManager().showError('设置皮肤失败', message: e.toString());
    }
  }
  
  Future<void> _resetToDefaultSkin() async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '恢复默认皮肤',
      content: '确定要恢复默认皮肤吗？',
      confirmText: '恢复',
    );
    
    if (!confirmed) return;
    
    try {
      final updatedAccount = _selectedAccount!.copyWith(
        skinUrl: null,
      );
      
      await _accountManager.updateAccount(updatedAccount);
      await _skinManager.clearAllCache();
      await _loadSelectedAccount();
      
      NotificationManager().showSuccess('已恢复默认皮肤');
    } catch (e) {
      NotificationManager().showError('恢复失败', message: e.toString());
    }
  }

  Widget _buildBackupSettings() {
    final allBackups = _backupManager.getAllBackups();
    final instanceManager = InstanceManager();

    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        _buildSettingsCard(
          title: '备份管理',
          children: [
            BASettingsItem(
              icon: Icons.folder,
              title: '查看所有备份',
              description: '${allBackups.length} 个备份',
              control: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: BAColors.primaryOf(context),
                  foregroundColor: BAColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('管理', style: TextStyle(fontSize: 12)),
              ),
            ),
            BASettingsItem(
              icon: Icons.storage,
              title: '备份存储',
              description: '管理所有备份文件',
              control: const SizedBox(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time, color: BAColors.primaryOf(context), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '总游戏时长',
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDuration(totalPlayTime),
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.casino, color: BAColors.primaryOf(context), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '总启动次数',
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalLaunchCount 次',
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today, color: BAColors.primaryOf(context), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日游戏',
                        style: TextStyle(
                          color: BAColors.textPrimaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDuration(todayPlayTime),
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];

    if (mostPlayed != null) {
      children.add(
        _buildSettingsCard(
          title: '最常玩的实例',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BAColors.primaryOf(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.star, color: BAColors.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mostPlayed.instanceName,
                          style: TextStyle(
                            color: BAColors.textPrimaryOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDuration(Duration(seconds: mostPlayed.totalPlayTimeSeconds))} / ${mostPlayed.launchCount}次',
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    children.add(
      _buildSettingsCard(
        title: '数据管理',
        children: [
          BASettingsItem(
            icon: Icons.delete_outline,
            title: '清除统计数据',
            description: '清除所有游戏统计数据',
            control: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: BAColors.primary,
                foregroundColor: BAColors.textOnPrimary,
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
    );

    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: children,
    );
  }
}
