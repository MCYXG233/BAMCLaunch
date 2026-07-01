import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../theme/theme_manager.dart';
import '../theme/background_manager.dart';
import '../components/ba_notification.dart';
import '../components/ba_background_selector.dart';
import '../../config/background_config.dart';
import '../../loader/java_selector_dialog.dart';

/// 设置面板分类
enum SettingsTab {
  general('通用', Icons.tune),
  game('游戏', Icons.games),
  download('下载', Icons.cloud_download),
  theme('主题', Icons.palette),
  advanced('高级', Icons.settings);

  const SettingsTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 顶部Tab式设置面板
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
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  final ConfigManager _configManager = ConfigManager();
  final BackgroundManager _backgroundManager = BackgroundManager();
  late final ThemeManager _themeManager;

  // 设置项状态
  String _gameDirectory = '';
  String _javaPath = '';
  double _memoryAllocation = 4096;
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

  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;
  late TextEditingController _jvmArgsController;
  late TextEditingController _gameArgsController;

  @override
  void initState() {
    super.initState();

    _themeManager = Provider.of<ThemeManager>(context, listen: false);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _tabController = TabController(
      length: SettingsTab.values.length,
      vsync: this,
    );

    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
    _jvmArgsController = TextEditingController();
    _gameArgsController = TextEditingController();

    _animationController.forward();
    _initManagers();
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
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
          (_configManager.getInt(ConfigKeys.memoryAllocation) ?? 4096).toDouble();
      _autoUpdate = _configManager.getBool(ConfigKeys.autoUpdate) ?? true;
      _downloadSource = _configManager.getString(ConfigKeys.downloadSource) ?? 'official';
      _concurrentDownloads = _configManager.getInt(ConfigKeys.concurrentDownloads) ?? 3;
      _downloadPath = _configManager.getString(ConfigKeys.downloadPath) ?? '';
      _launchAtStartup = _configManager.getBool(ConfigKeys.launchAtStartup) ?? false;
      _minimizeToTray = _configManager.getBool(ConfigKeys.minimizeToTray) ?? true;
      _closeToTray = _configManager.getBool(ConfigKeys.closeToTray) ?? false;

      _enableAnimation = _configManager.getBool(ConfigKeys.enableSplashAnimation) ?? true;
      _proxyHost = _configManager.getString(ConfigKeys.proxyHost) ?? '';
      _proxyPort = _configManager.getInt(ConfigKeys.proxyPort) ?? 0;
      _gameWindowSize = _configManager.getString(ConfigKeys.gameWindowSize) ?? '1280x720';
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
          _proxyPortController.text =
              _proxyPort == 0 ? '' : _proxyPort.toString();
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

  Future<void> _saveGameDirectory(String dir) async {
    try {
      await _configManager.setString(ConfigKeys.gameDirectory, dir);
      if (mounted) setState(() => _gameDirectory = dir);
      NotificationManager().showSuccess('游戏目录已保存');
    } catch (e) {
      if (mounted) NotificationManager().showError('保存游戏目录失败', message: e.toString());
    }
  }

  Future<void> _saveJavaPath(String path) async {
    try {
      await _configManager.setString(ConfigKeys.javaPath, path);
      if (mounted) setState(() => _javaPath = path);
      NotificationManager().showSuccess('Java路径已保存');
    } catch (e) {
      if (mounted) NotificationManager().showError('保存Java路径失败', message: e.toString());
    }
  }

  Future<void> _saveMemoryAllocation(double value) async {
    try {
      await _configManager.setInt(ConfigKeys.memoryAllocation, value.toInt());
      if (mounted) setState(() => _memoryAllocation = value);
      NotificationManager().showSuccess('内存分配已保存: ${value.toInt()} MB');
    } catch (e) {
      if (mounted) NotificationManager().showError('保存内存分配失败', message: e.toString());
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
      if (mounted) NotificationManager().showError('切换主题失败', message: e.toString());
    }
  }

  Future<void> _saveColorScheme(String scheme) async {
    try {
      await _themeManager.setTheme(scheme);
      if (mounted) {
        setState(() {
          _colorScheme = scheme;
        });
      }
      NotificationManager().showSuccess(
        scheme == 'blue_archive' ? '已切换到蔚蓝档案配色' : '已切换到 Minecraft 配色',
      );
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('切换配色方案失败', message: e.toString());
      }
    }
  }

  Future<void> _saveDownloadSource(String source) async {
    try {
      await _configManager.setString(ConfigKeys.downloadSource, source);
      if (mounted) setState(() => _downloadSource = source);
      NotificationManager().showSuccess('下载源已保存');
    } catch (e) {
      if (mounted) NotificationManager().showError('保存下载源失败', message: e.toString());
    }
  }

