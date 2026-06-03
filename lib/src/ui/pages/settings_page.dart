import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../game/java/java_widgets.dart';
import '../../core/logger.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../theme/theme_manager.dart';
import '../components/ba_buttons.dart';
import '../../download/download_source.dart';
import '../../download/download_engine.dart';

/// 设置页面
/// 用于管理应用的各种配置选项
class BAMCSettingsPage extends StatefulWidget {
  const BAMCSettingsPage({super.key});

  @override
  State<BAMCSettingsPage> createState() => _BAMCSettingsPageState();
}

class _BAMCSettingsPageState extends State<BAMCSettingsPage> {
  final IConfigManager _configManager = ConfigManager();
  final Logger _logger = Logger('BAMCSettingsPage');

  /// 当前选中的分类
  String _selectedCategory = 'general';

  /// 将字符串转换为ThemeMode
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 将ThemeMode转换为字符串
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// 语言
  String _language = 'zh-CN';

  /// 自动更新
  bool _autoUpdate = true;

  /// 下载路径
  String _downloadPath = '';

  /// 并发下载数
  int _concurrentDownloads = 3;

  /// 最大重试次数
  int _maxRetries = 3;

  /// 镜像源索引
  int _mirrorSourceIndex = 0;

  /// 自动切换镜像源
  bool _autoSwitchMirror = true;

  /// 镜像源管理器
  final MirrorSourceManager _mirrorManager = MirrorSourceManager();

  /// 默认游戏目录
  String _gameDirectory = '';

  /// 默认内存分配 (MB)
  int _memoryAllocation = 2048;

  /// 窗口宽度
  int _windowWidth = 1280;

  /// 窗口高度
  int _windowHeight = 720;

  /// 启用启动动画
  bool _enableSplashAnimation = true;

  /// 启用音效
  bool _enableSoundEffects = true;

  /// 游戏全屏
  bool _gameFullscreen = false;

  /// 游戏分辨率宽度
  int _gameResolutionWidth = 1920;

  /// 游戏分辨率高度
  int _gameResolutionHeight = 1080;

  /// 是否正在加载
  bool _isLoading = false;

  /// 背景类型 ('solid', 'gradient', 'image')
  String _backgroundType = 'gradient';

  /// 纯色背景颜色
  Color _solidBackgroundColor = BAColors.darkBackground;

  /// 渐变背景开始颜色
  Color _gradientStartColor = BAColors.darkBackground;

  /// 渐变背景结束颜色
  Color _gradientEndColor = BAColors.darkSurface;

  /// 背景图片路径
  String _backgroundImagePath = '';

  /// 背景透明度 (0-1)
  double _backgroundOpacity = 1.0;

  /// 主色调
  Color _primaryColor = BAColors.primary;

  /// 次要色调
  Color _secondaryColor = BAColors.secondary;

  /// 圆角大小 (0-32)
  double _cornerRadius = 16.0;

  /// 是否启用模糊效果
  bool _enableBlur = true;

