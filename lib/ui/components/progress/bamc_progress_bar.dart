import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum BamcProgressBarType {
  primary,
  secondary,
  warning,
  success,
  pixel,
}

enum BamcProgressBarSize {
  small,
  medium,
  large,
}

class BamcProgressBar extends StatelessWidget {
  final double value;
  final double? max;
  final BamcProgressBarType type;
  final BamcProgressBarSize size;
  final String? label;
  final String? valueLabel;
  final bool showPercentage;
  final bool animated;
  final Duration animationDuration;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool fullWidth;
  final Widget? leading;
  final Widget? trailing;

  const BamcProgressBar({
    super.key,
    required this.value,
    this.max = 100.0,
    this.type = BamcProgressBarType.primary,
    this.size = BamcProgressBarSize.medium,
    this.label,
    this.valueLabel,
    this.showPercentage = false,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.borderRadius,
    this.backgroundColor,
    this.progressColor,
    this.fullWidth = false,
    this.leading,
    this.trailing,
  });

  double _getBarHeight() {
    switch (size) {
      case BamcProgressBarSize.small:
        return 8;
      case BamcProgressBarSize.medium:
        return 12;
      case BamcProgressBarSize.large:
        return 16;
    }
  }

  double _getFontSize() {
    switch (size) {
      case BamcProgressBarSize.small:
        return 10;
      case BamcProgressBarSize.medium:
        return 12;
      case BamcProgressBarSize.large:
        return 14;
    }
  }

  Color _getProgressColor() {
    switch (type) {
      case BamcProgressBarType.primary:
        return progressColor ?? BamcColors.primary;
      case BamcProgressBarType.secondary:
        return progressColor ?? BamcColors.secondary;
      case BamcProgressBarType.warning:
        return progressColor ?? BamcColors.warning;
      case BamcProgressBarType.success:
        return progressColor ?? BamcColors.success;
      case BamcProgressBarType.pixel:
        return progressColor ?? BamcColors.primary;
    }
  }

  Color _getBackgroundColor() {
    return backgroundColor ?? BamcColors.border.withOpacity(0.3);
  }

  Widget _buildPixelProgressBar() {
    final progress = (value / max!).clamp(0.0, 1.0);
    const totalBlocks = 20; // 20个方块，更符合MC风格
    final filledBlocks = (progress * totalBlocks).floor();

    return Container(
      height: _getBarHeight(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BamcColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BamcColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(totalBlocks, (index) {
          final isFilled = index < filledBlocks;
          final isPartial = index == filledBlocks && progress * totalBlocks % 1 != 0;
          final partialWidth = (progress * totalBlocks % 1) * 100;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              child: isFilled
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getProgressColor(),
                            _getProgressColor().withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    )
                  : isPartial
                      ? Row(
                          children: [
                            Container(
                              width: partialWidth,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _getProgressColor(),
                                    _getProgressColor().withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(2),
                                  bottomLeft: Radius.circular(2),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getBackgroundColor(),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStandardProgressBar() {
    final progress = (value / max!).clamp(0.0, 1.0);
    final borderRadius = this.borderRadius ?? BorderRadius.circular(8);

    return Container(
      height: _getBarHeight(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: borderRadius,
        border: Border.all(
          color: BamcColors.border,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: animated
            ? AnimatedContainer(
                duration: animationDuration,
                width: fullWidth ? progress * 100 : null,
                constraints: fullWidth ? BoxConstraints.expand(width: progress) : null,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getProgressColor(),
                      _getProgressColor().withOpacity(0.8),
                    ],
                  ),
                  borderRadius: borderRadius,
                ),
              )
            : FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getProgressColor(),
                        _getProgressColor().withOpacity(0.8),
                      ],
                    ),
                    borderRadius: borderRadius,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (type == BamcProgressBarType.pixel) {
      return _buildPixelProgressBar();
    }
    return _buildStandardProgressBar();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (value / max!).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(0);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || valueLabel != null || showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: _getFontSize(),
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                        fontFamily: 'Minecraft',
                      ),
                    ),
                  const Spacer(),
                  if (valueLabel != null)
                    Text(
                      valueLabel!,
                      style: TextStyle(
                        fontSize: _getFontSize(),
                        color: BamcColors.textSecondary,
                      ),
                    ),
                  if (showPercentage)
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: _getFontSize(),
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(),
                        fontFamily: 'Minecraft',
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            width: fullWidth ? double.infinity : null,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: leading,
                  ),
                Expanded(
                  child: _buildProgressBar(),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
