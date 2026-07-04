import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/custom_theme_colors.dart';
import '../theme/theme_manager.dart';

/// 颜色选择面板
/// 提供预设颜色 + 自定义颜色选择
/// 自动同步到 ThemeManager 和 SharedPreferences
class ColorPickerPanel extends StatefulWidget {
  final String themeKey;
  final Brightness brightness;

  const ColorPickerPanel({
    super.key,
    required this.themeKey,
    required this.brightness,
  });

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  late List<PresetColor> _presets;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _presets = widget.themeKey == 'minecraft'
        ? CustomThemeColors.minecraftPresets
        : CustomThemeColors.blueArchivePresets;
    _selectedValue = _getCurrentValue();
  }

  int _getCurrentValue() {
    final colors = BAColors.customColors;
    final isLight = widget.brightness == Brightness.light;
    if (widget.themeKey == 'minecraft') {
      return isLight ? colors.minecraftLight : colors.minecraftDark;
    }
    return isLight ? colors.blueArchiveLight : colors.blueArchiveDark;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BAColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: BAColors.primaryOf(context), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.themeKey == 'minecraft'
                    ? 'Minecraft 主题色'
                    : '蔚蓝档案主题色',
                style: TextStyle(
                  color: BAColors.textPrimaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                widget.brightness == Brightness.light ? '浅色模式' : '深色模式',
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presets.map((p) {
              final isSelected = p.primaryValue == _selectedValue;
              return _ColorSwatch(
                preset: p,
                selected: isSelected,
                onTap: () => _selectColor(p.primaryValue),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCustomColorPicker,
                  icon: const Icon(Icons.colorize, size: 16),
                  label: const Text('自定义颜色'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BAColors.textPrimaryOf(context),
                    side: BorderSide(color: BAColors.borderOf(context)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _resetColor,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('默认'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BAColors.textSecondaryOf(context),
                  side: BorderSide(color: BAColors.borderOf(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectColor(int colorValue) async {
    setState(() => _selectedValue = colorValue);
    await ThemeManager.instance.setPrimaryColor(
      theme: widget.themeKey,
      brightness: widget.brightness,
      colorValue: colorValue,
    );
  }

  Future<void> _resetColor() async {
    const defaults = CustomThemeColors();
    final isLight = widget.brightness == Brightness.light;
    final value = widget.themeKey == 'minecraft'
        ? (isLight ? defaults.minecraftLight : defaults.minecraftDark)
        : (isLight ? defaults.blueArchiveLight : defaults.blueArchiveDark);
    await _selectColor(value);
  }

  Future<void> _openCustomColorPicker() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _CustomColorDialog(initial: _selectedValue),
    );
    if (result != null) {
      await _selectColor(result);
    }
  }
}

class _ColorSwatch extends StatelessWidget {
  final PresetColor preset;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: preset.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: preset.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? BAColors.primaryOf(context)
                  : BAColors.borderOf(context),
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: preset.color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}

/// 自定义颜色选择对话框（使用 HSV 颜色模型）
class _CustomColorDialog extends StatefulWidget {
  final int initial;
  const _CustomColorDialog({required this.initial});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSLColor _hsl;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(Color(widget.initial));
    _hexController = TextEditingController(
      text: widget.initial.toRadixString(16).padLeft(8, '0').toUpperCase(),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => _hsl.toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BAColors.surfaceOf(context),
      title: Text('自定义颜色',
          style: TextStyle(color: BAColors.textPrimaryOf(context))),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BAColors.borderOf(context)),
              ),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: '色相',
              value: _hsl.hue,
              max: 360,
              onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
            ),
            _buildSlider(
              label: '饱和度',
              value: _hsl.saturation * 100,
              max: 100,
              onChanged: (v) =>
                  setState(() => _hsl = _hsl.withSaturation(v / 100)),
            ),
            _buildSlider(
              label: '亮度',
              value: _hsl.lightness * 100,
              max: 100,
              onChanged: (v) =>
                  setState(() => _hsl = _hsl.withLightness(v / 100)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hexController,
              style: TextStyle(color: BAColors.textPrimaryOf(context)),
              decoration: InputDecoration(
                labelText: '十六进制值',
                labelStyle:
                    TextStyle(color: BAColors.textSecondaryOf(context)),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: BAColors.borderOf(context)),
                ),
                prefixText: '#',
              ),
              onSubmitted: _onHexSubmit,
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
            final c = _currentColor;
            Navigator.pop(context, (c.a * 255).toInt() << 24 |
                (c.r * 255).toInt() << 16 |
                (c.g * 255).toInt() << 8 |
                (c.b * 255).toInt());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: BAColors.primaryOf(context),
          ),
          child: const Text('确定', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _onHexSubmit(String value) {
    final cleaned = value.replaceFirst('#', '').replaceFirst('0x', '');
    if (cleaned.length == 6) {
      final v = int.tryParse('FF$cleaned', radix: 16);
      if (v != null) {
        setState(() => _hsl = HSLColor.fromColor(Color(v)));
      }
    } else if (cleaned.length == 8) {
      final v = int.tryParse(cleaned, radix: 16);
      if (v != null) {
        setState(() => _hsl = HSLColor.fromColor(Color(v)));
      }
    }
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(color: BAColors.textSecondaryOf(context))),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: max,
            onChanged: onChanged,
            activeColor: BAColors.primaryOf(context),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(0),
            style: TextStyle(color: BAColors.textSecondaryOf(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}