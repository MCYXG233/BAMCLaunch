import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../core/logger.dart';

/// 主题预设类型
enum ThemePreset {
  /// 蔚蓝档案蓝
  archiveBlue,
  /// 深空黑
  deepSpace,
  /// 森林绿
  forestGreen,
  /// 日落橙
  sunsetOrange,
  /// 紫罗兰
  violet,
  /// 自定义
  custom,
}

/// 自定义主题配置
class CustomThemeConfig {
  /// 主题名称
  final String name;

  /// 主色调
  final Color primaryColor;

  /// 次要色调
  final Color secondaryColor;

  /// 强调色
  final Color accentColor;

  /// 背景色
  final Color backgroundColor;

  /// 表面色
  final Color surfaceColor;

  /// 文字主色
  final Color onPrimaryColor;

  /// 文字次色
  final Color onSecondaryColor;

  /// 文字背景色
  final Color onBackgroundColor;

  /// 字体缩放
  final double fontScale;

  /// 圆角大小
  final double borderRadius;

  /// 模糊强度
  final double blurStrength;

  const CustomThemeConfig({
    this.name = '自定义',
    this.primaryColor = const Color(0xFF4FC3F7),
    this.secondaryColor = const Color(0xFF7C4DFF),
    this.accentColor = const Color(0xFFFF6B6B),
    this.backgroundColor = const Color(0xFF121212),
    this.surfaceColor = const Color(0xFF1E1E1E),
    this.onPrimaryColor = Colors.white,
    this.onSecondaryColor = Colors.white,
    this.onBackgroundColor = Colors.white,
    this.fontScale = 1.0,
    this.borderRadius = 16.0,
    this.blurStrength = 20.0,
  });

  CustomThemeConfig copyWith({
    String? name,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? onPrimaryColor,
    Color? onSecondaryColor,
    Color? onBackgroundColor,
    double? fontScale,
    double? borderRadius,
    double? blurStrength,
  }) {
    return CustomThemeConfig(
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      onSecondaryColor: onSecondaryColor ?? this.onSecondaryColor,
      onBackgroundColor: onBackgroundColor ?? this.onBackgroundColor,
      fontScale: fontScale ?? this.fontScale,
      borderRadius: borderRadius ?? this.borderRadius,
      blurStrength: blurStrength ?? this.blurStrength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'accentColor': accentColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'onPrimaryColor': onPrimaryColor.value,
      'onSecondaryColor': onSecondaryColor.value,
      'onBackgroundColor': onBackgroundColor.value,
      'fontScale': fontScale,
      'borderRadius': borderRadius,
      'blurStrength': blurStrength,
    };
  }

  factory CustomThemeConfig.fromJson(Map<String, dynamic> json) {
    return CustomThemeConfig(
      name: json['name'] as String? ?? '自定义',
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF4FC3F7),
      secondaryColor: Color(json['secondaryColor'] as int? ?? 0xFF7C4DFF),
      accentColor: Color(json['accentColor'] as int? ?? 0xFFFF6B6B),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFF121212),
      surfaceColor: Color(json['surfaceColor'] as int? ?? 0xFF1E1E1E),
      onPrimaryColor: Color(json['onPrimaryColor'] as int? ?? 0xFFFFFFFF),
      onSecondaryColor: Color(json['onSecondaryColor'] as int? ?? 0xFFFFFFFF),
      onBackgroundColor: Color(json['onBackgroundColor'] as int? ?? 0xFFFFFFFF),
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
      blurStrength: (json['blurStrength'] as num?)?.toDouble() ?? 20.0,
    );
  }

  /// 从预设创建
  factory CustomThemeConfig.fromPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.archiveBlue:
        return const CustomThemeConfig(
          name: '蔚蓝档案蓝',
          primaryColor: Color(0xFF4FC3F7),
          secondaryColor: Color(0xFF7C4DFF),
          accentColor: Color(0xFFFF6B6B),
          backgroundColor: Color(0xFF0D1B2A),
          surfaceColor: Color(0xFF1B263B),
        );
      case ThemePreset.deepSpace:
        return const CustomThemeConfig(
          name: '深空黑',
          primaryColor: Color(0xFF6B5B95),
          secondaryColor: Color(0xFF88B04B),
          accentColor: Color(0xFFFFD700),
          backgroundColor: Color(0xFF0A0A0A),
          surfaceColor: Color(0xFF1A1A1A),
        );
      case ThemePreset.forestGreen:
        return const CustomThemeConfig(
          name: '森林绿',
          primaryColor: Color(0xFF2E7D32),
          secondaryColor: Color(0xFF81C784),
          accentColor: Color(0xFFFFB74D),
          backgroundColor: Color(0xFF1B2E1B),
          surfaceColor: Color(0xFF2E4D2E),
        );
      case ThemePreset.sunsetOrange:
        return const CustomThemeConfig(
          name: '日落橙',
          primaryColor: Color(0xFFFF7043),
          secondaryColor: Color(0xFFFFA726),
          accentColor: Color(0xFFEC407A),
          backgroundColor: Color(0xFF2C1810),
          surfaceColor: Color(0xFF3D2418),
        );
      case ThemePreset.violet:
        return const CustomThemeConfig(
          name: '紫罗兰',
          primaryColor: Color(0xFF9C27B0),
          secondaryColor: Color(0xFFE91E63),
          accentColor: Color(0xFF00BCD4),
          backgroundColor: Color(0xFF1A0A2E),
          surfaceColor: Color(0xFF2D1B4E),
        );
      case ThemePreset.custom:
        return const CustomThemeConfig();
    }
  }
}