  Future<void> _saveConcurrentDownloads(int count) async {
    try {
      await _configManager.setInt(ConfigKeys.concurrentDownloads, count);
      if (mounted) setState(() => _concurrentDownloads = count);
      NotificationManager().showSuccess('下载线程已保存');
    } catch (e) {
      if (mounted) NotificationManager().showError('保存下载线程失败', message: e.toString());
    }
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  // ==================== 构建方法 ====================

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    return Stack(
      children: [
        // 点击背景关闭
        GestureDetector(
          onTap: _close,
          child: Container(color: Colors.transparent),
        ),

        // 面板主体
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                constraints: const BoxConstraints(maxWidth: 900, minWidth: 700),
                height: double.infinity,
                decoration: BoxDecoration(
                  color: BAColors.surfaceOf(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    Expanded(child: _buildTabContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(color: BAColors.borderOf(context)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: BAColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.settings, color: BAColors.textPrimaryOf(context), size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            '设置',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // 恢复默认按钮
          TextButton.icon(
            onPressed: _showResetDialog,
            icon: Icon(Icons.restore, size: 14, color: BAColors.textSecondaryOf(context)),
            label: Text(
              '恢复默认',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(width: 4),

          // 关闭按钮
          IconButton(
            onPressed: _close,
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context), size: 20),
            tooltip: '关闭',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  /// 顶部分类Tab栏
  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(color: BAColors.borderOf(context)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: Colors.white,
        unselectedLabelColor: BAColors.textSecondaryOf(context),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        indicator: BoxDecoration(
          gradient: BAColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: BAColors.primaryOf(context).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
          BAColors.primaryOf(context).withValues(alpha: 0.06),
        ),
        tabs: SettingsTab.values.map((tab) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 15),
                const SizedBox(width: 5),
                Text(tab.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tab内容区域
  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGeneralSettings(),
        _buildGameSettings(),
        _buildDownloadSettings(),
        _buildThemeSettings(),
        _buildAdvancedSettings(),
      ],
    );
  }

  // ==================== 通用设置 ====================

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('通用设置'),
          const SizedBox(height: 16),

          // 开机自启
          _buildSettingCard(
            children: [
              _buildSwitchRow(
                icon: Icons.power_settings_new,
                iconColor: BAColors.warningOf(context),
                title: '开机自启',
                subtitle: '系统启动时自动运行启动器',
                value: _launchAtStartup,
                onChanged: (value) async {
                  try {
                    await _configManager.setBool(ConfigKeys.launchAtStartup, value);
                    if (!mounted) return;
                    setState(() => _launchAtStartup = value);
                  } catch (e) {
                    if (mounted) {
                      NotificationManager().showError('保存失败', message: e.toString());
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 最小化到托盘
          _buildSettingCard(
            children: [
              _buildSwitchRow(
                icon: Icons.minimize,
                iconColor: BAColors.primaryOf(context),
                title: '最小化到托盘',
                subtitle: '最小化时隐藏到系统托盘',
                value: _minimizeToTray,
                onChanged: (value) async {
                  try {
                    await _configManager.setBool(ConfigKeys.minimizeToTray, value);
                    if (!mounted) return;
                    setState(() => _minimizeToTray = value);
                  } catch (e) {
                    if (mounted) {
                      NotificationManager().showError('保存失败', message: e.toString());
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 关闭到托盘
          _buildSettingCard(
            children: [
              _buildSwitchRow(
                icon: Icons.close,
                iconColor: BAColors.dangerOf(context),
                title: '关闭到托盘',
                subtitle: '关闭窗口时最小化到托盘而非退出',
                value: _closeToTray,
                onChanged: (value) async {
                  try {
                    await _configManager.setBool(ConfigKeys.closeToTray, value);
                    if (!mounted) return;
                    setState(() => _closeToTray = value);
                  } catch (e) {
                    if (mounted) {
                      NotificationManager().showError('保存失败', message: e.toString());
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 自动更新
          _buildSettingCard(
            children: [
              _buildSwitchRow(
                icon: Icons.system_update,
                iconColor: BAColors.successOf(context),
                title: '自动更新',
                subtitle: '自动检查并下载启动器更新',
                value: _autoUpdate,
                onChanged: (value) async {
                  try {
                    await _configManager.setBool(ConfigKeys.autoUpdate, value);
                    if (!mounted) return;
                    setState(() => _autoUpdate = value);
                  } catch (e) {
                    if (mounted) {
                      NotificationManager().showError('保存失败', message: e.toString());
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 动画效果
          _buildSettingCard(
            children: [
              _buildSwitchRow(
                icon: Icons.animation,
                iconColor: BAColors.secondaryOf(context),
                title: '动画效果',
                subtitle: '启用界面动画过渡',
                value: _enableAnimation,
                onChanged: (value) async {
                  try {
                    await _configManager.setBool(ConfigKeys.enableSplashAnimation, value);
                    if (!mounted) return;
                    setState(() => _enableAnimation = value);
                    NotificationManager().showSuccess('动画设置已保存');
                  } catch (e) {
                    if (mounted) {
                      NotificationManager().showError('保存失败', message: e.toString());
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 游戏设置 ====================

  Widget _buildGameSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('游戏设置'),
          const SizedBox(height: 16),

          // 游戏目录
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.folder,
                iconColor: BAColors.accentPinkOf(context),
                title: '游戏目录',
                subtitle: _gameDirectory.isEmpty ? '未设置' : _gameDirectory,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      _saveGameDirectory(result);
                    }
                  },
                  child: const Text('选择'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Java 路径
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.coffee,
                iconColor: BAColors.secondaryOf(context),
                title: 'Java 路径',
                subtitle: _javaPath.isEmpty ? '自动检测' : _javaPath,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final result = await JavaSelectorDialog.show(context);
                    if (result != null) {
                      _saveJavaPath(result);
                    }
                  },
                  child: const Text('选择'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 内存分配
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory, color: BAColors.primaryOf(context), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '内存分配',
                          style: TextStyle(
                            color: BAColors.textPrimaryOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_memoryAllocation.toInt()} MB',
                          style: TextStyle(
                            color: BAColors.primaryOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: BAColors.primaryOf(context),
                        inactiveTrackColor: BAColors.primaryOf(context).withValues(alpha: 0.2),
                        thumbColor: BAColors.primaryOf(context),
                        overlayColor: BAColors.primaryOf(context).withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: _memoryAllocation,
                        min: 512,
                        max: 16384,
                        divisions: 32,
                        onChanged: (value) {
                          setState(() => _memoryAllocation = value);
                        },
                        onChangeEnd: (value) {
                          _saveMemoryAllocation(value);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('512 MB', style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 11)),
                        Text('16 GB', style: TextStyle(color: BAColors.textSecondaryOf(context), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 游戏窗口大小
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.aspect_ratio,
                iconColor: BAColors.infoOf(context),
                title: '游戏窗口大小',
                subtitle: '启动游戏时的默认窗口分辨率',
                trailing: DropdownButton<String>(
                  value: _gameWindowSize,
                  underline: const SizedBox(),
                  dropdownColor: BAColors.surfaceOf(context),
                  items: const [
                    DropdownMenuItem(value: '1280x720', child: Text('1280x720')),
                    DropdownMenuItem(value: '1920x1080', child: Text('1920x1080')),
                    DropdownMenuItem(value: '1600x900', child: Text('1600x900')),
                    DropdownMenuItem(value: '1366x768', child: Text('1366x768')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      try {
                        await _configManager.setString(ConfigKeys.gameWindowSize, value);
                        if (!mounted) return;
                        setState(() => _gameWindowSize = value);
                      } catch (e) {
                        if (mounted) {
                          NotificationManager().showError('保存失败', message: e.toString());
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // JVM 参数
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: BAColors.secondaryOf(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'JVM 参数',
                                style: TextStyle(
                                  color: BAColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '传递给 Java 虚拟机的额外参数',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jvmArgsController,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: '例如: -XX:+UseG1GC -XX:MaxGCPauseMillis=50',
                        hintStyle: TextStyle(
                          color: BAColors.textDisabledOf(context),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: BAColors.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      onSubmitted: (value) async {
                        try {
                          await _configManager.setString(ConfigKeys.jvmArguments, value);
                          if (mounted) setState(() => _jvmArguments = value);
                        } catch (e) {
                          if (mounted) {
                            NotificationManager().showError('保存失败', message: e.toString());
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 游戏参数
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gamepad, color: BAColors.accentPinkOf(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '游戏参数',
                                style: TextStyle(
                                  color: BAColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '传递给 Minecraft 的额外启动参数',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _gameArgsController,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: '例如: --demo',
                        hintStyle: TextStyle(
                          color: BAColors.textDisabledOf(context),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: BAColors.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      onSubmitted: (value) async {
                        try {
                          await _configManager.setString(ConfigKeys.gameArguments, value);
                          if (mounted) setState(() => _gameArguments = value);
                        } catch (e) {
                          if (mounted) {
                            NotificationManager().showError('保存失败', message: e.toString());
                          }
                        }
                      },
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

  // ==================== 下载设置 ====================

  Widget _buildDownloadSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('下载设置'),
          const SizedBox(height: 16),

          // 下载源
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.cloud_download,
                iconColor: BAColors.primaryOf(context),
                title: '下载源',
                subtitle: '选择游戏文件下载来源',
                trailing: DropdownButton<String>(
                  value: _downloadSource,
                  underline: const SizedBox(),
                  dropdownColor: BAColors.surfaceOf(context),
                  items: const [
                    DropdownMenuItem(value: 'official', child: Text('官方')),
                    DropdownMenuItem(value: 'bmclapi', child: Text('BMCLAPI')),
                  ],
                  onChanged: (value) {
                    if (value != null) _saveDownloadSource(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 并发下载数
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.speed,
                iconColor: BAColors.secondaryOf(context),
                title: '并发下载数',
                subtitle: '同时下载的文件数量',
                trailing: DropdownButton<int>(
                  value: _concurrentDownloads,
                  underline: const SizedBox(),
                  dropdownColor: BAColors.surfaceOf(context),
                  items: [1, 2, 3, 4, 5].map((v) {
                    return DropdownMenuItem(value: v, child: Text('$v'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _saveConcurrentDownloads(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 下载路径
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.save,
                iconColor: BAColors.accentPinkOf(context),
                title: '下载保存路径',
                subtitle: _downloadPath.isEmpty ? '默认路径' : _downloadPath,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      try {
                        await _configManager.setString(ConfigKeys.downloadPath, result);
                        if (!mounted) return;
                        setState(() => _downloadPath = result);
                      } catch (e) {
                        if (mounted) {
                          NotificationManager().showError('保存失败', message: e.toString());
                        }
                      }
                    }
                  },
                  child: const Text('选择'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 主题设置 ====================

  Widget _buildThemeSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('主题设置'),
          const SizedBox(height: 16),

          // 配色方案
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.palette,
                iconColor: BAColors.primaryOf(context),
                title: '配色方案',
                subtitle: _colorScheme == 'blue_archive' ? '蔚蓝档案风格' : 'Minecraft 风格',
                trailing: DropdownButton<String>(
                  value: _colorScheme,
                  underline: const SizedBox(),
                  dropdownColor: BAColors.surfaceOf(context),
                  iconEnabledColor: BAColors.textPrimaryOf(context),
                  style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'blue_archive', child: Text('蔚蓝档案')),
                    DropdownMenuItem(value: 'minecraft', child: Text('Minecraft')),
                  ],
                  onChanged: (value) {
                    if (value != null) _saveColorScheme(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 主题模式
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.dark_mode,
                iconColor: BAColors.primaryOf(context),
                title: '主题模式',
                subtitle: '选择应用的外观主题',
                trailing: DropdownButton<String>(
                  value: _themeMode,
                  underline: const SizedBox(),
                  dropdownColor: BAColors.surfaceOf(context),
                  iconEnabledColor: BAColors.textPrimaryOf(context),
                  style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 13),
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

          // 背景设置
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.image,
                iconColor: BAColors.accentPinkOf(context),
                title: '背景设置',
                subtitle: '自定义应用背景',
                trailing: TextButton(
                  onPressed: () => _showBackgroundSelector(),
                  style: TextButton.styleFrom(foregroundColor: BAColors.textPrimaryOf(context)),
                  child: const Text('选择'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 高级设置 ====================

  Widget _buildAdvancedSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('代理设置'),
          const SizedBox(height: 16),

          // 代理主机
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: BAColors.infoOf(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '代理主机',
                                style: TextStyle(
                                  color: BAColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'HTTP 代理服务器地址',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proxyHostController,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: '例如: 127.0.0.1',
                        hintStyle: TextStyle(
                          color: BAColors.textDisabledOf(context),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: BAColors.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      onSubmitted: (value) async {
                        try {
                          await _configManager.setString(ConfigKeys.proxyHost, value);
                          if (mounted) setState(() => _proxyHost = value);
                          NotificationManager().showSuccess('代理主机已保存');
                        } catch (e) {
                          if (mounted) {
                            NotificationManager().showError('保存失败', message: e.toString());
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 代理端口
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.numbers, color: BAColors.infoOf(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '代理端口',
                                style: TextStyle(
                                  color: BAColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '代理服务器端口号',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proxyPortController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: '例如: 1080',
                        hintStyle: TextStyle(
                          color: BAColors.textDisabledOf(context),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: BAColors.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      onSubmitted: (value) async {
                        try {
                          final port = int.tryParse(value) ?? 0;
                          await _configManager.setInt(ConfigKeys.proxyPort, port);
                          if (mounted) setState(() => _proxyPort = port);
                          NotificationManager().showSuccess('代理端口已保存');
                        } catch (e) {
                          if (mounted) {
                            NotificationManager().showError('保存失败', message: e.toString());
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('关于'),
          const SizedBox(height: 16),

          // 应用信息卡片
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: BAColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: BAColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.games,
                        color: BAColors.textPrimaryOf(context),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'BAMCLaunch',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本 1.0.0',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '一个简洁优雅的 Minecraft 启动器',
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 开源组件
          _buildSettingCard(
            children: [
              _buildSettingRow(
                icon: Icons.favorite,
                iconColor: BAColors.accentPinkOf(context),
                title: '开源组件',
                subtitle: '感谢所有开源项目的贡献者',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => _showOpenSourceDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 通用UI组件 ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: BAColors.textPrimaryOf(context),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: BAColors.primaryOf(context),
          ),
        ],
      ),
    );
  }

  // ==================== 辅助方法 ====================

  /// 显示背景选择对话框
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

  /// 显示开源组件对话框
  void _showOpenSourceDialog() {
    final openSourceProjects = [
      {'name': 'Flutter', 'url': 'https://github.com/flutter/flutter', 'license': 'BSD-3-Clause'},
      {'name': 'PCL', 'url': 'https://github.com/Meloong-Git/PCL', 'license': 'MIT'},
      {'name': 'HMCL', 'url': 'https://github.com/HMCL-dev/HMCL', 'license': 'GPL-3.0'},
      {'name': 'SJMCL', 'url': 'https://github.com/UNIkeEN/SJMCL', 'license': 'MIT'},
      {'name': 'url_launcher', 'url': 'https://github.com/flutter/packages/tree/main/packages/url_launcher', 'license': 'BSD-3-Clause'},
      {'name': 'file_picker', 'url': 'https://github.com/miguelpruivo/flutter_file_picker', 'license': 'MIT'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: BAColors.accentPinkOf(context), size: 20),
            const SizedBox(width: 8),
            const Text('开源组件'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: openSourceProjects.length,
            itemBuilder: (context, index) {
              final project = openSourceProjects[index];
              return ListTile(
                leading: Icon(Icons.code, color: BAColors.primaryOf(context)),
                title: Text(project['name'] as String),
                subtitle: Text('License: ${project['license'] as String}'),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    final uri = Uri.parse(project['url'] as String);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  /// 显示恢复默认设置对话框
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认设置'),
        content: const Text('确定要恢复所有设置为默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resetAllSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BAColors.dangerOf(context),
              foregroundColor: BAColors.textPrimaryOf(context),
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 恢复所有设置为默认值
  Future<void> _resetAllSettings() async {
    try {
      await _configManager.setString(ConfigKeys.gameDirectory, '');
      await _configManager.setString(ConfigKeys.javaPath, '');
      await _configManager.setInt(ConfigKeys.memoryAllocation, 4096);
      await _configManager.setBool(ConfigKeys.autoUpdate, true);
      await _configManager.setString(ConfigKeys.downloadSource, 'official');
      await _configManager.setInt(ConfigKeys.concurrentDownloads, 3);
      await _configManager.setString(ConfigKeys.downloadPath, '');
      await _configManager.setBool(ConfigKeys.launchAtStartup, false);
      await _configManager.setBool(ConfigKeys.minimizeToTray, true);
      await _configManager.setBool(ConfigKeys.closeToTray, false);
      await _configManager.setBool(ConfigKeys.autoRetryDownload, true);
      await _configManager.setBool(ConfigKeys.enableSplashAnimation, true);
      await _configManager.setString(ConfigKeys.gameWindowSize, '1280x720');
      await _configManager.setString(ConfigKeys.jvmArguments, '');
      await _configManager.setString(ConfigKeys.gameArguments, '');
      await _configManager.setString(ConfigKeys.proxyHost, '');
      await _configManager.setInt(ConfigKeys.proxyPort, 0);

      await _themeManager.setThemeMode(ThemeMode.dark);
      await _themeManager.setBlueArchiveTheme();
      await _backgroundManager.saveBackgroundConfig(BackgroundConfig.classic);

      await _loadSettings();

      if (!mounted) return;
      _tabController.animateTo(0);

      NotificationManager().showSuccess('设置已恢复为默认值');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('恢复默认设置失败', message: e.toString());
      }
    }
  }
}
