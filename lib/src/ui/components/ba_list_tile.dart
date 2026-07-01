import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_progress.dart';

/// 卡片式列表项
class BAListTile extends StatefulWidget {
  /// 前导图标
  final Widget? leading;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 尾部控件
  final Widget? trailing;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否选中
  final bool selected;

  /// 是否启用
  final bool enabled;

  /// 高度
  final double? height;

  /// 内边距
  final EdgeInsetsGeometry? contentPadding;

  const BAListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.height,
    this.contentPadding,
  });

  @override
  State<BAListTile> createState() => _BAListTileState();
}

class _BAListTileState extends State<BAListTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final translateY = _isPressed ? 2.0 : 0.0;
    final shadowOpacity = _isPressed ? 0.15 : (_isHovered ? 0.4 : 0.25);
    final blurRadius = _isPressed ? 4.0 : (_isHovered ? 12.0 : 8.0);
    final offsetY = _isPressed ? 2.0 : (_isHovered ? 6.0 : 4.0);

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: enabled ? widget.onLongPress : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          height: widget.height,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            color: widget.selected
                ? (enabled
                      ? BAColors.primaryOf(context).withValues(alpha: 0.15)
                      : BAColors.surfaceVariantOf(context))
                : (enabled ? BAColors.surfaceOf(context) : BAColors.surfaceVariantOf(context)),
            borderRadius: BATheme.borderRadius,
            border: Border.all(
              color: widget.selected
                  ? (enabled ? BAColors.primaryOf(context) : BAColors.borderOf(context))
                  : (_isHovered
                        ? BAColors.primaryOf(context).withValues(alpha: 0.5)
                        : BAColors.borderOf(context)),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withValues(alpha: shadowOpacity),
                      blurRadius: blurRadius,
                      offset: Offset(0, offsetY),
                    ),
                  ]
                : null,
          ),
          padding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: enabled
                        ? (widget.selected
                              ? BAColors.primaryOf(context)
                              : BAColors.textSecondaryOf(context))
                        : BAColors.textDisabledOf(context),
                    size: 24,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: BATypography.bodyMedium.copyWith(
                        color: enabled
                            ? (widget.selected
                                  ? BAColors.primaryOf(context)
                                  : BAColors.textPrimaryOf(context))
                            : BAColors.textDisabledOf(context),
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: BATypography.bodySmall.copyWith(
                          color: enabled
                              ? BAColors.textSecondaryOf(context)
                              : BAColors.textDisabledOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                IconTheme(
                  data: IconThemeData(
                    color: enabled
                        ? BAColors.textSecondaryOf(context)
                        : BAColors.textDisabledOf(context),
                    size: 20,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 带进度的卡片列表项
class BAProgressListTile extends StatefulWidget {
  /// 前导图标
  final Widget? leading;

  /// 标题
  final String title;

  /// 进度值
  final double progress;

  /// 进度条是否是MC风格
  final bool useExperienceStyle;

  /// 是否显示百分比
  final bool showPercentage;

  /// 尾部控件
  final Widget? trailing;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否选中
  final bool selected;

  /// 是否启用
  final bool enabled;

  /// 内边距
  final EdgeInsetsGeometry? contentPadding;

  const BAProgressListTile({
    super.key,
    this.leading,
    required this.title,
    required this.progress,
    this.useExperienceStyle = false,
    this.showPercentage = true,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.contentPadding,
  });

  @override
  State<BAProgressListTile> createState() => _BAProgressListTileState();
}

class _BAProgressListTileState extends State<BAProgressListTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final translateY = _isPressed ? 2.0 : 0.0;
    final shadowOpacity = _isPressed ? 0.15 : (_isHovered ? 0.4 : 0.25);
    final blurRadius = _isPressed ? 4.0 : (_isHovered ? 12.0 : 8.0);
    final offsetY = _isPressed ? 2.0 : (_isHovered ? 6.0 : 4.0);

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: enabled ? widget.onLongPress : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            color: widget.selected
                ? (enabled
                      ? BAColors.primaryOf(context).withValues(alpha: 0.15)
                      : BAColors.surfaceVariantOf(context))
                : (enabled ? BAColors.surfaceOf(context) : BAColors.surfaceVariantOf(context)),
            borderRadius: BATheme.borderRadius,
            border: Border.all(
              color: widget.selected
                  ? (enabled ? BAColors.primaryOf(context) : BAColors.borderOf(context))
                  : (_isHovered
                        ? BAColors.primaryOf(context).withValues(alpha: 0.5)
                        : BAColors.borderOf(context)),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: BAColors.shadowOf(context).withValues(alpha: shadowOpacity),
                      blurRadius: blurRadius,
                      offset: Offset(0, offsetY),
                    ),
                  ]
                : null,
          ),
          padding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: enabled
                        ? (widget.selected
                              ? BAColors.primaryOf(context)
                              : BAColors.textSecondaryOf(context))
                        : BAColors.textDisabledOf(context),
                    size: 24,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: BATypography.bodyMedium.copyWith(
                        color: enabled
                            ? (widget.selected
                                  ? BAColors.primaryOf(context)
                                  : BAColors.textPrimaryOf(context))
                            : BAColors.textDisabledOf(context),
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.useExperienceStyle)
                      BAExperienceProgressBar(
                        value: widget.progress,
                        showPercentage: widget.showPercentage,
                        height: 20,
                      )
                    else
                      BAProgressBar(
                        value: widget.progress,
                        showPercentage: widget.showPercentage,
                        height: 10,
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                IconTheme(
                  data: IconThemeData(
                    color: enabled
                        ? BAColors.textSecondaryOf(context)
                        : BAColors.textDisabledOf(context),
                    size: 20,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