/// 主题编辑器状态
class ThemeEditorState extends ChangeNotifier {
  ThemePreset _currentPreset = ThemePreset.archiveBlue;
  CustomThemeConfig _customConfig = CustomThemeConfig.fromPreset(ThemePreset.archiveBlue);
  bool _isEditing = false;
  final Logger _logger = Logger('ThemeEditor');

  ThemePreset get currentPreset => _currentPreset;
  CustomThemeConfig get customConfig => _customConfig;
  bool get isEditing => _isEditing;

  /// 加载保存的主题配置
  Future<void> loadConfig() async {
    try {
      final config = ConfigManager();
      await config.initialize();
      final json = config.getString(ConfigKeys.themeConfig);
      if (json != null) {
        _customConfig = CustomThemeConfig.fromJson(jsonDecode(json));
        _currentPreset = ThemePreset.custom;
      }
    } catch (e) {
      _logger.warn('Failed to load theme config: $e');
    }
    notifyListeners();
  }

  /// 保存主题配置
  Future<void> saveConfig() async {
    try {
      final config = ConfigManager();
      await config.initialize();
      await config.setString(
        ConfigKeys.themeConfig,
        jsonEncode(_customConfig.toJson()),
      );
      _logger.info('Theme config saved');
    } catch (e) {
      _logger.error('Failed to save theme config', e);
    }
  }

  /// 选择预设
  void selectPreset(ThemePreset preset) {
    _currentPreset = preset;
    _customConfig = CustomThemeConfig.fromPreset(preset);
    _isEditing = false;
    notifyListeners();
    saveConfig();
  }

  /// 开始编辑自定义主题
  void startEditing() {
    _isEditing = true;
    _currentPreset = ThemePreset.custom;
    notifyListeners();
  }

  /// 更新自定义配置
  void updateConfig(CustomThemeConfig config) {
    _customConfig = config;
    _currentPreset = ThemePreset.custom;
    _isEditing = true;
    notifyListeners();
  }

  /// 更新颜色
  void updateColor({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
  }) {
    _customConfig = _customConfig.copyWith(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      accentColor: accentColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
    );
    _currentPreset = ThemePreset.custom;
    _isEditing = true;
    notifyListeners();
  }

  /// 更新其他设置
  void updateSettings({
    double? fontScale,
    double? borderRadius,
    double? blurStrength,
  }) {
    _customConfig = _customConfig.copyWith(
      fontScale: fontScale,
      borderRadius: borderRadius,
      blurStrength: blurStrength,
    );
    notifyListeners();
  }

  /// 重置为默认
  void resetToDefault() {
    _currentPreset = ThemePreset.archiveBlue;
    _customConfig = CustomThemeConfig.fromPreset(ThemePreset.archiveBlue);
    _isEditing = false;
    notifyListeners();
    saveConfig();
  }
}

/// 颜色选择器组件
class ColorPickerTile extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerTile({
    super.key,
    required this.label,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: color,
        onColorSelected: onColorChanged,
      ),
    );
  }
}

