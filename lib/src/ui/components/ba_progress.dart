import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// MC经验条风格进度条
class BAExperienceProgressBar extends StatefulWidget {
  /// 进度值 (0.0 - 1.0)
  final double value;

  /// 是否显示百分比
  final bool showPercentage;

  /// 是否显示动画
  final bool animate;

  /// 动画时长
  final Duration duration;

  /// 高度
  final double height;

  /// 进度条颜色
  final Color? color;

  /// 背景颜色
  final Color? backgroundColor;

  /// 百分比文本样式
  final TextStyle? percentageStyle;

  const BAExperienceProgressBar({
    super.key,
    required this.value,
    this.showPercentage = true,
    this.animate = true,
    this.duration = const Duration(milliseconds: 300),
    this.height = 24,
    this.color,
    this.backgroundColor,
    this.percentageStyle,
  });

  @override
  State<BAExperienceProgressBar> createState() =>
      _BAExperienceProgressBarState();
}

class _BAExperienceProgressBarState extends State<BAExperienceProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation =
        Tween<double>(begin: 0.0, end: widget.value).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {
            _currentValue = _animation.value;
          });
        });
    if (widget.animate) {
      _controller.forward();
    } else {
      _currentValue = widget.value;
    }
  }

  @override
  void didUpdateWidget(BAExperienceProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != oldWidget.value) {
      if (widget.animate) {
        _animation = Tween<double>(begin: _currentValue, end: widget.value)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            );
        _controller.reset();
        _controller.forward();
      } else {
        _currentValue = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.color ?? BAColors.successOf(context);
    final bgColor = widget.backgroundColor ?? BAColors.surfaceVariantOf(context);
    final clampedValue = _currentValue.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: BAColors.borderOf(context), width: 2),
            boxShadow: [
              BoxShadow(
                color: BAColors.shadowOf(context).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _PixelProgress(
                  progress: clampedValue,
                  color: progressColor,
                ),
              ),
              if (widget.showPercentage)
                Center(
                  child: Text(
                    '${(clampedValue * 100).toStringAsFixed(0)}%',
                    style:
                        widget.percentageStyle ??
                        BATypography.bodySmall.copyWith(
                          color: BAColors.textPrimaryOf(context),
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 像素化进度条
class _PixelProgress extends StatelessWidget {
  final double progress;
  final Color color;

  const _PixelProgress({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelCount = (constraints.maxWidth / 8).floor();
        final filledPixels = (pixelCount * progress).round();

        return Row(
          children: List.generate(pixelCount, (index) {
            final isFilled = index < filledPixels;
            final isPartial = index == filledPixels - 1 && filledPixels > 0;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: isFilled
                      ? (isPartial ? color.withOpacity(0.9) : color)
                      : Colors.transparent,
                  border: isFilled
                      ? Border(
                          top: BorderSide(color: color.withOpacity(0.3)),
                          left: BorderSide(color: color.withOpacity(0.3)),
                          bottom: BorderSide(
                            color: Colors.black.withOpacity(0.2),
                          ),
                          right: BorderSide(
                            color: Colors.black.withOpacity(0.2),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 普通进度条组件
class BAProgressBar extends StatelessWidget {
  /// 进度值 (0.0 - 1.0)
  final double value;

  /// 是否显示百分比
  final bool showPercentage;

  /// 高度
  final double height;

  /// 进度条颜色
  final Color? color;

  /// 背景颜色
  final Color? backgroundColor;

  /// 百分比文本样式
  final TextStyle? percentageStyle;

  const BAProgressBar({
    super.key,
    required this.value,
    this.showPercentage = true,
    this.height = 12,
    this.color,
    this.backgroundColor,
    this.percentageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? BAColors.primaryOf(context);
    final bgColor = backgroundColor ?? BAColors.surfaceVariantOf(context);
    final clampedValue = value.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BATheme.borderRadiusSmall,
            border: Border.all(color: BAColors.borderOf(context), width: 1),
            boxShadow: BATheme.shadowsSmall,
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: clampedValue,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BATheme.borderRadiusSmall,
                  ),
                ),
              ),
              if (showPercentage && height >= 20)
                Center(
                  child: Text(
                    '${(clampedValue * 100).toStringAsFixed(0)}%',
                    style:
                        percentageStyle ??
                        BATypography.bodySmall.copyWith(
                          color: BAColors.textPrimaryOf(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
