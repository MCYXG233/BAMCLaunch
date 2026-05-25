import 'package:flutter/material.dart';

/// 蔚蓝档案UI设计规范的颜色定义
class BAColors {
  /// 主色调 - 清新蓝
  static const Color primary = Color(0xFF5EA8F0);

  /// 辅助色 - MC草方块绿
  static const Color secondary = Color(0xFF7CB342);

  /// 强调色 - 红石红（警告/错误）
  static const Color danger = Color(0xFFE53935);

  /// 强调色 - 金块黄（成功/高亮）
  static const Color success = Color(0xFFFDD835);

  // ========== 深色主题颜色 ==========
  /// 深色主题 - 背景色
  static const Color darkBackground = Color(0xFF1A1A2E);

  /// 深色主题 - 表面色 - 卡片背景
  static const Color darkSurface = Color(0xFF16213E);

  /// 深色主题 - 表面色变体 - 稍深的表面色
  static const Color darkSurfaceVariant = Color(0xFF0F3460);

  /// 深色主题 - 文本主要颜色
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// 深色主题 - 文本次要颜色
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// 深色主题 - 文本禁用颜色
  static const Color darkTextDisabled = Color(0xFF6A6A6A);

  /// 深色主题 - 边框颜色
  static const Color darkBorder = Color(0xFF2A2A4A);

  /// 深色主题 - 毛玻璃效果背景色
  static const Color darkGlass = Color(0xCC1A1A2E);

  /// 深色主题 - 阴影颜色
  static const Color darkShadow = Color(0x80000000);

  // ========== 浅色主题颜色 ==========
  /// 浅色主题 - 背景色
  static const Color lightBackground = Color(0xFFF5F7FA);

  /// 浅色主题 - 表面色 - 卡片背景
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// 浅色主题 - 表面色变体
  static const Color lightSurfaceVariant = Color(0xFFE8F0FE);

  /// 浅色主题 - 文本主要颜色
  static const Color lightTextPrimary = Color(0xFF1A1A2E);

  /// 浅色主题 - 文本次要颜色
  static const Color lightTextSecondary = Color(0xFF5A5A7A);

  /// 浅色主题 - 文本禁用颜色
  static const Color lightTextDisabled = Color(0xFFA0A0A0);

  /// 浅色主题 - 边框颜色
  static const Color lightBorder = Color(0xFFD0D0E0);

  /// 浅色主题 - 毛玻璃效果背景色
  static const Color lightGlass = Color(0xCCF5F7FA);

  /// 浅色主题 - 阴影颜色
  static const Color lightShadow = Color(0x30000000);

  // ========== 主题无关颜色变体 ==========
  /// 按钮按下时的深色
  static const Color primaryDark = Color(0xFF3C88CF);

  /// 辅助色深色
  static const Color secondaryDark = Color(0xFF5A9220);

  /// 危险色深色
  static const Color dangerDark = Color(0xFFC62828);

  /// 主色调浅色
  static const Color primaryLight = Color(0xFF8BC4F7);

  /// 辅助色浅色
  static const Color secondaryLight = Color(0xFF9ED46B);

  /// 危险色浅色
  static const Color dangerLight = Color(0xFFEF5350);

  // ========== 向后兼容：默认深色主题颜色 ==========
  /// 背景色（默认深色）
  static const Color background = darkBackground;

  /// 表面色（默认深色）
  static const Color surface = darkSurface;

  /// 表面色变体（默认深色）
  static const Color surfaceVariant = darkSurfaceVariant;

  /// 文本主要颜色（默认深色）
  static const Color textPrimary = darkTextPrimary;

  /// 文本次要颜色（默认深色）
  static const Color textSecondary = darkTextSecondary;

  /// 文本禁用颜色（默认深色）
  static const Color textDisabled = darkTextDisabled;

  /// 边框颜色（默认深色）
  static const Color border = darkBorder;

  /// 毛玻璃效果背景色（默认深色）
  static const Color glass = darkGlass;

  /// 阴影颜色（默认深色）
  static const Color shadow = darkShadow;

  /// 根据当前主题获取背景色
  static Color backgroundOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightBackground : darkBackground;
  }

  /// 根据当前主题获取表面色
  static Color surfaceOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightSurface : darkSurface;
  }

  /// 根据当前主题获取表面色变体
  static Color surfaceVariantOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightSurfaceVariant : darkSurfaceVariant;
  }

  /// 根据当前主题获取文本主要颜色
  static Color textPrimaryOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;
  }

  /// 根据当前主题获取文本次要颜色
  static Color textSecondaryOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightTextSecondary : darkTextSecondary;
  }

  /// 根据当前主题获取文本禁用颜色
  static Color textDisabledOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightTextDisabled : darkTextDisabled;
  }

  /// 根据当前主题获取边框颜色
  static Color borderOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightBorder : darkBorder;
  }

  /// 根据当前主题获取阴影颜色
  static Color shadowOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadow : darkShadow;
  }
}
