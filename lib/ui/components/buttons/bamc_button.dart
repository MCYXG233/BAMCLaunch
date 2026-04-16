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
  });

  @override
  State<BamcButton> createState() => _BamcButtonState();
}

class _BamcButtonState extends State<BamcButton> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  List<_PixelParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addListener(() {
        setState(() {
          _particles.removeWhere((p) => p.animation.value <= 0);
        });
      });
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
    _spawnParticles(details.localPosition);
  }

  void _spawnParticles(Offset position) {
    final random = DateTime.now().microsecond % 1000;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159;
      final distance = 20 + (random % 20).toDouble();
      final particle = _PixelParticle(
        position: position,
        dx: cos(angle) * distance,
        dy: sin(angle) * distance,
        color: BamcEffects.pixelLoadingColors[i % BamcEffects.pixelLoadingColors.length],
        controller: _particleController,
      );
      setState(() {
        _particles.add(particle);
      });
    }
    _particleController.forward(from: 0);
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  double _getPaddingVertical() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 8;
      case BamcButtonSize.medium:
        return 12;
      case BamcButtonSize.large:
        return 16;
    }
  }

  double _getPaddingHorizontal() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 12;
      case BamcButtonSize.medium:
        return 16;
      case BamcButtonSize.large:
        return 20;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case BamcButtonSize.small:
        return 12;
      case BamcButtonSize.medium:
        return 14;
      case BamcButtonSize.large:
        return 16;
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
                widget.type == BamcButtonType.outline || widget.type == BamcButtonType.text
                    ? BamcColors.primary
                    : Colors.white,
              ),
            ),
          )
        else if (widget.icon != null)
          Icon(
            widget.icon,
            size: _getIconSize(),
            color: widget.type == BamcButtonType.outline || widget.type == BamcButtonType.text
                ? BamcColors.primary
                : Colors.white,
          ),
        if ((widget.isLoading || widget.icon != null) && widget.text.isNotEmpty)
          SizedBox(width: widget.size == BamcButtonSize.small ? 6 : 8),
        if (!widget.isLoading)
          Text(
            widget.text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: widget.type == BamcButtonType.outline || widget.type == BamcButtonType.text
                  ? BamcColors.primary
                  : Colors.white,
              fontFamily: widget.type != BamcButtonType.text ? 'Minecraft' : null,
            ),
          ),
      ],
    );
  }

  BoxDecoration _getDecoration() {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(6);
    
    switch (widget.type) {
      case BamcButtonType.primary:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BamcColors.primary,
              BamcColors.primaryDark,
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [
            BoxShadow(
              color: BamcColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: BamcColors.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [
            BoxShadow(
              color: BamcColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        );
      case BamcButtonType.secondary:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BamcColors.secondary,
              BamcColors.secondaryDark,
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [
            BoxShadow(
              color: BamcColors.secondary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: BamcColors.secondary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [
            BoxShadow(
              color: BamcColors.secondary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        );
      case BamcButtonType.warning:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BamcColors.warning,
              BamcColors.warningDark,
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [
            BoxShadow(
              color: BamcColors.warning.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: BamcColors.warning.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [
            BoxShadow(
              color: BamcColors.warning.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        );
      case BamcButtonType.success:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BamcColors.success,
              BamcColors.successDark,
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [
            BoxShadow(
              color: BamcColors.success.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: BamcColors.success.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [
            BoxShadow(
              color: BamcColors.success.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        );
      case BamcButtonType.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered ? BamcColors.primaryLight : BamcColors.primary,
            width: 2,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [
            BoxShadow(
              color: BamcColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null),
        );
      case BamcButtonType.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.isLoading;
    final scale = _animationController.isAnimating && _animationController.value > 0.5 ? 0.95 : (_isHovered ? 1.05 : 1.0);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
                        color: BamcColors.textDisabled.withOpacity(0.3),
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
                        border: Border.all(
                          color: BamcColors.border,
                          width: 1,
                        ),
                      )
                    : _getDecoration(),
                child: Opacity(
                  opacity: isDisabled ? 0.6 : (_isHovered ? 1.1 : 1.0),
                  child: _buildButtonContent(),
                ),
              ),
            ),
            ..._particles.map((particle) => _buildParticle(particle)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(_PixelParticle particle) {
    return AnimatedBuilder(
      animation: particle.animation,
      builder: (context, child) {
        final progress = particle.animation.value;
        return Positioned(
          left: particle.position.dx + particle.dx * (1 - progress) - 4,
          top: particle.position.dy + particle.dy * (1 - progress) - 4,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: progress,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: particle.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PixelParticle {
  final Offset position;
  final double dx;
  final double dy;
  final Color color;
  final Animation<double> animation;

  _PixelParticle({
    required this.position,
    required this.dx,
    required this.dy,
    required this.color,
    required AnimationController controller,
  }) : animation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOut,
          ),
        );