/// 颜色选择对话框
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 颜色预览
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // 预设颜色
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    final hsl = HSLColor.fromColor(color);
                    setState(() {
                      _hue = hsl.hue;
                      _saturation = hsl.saturation;
                      _lightness = hsl.lightness;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 滑块
            Text('色相 (${_hue.toStringAsFixed(0)}°)'),
            Slider(
              value: _hue,
              min: 0,
              max: 360,
              onChanged: (v) => setState(() => _hue = v),
            ),
            Text('饱和度 (${(_saturation * 100).toStringAsFixed(0)}%)'),
            Slider(
              value: _saturation,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _saturation = v),
            ),
            Text('亮度 (${(_lightness * 100).toStringAsFixed(0)}%)'),
            Slider(
              value: _lightness,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _lightness = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorSelected(_currentColor);
            Navigator.pop(context);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 滑块设置组件
class SliderSettingTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  const SliderSettingTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.suffix = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.toStringAsFixed(1)}$suffix',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 主题编辑器组件
class ThemeEditorWidget extends StatelessWidget {
  final ThemeEditorState editorState;

  const ThemeEditorWidget({
    super.key,
    required this.editorState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editorState,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预设选择
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '主题预设',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ThemePreset.values
                        .where((p) => p != ThemePreset.custom)
                        .map((preset) => _PresetChip(
                              preset: preset,
                              isSelected: editorState.currentPreset == preset,
                              onTap: () => editorState.selectPreset(preset),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 自定义颜色
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自定义颜色',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (editorState.isEditing)
                        TextButton.icon(
                          onPressed: editorState.resetToDefault,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('重置'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ColorPickerTile(
                    label: '主色调',
                    color: editorState.customConfig.primaryColor,
                    onColorChanged: (c) =>
                        editorState.updateColor(primaryColor: c),
                  ),
                  ColorPickerTile(
                    label: '次要色',
                    color: editorState.customConfig.secondaryColor,
                    onColorChanged: (c) =>
                        editorState.updateColor(secondaryColor: c),
                  ),
                  ColorPickerTile(
                    label: '强调色',
                    color: editorState.customConfig.accentColor,
                    onColorChanged: (c) =>
                        editorState.updateColor(accentColor: c),
                  ),
                  ColorPickerTile(
                    label: '背景色',
                    color: editorState.customConfig.backgroundColor,
                    onColorChanged: (c) =>
                        editorState.updateColor(backgroundColor: c),
                  ),
                  ColorPickerTile(
                    label: '表面色',
                    color: editorState.customConfig.surfaceColor,
                    onColorChanged: (c) =>
                        editorState.updateColor(surfaceColor: c),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 其他设置
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '其他设置',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SliderSettingTile(
                    label: '字体缩放',
                    value: editorState.customConfig.fontScale,
                    min: 0.8,
                    max: 1.4,
                    suffix: 'x',
                    onChanged: (v) => editorState.updateSettings(fontScale: v),
                  ),
                  SliderSettingTile(
                    label: '圆角大小',
                    value: editorState.customConfig.borderRadius,
                    min: 0,
                    max: 32,
                    suffix: 'px',
                    onChanged: (v) =>
                        editorState.updateSettings(borderRadius: v),
                  ),
                  SliderSettingTile(
                    label: '模糊强度',
                    value: editorState.customConfig.blurStrength,
                    min: 0,
                    max: 50,
                    suffix: '',
                    onChanged: (v) =>
                        editorState.updateSettings(blurStrength: v),
                  ),
                ],
              ),
            ),
            // 预览
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预览',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ThemePreview(config: editorState.customConfig),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 主题预览卡片
class _ThemePreview extends StatelessWidget {
  final CustomThemeConfig config;

  const _ThemePreview({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: config.surfaceColor,
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '预览文本 ${config.fontScale}x',
            style: TextStyle(
              color: config.onBackgroundColor,
              fontSize: 14 * config.fontScale,
            ),
          ),
        ],
      ),
    );
  }
}

/// 预设选择芯片
class _PresetChip extends StatelessWidget {
  final ThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  String get _presetName {
    switch (preset) {
      case ThemePreset.archiveBlue:
        return '蔚蓝档案蓝';
      case ThemePreset.deepSpace:
        return '深空黑';
      case ThemePreset.forestGreen:
        return '森林绿';
      case ThemePreset.sunsetOrange:
        return '日落橙';
      case ThemePreset.violet:
        return '紫罗兰';
      case ThemePreset.custom:
        return '自定义';
    }
  }

  Color get _presetColor {
    switch (preset) {
      case ThemePreset.archiveBlue:
        return const Color(0xFF4FC3F7);
      case ThemePreset.deepSpace:
        return const Color(0xFF6B5B95);
      case ThemePreset.forestGreen:
        return const Color(0xFF2E7D32);
      case ThemePreset.sunsetOrange:
        return const Color(0xFFFF7043);
      case ThemePreset.violet:
        return const Color(0xFF9C27B0);
      case ThemePreset.custom:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _presetColor : _presetColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _presetColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              _presetName,
              style: TextStyle(
                color: isSelected ? Colors.white : _presetColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
