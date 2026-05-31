import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../theme/ba_theme_colors.dart';

/// 蔚蓝档案风格按钮组件
class BAButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BAButtonStyle style;
  final double? height;
  final double? width;
  final bool loading;
  final bool enabled;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final EdgeInsets? padding;

  const BAButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = BAButtonStyle.primary,
    this.height,
    this.width,
    this.loading = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.padding,
  });

  @override
  State<BAButton> createState() => _BAButtonState();
}

class _BAButtonState extends State<BAButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.loading || !widget.enabled;
    final effectiveOnPressed = isDisabled ? null : widget.onPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: effectiveOnPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: BAAnimation.fast,
          curve: Curves.easeOutCubic,
          height: widget.height ?? 48,
          width: widget.width,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: _getDecoration(context, isDisabled),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: BAAnimation.micro,
            child: widget.loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getLoadingColor(context, isDisabled),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        widget.leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      DefaultTextStyle(
                        style: _getTextStyle(context, isDisabled),
                        child: widget.child,
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        widget.trailingIcon!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(BuildContext context, bool isDisabled) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color borderColor;
    List<BoxShadow> shadows;

    switch (widget.style) {
      case BAButtonStyle.primary:
        backgroundColor = isDisabled
            ? BAColors.primary.withOpacity(0.4)
            : (_isHovered ? BAColors.primaryDark : BAColors.primary);
        borderColor = Colors.transparent;
        shadows = isDisabled ? [] : BATheme.shadowsSmallOf(context);
        break;
      case BAButtonStyle.secondary:
        backgroundColor = isDisabled
            ? BAColors.surfaceVariantOf(context).withOpacity(0.4)
            : BAColors.surfaceVariantOf(context);
        borderColor = isDisabled
            ? BAColors.borderOf(context)
            : (_isHovered
                ? BAColors.primary.withOpacity(0.5)
                : BAColors.borderOf(context));
        shadows = isDisabled ? [] : BATheme.shadowsSmallOf(context);
        break;
      case BAButtonStyle.text:
        backgroundColor = Colors.transparent;
        borderColor = Colors.transparent;
        shadows = [];
        break;
      case BAButtonStyle.outline:
        backgroundColor = Colors.transparent;
        borderColor = isDisabled
            ? BAColors.borderOf(context)
            : (_isHovered ? BAColors.primary : BAColors.borderOf(context));
        shadows = [];
        break;
      case BAButtonStyle.danger:
        backgroundColor = isDisabled
            ? BAColors.danger.withOpacity(0.4)
            : (_isHovered
                ? BAColors.danger.withOpacity(0.8)
                : BAColors.danger);
        borderColor = Colors.transparent;
        shadows = isDisabled ? [] : BATheme.shadowsSmallOf(context);
        break;
      case BAButtonStyle.success:
        backgroundColor = isDisabled
            ? BAColors.success.withOpacity(0.4)
            : (_isHovered
                ? BAColors.success.withOpacity(0.8)
                : BAColors.success);
        borderColor = Colors.transparent;
        shadows = isDisabled ? [] : BATheme.shadowsSmallOf(context);
        break;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(BAThemeData.radiusCircle),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: shadows,
    );
  }

  TextStyle _getTextStyle(BuildContext context, bool isDisabled) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor;

    switch (widget.style) {
      case BAButtonStyle.primary:
      case BAButtonStyle.danger:
      case BAButtonStyle.success:
        textColor = isDisabled
            ? Colors.white.withOpacity(0.5)
            : Colors.white;
        break;
      case BAButtonStyle.secondary:
        textColor = isDisabled
            ? BAColors.textDisabledOf(context)
            : BAColors.textPrimaryOf(context);
        break;
      case BAButtonStyle.text:
      case BAButtonStyle.outline:
        textColor = isDisabled
            ? BAColors.textDisabledOf(context)
            : (_isHovered ? BAColors.primary : BAColors.textPrimaryOf(context));
        break;
    }

    return BATypography.button.copyWith(color: textColor);
  }

  Color _getLoadingColor(BuildContext context, bool isDisabled) {
    switch (widget.style) {
      case BAButtonStyle.primary:
      case BAButtonStyle.danger:
      case BAButtonStyle.success:
        return Colors.white.withOpacity(isDisabled ? 0.5 : 1.0);
      case BAButtonStyle.secondary:
      case BAButtonStyle.text:
      case BAButtonStyle.outline:
        return isDisabled
            ? BAColors.textDisabledOf(context)
            : BAColors.primary;
    }
  }
}

/// 蔚蓝档案按钮样式
enum BAButtonStyle {
  primary,
  secondary,
  text,
  outline,
  danger,
  success,
}

/// 蔚蓝档案风格主按钮
class BAPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? height;
  final double? width;
  final bool enabled;
  final EdgeInsets? padding;

  const BAPrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.width,
    this.enabled = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BAButton(
      onPressed: onPressed,
      style: BAButtonStyle.primary,
      loading: loading,
      height: height,
      width: width,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      padding: padding,
      child: Text(text),
    );
  }
}

/// 蔚蓝档案风格次要按钮
class BASecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? height;
  final double? width;
  final bool enabled;

  const BASecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.width,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BAButton(
      onPressed: onPressed,
      style: BAButtonStyle.secondary,
      loading: loading,
      height: height,
      width: width,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: Text(text),
    );
  }
}

/// 蔚蓝档案风格危险按钮
class BADangerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? height;
  final double? width;
  final bool enabled;

  const BADangerButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.width,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BAButton(
      onPressed: onPressed,
      style: BAButtonStyle.danger,
      loading: loading,
      height: height,
      width: width,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: Text(text),
    );
  }
}

/// 蔚蓝档案风格图标按钮
class BAIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double size;
  final bool enabled;
  final Color? color;
  final Color? backgroundColor;

  const BAIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size = 20,
    this.enabled = true,
    this.color,
    this.backgroundColor,
  });

  @override
  State<BAIconButton> createState() => _BAIconButtonState();
}

class _BAIconButtonState extends State<BAIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled;
    final effectiveOnPressed = isDisabled ? null : widget.onPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: BAAnimation.fast,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  (_isHovered
                      ? BAColors.surfaceVariantOf(context)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(BAThemeData.radius),
            ),
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: BAAnimation.micro,
              child: IconButton(
                onPressed: effectiveOnPressed,
                icon: Icon(widget.icon),
                iconSize: widget.size,
                color: isDisabled
                    ? BAColors.textDisabledOf(context)
                    : (widget.color ?? BAColors.textPrimaryOf(context)),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
