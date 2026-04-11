import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

class BamcCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? header;
  final Widget? footer;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useGlassEffect;
  final bool hoverable;
  final double? width;

  const BamcCard({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.footer,
    this.elevation,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.useGlassEffect = false,
    this.hoverable = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) header!,
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BamcColors.textPrimary,
              ),
            ),
          ),
        child,
        if (footer != null) footer!,
      ],
    );

    final cardDecoration = BoxDecoration(
      color: color ?? BamcColors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      border: border ??
          Border.all(
            color: BamcColors.border,
            width: 1,
          ),
      boxShadow: elevation != null
          ? [
              BamcEffects.standardShadow(
                blurRadius: elevation!,
              ),
            ]
          : null,
    );

    final cardWidget = SizedBox(
      width: width,
      child: Container(
        margin: margin ?? const EdgeInsets.all(0),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: cardContent,
      ),
    );

    if (useGlassEffect) {
      return SizedBox(
        width: width,
        child: BamcEffects.glassEffect(
          child: cardContent,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: border,
        ),
      );
    }

    if (hoverable) {
      return SizedBox(
        width: width,
        child: MouseRegion(
          onHover: (_) {},
          onExit: (_) {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: margin ?? const EdgeInsets.all(0),
            padding: padding ?? const EdgeInsets.all(16),
            decoration: cardDecoration.copyWith(
              boxShadow: [
                BamcEffects.hoverShadow(),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    }

    return cardWidget;
  }
}