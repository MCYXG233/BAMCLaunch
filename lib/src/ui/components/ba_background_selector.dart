import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../config/background_config.dart';

class BABackgroundSelector extends StatefulWidget {
  final BackgroundConfig currentConfig;
  final ValueChanged<BackgroundConfig> onConfigChanged;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickVideo;

  const BABackgroundSelector({
    super.key,
    required this.currentConfig,
    required this.onConfigChanged,
    this.onPickImage,
    this.onPickVideo,
  });

  @override
  State<BABackgroundSelector> createState() => _BABackgroundSelectorState();
}

class _BABackgroundSelectorState extends State<BABackgroundSelector> {
  late BackgroundConfig _config;
  final List<BackgroundConfig> _presets = [
    BackgroundConfig.classic,
    BackgroundConfig.sakura,
    BackgroundConfig.night,
    BackgroundConfig.mint,
    BackgroundConfig.sunset,
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;
  }

  @override
  void didUpdateWidget(BABackgroundSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentConfig != widget.currentConfig) {
      _config = widget.currentConfig;
    }
  }

  void _selectPreset(BackgroundConfig preset) {
    setState(() {
      _config = preset;
    });
    widget.onConfigChanged(preset);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '背景设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          '预设背景',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BAColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presets.map((preset) {
            return _PresetCard(
              config: preset,
              isSelected: _config.type == preset.type &&
                  _config.gradientColors == preset.gradientColors,
              onTap: () => _selectPreset(preset),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        Text(
          '自定义',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BAColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.onPickImage != null)
              _CustomImageButton(
                onTap: widget.onPickImage!,
                isSelected: _config.type == BackgroundType.image,
              ),
            if (widget.onPickVideo != null)
              _CustomVideoButton(
                onTap: widget.onPickVideo!,
                isSelected: _config.type == BackgroundType.video,
              ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          '调整选项',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BAColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 12),

        _SliderOption(
          label: '模糊度',
          value: _config.blur,
          min: 0,
          max: 25,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(blur: value);
            });
            widget.onConfigChanged(_config);
          },
        ),

        const SizedBox(height: 12),

        _SliderOption(
          label: '透明度',
          value: _config.opacity,
          min: 0.3,
          max: 1.0,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(opacity: value);
            });
            widget.onConfigChanged(_config);
          },
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final BackgroundConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BAAnimation.fast,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: config.gradientColors?.map((c) => Color(c)).toList() ??
                  [BAColors.backgroundOf(context), BAColors.backgroundSecondaryOf(context)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(BAThemeData.radius),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context)
                  : BAColors.borderOf(context).withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? BAThemeColors.glowShadow : [],
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    Icons.check_circle,
                    color: BAColors.primaryOf(context),
                    size: 24,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _CustomImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;

  const _CustomImageButton({
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(BAThemeData.radius),
            border: Border.all(
              color: isSelected
                  ? BAColors.primaryOf(context)
                  : BAColors.borderOf(context).withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                '上传图片',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomVideoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;

  const _CustomVideoButton({
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Windows 平台仅支持 MP4 格式',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(BAThemeData.radius),
              border: Border.all(
                color: isSelected
                    ? BAColors.primaryOf(context)
                    : BAColors.borderOf(context).withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  '上传视频',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderOption extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderOption({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 13,
                color: BAColors.textPrimaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: BAColors.primaryOf(context),
            inactiveTrackColor: BAColors.borderOf(context),
            thumbColor: BAColors.primaryOf(context),
            overlayColor: BAColors.primaryOf(context).withOpacity(0.12),
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
