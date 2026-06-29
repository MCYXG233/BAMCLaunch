import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// BA 视觉效果组件库
///
/// 提供高级视觉效果，包括玻璃拟态、粒子、霓虹灯、骨架屏、涟漪等。
///
/// 使用方式：
/// ```dart
/// BAEffects.glassMorphism(
///   child: Container(width: 200, height: 100),
/// )
/// ```
class BAEffects {
  BAEffects._();

  /// 玻璃拟态效果
  ///
  /// 使用 [BackdropFilter] 对子组件底层进行高斯模糊，
  /// 配合半透明背景色营造毛玻璃质感。
  static Widget glassMorphism({
    required Widget child,
    double sigmaX = 10.0,
    double sigmaY = 10.0,
    Color backgroundColor = const Color(0x33FFFFFF),
    Color borderColor = const Color(0x33FFFFFF),
    double borderWidth = 1.0,
    double borderRadius = 16.0,
    BorderRadiusGeometry? borderRadiusGeometry,
  }) {
    return _BAGlassMorphismWidget(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      borderRadiusGeometry: borderRadiusGeometry,
      child: child,
    );
  }

  /// 粒子效果
  ///
  /// 使用 [CustomPainter] 绘制飘浮粒子，
  /// 适合用作页面背景的装饰性动画。
  static Widget particles({
    required Widget child,
    bool isActive = true,
    int particleCount = 30,
    Color particleColor = const Color(0x44FFFFFF),
    double minRadius = 1.0,
    double maxRadius = 3.0,
    Duration duration = const Duration(seconds: 8),
  }) {
    return _BAParticlesWidget(
      isActive: isActive,
      particleCount: particleCount,
      particleColor: particleColor,
      minRadius: minRadius,
      maxRadius: maxRadius,
      duration: duration,
      child: child,
    );
  }

  /// 霓虹灯效果
  ///
  /// 多层彩色发光阴影叠加，营造赛博朋克风格的霓虹灯光效。
  /// 适用于标题、按钮等需要吸引注意力的元素。
  static Widget neonGlow({
    required Widget child,
    bool isActive = true,
    Color glowColor = const Color(0xFF00F5FF),
    Duration duration = const Duration(milliseconds: 1500),
    double blurRadius = 16.0,
    double spreadRadius = 2.0,
  }) {
    return _BANeonGlowWidget(
      isActive: isActive,
      glowColor: glowColor,
      duration: duration,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
      child: child,
    );
  }

