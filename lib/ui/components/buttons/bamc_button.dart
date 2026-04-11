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

class _BamcButtonState extends State<BamcButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
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
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
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
            ),
          ),
      ],
    );
  }

  BoxDecoration _getDecoration() {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8);
    
    switch (widget.type) {
      case BamcButtonType.primary:
        return BoxDecoration(
          gradient: BamcEffects.primaryGradient(),
          borderRadius: borderRadius,
          boxShadow: widget.shadows ?? (_isHovered ? [BamcEffects.hoverShadow()] : [BamcEffects.standardShadow()]),
        );
      case BamcButtonType.secondary:
        return BoxDecoration(
          gradient: BamcEffects.secondaryGradient(),
          borderRadius: borderRadius,
          boxShadow: widget.shadows ?? (_isHovered ? [BamcEffects.hoverShadow()] : [BamcEffects.standardShadow()]),
        );
      case BamcButtonType.warning:
        return BoxDecoration(
          gradient: BamcEffects.warningGradient(),
          borderRadius: borderRadius,
          boxShadow: widget.shadows ?? (_isHovered ? [BamcEffects.hoverShadow()] : [BamcEffects.standardShadow()]),
        );
      case BamcButtonType.success:
        return BoxDecoration(
          gradient: BamcEffects.successGradient(),
          borderRadius: borderRadius,
          boxShadow: widget.shadows ?? (_isHovered ? [BamcEffects.hoverShadow()] : [BamcEffects.standardShadow()]),
        );
      case BamcButtonType.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: BamcColors.primary,
            width: 2,
          ),
          boxShadow: widget.shadows ?? (_isHovered ? [BamcEffects.hoverShadow()] : null),
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
    
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              vertical: _getPaddingVertical(),
              horizontal: _getPaddingHorizontal(),
            ),
            decoration: isDisabled
                ? BoxDecoration(
                    color: BamcColors.textDisabled.withOpacity(0.3),
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  )
                : _getDecoration(),
            child: Opacity(
              opacity: isDisabled ? 0.6 : 1.0,
              child: _buildButtonContent(),
            ),
          ),
        ),
      ),
    );
  }
}