  /// 模糊程度 (0-100)
  double _blurIntensity = 10.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _language = _configManager.get<String>(ConfigKeys.language) ?? 'zh-CN';
        _autoUpdate = _configManager.get<bool>(ConfigKeys.autoUpdate) ?? true;
        _downloadPath =
            _configManager.get<String>(ConfigKeys.downloadPath) ?? '';
        _concurrentDownloads =
            _configManager.get<int>(ConfigKeys.concurrentDownloads) ?? 3;
        _maxRetries = _configManager.get<int>(ConfigKeys.maxRetries) ?? 3;
        _mirrorSourceIndex =
            _configManager.get<int>(ConfigKeys.mirrorSourceIndex) ?? 0;
        _autoSwitchMirror =
            _configManager.get<bool>(ConfigKeys.autoSwitchMirror) ?? true;
        _gameDirectory =
            _configManager.get<String>(ConfigKeys.gameDirectory) ?? '';
        _memoryAllocation =
            _configManager.get<int>(ConfigKeys.memoryAllocation) ?? 2048;
        _windowWidth =
            _configManager.get<int>(ConfigKeys.windowWidth) ?? 1280;
        _windowHeight =
            _configManager.get<int>(ConfigKeys.windowHeight) ?? 720;
        _enableSplashAnimation =
            _configManager.get<bool>(ConfigKeys.enableSplashAnimation) ?? true;
        _enableSoundEffects =
            _configManager.get<bool>(ConfigKeys.enableSoundEffects) ?? true;
        _gameFullscreen =
            _configManager.get<bool>(ConfigKeys.fullscreen) ?? false;
        _gameResolutionWidth =
            _configManager.get<int>(ConfigKeys.resolutionWidth) ?? 1920;
        _gameResolutionHeight =
            _configManager.get<int>(ConfigKeys.resolutionHeight) ?? 1080;
      });
      // 同步镜像源管理器的设置
      _mirrorManager.setSelectedMirrorIndex(_mirrorSourceIndex);
      DownloadEngine().setAutoSwitchMirror(_autoSwitchMirror);
    } catch (e, stackTrace) {
      _logger.error('加载设置失败', e, stackTrace);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      await _configManager.set<String>(ConfigKeys.language, _language);
      await _configManager.set<bool>(ConfigKeys.autoUpdate, _autoUpdate);
      await _configManager.set<String>(ConfigKeys.downloadPath, _downloadPath);
      await _configManager.set<int>(
        ConfigKeys.concurrentDownloads,
        _concurrentDownloads,
      );
      await _configManager.set<int>(ConfigKeys.maxRetries, _maxRetries);
      await _configManager.set<int>(
        ConfigKeys.mirrorSourceIndex,
        _mirrorSourceIndex,
      );
      await _configManager.set<bool>(
        ConfigKeys.autoSwitchMirror,
        _autoSwitchMirror,
      );
      await _configManager.set<String>(
        ConfigKeys.gameDirectory,
        _gameDirectory,
      );
      await _configManager.set<int>(
        ConfigKeys.memoryAllocation,
        _memoryAllocation,
      );
      await _configManager.set<int>(ConfigKeys.windowWidth, _windowWidth);
      await _configManager.set<int>(ConfigKeys.windowHeight, _windowHeight);
      await _configManager.set<bool>(ConfigKeys.enableSplashAnimation, _enableSplashAnimation);
      await _configManager.set<bool>(ConfigKeys.enableSoundEffects, _enableSoundEffects);
      await _configManager.set<bool>(ConfigKeys.fullscreen, _gameFullscreen);
      await _configManager.set<int>(ConfigKeys.resolutionWidth, _gameResolutionWidth);
      await _configManager.set<int>(ConfigKeys.resolutionHeight, _gameResolutionHeight);

      // 同步镜像源管理器和下载引擎的设置
      _mirrorManager.setSelectedMirrorIndex(_mirrorSourceIndex);
      DownloadEngine().setAutoSwitchMirror(_autoSwitchMirror);
      DownloadEngine().setDownloadSource(_mirrorManager.currentMirrorSource);

      if (mounted) {
        _showSnackBar('设置已保存!', success: true);
      }
    } catch (e, stackTrace) {
      _logger.error('保存设置失败', e, stackTrace);
      if (mounted) {
        _showSnackBar('保存设置失败: $e');
      }
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? BAColors.success : BAColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAColors.background,
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// 构建侧边栏
  Widget _buildSidebar() {
    final categories = [
      {'id': 'general', 'icon': Icons.settings, 'label': '通用'},
      {'id': 'appearance', 'icon': Icons.palette, 'label': '外观'},
      {'id': 'download', 'icon': Icons.download, 'label': '下载'},
      {'id': 'game', 'icon': Icons.sports_esports, 'label': '游戏'},
      {'id': 'about', 'icon': Icons.info, 'label': '关于'},
    ];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: BAColors.surface,
        border: Border(right: BorderSide(color: BAColors.border, width: 1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _buildCategoryItem(
              icon: category['icon'] as IconData,
              label: category['label'] as String,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'] as String;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? BAColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(
          color: isSelected ? BAColors.primary : Colors.transparent,
          width: isSelected ? 1 : 0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BATheme.borderRadiusSmall,
        child: InkWell(
          onTap: onTap,
          borderRadius: BATheme.borderRadiusSmall,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? BAColors.primary : BAColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: BATypography.bodyMedium.copyWith(
                    color: isSelected ? BAColors.primary : BAColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCategoryContent(),
                ),
        ),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BAColors.surface,
        border: Border(bottom: BorderSide(color: BAColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getCategoryTitle(),
              style: BATypography.headlineMedium.copyWith(
                color: BAColors.textPrimary,
              ),
            ),
          ),
          BAPrimaryButton(
            text: '保存设置',
            onPressed: _saveSettings,
            leadingIcon: const Icon(Icons.save, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 获取分类标题
  String _getCategoryTitle() {
    switch (_selectedCategory) {
      case 'general':
        return '通用设置';
      case 'appearance':
        return '外观设置';
      case 'download':
        return '下载设置';
      case 'game':
        return '游戏设置';
      case 'about':
        return '关于';
      default:
        return '设置';
    }
  }

  /// 构建分类内容
  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'general':
        return _buildGeneralSettings();
      case 'appearance':
        return _buildAppearanceSettings();
      case 'download':
        return _buildDownloadSettings();
      case 'game':
        return _buildGameSettings();
      case 'about':
        return _buildAboutPage();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建通用设置
  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('外观'),
        _buildSettingItem(
          title: '主题模式',
          subtitle: '选择应用的主题',
          child: _buildThemeSelector(),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '语言',
          subtitle: '选择应用的显示语言',
          child: _buildLanguageSelector(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('窗口'),
        _buildSettingItem(
          title: '窗口宽度',
          subtitle: '应用窗口的宽度 (像素)',
          child: _buildNumberSelector(
            value: _windowWidth,
            min: 800,
            max: 3840,
            onChanged: (value) {
              setState(() {
                _windowWidth = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '窗口高度',
          subtitle: '应用窗口的高度 (像素)',
          child: _buildNumberSelector(
            value: _windowHeight,
            min: 600,
            max: 2160,
            onChanged: (value) {
              setState(() {
                _windowHeight = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('动画与音效'),
        _buildSettingItem(
          title: '启动动画',
          subtitle: '启用启动时的动画效果',
          child: Switch(
            value: _enableSplashAnimation,
            onChanged: (value) {
              setState(() {
                _enableSplashAnimation = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '音效',
          subtitle: '启用界面音效',
          child: Switch(
            value: _enableSoundEffects,
            onChanged: (value) {
              setState(() {
                _enableSoundEffects = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('更新'),
        _buildSettingItem(
          title: '自动检查更新',
          subtitle: '启动时自动检查更新',
          child: Switch(
            value: _autoUpdate,
            onChanged: (value) {
              setState(() {
                _autoUpdate = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
      ],
    );
  }

  /// 构建外观设置
  Widget _buildAppearanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('主题'),
        _buildSettingItem(
          title: '主题模式',
          subtitle: '选择应用的主题',
          child: _buildThemeSelector(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('背景'),
        _buildSettingItem(
          title: '背景类型',
          subtitle: '选择背景样式',
          child: _buildBackgroundTypeSelector(),
        ),
        const SizedBox(height: 24),
        if (_backgroundType == 'solid')
          _buildSettingItem(
            title: '背景颜色',
            subtitle: '选择纯色背景',
            child: _buildColorPicker(_solidBackgroundColor, (color) {
              setState(() {
                _solidBackgroundColor = color;
              });
            }),
          )
        else if (_backgroundType == 'gradient') ...[
          _buildSettingItem(
            title: '渐变开始色',
            subtitle: '选择渐变起始颜色',
            child: _buildColorPicker(_gradientStartColor, (color) {
              setState(() {
                _gradientStartColor = color;
              });
            }),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            title: '渐变结束色',
            subtitle: '选择渐变结束颜色',
            child: _buildColorPicker(_gradientEndColor, (color) {
              setState(() {
                _gradientEndColor = color;
              });
            }),
          ),
        ] else if (_backgroundType == 'image')
          _buildSettingItem(
            title: '背景图片',
            subtitle: '选择自定义背景图片',
            child: _buildBackgroundImageSelector(),
          ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '背景透明度',
          subtitle: '调整背景的透明度',
          child: _buildOpacitySlider(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('颜色'),
        _buildSettingItem(
          title: '主色调',
          subtitle: '选择主要强调色',
          child: _buildColorPicker(_primaryColor, (color) {
            setState(() {
              _primaryColor = color;
            });
          }),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '次要色调',
          subtitle: '选择次要强调色',
          child: _buildColorPicker(_secondaryColor, (color) {
            setState(() {
              _secondaryColor = color;
            });
          }),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('界面'),
        _buildSettingItem(
          title: '圆角大小',
          subtitle: '调整界面元素的圆角',
          child: _buildCornerRadiusSlider(),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '启用模糊效果',
          subtitle: '启用毛玻璃效果',
          child: Switch(
            value: _enableBlur,
            onChanged: (value) {
              setState(() {
                _enableBlur = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
        if (_enableBlur)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildSettingItem(
              title: '模糊程度',
              subtitle: '调整模糊效果强度',
              child: _buildBlurSlider(),
            ),
          ),
      ],
    );
  }

  /// 构建背景类型选择器
  Widget _buildBackgroundTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariant,
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(color: BAColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _backgroundType,
          icon: Icon(Icons.arrow_drop_down, color: BAColors.textSecondary),
          items: const [
            DropdownMenuItem(value: 'gradient', child: Text('渐变背景')),
            DropdownMenuItem(value: 'solid', child: Text('纯色背景')),
            DropdownMenuItem(value: 'image', child: Text('图片背景')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _backgroundType = value;
              });
            }
          },
        ),
      ),
    );
  }

  /// 构建颜色选择器
  Widget _buildColorPicker(Color currentColor, ValueChanged<Color> onChanged) {
    final colors = [
      const Color(0xFF6C77FF),
      const Color(0xFFFF7CA4),
      const Color(0xFF00D9FF),
      const Color(0xFFFFD700),
      const Color(0xFF00FF88),
      const Color(0xFFFF6B6B),
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
      const Color(0xFF1E1E2E),
      const Color(0xFF11111B),
      const Color(0xFFFFF8F0),
      const Color(0xFFFFE4F1),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color == currentColor;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? BAColors.primary : BAColors.border,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  /// 构建背景图片选择器
  Widget _buildBackgroundImageSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariant,
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: Text(
            _backgroundImagePath.isEmpty ? '未选择' : _backgroundImagePath,
            style: BATypography.bodyMedium.copyWith(
              color: _backgroundImagePath.isEmpty
                  ? BAColors.textDisabled
                  : BAColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        BASecondaryButton(
          text: '选择图片',
          onPressed: () {
            // TODO: 实现图片选择
            setState(() {
              _backgroundImagePath = '/path/to/image.png';
            });
          },
        ),
      ],
    );
  }

  /// 构建透明度滑块
  Widget _buildOpacitySlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: Slider(
            value: _backgroundOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            label: '${(_backgroundOpacity * 100).round()}%',
            activeColor: BAColors.primary,
            onChanged: (value) {
              setState(() {
                _backgroundOpacity = value;
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(_backgroundOpacity * 100).round()}%',
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建圆角滑块
  Widget _buildCornerRadiusSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: Slider(
            value: _cornerRadius,
            min: 0,
            max: 32,
            divisions: 32,
            label: '${_cornerRadius.round()} px',
            activeColor: BAColors.primary,
            onChanged: (value) {
              setState(() {
                _cornerRadius = value;
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_cornerRadius.round()} px',
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建模糊滑块
  Widget _buildBlurSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: Slider(
            value: _blurIntensity,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_blurIntensity.round()}',
            activeColor: BAColors.primary,
            onChanged: (value) {
              setState(() {
                _blurIntensity = value;
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_blurIntensity.round()}',
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondary),
        ),
      ],
    );
  }

  /// 构建下载设置
  Widget _buildDownloadSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('镜像源设置'),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: '下载镜像源',
          subtitle: '选择游戏资源下载的镜像源',
          child: _buildMirrorSelector(),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '自动切换镜像源',
          subtitle: '当前镜像源不可用时自动切换',
          child: Switch(
            value: _autoSwitchMirror,
            onChanged: (value) {
              setState(() {
                _autoSwitchMirror = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('下载设置'),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: '下载路径',
          subtitle: '选择文件保存位置',
          child: _buildPathSelector(
            path: _downloadPath,
            onChanged: (value) {
              setState(() {
                _downloadPath = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '并发下载数',
          subtitle: '同时下载的文件数量',
          child: _buildNumberSelector(
            value: _concurrentDownloads,
            min: 1,
            max: 10,
            onChanged: (value) {
              setState(() {
                _concurrentDownloads = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '最大重试次数',
          subtitle: '下载失败时的最大重试次数',
          child: _buildNumberSelector(
            value: _maxRetries,
            min: 0,
            max: 10,
            onChanged: (value) {
              setState(() {
                _maxRetries = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 构建镜像源选择器
  Widget _buildMirrorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariant,
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(color: BAColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _mirrorSourceIndex,
          icon: Icon(Icons.arrow_drop_down, color: BAColors.textSecondary),
          items: _mirrorManager.allMirrorSources.asMap().entries.map((entry) {
            int idx = entry.key;
            BMCLApiDownloadSource source = entry.value;
            return DropdownMenuItem<int>(
              value: idx,
              child: Text('${source.name} (${source.baseUrl}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _mirrorSourceIndex = value;
              });
            }
          },
        ),
      ),
    );
  }

  /// 构建游戏设置
  Widget _buildGameSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          title: '默认游戏目录',
          subtitle: '游戏文件保存位置',
          child: _buildPathSelector(
            path: _gameDirectory,
            onChanged: (value) {
              setState(() {
                _gameDirectory = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '默认内存分配',
          subtitle: '游戏使用的最大内存 (MB)',
          child: _buildMemorySlider(),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('显示设置'),
        _buildSettingItem(
          title: '全屏模式',
          subtitle: '启动游戏时使用全屏',
          child: Switch(
            value: _gameFullscreen,
            onChanged: (value) {
              setState(() {
                _gameFullscreen = value;
              });
            },
            activeColor: BAColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '分辨率宽度',
          subtitle: '游戏窗口的宽度 (像素)',
          child: _buildNumberSelector(
            value: _gameResolutionWidth,
            min: 800,
            max: 3840,
            onChanged: (value) {
              setState(() {
                _gameResolutionWidth = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: '分辨率高度',
          subtitle: '游戏窗口的高度 (像素)',
          child: _buildNumberSelector(
            value: _gameResolutionHeight,
            min: 600,
            max: 2160,
            onChanged: (value) {
              setState(() {
                _gameResolutionHeight = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          title: 'Java 路径',
          subtitle: '选择 Java 运行环境',
          child: BAPrimaryButton(
            text: '选择 Java',
            onPressed: () => showJavaSelectionDialog(context),
          ),
        ),
      ],
    );
  }

  /// 构建关于页面
  Widget _buildAboutPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: BAColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.extension, size: 56, color: BAColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'BAMC Launcher',
                style: BATypography.headlineMedium.copyWith(
                  color: BAColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '版本 1.0.0',
                style: BATypography.bodyMedium.copyWith(
                  color: BAColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              BAPrimaryButton(
                text: '检查更新',
                onPressed: () {
                  // TODO: 实现检查更新逻辑
                  _showSnackBar('正在检查更新...', success: true);
                },
                leadingIcon: const Icon(Icons.update, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildSectionTitle('关于'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surface,
            borderRadius: BATheme.borderRadius,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: Text(
            'BAMC Launcher 是一个现代化的 Minecraft 启动器，支持版本管理、账户管理、游戏设置等功能。',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('开源许可证'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariant,
            borderRadius: BATheme.borderRadius,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: Text(
            '本项目采用 GNU General Public License v3 (GPLv3) 开源许可证。\n\n完整许可证文本请参阅项目根目录的 LICENSE 文件。\n\n使用 BMCLAPI 时，请遵守 BMCLAPI 的使用协议，在下载界面标注来源。',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('致谢'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAColors.surface,
            borderRadius: BATheme.borderRadius,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: Text(
            '感谢 Mojang Studios 创造 Minecraft。\n感谢 BMCLAPI 提供版本下载服务。',
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: BATypography.headlineSmall.copyWith(color: BAColors.textPrimary),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: BATypography.bodyLarge.copyWith(
                  color: BAColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: BATypography.bodySmall.copyWith(
                  color: BAColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        child,
      ],
    );
  }

  /// 构建主题选择器
  Widget _buildThemeSelector() {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final currentThemeString = _themeModeToString(themeManager.themeMode);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariant,
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentThemeString,
              icon: Icon(Icons.arrow_drop_down, color: BAColors.textSecondary),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                DropdownMenuItem(value: 'light', child: Text('明亮')),
                DropdownMenuItem(value: 'dark', child: Text('暗黑')),
              ],
              onChanged: (value) {
                if (value != null) {
                  themeManager.setThemeMode(_stringToThemeMode(value));
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建语言选择器
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariant,
        borderRadius: BATheme.borderRadiusSmall,
        border: Border.all(color: BAColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _language,
          icon: Icon(Icons.arrow_drop_down, color: BAColors.textSecondary),
          items: const [
            DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
            DropdownMenuItem(value: 'en-US', child: Text('English')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _language = value;
              });
            }
          },
        ),
      ),
    );
  }

  /// 构建路径选择器
  Widget _buildPathSelector({
    required String path,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BAColors.surfaceVariant,
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: BAColors.border, width: 1),
          ),
          child: Text(
            path.isEmpty ? '未设置' : path,
            style: BATypography.bodyMedium.copyWith(
              color: path.isEmpty
                  ? BAColors.textDisabled
                  : BAColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        BASecondaryButton(
          text: '浏览',
          onPressed: () {
            // TODO: 实现文件夹选择对话框
            onChanged('/path/to/directory');
          },
        ),
      ],
    );
  }

  /// 构建数字选择器
  Widget _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BASecondaryButton(
          text: '-',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          height: 36,
          width: 40,
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: BATypography.bodyLarge.copyWith(
              color: BAColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        BASecondaryButton(
          text: '+',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          height: 36,
          width: 40,
        ),
      ],
    );
  }

  /// 构建内存滑块
  Widget _buildMemorySlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: Slider(
            value: _memoryAllocation.toDouble(),
            min: 512,
            max: 16384,
            divisions: 31,
            label: '${_memoryAllocation} MB',
            activeColor: BAColors.primary,
            onChanged: (value) {
              setState(() {
                _memoryAllocation = value.round();
              });
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_memoryAllocation} MB',
          style: BATypography.bodySmall.copyWith(color: BAColors.textSecondary),
        ),
      ],
    );
  }
}
