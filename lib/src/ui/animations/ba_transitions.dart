import 'package:flutter/material.dart';

/// BA 页面过渡动画库
///
/// 提供多种页面切换过渡效果，所有方法返回 [Route] 对象，
/// 可直接用于 [Navigator.push] / [Navigator.pushReplacement]。
///
/// 使用方式：
/// ```dart
/// Navigator.of(context).push(
///   BATransitions.slideFade(
///     page: const NextPage(),
///     direction: AxisDirection.left,
///   ),
/// );
/// ```
class BATransitions {
  BATransitions._();

  /// 滑动淡入过渡
  ///
  /// 页面从指定 [direction] 方向滑入，同时配合淡入效果。
  /// 支持自定义动画时长、曲线和滑动偏移量。
  static Route<T> slideFade<T>({
    required Widget page,
    AxisDirection direction = AxisDirection.right,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
    double slideOffset = 30.0,
  }) {
    return _buildRoute(
      page: page,
      duration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        final offset = _getSlideOffset(direction, slideOffset);

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// 缩放淡入过渡
  ///
  /// 页面从 [initialScale] 缩放至原始大小，同时配合淡入效果。
  /// 适用于对话框、详情页等场景。
  static Route<T> scaleFade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutBack,
    double initialScale = 0.85,
    Alignment alignment = Alignment.center,
  }) {
    return _buildRoute(
      page: page,
      duration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
          ),
          child: ScaleTransition(
            alignment: alignment,
            scale: Tween<double>(
              begin: initialScale,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// 旋转淡入过渡
  ///
  /// 页面伴随旋转和缩放效果进入，同时配合淡入。
  /// 适用于需要活泼感的页面切换场景。
  static Route<T> rotateFade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 450),
    Curve curve = Curves.easeOutBack,
    double rotationTurns = 0.05,
    double initialScale = 0.9,
  }) {
    return _buildRoute(
      page: page,
      duration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
          ),
          child: RotationTransition(
            turns: Tween<double>(
              begin: rotationTurns,
              end: 0.0,
            ).animate(curvedAnimation),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: initialScale,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// 弹性过渡
  ///
  /// 页面以弹性缩放的方式进入，使用 [Curves.elasticOut] 曲线
  /// 实现自然的弹跳效果。适用于弹窗、卡片展开等场景。
  static Route<T> elastic<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticOut,
    double initialScale = 0.0,
    bool fadeIn = true,
  }) {
    return _buildRoute(
      page: page,
      duration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        Widget result = ScaleTransition(
          scale: Tween<double>(
            begin: initialScale,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        );

        if (fadeIn) {
          result = FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
              ),
            ),
            child: result,
          );
        }

        return result;
      },
    );
  }

  /// 共享元素过渡
  ///
  /// 使用 Flutter 内置的 [Hero] 动画实现共享元素过渡效果。
  /// 在源页面和目标页面中使用相同 [tag] 的 [Hero] 组件，
  /// 框架会自动在页面切换时为该元素生成平滑的过渡动画。
  ///
  /// 使用方式：
  /// ```dart
  /// // 源页面
  /// Hero(
  ///   tag: 'avatar',
  ///   child: CircleAvatar(...),
  /// )
  ///
  /// // 导航
  /// Navigator.of(context).push(
  ///   BATransitions.sharedElement(
  ///     page: DetailPage(),
  ///   ),
  /// );
  ///
  /// // 目标页面
  /// Hero(
  ///   tag: 'avatar',
  ///   child: CircleAvatar(...),
  /// )
  /// ```
  static Route<T> sharedElement<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RectTween? createRectTween,
    HeroFlightShuttleBuilder? flightShuttleBuilder,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  // ===========================================================================
  // 内部方法
  // ===========================================================================

  /// 构建通用路由
  static Route<T> _buildRoute<T>({
    required Widget page,
    required Duration duration,
    required Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) transitionBuilder,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: transitionBuilder,
    );
  }

  /// 根据方向计算滑动偏移
  static Offset _getSlideOffset(AxisDirection direction, double distance) {
    switch (direction) {
      case AxisDirection.up:
        return Offset(0.0, distance / 100);
      case AxisDirection.down:
        return Offset(0.0, -distance / 100);
      case AxisDirection.left:
        return Offset(distance / 100, 0.0);
      case AxisDirection.right:
        return Offset(-distance / 100, 0.0);
    }
  }
}
