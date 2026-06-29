import 'dart:math';
import 'package:flutter/material.dart';

/// BA 通用动画组件库
///
/// 提供常用的动画效果组件，所有动画组件均支持 [isActive] 参数控制启停。
///
/// 使用方式：
/// ```dart
/// BAAnimations.pulse(
///   child: Container(width: 20, height: 20, color: Colors.red),
/// )
/// ```
class BAAnimations {
  BAAnimations._();

  /// 脉冲动画，用于状态指示器
  ///
  /// 子组件会以 [scaleBegin] 到 [scaleEnd] 的范围进行缩放循环，
  /// 适用于在线状态、加载中等指示场景。
  static Widget pulse({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 1000),
    double scaleBegin = 1.0,
    double scaleEnd = 1.15,
    Color? glowColor,
    double glowRadius = 6.0,
  }) {
    return _BAPulseWidget(
      isActive: isActive,
      duration: duration,
      scaleBegin: scaleBegin,
      scaleEnd: scaleEnd,
      glowColor: glowColor,
      glowRadius: glowRadius,
      child: child,
    );
  }

  /// 呼吸灯效果，用于按钮
  ///
  /// 子组件会呈现柔和的透明度渐变呼吸效果，
  /// 适用于按钮高亮、待操作提示等场景。
  static Widget breathe({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 2000),
    double minOpacity = 0.6,
    double maxOpacity = 1.0,
    double glowRadius = 8.0,
    Color glowColor = const Color(0xFF2196F3),
  }) {
    return _BABreatheWidget(
      isActive: isActive,
      duration: duration,
      minOpacity: minOpacity,
      maxOpacity: maxOpacity,
      glowRadius: glowRadius,
      glowColor: glowColor,
      child: child,
    );
  }

  /// 错落进入动画，用于列表
  ///
  /// 列表中的每个子项会按照 [staggerDelay] 的间隔依次执行
  /// 淡入 + 上移动画，适合列表/网格加载时使用。
  static Widget staggeredEntry({
    required List<Widget> children,
    bool isActive = true,
    Duration itemDuration = const Duration(milliseconds: 400),
    Duration staggerDelay = const Duration(milliseconds: 80),
    double slideOffset = 30.0,
    Curve curve = Curves.easeOutCubic,
  }) {
    return _BAStaggeredEntryWidget(
      isActive: isActive,
      itemDuration: itemDuration,
      staggerDelay: staggerDelay,
      slideOffset: slideOffset,
      curve: curve,
      children: children,
    );
  }

  /// 弹性缩放动画
  ///
  /// 子组件从 [initialScale] 弹性缩放到 1.0，
  /// 适用于卡片展开、弹窗出现等需要活泼感的场景。
  static Widget elasticScale({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 800),
    double initialScale = 0.0,
  }) {
    return _BAElasticScaleWidget(
      isActive: isActive,
      duration: duration,
      initialScale: initialScale,
      child: child,
    );
  }

  /// 渐变边框容器
  ///
  /// 子组件外围包裹一圈旋转渐变边框，
  /// 可用于高亮卡片、选中状态、特殊标识等场景。
  static Widget gradientBorder({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 3000),
    List<Color> gradientColors = const [
      Color(0xFF2196F3),
      Color(0xFF9C27B0),
      Color(0xFFFF9800),
      Color(0xFF2196F3),
    ],
    double borderWidth = 2.0,
    double borderRadius = 12.0,
  }) {
    return _BAGradientBorderWidget(
      isActive: isActive,
      duration: duration,
      gradientColors: gradientColors,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// 发光效果
  ///
  /// 子组件外围呈现脉冲式发光阴影，
  /// 适用于重要按钮、焦点元素等需要吸引注意力的场景。
  static Widget glow({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 1500),
    Color glowColor = const Color(0xFF2196F3),
    double maxBlurRadius = 16.0,
    double maxSpreadRadius = 4.0,
  }) {
    return _BAGlowWidget(
      isActive: isActive,
      duration: duration,
      glowColor: glowColor,
      maxBlurRadius: maxBlurRadius,
      maxSpreadRadius: maxSpreadRadius,
      child: child,
    );
  }
}

// =============================================================================
// 脉冲动画
// =============================================================================

class _BAPulseWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final double scaleBegin;
  final double scaleEnd;
  final Color? glowColor;
  final double glowRadius;

  const _BAPulseWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.scaleBegin,
    required this.scaleEnd,
    this.glowColor,
    required this.glowRadius,
  });

  @override
  State<_BAPulseWidget> createState() => _BAPulseWidgetState();
}

class _BAPulseWidgetState extends State<_BAPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.scaleBegin,
      end: widget.scaleEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BAPulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: widget.glowColor != null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor!
                          .withValues(alpha: 0.4 * _glowAnimation.value),
                      blurRadius: widget.glowRadius * _glowAnimation.value,
                      spreadRadius:
                          widget.glowRadius * 0.5 * _glowAnimation.value,
                    ),
                  ],
                )
              : null,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// =============================================================================
