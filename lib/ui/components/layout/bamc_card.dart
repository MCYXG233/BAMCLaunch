import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum BamcCardType {
  standard,
  glass,
  elevated,
  outline,
}

class BamcCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? header;
  final Widget? footer;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hoverable;
  final Gradient? gradient;
  final BamcCardType type;
  final bool showGlow;
  final Color? glowColor;

  const BamcCard({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.footer,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.hoverable = false,
    this.gradient,
    this.type = BamcCardType.standard,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  State<BamcCard> createState() => _BamcCardState();
}

class _BamcCardState extends State<BamcCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  BoxDecoration _getDecoration() {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveGlowColor = widget.glowColor ?? BamcColors.neonBlue;
    
    Color borderColor;
    List<BoxShadow> shadows;
    
    if (widget.type == BamcCardType.glass) {
      borderColor = _isHovered 
          ? BamcColors.glassBorderGlow 
          : BamcColors.glassBorder;
      shadows = _isHovered
          ? [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: BamcColors.shadowHeavy,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: BamcColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ];
    } else if (widget.type == BamcCardType.elevated) {
      borderColor = _isHovered
          ? effectiveGlowColor
          : BamcColors.border;
      shadows = _isHovered
          ? [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: BamcColors.shadowHeavy,
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ]
          : [
              BoxShadow(
                color: BamcColors.shadowMedium,
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: BamcColors.shadowLight,
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ];
    } else if (widget.type == BamcCardType.outline) {
      borderColor = _isHovered
          ? effectiveGlowColor
          : BamcColors.border;
      shadows = _isHovered
          ? [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]
          : [];
    } else {
      borderColor = _isHovered
          ? effectiveGlowColor.withOpacity(0.6)
          : BamcColors.border;
      shadows = _isHovered
          ? [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: BamcColors.shadowHeavy,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: BamcColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ];
    }

    return BoxDecoration(
      color: widget.gradient == null 
          ? _getBackgroundColor() 
          : null,
      gradient: widget.gradient ?? _getBackgroundGradient(),
      borderRadius: borderRadius,
      border: widget.border ??
          Border.all(
            color: borderColor,
            width: _isHovered ? 1.5 : 1,
          ),
      boxShadow: shadows,
    );
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case BamcCardType.glass:
        return BamcColors.glassBackground;
      case BamcCardType.elevated:
        return widget.color ?? BamcColors.card;
      case BamcCardType.outline:
        return Colors.transparent;
      default:
        return widget.color ?? BamcColors.card;
    }
  }

  Gradient? _getBackgroundGradient() {
    if (widget.type == BamcCardType.glass) {
      return BamcColors.glassCardGradient;
    }
    return null;
  }

  Widget _buildGlowEffect() {
    if (!widget.showGlow || !_isHovered) return const SizedBox();
    
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveGlowColor = widget.glowColor ?? BamcColors.neonBlue;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 30 * _glowAnimation.value,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.header != null) widget.header!,
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        widget.child,
        if (widget.footer != null) widget.footer!,
      ],
    );

    final decoration = _getDecoration();

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: cardContent,
    );

    if (widget.hoverable || widget.onTap != null) {
      card = MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.onTap != null
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.onTap != null
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.onTap != null
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.onTap,
          child: Stack(
            children: [
              _buildGlowEffect(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                padding: widget.padding ?? const EdgeInsets.all(16),
                transform: Matrix4.identity()
                  ..translate(
                    0.0,
                    _isPressed ? 2.0 : (_isHovered ? -3.0 : 0.0),
                  )
                  ..scale(_isPressed ? 0.985 : (_isHovered ? 1.01 : 1.0)),
                decoration: decoration,
                child: cardContent,
              ),
            ],
          ),
        ),
      );
    }

    return card;
  }
}