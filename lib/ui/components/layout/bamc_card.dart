import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// BAMC 卡片组件
///
/// 融合 Minecraft × 蔚蓝档案风格的卡片
/// 特点：
/// - 柔和圆角
/// - 精致边框
/// - 悬浮动效
/// - 点击反馈
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
  });

  @override
  State<BamcCard> createState() => _BamcCardState();
}

class _BamcCardState extends State<BamcCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
              ),
            ),
          ),
        widget.child,
        if (widget.footer != null) widget.footer!,
      ],
    );

    // 卡片装饰
    final decoration = BoxDecoration(
      color: widget.gradient == null ? (widget.color ?? BamcColors.card) : null,
      gradient: widget.gradient,
      borderRadius: borderRadius,
      border: widget.border ??
          Border.all(
            color: _isHovered
                ? BamcColors.primary.withValues(alpha: 0.3)
                : BamcColors.border,
            width: 1,
          ),
      boxShadow: _isHovered
          ? [
              BoxShadow(
                color: BamcColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: BamcColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: BamcColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
    );

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: cardContent,
    );

    // 可悬浮效果
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: widget.padding ?? const EdgeInsets.all(16),
            transform: Matrix4.identity()
              ..translate(
                0.0,
                _isPressed ? 1.0 : (_isHovered ? -2.0 : 0.0),
              )
              ..scale(_isPressed ? 0.99 : (_isHovered ? 1.01 : 1.0)),
            decoration: decoration.copyWith(
              border: widget.border ??
                  Border.all(
                    color: _isHovered
                        ? BamcColors.primary.withValues(alpha: 0.4)
                        : _isPressed
                            ? BamcColors.primary.withValues(alpha: 0.5)
                            : BamcColors.border,
                    width: _isHovered ? 1.5 : 1,
                  ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: BamcColors.shadowLight,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : _isHovered
                      ? [
                          BoxShadow(
                            color: BamcColors.shadowMedium,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: BamcColors.primary.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: BamcColors.shadowLight,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
            ),
            child: cardContent,
          ),
        ),
      );
    }

    return card;
  }
}
