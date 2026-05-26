import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

/// 动画缓动曲线集合（学习 PCL2）
class BAAnimations {
  /// 弹性曲线
  static const Curve elasticOut = Curves.elasticOut;

  /// 回弹曲线
  static const Curve bounceOut = Curves.bounceOut;

  /// 平滑曲线
  static const Curve smooth = Curves.easeInOutCubic;

  /// 快速曲线
  static const Curve fast = Curves.easeOutCubic;

  /// 慢速曲线
  static const Curve slow = Curves.easeInOutQuart;

  /// 弹性回弹
  static const Curve elasticInOut = _ElasticInOut();

  /// 呼吸效果
  static const Curve breathing = _BreathingCurve();
}

/// 自定义弹性缓动曲线
class _ElasticInOut extends Curve {
  const _ElasticInOut();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return 0.5 * Curves.easeOutBack.transform(2 * t);
    } else {
      return 0.5 * Curves.easeInBack.transform(2 * t - 1) + 0.5;
    }
  }
}

/// 呼吸效果曲线
class _BreathingCurve extends Curve {
  const _BreathingCurve();

  @override
  double transformInternal(double t) {
    return (1 + Curves.easeInOutSine.transform(t)) / 2;
  }
}

/// 页面切换动画控制器
class BAPageTransitionBuilder {
  /// 淡入淡出滑动动画
  static Widget fadeSlideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset beginOffset = const Offset(0.0, 0.1),
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: BAAnimations.smooth,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: BAAnimations.elasticOut,
          ),
        ),
        child: child,
      ),
    );
  }

  /// 缩放淡入动画
  static Widget scaleFadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: BAAnimations.elasticOut,
          ),
        ),
        child: child,
      ),
    );
  }

  /// 旋转淡入动画
  static Widget rotateFadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      ),
      child: RotationTransition(
        turns: Tween<double>(begin: 0.1, end: 0.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: BAAnimations.bounceOut,
          ),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: BAAnimations.elasticOut,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 动画扩展类
extension AnimationExtensions on Animation<double> {
  /// 添加弹性效果
  Animation<double> get elastic => CurvedAnimation(
        parent: this,
        curve: BAAnimations.elasticOut,
      );

  /// 添加回弹效果
  Animation<double> get bounce => CurvedAnimation(
        parent: this,
        curve: BAAnimations.bounceOut,
      );

  /// 添加平滑效果
  Animation<double> get smooth => CurvedAnimation(
        parent: this,
        curve: BAAnimations.smooth,
      );

  /// 添加快速效果
  Animation<double> get fast => CurvedAnimation(
        parent: this,
        curve: BAAnimations.fast,
      );

  /// 添加慢速效果
  Animation<double> get slow => CurvedAnimation(
        parent: this,
        curve: BAAnimations.slow,
      );
}

/// 动画控制器状态管理器
class BAAnimationManager {
  static final BAAnimationManager _instance = BAAnimationManager._internal();
  factory BAAnimationManager() => _instance;
  BAAnimationManager._internal();

  final Map<String, AnimationController> _controllers = {};

  AnimationController? getController(String key) => _controllers[key];

  void registerController(String key, AnimationController controller) {
    _controllers[key] = controller;
  }

  void unregisterController(String key) {
    _controllers.remove(key);
  }

  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

/// 动画构建器
class BAAnimationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Animation<double> animation) builder;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  final bool autoStart;
  final bool repeat;

  const BAAnimationBuilder({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
    this.delay,
    this.curve = BAAnimations.smooth,
    this.autoStart = true,
    this.repeat = false,
  });

  @override
  State<BAAnimationBuilder> createState() => _BAAnimationBuilderState();
}

class _BAAnimationBuilderState extends State<BAAnimationBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    BAAnimationManager().registerController(hashCode.toString(), _controller);

    if (widget.autoStart) {
      if (widget.delay != null) {
        Future.delayed(widget.delay!, () {
          if (mounted) {
            if (widget.repeat) {
              _controller.repeat();
            } else {
              _controller.forward();
            }
          }
        });
      } else {
        if (widget.repeat) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    BAAnimationManager().unregisterController(hashCode.toString());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => widget.builder(context, _animation),
    );
  }
}

/// 悬浮效果构建器
class BAFloatBuilder extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatDistance;
  final bool enabled;

  const BAFloatBuilder({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.floatDistance = 5.0,
    this.enabled = true,
  });

  @override
  State<BAFloatBuilder> createState() => _BAFloatBuilderState();
}

class _BAFloatBuilderState extends State<BAFloatBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.breathing,
      ),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.floatDistance * _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

/// 脉冲效果构建器
class BAPulseBuilder extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleFactor;
  final bool enabled;

  const BAPulseBuilder({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.scaleFactor = 1.05,
    this.enabled = true,
  });

  @override
  State<BAPulseBuilder> createState() => _BAPulseBuilderState();
}

class _BAPulseBuilderState extends State<BAPulseBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.breathing,
      ),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 渐变动画构建器
class BAGlowBuilder extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color glowColor;
  final double maxGlowRadius;
  final bool enabled;

  const BAGlowBuilder({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.glowColor = const Color(0xFF2196F3),
    this.maxGlowRadius = 10.0,
    this.enabled = true,
  });

  @override
  State<BAGlowBuilder> createState() => _BAGlowBuilderState();
}

class _BAGlowBuilderState extends State<BAGlowBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.breathing,
      ),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.5 * _animation.value),
                blurRadius: widget.maxGlowRadius * _animation.value,
                spreadRadius: widget.maxGlowRadius * _animation.value * 0.5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