// 呼吸灯效果
// =============================================================================

class _BABreatheWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final double glowRadius;
  final Color glowColor;

  const _BABreatheWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.minOpacity,
    required this.maxOpacity,
    required this.glowRadius,
    required this.glowColor,
  });

  @override
  State<_BABreatheWidget> createState() => _BABreatheWidgetState();
}

class _BABreatheWidgetState extends State<_BABreatheWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BABreatheWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withValues(alpha: 0.3 * _glowAnimation.value),
                blurRadius: widget.glowRadius * _glowAnimation.value,
                spreadRadius: widget.glowRadius * 0.3 * _glowAnimation.value,
              ),
            ],
          ),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// =============================================================================
// 错落进入动画
// =============================================================================

class _BAStaggeredEntryWidget extends StatefulWidget {
  final List<Widget> children;
  final bool isActive;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double slideOffset;
  final Curve curve;

  const _BAStaggeredEntryWidget({
    required this.children,
    required this.isActive,
    required this.itemDuration,
    required this.staggerDelay,
    required this.slideOffset,
    required this.curve,
  });

  @override
  State<_BAStaggeredEntryWidget> createState() =>
      _BAStaggeredEntryWidgetState();
}

class _BAStaggeredEntryWidgetState extends State<_BAStaggeredEntryWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    if (widget.isActive) {
      _controller.forward();
    }
  }

  void _buildAnimations() {
    final itemCount = widget.children.length;
    if (itemCount == 0) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration.zero,
      );
      _fadeAnimations = [];
      _slideAnimations = [];
      return;
    }

    final totalDuration = widget.itemDuration.inMilliseconds +
        widget.staggerDelay.inMilliseconds * (itemCount - 1);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration),
    );

    _fadeAnimations = List.generate(itemCount, (index) {
      final start =
          (widget.staggerDelay.inMilliseconds * index) / totalDuration;
      final end = (widget.staggerDelay.inMilliseconds * index +
              widget.itemDuration.inMilliseconds) /
          totalDuration;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: widget.curve),
        ),
      );
    });

    _slideAnimations = List.generate(itemCount, (index) {
      final start =
          (widget.staggerDelay.inMilliseconds * index) / totalDuration;
      final end = (widget.staggerDelay.inMilliseconds * index +
              widget.itemDuration.inMilliseconds) /
          totalDuration;
      return Tween<Offset>(
        begin: Offset(0, widget.slideOffset),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: widget.curve),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(_BAStaggeredEntryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.stop();
      }
    }
    if (widget.children.length != oldWidget.children.length) {
      _controller.dispose();
      _buildAnimations();
      if (widget.isActive) {
        _controller.forward();
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
    if (widget.children.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.children.length, (index) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: widget.children[index],
              ),
            );
          }),
        );
      },
    );
  }
}

// =============================================================================
// 弹性缩放动画
// =============================================================================

class _BAElasticScaleWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final double initialScale;

  const _BAElasticScaleWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.initialScale,
  });

  @override
  State<_BAElasticScaleWidget> createState() => _BAElasticScaleWidgetState();
}

class _BAElasticScaleWidgetState extends State<_BAElasticScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_BAElasticScaleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.stop();
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

// =============================================================================
// 渐变边框容器
// =============================================================================

class _BAGradientBorderWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final List<Color> gradientColors;
  final double borderWidth;
  final double borderRadius;

  const _BAGradientBorderWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.gradientColors,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  State<_BAGradientBorderWidget> createState() =>
      _BAGradientBorderWidgetState();
}

class _BAGradientBorderWidgetState extends State<_BAGradientBorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_BAGradientBorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _controller.value,
            gradientColors: widget.gradientColors,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  BorderRadius.circular(widget.borderRadius - widget.borderWidth),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final double borderWidth;
  final double borderRadius;

  _GradientBorderPainter({
    required this.progress,
    required this.gradientColors,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final gradient = SweepGradient(
      colors: gradientColors,
      stops: List.generate(
        gradientColors.length,
        (i) => i / (gradientColors.length - 1),
      ),
      transform: GradientRotation(progress * 2 * pi),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

// =============================================================================
// 发光效果
// =============================================================================

class _BAGlowWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final Color glowColor;
  final double maxBlurRadius;
  final double maxSpreadRadius;

  const _BAGlowWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.glowColor,
    required this.maxBlurRadius,
    required this.maxSpreadRadius,
  });

  @override
  State<_BAGlowWidget> createState() => _BAGlowWidgetState();
}

class _BAGlowWidgetState extends State<_BAGlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BAGlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
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
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final value = _glowAnimation.value;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.5 * value),
                blurRadius: widget.maxBlurRadius * value,
                spreadRadius: widget.maxSpreadRadius * value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
