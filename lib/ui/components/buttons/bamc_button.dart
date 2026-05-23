import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

enum BamcButtonType {
  primary,
  secondary,
  warning,
  success,
  outline,
  text,
  glow,
}

enum BamcButtonSize {
  small,
  medium,
  large,
}

class BamcButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final BamcButtonType type;
  final BamcButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool disabled;
  final bool fullWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final bool showGlow;

  const BamcButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = BamcButtonType.primary,
    this.size = BamcButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.borderRadius,
    this.shadows,
    this.showGlow = true,
  });

  @override
  State<BamcButton> createState() => _BamcButtonState();
}

class _BamcButtonState extends State<BamcButton> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  Offset? _pressPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered && widget.showGlow && !_glowController.isAnimating) {
      _glowController.forward();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
      _pressPosition = details.localPosition;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
      _pressPosition = null;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
      _pressPosition = null;
    });
    _animationController.reverse();
  }

  double _getPaddingVertical() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 8;
      case BamcButtonSize.medium:
        return 14;
      case BamcButtonSize.large:
        return 18;
    }
  }

  double _getPaddingHorizontal() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 14;
      case BamcButtonSize.medium:
        return 20;
      case BamcButtonSize.large:
        return 28;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 12;
      case BamcButtonSize.medium:
        return 15;
      case BamcButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 16;
      case BamcButtonSize.medium:
        return 20;
      case BamcButtonSize.large:
        return 24;
    }
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: _getIconSize(),
            height: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.type == BamcButtonType.outline ||
                        widget.type == BamcButtonType.text
                    ? BamcColors.primary
                    : Colors.white,
              ),
            ),
          )
        else if (widget.icon != null)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isHovered ? _glowAnimation.value : 1.0,
                child: Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: _getIconColor(),
                  shadows: _isHovered && widget.type != BamcButtonType.outline && widget.type != BamcButtonType.text
                      ? [
                          Shadow(
                            color: BamcColors.neonBlue,
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        if ((widget.isLoading || widget.icon != null) && widget.text.isNotEmpty)
          SizedBox(width: widget.size == BamcButtonSize.small ? 6 : 10),
        if (!widget.isLoading)
          Text(
            widget.text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
              shadows: _isHovered && widget.type != BamcButtonType.outline && widget.type != BamcButtonType.text
                  ? [
                      Shadow(
                        color: BamcColors.neonBlue.withOpacity(0.5),
                        offset: const Offset(0, 0),
                        blurRadius: 8,
                      ),
                    ]
                  : (widget.type != BamcButtonType.outline && widget.type != BamcButtonType.text
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null),
            ),
          ),
      ],
    );
  }

  Color _getTextColor() {
    if (widget.type == BamcButtonType.outline || widget.type == BamcButtonType.text) {
      return _isHovered ? BamcColors.neonBlue : BamcColors.primary;
    }
    return Colors.white;
  }

  Color _getIconColor() {
    if (widget.type == BamcButtonType.outline || widget.type == BamcButtonType.text) {
      return _isHovered ? BamcColors.neonBlue : BamcColors.primary;
    }
    return Colors.white;
  }

  BoxDecoration _getDecoration() {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final glowColor = widget.type == BamcButtonType.secondary
        ? BamcColors.neonGreen
        : widget.type == BamcButtonType.warning
            ? BamcColors.neonOrange
            : widget.type == BamcButtonType.success
                ? BamcColors.success
                : BamcColors.neonBlue;

    switch (widget.type) {
      case BamcButtonType.primary:
      case BamcButtonType.glow:
        return BoxDecoration(
          gradient: BamcColors.primaryGradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.neonBlue : Colors.white.withOpacity(0.2),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: widget.shadows ??
              (_isHovered
                  ? [
                      BoxShadow(
                        color: BamcColors.neonBlue.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: BamcColors.neonBlue.withOpacity(0.2),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: BamcColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]),
        );
      case BamcButtonType.secondary:
        return BoxDecoration(
          gradient: BamcColors.secondaryGradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.neonGreen : Colors.white.withOpacity(0.2),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: widget.shadows ??
              (_isHovered
                  ? [
                      BoxShadow(
                        color: BamcColors.neonGreen.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: BamcColors.neonGreen.withOpacity(0.2),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: BamcColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]),
        );
      case BamcButtonType.warning:
        return BoxDecoration(
          gradient: BamcColors.warningGradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.neonOrange : Colors.white.withOpacity(0.2),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: widget.shadows ??
              (_isHovered
                  ? [
                      BoxShadow(
                        color: BamcColors.warning.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: BamcColors.warning.withOpacity(0.2),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: BamcColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]),
        );
      case BamcButtonType.success:
        return BoxDecoration(
          gradient: BamcColors.successGradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.success : Colors.white.withOpacity(0.2),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: widget.shadows ??
              (_isHovered
                  ? [
                      BoxShadow(
                        color: BamcColors.success.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: BamcColors.success.withOpacity(0.2),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: BamcColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]),
        );
      case BamcButtonType.outline:
        return BoxDecoration(
          color: _isHovered ? BamcColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.neonBlue : BamcColors.primary,
            width: _isHovered ? 2 : 2,
          ),
          boxShadow: widget.shadows ??
              (_isHovered
                  ? [
                      BoxShadow(
                        color: BamcColors.neonBlue.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null),
        );
      case BamcButtonType.text:
        return BoxDecoration(
          color: _isHovered ? BamcColors.surfaceLight : Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }

  Widget _buildRippleEffect() {
    if (_pressPosition == null || !_isPressed) return const SizedBox();
    
    return Positioned(
      left: _pressPosition!.dx - 20,
      top: _pressPosition!.dy - 20,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = _animationController.value;
          return Opacity(
            opacity: 1 - progress,
            child: Transform.scale(
              scale: 1 + progress * 3,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.isLoading;
    final scale = _animationController.isAnimating && _animationController.value > 0.5
        ? 0.95
        : (_isHovered ? 1.03 : 1.0);

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.fullWidth ? double.infinity : null,
                padding: EdgeInsets.symmetric(
                  vertical: _getPaddingVertical(),
                  horizontal: _getPaddingHorizontal(),
                ),
                decoration: isDisabled
                    ? BoxDecoration(
                        color: BamcColors.textDisabled.withOpacity(0.15),
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                        border: Border.all(
                          color: BamcColors.border,
                          width: 1,
                        ),
                      )
                    : _getDecoration(),
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: _buildButtonContent(),
                ),
              ),
            ),
            _buildRippleEffect(),
          ],
        ),
      ),
    );
  }
}