  /// 骨架屏效果
  ///
  /// 使用 [ShaderMask] 配合线性渐变实现从左到右的高光扫过动画，
  /// 常用于内容加载中的占位展示。
  static Widget shimmer({
    required Widget child,
    bool isActive = true,
    Duration duration = const Duration(milliseconds: 1500),
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return _BAShimmerWidget(
      isActive: isActive,
      duration: duration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// 涟漪效果
  ///
  /// 以点击位置为圆心向外扩散同心圆环，
  /// 使用 [CustomPainter] 绘制，适合用作按钮或卡片的点击反馈。
  static Widget ripple({
    required Widget child,
    bool isActive = true,
    Color rippleColor = const Color(0x44FFFFFF),
    Duration duration = const Duration(milliseconds: 800),
    int rippleCount = 3,
    double maxRadius = 80.0,
    double strokeWidth = 2.0,
  }) {
    return _BARippleWidget(
      isActive: isActive,
      rippleColor: rippleColor,
      duration: duration,
      rippleCount: rippleCount,
      maxRadius: maxRadius,
      strokeWidth: strokeWidth,
      child: child,
    );
  }
}

// =============================================================================
// 玻璃拟态效果
// =============================================================================

class _BAGlassMorphismWidget extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final BorderRadiusGeometry? borderRadiusGeometry;

  const _BAGlassMorphismWidget({
    required this.child,
    required this.sigmaX,
    required this.sigmaY,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    this.borderRadiusGeometry,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadiusGeometry ?? BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// 粒子效果
// =============================================================================

class _ParticleData {
  double x;
  double y;
  double radius;
  double speedX;
  double speedY;
  double opacity;

  _ParticleData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _BAParticlesWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final int particleCount;
  final Color particleColor;
  final double minRadius;
  final double maxRadius;
  final Duration duration;

  const _BAParticlesWidget({
    required this.child,
    required this.isActive,
    required this.particleCount,
    required this.particleColor,
    required this.minRadius,
    required this.maxRadius,
    required this.duration,
  });

  @override
  State<_BAParticlesWidget> createState() => _BAParticlesWidgetState();
}

class _BAParticlesWidgetState extends State<_BAParticlesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ParticleData> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particles = List.generate(widget.particleCount, (_) {
      return _createParticle();
    });

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  _ParticleData _createParticle() {
    return _ParticleData(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      radius: widget.minRadius +
          _random.nextDouble() * (widget.maxRadius - widget.minRadius),
      speedX: (_random.nextDouble() - 0.5) * 0.002,
      speedY: -_random.nextDouble() * 0.003 - 0.001,
      opacity: _random.nextDouble() * 0.6 + 0.1,
    );
  }

  @override
  void didUpdateWidget(_BAParticlesWidget oldWidget) {
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
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              _updateParticles();
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  color: widget.particleColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.speedX;
      p.y += p.speedY;
      if (p.y < -0.05) {
        p.y = 1.05;
        p.x = _random.nextDouble();
      }
      if (p.x < -0.05) p.x = 1.05;
      if (p.x > 1.05) p.x = -0.05;
    }
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_ParticleData> particles;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}

// =============================================================================
// 霓虹灯效果
// =============================================================================

class _BANeonGlowWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color glowColor;
  final Duration duration;
  final double blurRadius;
  final double spreadRadius;

  const _BANeonGlowWidget({
    required this.child,
    required this.isActive,
    required this.glowColor,
    required this.duration,
    required this.blurRadius,
    required this.spreadRadius,
  });

  @override
  State<_BANeonGlowWidget> createState() => _BANeonGlowWidgetState();
}

class _BANeonGlowWidgetState extends State<_BANeonGlowWidget>
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
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BANeonGlowWidget oldWidget) {
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
        final value = _controller.value;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.4 * value),
                blurRadius: widget.blurRadius * value,
                spreadRadius: widget.spreadRadius * value,
              ),
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.2 * value),
                blurRadius: widget.blurRadius * 2 * value,
                spreadRadius: widget.spreadRadius * 1.5 * value,
              ),
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.1 * value),
                blurRadius: widget.blurRadius * 3 * value,
                spreadRadius: widget.spreadRadius * 2 * value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// 骨架屏效果
// =============================================================================

class _BAShimmerWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const _BAShimmerWidget({
    required this.child,
    required this.isActive,
    required this.duration,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_BAShimmerWidget> createState() => _BAShimmerWidgetState();
}

class _BAShimmerWidgetState extends State<_BAShimmerWidget>
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
  void didUpdateWidget(_BAShimmerWidget oldWidget) {
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

// =============================================================================
// 涟漪效果
// =============================================================================

class _BARippleWidget extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color rippleColor;
  final Duration duration;
  final int rippleCount;
  final double maxRadius;
  final double strokeWidth;

  const _BARippleWidget({
    required this.child,
    required this.isActive,
    required this.rippleColor,
    required this.duration,
    required this.rippleCount,
    required this.maxRadius,
    required this.strokeWidth,
  });

  @override
  State<_BARippleWidget> createState() => _BARippleWidgetState();
}

class _BARippleWidgetState extends State<_BARippleWidget>
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
  void didUpdateWidget(_BARippleWidget oldWidget) {
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
          painter: _RipplePainter(
            progress: _controller.value,
            rippleColor: widget.rippleColor,
            rippleCount: widget.rippleCount,
            maxRadius: widget.maxRadius,
            strokeWidth: widget.strokeWidth,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color rippleColor;
  final int rippleCount;
  final double maxRadius;
  final double strokeWidth;

  _RipplePainter({
    required this.progress,
    required this.rippleColor,
    required this.rippleCount,
    required this.maxRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < rippleCount; i++) {
      final offset = i / rippleCount;
      final rippleProgress = (progress + offset) % 1.0;
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = rippleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1.0 - rippleProgress * 0.5);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
