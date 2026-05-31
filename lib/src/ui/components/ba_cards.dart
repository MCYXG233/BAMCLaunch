import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/animations.dart';
import '../theme/ba_theme_colors.dart';

/// 增强的卡片组件
class BAAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;
  final bool enableHoverEffect;
  final bool enableScaleEffect;
  final bool enableGlowEffect;
  final Duration animationDuration;
  final Color? glowColor;

  const BAAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.enableHoverEffect = true,
    this.enableScaleEffect = true,
    this.enableGlowEffect = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.glowColor,
  });

  @override
  State<BAAnimatedCard> createState() => _BAAnimatedCardState();
}

class _BAAnimatedCardState extends State<BAAnimatedCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BAAnimation.normal,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimation.defaultCurve,
      ),
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimation.defaultCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (widget.enableScaleEffect || widget.enableHoverEffect) {
      if (isHovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _onPress(bool isPressed) {
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableScaleEffect || widget.enableHoverEffect
              ? _scaleAnimation.value
              : 1.0,
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? BAColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
              border: Border.all(
                color: _isHovered
                    ? (widget.borderColor ?? BAColors.primary.withOpacity(0.4))
                    : (widget.borderColor ?? BAColors.border.withOpacity(0.5)),
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _isHovered ? 0.08 : 0.04,
                  ),
                  blurRadius: _elevationAnimation.value * 3,
                  offset: Offset(0, _elevationAnimation.value),
                ),
                if (widget.enableGlowEffect && _isHovered)
                  BoxShadow(
                    color: (widget.glowColor ?? BAColors.primary)
                        .withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onHighlightChanged: _onPress,
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(BAThemeData.spacingMedium),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.enableHoverEffect) {
      return MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: card,
      );
    }

    return card;
  }
}

/// 悬浮信息卡片
class BAHoverCard extends StatefulWidget {
  final Widget child;
  final Widget hoverContent;
  final double hoverHeight;
  final Duration animationDuration;
  final Color? backgroundColor;

  const BAHoverCard({
    super.key,
    required this.child,
    required this.hoverContent,
    this.hoverHeight = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.backgroundColor,
  });

  @override
  State<BAHoverCard> createState() => _BAHoverCardState();
}

class _BAHoverCardState extends State<BAHoverCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: widget.hoverHeight,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.smooth,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.child,
              SizedBox(
                height: _heightAnimation.value,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          BAColors.surfaceVariant.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: widget.hoverContent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 可展开的卡片
class BAExpandableCard extends StatefulWidget {
  final Widget title;
  final Widget content;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final double borderRadius;

  const BAExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.backgroundColor,
    this.borderRadius = 12.0,
  });

  @override
  State<BAExpandableCard> createState() => _BAExpandableCardState();
}

class _BAExpandableCardState extends State<BAExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconTurns = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.smooth,
      ),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BAAnimatedCard(
      padding: EdgeInsets.zero,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: widget.title),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      color: BAColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: widget.content,
          ),
        ],
      ),
    );
  }
}

/// 渐变边框卡片
class BAGradientBorderCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderWidth;
  final double borderRadius;
  final Duration animationDuration;
  final bool animateGradient;
  final VoidCallback? onTap;

  const BAGradientBorderCard({
    super.key,
    required this.child,
    this.gradientColors = const [BAColors.primary, BAColors.secondary],
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.animationDuration = const Duration(seconds: 3),
    this.animateGradient = true,
    this.onTap,
  });

  @override
  State<BAGradientBorderCard> createState() => _BAGradientBorderCardState();
}

class _BAGradientBorderCardState extends State<BAGradientBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.animateGradient) {
      _controller.repeat();
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
        final colors = widget.animateGradient
            ? [
                Color.lerp(
                  widget.gradientColors[0],
                  widget.gradientColors[1],
                  _controller.value,
                )!,
                Color.lerp(
                  widget.gradientColors[1],
                  widget.gradientColors[0],
                  _controller.value,
                )!,
              ]
            : widget.gradientColors;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: Material(
            color: BAColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(
              widget.borderRadius - widget.borderWidth,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
