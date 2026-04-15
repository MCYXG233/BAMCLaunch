import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';

class BamcEffects {
  // 毛玻璃效果
  static Widget glassEffect({
    required Widget child,
    Color backgroundColor = BamcColors.glassBackground,
    double blurRadius = 10,
    BorderRadius? borderRadius,
    Border? border,
    BoxShadow? shadow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
        boxShadow: shadow != null
            ? [shadow]
            : [
                const BoxShadow(
                  color: BamcColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: child,
        ),
      ),
    );
  }

  // 主色调渐变
  static LinearGradient primaryGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        BamcColors.primaryLight,
        BamcColors.primary,
        BamcColors.primaryDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // 辅助色渐变
  static LinearGradient secondaryGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        BamcColors.secondaryLight,
        BamcColors.secondary,
        BamcColors.secondaryDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // 警告色渐变
  static LinearGradient warningGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        BamcColors.warningLight,
        BamcColors.warning,
        BamcColors.warningDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // 成功色渐变
  static LinearGradient successGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        BamcColors.successLight,
        BamcColors.success,
        BamcColors.successDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // 清新蓝渐变（MC方块风格）
  static LinearGradient minecraftBlueGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB),
        Color(0xFF4682B4),
      ],
    );
  }

  // 草方块绿色渐变
  static LinearGradient grassBlockGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7CB342),
        Color(0xFF558B2F),
      ],
    );
  }

  // 标准阴影
  static BoxShadow standardShadow({
    Color color = BamcColors.shadow,
    double blurRadius = 8,
    Offset offset = const Offset(0, 2),
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
      spreadRadius: spreadRadius,
    );
  }

  // 悬浮阴影
  static BoxShadow hoverShadow({
    Color color = BamcColors.shadow,
    double blurRadius = 12,
    Offset offset = const Offset(0, 4),
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
      spreadRadius: spreadRadius,
    );
  }

  // 强烈阴影（用于重要元素）
  static BoxShadow strongShadow({
    Color color = BamcColors.shadow,
    double blurRadius = 20,
    Offset offset = const Offset(0, 8),
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
      spreadRadius: spreadRadius,
    );
  }

  // 内阴影效果
  static BoxShadow innerShadow({
    Color color = BamcColors.shadow,
    double blurRadius = 10,
    Offset offset = const Offset(0, 2),
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: blurRadius,
      offset: offset,
      spreadRadius: spreadRadius,
    );
  }

  // 发光效果
  static BoxShadow glowEffect({
    Color color = BamcColors.primary,
    double blurRadius = 20,
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: blurRadius,
      offset: Offset.zero,
      spreadRadius: spreadRadius,
    );
  }

  // 彩虹发光效果
  static List<BoxShadow> rainbowGlowEffect() {
    return [
      glowEffect(color: Colors.red),
      glowEffect(color: Colors.orange),
      glowEffect(color: Colors.yellow),
      glowEffect(color: Colors.green),
      glowEffect(color: Colors.blue),
      glowEffect(color: Colors.indigo),
      glowEffect(color: Colors.purple),
    ];
  }

  // 像素化边框
  static Border pixelBorder({
    Color color = BamcColors.border,
    double width = 1,
  }) {
    return Border.all(
      color: color,
      width: width,
    );
  }

  // 方块化边框
  static BorderRadius squareBorderRadius(double radius) {
    return BorderRadius.circular(radius);
  }

  // 圆形边框
  static BorderRadius circularBorderRadius(double radius) {
    return BorderRadius.circular(radius);
  }

  // MC方块风格边框
  static BoxDecoration minecraftBlockDecoration({
    Color color = BamcColors.primary,
    double borderWidth = 2,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      ],
    );
  }

  // 按钮按下效果
  static Matrix4 buttonPressTransform() {
    return Matrix4.identity()
      ..scale(0.95)
      ..translate(0, 2);
  }

  // 悬浮缩放效果
  static Matrix4 hoverScaleTransform() {
    return Matrix4.identity()
      ..scale(1.05);
  }

  // 渐入动画
  static Animation<double> fadeInAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  // 滑入动画
  static Animation<Offset> slideInAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  // 弹跳动画
  static Animation<double> bounceAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut,
      ),
    );
  }
}
