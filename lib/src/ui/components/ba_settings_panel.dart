import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/ba_theme_colors.dart';
import '../theme/mc_theme_colors.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../theme/theme_manager.dart';
import '../theme/background_manager.dart';
import '../components/ba_notification.dart';
import '../components/ba_background_selector.dart';
import '../../config/background_config.dart';
import '../../loader/java_selector_dialog.dart';
import '../components/ba_dialog.dart';

/// 设置面板分类
enum SettingsCategory {
  appearance('外观', Icons.palette),
  game('游戏', Icons.games),
  download('下载', Icons.download),
  advanced('高级', Icons.settings),
  about('关于', Icons.info);

  const SettingsCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 右侧滑出式设置面板
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final ConfigManager _configManager = ConfigManager();
  final ThemeManager _themeManager = ThemeManager();
  final BackgroundManager _backgroundManager = BackgroundManager();

  SettingsCategory _selectedCategory = SettingsCategory.appearance;
  bool _managersInitialized = false;

  // 设置项状态
  String _gameDirectory = '';
  String _javaPath = '';
  double _memoryAllocation = 4096;
  String _themeMode = 'dark';
  bool _autoUpdate = true;
  String _downloadSource = 'official';
  int _concurrentDownloads = 3;
  String _downloadPath = '';
  bool _launchAtStartup = false;
  bool _minimizeToTray = true;
  bool _closeToTray = false;
  bool _autoRetryDownload = true;
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
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _jvmArgsController.dispose();
    _gameArgsController.dispose();
    super.dispose();
  }

  Future<void> _initManagers() async {
    await _themeManager.initialize();
    await _backgroundManager.initialize();
    if (mounted) {
      setState(() {
        _managersInitialized = true;
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
      _autoRetryDownload = _configManager.getBool(ConfigKeys.autoRetryDownload) ?? true;
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

  Future<void> _saveBool(String key, bool value) async {
    try {
      await _configManager.setBool(key, value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) NotificationManager().showError('保存失败', message: e.toString());
    }
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    NotificationManager().init(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1A1B1E)
        : const Color(0xFFFAFBFD);
    final surfaceColor = isDark
        ? const Color(0xFF2D2E32)
        : const Color(0xFFFFFFFF);
    final textColor = isDark
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF2D3748);
    final textSecondary = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF718096);
    final borderColor = isDark
        ? const Color(0xFF373A40)
        : const Color(0xFFE2E8F0);

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
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 顶部栏
                    _buildHeader(textColor, textSecondary),

                    // 内容区域
                    Expanded(
                      child: Row(
                        children: [
                          // 左侧分类导航
                          _buildCategoryNav(
                            textColor,
                            textSecondary,
                            borderColor,
                            surfaceColor,
                          ),

                          // 分隔线
                          Container(width: 1, color: borderColor),

                          // 右侧设置内容
                          Expanded(
                            child: _buildSettingsContent(
                              textColor,
                              textSecondary,
                              borderColor,
                              surfaceColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 底部按钮
                    _buildFooter(textColor, textSecondary, borderColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color textSecondary) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAThemeColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(color: BAThemeColors.borderOf(context)),
        ),
      ),
      child: Row(
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: MCThemeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                '设置',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 关闭按钮
          IconButton(
            onPressed: _close,
            icon: Icon(Icons.close, color: textSecondary),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNav(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return Container(
      width: 180,
      color: surfaceColor.withValues(alpha: 0.5),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildCategoryItem(
            SettingsCategory.appearance,
            textColor,
            textSecondary,
          ),
          _buildCategoryItem(
            SettingsCategory.game,
            textColor,
            textSecondary,
          ),
          _buildCategoryItem(
            SettingsCategory.download,
            textColor,
            textSecondary,
          ),
          _buildCategoryItem(
            SettingsCategory.advanced,
            textColor,
            textSecondary,
          ),
          _buildCategoryItem(
            SettingsCategory.about,
            textColor,
            textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    SettingsCategory category,
    Color textColor,
    Color textSecondary,
  ) {
    final isSelected = _selectedCategory.index >= 0 &&
        _getCategoryFromIndex(_selectedCategory.index) == category;
    final primaryColor = BAThemeColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedCategory = category;
          }),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: primaryColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: isSelected ? primaryColor : textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  category.label,
                  style: TextStyle(
                    color: isSelected ? primaryColor : textColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SettingsCategory _getCategoryFromIndex(int index) {
    if (index < 0 || index >= SettingsCategory.values.length) {
      return SettingsCategory.appearance;
    }
    return SettingsCategory.values[index];
  }

  Widget _buildSettingsContent(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    switch (_selectedCategory) {
      case SettingsCategory.appearance:
        return _buildAppearanceSettings(textColor, textSecondary, borderColor, surfaceColor);
      case SettingsCategory.game:
        return _buildGameSettings(textColor, textSecondary, borderColor, surfaceColor);
      case SettingsCategory.download:
        return _buildDownloadSettings(textColor, textSecondary, borderColor, surfaceColor);
      case SettingsCategory.advanced:
        return _buildAdvancedSettings(textColor, textSecondary, borderColor, surfaceColor);
      case SettingsCategory.about:
        return _buildAboutSettings(textColor, textSecondary, borderColor, surfaceColor);
    }
  }

  Widget _buildAppearanceSettings(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('外观', textColor),
          const SizedBox(height: 16),

          // 主题模式
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.dark_mode,
                iconColor: MCThemeColors.primary,
                title: '主题模式',
                subtitle: '选择应用的外观主题',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: DropdownButton<String>(
                  value: _themeMode,
                  underline: const SizedBox(),
                  dropdownColor: surfaceColor,
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.image,
                iconColor: MCThemeColors.accent,
                title: '背景设置',
                subtitle: '自定义应用背景',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: TextButton(
                  onPressed: () {
                    // 背景设置功能待实现
                    NotificationManager().showInfo('背景设置功能开发中');
                  },
                  child: const Text('选择'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 动画效果
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSwitchRow(
                icon: Icons.animation,
                iconColor: MCThemeColors.secondary,
                title: '动画效果',
                subtitle: '启用界面动画过渡',
                textColor: textColor,
                textSecondary: textSecondary,
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameSettings(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('游戏', textColor),
          const SizedBox(height: 16),

          // 游戏目录
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.folder,
                iconColor: MCThemeColors.accent,
                title: '游戏目录',
                subtitle: _gameDirectory.isEmpty ? '未设置' : _gameDirectory,
                textColor: textColor,
                textSecondary: textSecondary,
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.coffee,
                iconColor: MCThemeColors.secondary,
                title: 'Java 路径',
                subtitle: _javaPath.isEmpty ? '自动检测' : _javaPath,
                textColor: textColor,
                textSecondary: textSecondary,
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory, color: MCThemeColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '内存分配',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_memoryAllocation.toInt()} MB',
                          style: TextStyle(
                            color: BAThemeColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: BAThemeColors.primary,
                        inactiveTrackColor: BAThemeColors.primary.withValues(alpha: 0.2),
                        thumbColor: BAThemeColors.primary,
                        overlayColor: BAThemeColors.primary.withValues(alpha: 0.1),
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
                        Text('512 MB', style: TextStyle(color: textSecondary, fontSize: 11)),
                        Text('16 GB', style: TextStyle(color: textSecondary, fontSize: 11)),
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.aspect_ratio,
                iconColor: MCThemeColors.diamond,
                title: '游戏窗口大小',
                subtitle: '启动游戏时的默认窗口分辨率',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: DropdownButton<String>(
                  value: _gameWindowSize,
                  underline: const SizedBox(),
                  dropdownColor: surfaceColor,
                  items: const [
                    DropdownMenuItem(value: '1280x720', child: Text('1280x720')),
                    DropdownMenuItem(value: '1920x1080', child: Text('1920x1080')),
                    DropdownMenuItem(value: '1600x900', child: Text('1600x900')),
                    DropdownMenuItem(value: '1366x768', child: Text('1366x768')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gameWindowSize = value);
                      _configManager.setString(ConfigKeys.gameWindowSize, value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSettings(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('下载', textColor),
          const SizedBox(height: 16),

          // 下载源
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.cloud_download,
                iconColor: BAThemeColors.primary,
                title: '下载源',
                subtitle: '选择游戏文件下载来源',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: DropdownButton<String>(
                  value: _downloadSource,
                  underline: const SizedBox(),
                  dropdownColor: surfaceColor,
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.speed,
                iconColor: MCThemeColors.secondary,
                title: '并发下载数',
                subtitle: '同时下载的文件数量',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: DropdownButton<int>(
                  value: _concurrentDownloads,
                  underline: const SizedBox(),
                  dropdownColor: surfaceColor,
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
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.save,
                iconColor: MCThemeColors.accent,
                title: '下载保存路径',
                subtitle: _downloadPath.isEmpty ? '默认路径' : _downloadPath,
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      await _configManager.setString(ConfigKeys.downloadPath, result);
                      setState(() => _downloadPath = result);
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

  Widget _buildAdvancedSettings(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('高级', textColor),
          const SizedBox(height: 16),

          // 开机自启
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSwitchRow(
                icon: Icons.power_settings_new,
                iconColor: MCThemeColors.warning,
                title: '开机自启',
                subtitle: '系统启动时自动运行',
                textColor: textColor,
                textSecondary: textSecondary,
                value: _launchAtStartup,
                onChanged: (value) async {
                  await _configManager.setBool(ConfigKeys.launchAtStartup, value);
                  setState(() => _launchAtStartup = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 最小化到托盘
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSwitchRow(
                icon: Icons.minimize,
                iconColor: MCThemeColors.primary,
                title: '最小化到托盘',
                subtitle: '最小化时隐藏到系统托盘',
                textColor: textColor,
                textSecondary: textSecondary,
                value: _minimizeToTray,
                onChanged: (value) async {
                  await _configManager.setBool(ConfigKeys.minimizeToTray, value);
                  setState(() => _minimizeToTray = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 关闭到托盘
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSwitchRow(
                icon: Icons.close,
                iconColor: MCThemeColors.danger,
                title: '关闭到托盘',
                subtitle: '关闭窗口时最小化到托盘而非退出',
                textColor: textColor,
                textSecondary: textSecondary,
                value: _closeToTray,
                onChanged: (value) async {
                  await _configManager.setBool(ConfigKeys.closeToTray, value);
                  setState(() => _closeToTray = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 自动更新
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSwitchRow(
                icon: Icons.system_update,
                iconColor: MCThemeColors.success,
                title: '自动更新',
                subtitle: '自动检查并下载更新',
                textColor: textColor,
                textSecondary: textSecondary,
                value: _autoUpdate,
                onChanged: (value) async {
                  await _configManager.setBool(ConfigKeys.autoUpdate, value);
                  setState(() => _autoUpdate = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(
    Color textColor,
    Color textSecondary,
    Color borderColor,
    Color surfaceColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('关于', textColor),
          const SizedBox(height: 16),

          // 应用信息卡片
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: MCThemeColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: MCThemeColors.glowShadow,
                      ),
                      child: const Icon(
                        Icons.games,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BAMCLaunch',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本 1.0.0',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '一个简洁优雅的 Minecraft 启动器',
                      style: TextStyle(
                        color: textSecondary,
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

          // 致谢
          _buildSettingCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildSettingRow(
                icon: Icons.favorite,
                iconColor: MCThemeColors.woolPink,
                title: '开源组件',
                subtitle: '感谢所有开源项目的贡献者',
                textColor: textColor,
                textSecondary: textSecondary,
                trailing: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    Color textColor,
    Color textSecondary,
    Color borderColor,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: BAThemeColors.surfaceOf(context),
        border: Border(
          top: BorderSide(color: BAThemeColors.borderOf(context)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              // 恢复默认设置
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('恢复默认设置'),
                  content: const Text('确定要恢复所有设置为默认值吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // TODO: 实现恢复默认设置
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('恢复默认'),
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: BorderSide(color: borderColor),
            ),
          ),

          const Spacer(),

          ElevatedButton.icon(
            onPressed: _close,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('完成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BAThemeColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingCard({
    required Color surfaceColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
    required Color textColor,
    required Color textSecondary,
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
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    required Color textColor,
    required Color textSecondary,
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
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BAThemeColors.primary,
          ),
        ],
      ),
    );
  }
}
