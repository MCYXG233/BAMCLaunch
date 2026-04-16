import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

enum MinecraftXpBarStyle {
  grass,
  gold,
  diamond,
  redstone,
  emerald,
  lapis,
  netherite,
}

class MinecraftXpBar extends StatefulWidget {
  final double value;
  final double max;
  final MinecraftXpBarStyle style;
  final double height;
  final int totalBlocks;
  final bool animated;
  final Duration animationDuration;
  final bool showPercentage;
  final String? label;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MinecraftXpBar({
    super.key,
    required this.value,
    this.max = 100.0,
    this.style = MinecraftXpBarStyle.grass,
    this.height = 24,
    this.totalBlocks = 20,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 500),
    this.showPercentage = false,
    this.label,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  State<MinecraftXpBar> createState() => _MinecraftXpBarState();
}

class _MinecraftXpBarState extends State<MinecraftXpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _previousValue = widget.value;
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.value / widget.max).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    if (widget.animated) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MinecraftXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final oldProgress = (_previousValue / oldWidget.max).clamp(0.0, 1.0);
      final newProgress = (widget.value / widget.max).clamp(0.0, 1.0);
      _previousValue = widget.value;
      _progressAnimation = Tween<double>(
        begin: oldProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ));
      _animationController.reset();
      if (widget.animated) {
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    switch (widget.style) {
      case MinecraftXpBarStyle.grass:
        return BamcColors.secondary;
      case MinecraftXpBarStyle.gold:
        return BamcColors.success;
      case MinecraftXpBarStyle.diamond:
        return const Color(0xFF00BCD4);
      case MinecraftXpBarStyle.redstone:
        return BamcColors.warning;
      case MinecraftXpBarStyle.emerald:
        return const Color(0xFF4CAF50);
      case MinecraftXpBarStyle.lapis:
        return BamcColors.primary;
      case MinecraftXpBarStyle.netherite:
        return const Color(0xFF424242);
    }
  }

  Color _getLightColor() {
    switch (widget.style) {
      case MinecraftXpBarStyle.grass:
        return BamcColors.secondaryLight;
      case MinecraftXpBarStyle.gold:
        return BamcColors.successLight;
      case MinecraftXpBarStyle.diamond:
        return const Color(0xFF4DD0E1);
      case MinecraftXpBarStyle.redstone:
        return BamcColors.warningLight;
      case MinecraftXpBarStyle.emerald:
        return const Color(0xFF81C784);
      case MinecraftXpBarStyle.lapis:
        return BamcColors.primaryLight;
      case MinecraftXpBarStyle.netherite:
        return const Color(0xFF757575);
    }
  }

  Color _getDarkColor() {
    switch (widget.style) {
      case MinecraftXpBarStyle.grass:
        return BamcColors.secondaryDark;
      case MinecraftXpBarStyle.gold:
        return BamcColors.successDark;
      case MinecraftXpBarStyle.diamond:
        return const Color(0xFF0097A7);
      case MinecraftXpBarStyle.redstone:
        return BamcColors.warningDark;
      case MinecraftXpBarStyle.emerald:
        return const Color(0xFF388E3C);
      case MinecraftXpBarStyle.lapis:
        return BamcColors.primaryDark;
      case MinecraftXpBarStyle.netherite:
        return const Color(0xFF212121);
    }
  }

  Color _getBlockColor(int index, bool isFilled, double partial) {
    if (!isFilled && partial <= 0) {
      return BamcColors.border.withOpacity(0.3);
    }
    return _getPrimaryColor();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = ((widget.value / widget.max) * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null || widget.showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BamcColors.textPrimary,
                      ),
                    ),
                  const Spacer(),
                  if (widget.showPercentage)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final displayPercentage =
                            (_progressAnimation.value * 100).toStringAsFixed(0);
                        return Text(
                          '$displayPercentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getPrimaryColor(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          SizedBox(
            height: widget.height,
            child: Row(
              children: [
                if (widget.leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: widget.leading,
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      border: Border.all(
                        color: _getDarkColor().withOpacity(0.5),
                        width: 2,
                      ),
                      color: BamcColors.background,
                      boxShadow: [
                        BoxShadow(
                          color: _getPrimaryColor().withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(widget.height / 2 - 2),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final progress = _progressAnimation.value;
                          return Row(
                            children:
                                List.generate(widget.totalBlocks, (index) {
                              final blockProgress =
                                  (index + 1) / widget.totalBlocks;
                              final prevBlockProgress =
                                  index / widget.totalBlocks;
                              final isFilled = progress >= blockProgress;
                              final partial = ((progress - prevBlockProgress) *
                                      widget.totalBlocks)
                                  .clamp(0.0, 1.0);
                              final isPartial = !isFilled && partial > 0;

                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 1,
                                    vertical: widget.height * 0.15,
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: BamcColors.border
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      if (isFilled || isPartial)
                                        FractionallySizedBox(
                                          widthFactor: isFilled ? 1.0 : partial,
                                          alignment: Alignment.centerLeft,
                                          child: _buildBlock(
                                            isFilled: true,
                                            partial: partial,
                                            index: index,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget.trailing,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    required bool isFilled,
    required double partial,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getLightColor(),
            _getPrimaryColor(),
            _getDarkColor(),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getDarkColor().withOpacity(0.3),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _buildPixelOverlay(index),
    );
  }

  Widget _buildPixelOverlay(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelSize = constraints.maxHeight / 3;
        return CustomPaint(
          painter: _PixelOverlayPainter(
            pixelSize: pixelSize,
            lightColor: _getLightColor().withOpacity(0.3),
            darkColor: _getDarkColor().withOpacity(0.2),
            index: index,
          ),
        );
      },
    );
  }
}

class _PixelOverlayPainter extends CustomPainter {
  final double pixelSize;
  final Color lightColor;
  final Color darkColor;
  final int index;

  _PixelOverlayPainter({
    required this.pixelSize,
    required this.lightColor,
    required this.darkColor,
    required this.index,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    final random = Random(index);

    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < (size.width / pixelSize).ceil(); x++) {
        if (random.nextDouble() < 0.15) {
          final paint = random.nextBool() ? lightPaint : darkPaint;
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelOverlayPainter oldDelegate) {
    return oldDelegate.pixelSize != pixelSize ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor ||
        oldDelegate.index != index;
  }
}
