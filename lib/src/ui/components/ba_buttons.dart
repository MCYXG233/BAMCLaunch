import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// 主按钮 - 清新蓝色，立体悬浮效果
class BAPrimaryButton extends StatefulWidget {
  /// 按钮文字
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否禁用
  final bool disabled;

  /// 是否加载中
  final bool loading;

  /// 左侧图标
  final Widget? leadingIcon;

  /// 右侧图标
  final Widget? trailingIcon;

  /// 按钮高度
  final double height;

  /// 按钮宽度
  final double? width;

  const BAPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48,
    this.width,
  });

  @override
  State<BAPrimaryButton> createState() => _BAPrimaryButtonState();
}

class _BAPrimaryButtonState extends State<BAPrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => !widget.disabled && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final translateY = _isPressed ? 2.0 : 0.0;
    final shadowOpacity = _isPressed ? 0.15 : 0.3;
    final blurRadius = _isPressed ? 4.0 : 8.0;
    final offsetY = _isPressed ? 2.0 : 4.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _isEnabled ? setState(() => _isPressed = true) : null,
        onTapUp: (_) {
          if (_isEnabled) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
          }
        },
        onTapCancel: () =>
            _isEnabled ? setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          height: widget.height,
          width: widget.width,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            color: _isEnabled
                ? (_isHovered ? BAColors.primaryDark : BAColors.primary)
                : BAColors.textDisabled,
            borderRadius: BATheme.borderRadius,
            boxShadow: _isEnabled
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withOpacity(shadowOpacity),
                      blurRadius: blurRadius,
                      offset: Offset(0, offsetY),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BATheme.borderRadius,
            child: InkWell(
              onTap: _isEnabled ? widget.onPressed : null,
              borderRadius: BATheme.borderRadius,
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            widget.leadingIcon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: BATypography.button.copyWith(
                              color: Colors.white,
                            ),
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
        ),
      ),
    );
  }
}

/// 次要按钮 - 草绿色/描边样式，立体悬浮效果
class BASecondaryButton extends StatefulWidget {
  /// 按钮文字
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否禁用
  final bool disabled;

  /// 是否加载中
  final bool loading;

  /// 左侧图标
  final Widget? leadingIcon;

  /// 右侧图标
  final Widget? trailingIcon;

  /// 按钮高度
  final double height;

  /// 按钮宽度
  final double? width;

  const BASecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48,
    this.width,
  });

  @override
  State<BASecondaryButton> createState() => _BASecondaryButtonState();
}

class _BASecondaryButtonState extends State<BASecondaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => !widget.disabled && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final translateY = _isPressed ? 2.0 : 0.0;
    final shadowOpacity = _isPressed ? 0.15 : 0.3;
    final blurRadius = _isPressed ? 4.0 : 8.0;
    final offsetY = _isPressed ? 2.0 : 4.0;

    final backgroundColor = _isEnabled
        ? (_isHovered ? BAColors.surfaceVariant : BAColors.surface)
        : BAColors.surfaceVariant;

    final borderColor = _isEnabled
        ? (_isHovered ? BAColors.secondaryDark : BAColors.secondary)
        : BAColors.textDisabled;

    final textColor = _isEnabled
        ? (_isHovered ? BAColors.secondaryDark : BAColors.secondary)
        : BAColors.textDisabled;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _isEnabled ? setState(() => _isPressed = true) : null,
        onTapUp: (_) {
          if (_isEnabled) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
          }
        },
        onTapCancel: () =>
            _isEnabled ? setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          height: widget.height,
          width: widget.width,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BATheme.borderRadius,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: _isEnabled
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withOpacity(shadowOpacity),
                      blurRadius: blurRadius,
                      offset: Offset(0, offsetY),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BATheme.borderRadius,
            child: InkWell(
              onTap: _isEnabled ? widget.onPressed : null,
              borderRadius: BATheme.borderRadius,
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            textColor.withOpacity(0.8),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            widget.leadingIcon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: BATypography.button.copyWith(
                              color: textColor,
                            ),
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
        ),
      ),
    );
  }
}

/// 危险按钮 - 红色，立体悬浮效果
class BADangerButton extends StatefulWidget {
  /// 按钮文字
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否禁用
  final bool disabled;

  /// 是否加载中
  final bool loading;

  /// 左侧图标
  final Widget? leadingIcon;

  /// 右侧图标
  final Widget? trailingIcon;

  /// 按钮高度
  final double height;

  /// 按钮宽度
  final double? width;

  const BADangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48,
    this.width,
  });

  @override
  State<BADangerButton> createState() => _BADangerButtonState();
}

class _BADangerButtonState extends State<BADangerButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => !widget.disabled && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final translateY = _isPressed ? 2.0 : 0.0;
    final shadowOpacity = _isPressed ? 0.15 : 0.3;
    final blurRadius = _isPressed ? 4.0 : 8.0;
    final offsetY = _isPressed ? 2.0 : 4.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _isEnabled ? setState(() => _isPressed = true) : null,
        onTapUp: (_) {
          if (_isEnabled) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
          }
        },
        onTapCancel: () =>
            _isEnabled ? setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          height: widget.height,
          width: widget.width,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            color: _isEnabled
                ? (_isHovered ? BAColors.dangerDark : BAColors.danger)
                : BAColors.textDisabledOf(context),
            borderRadius: BATheme.borderRadius,
            boxShadow: _isEnabled
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withOpacity(shadowOpacity),
                      blurRadius: blurRadius,
                      offset: Offset(0, offsetY),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BATheme.borderRadius,
            child: InkWell(
              onTap: _isEnabled ? widget.onPressed : null,
              borderRadius: BATheme.borderRadius,
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            widget.leadingIcon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: BATypography.button.copyWith(
                              color: Colors.white,
                            ),
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
        ),
      ),
    );
  }
}
