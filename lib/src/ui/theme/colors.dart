import 'package:flutter/material.dart';

/// 蔚蓝档案 (Blue Archive) UI 设计规范的颜色定义
/// 完全按照蔚蓝档案的视觉风格设计
class BAColors {
  // ========== 蔚蓝档案核心品牌色 ==========
  
  /// 蔚蓝档案主色调 - 蔚蓝色 (Millennium Blue)
  static const Color primary = Color(0xFF5E81F4);
  
  /// 蔚蓝档案主色调深版
  static const Color primaryDark = Color(0xFF3D5DD1);
  
  /// 蔚蓝档案主色调浅版
  static const Color primaryLight = Color(0xFF8AA3F7);
  
  /// 蔚蓝档案辅助色 - 粉色 (Abydos Pink)
  static const Color secondary = Color(0xFFFF85B0);
  
  /// 蔚蓝档案辅助色深版
  static const Color secondaryDark = Color(0xFFD64D87);
  
  /// 蔚蓝档案辅助色浅版
  static const Color secondaryLight = Color(0xFFFFAEC5);
  
  /// 蔚蓝色调 - 绿色 (Gehenna Green)
  static const Color accentGreen = Color(0xFF4CAF50);
  
  /// 蔚蓝色调 - 金色 (SRT Gold)
  static const Color accentGold = Color(0xFFFFD700);
  
  /// 蔚蓝色调 - 紫色 (Arius Purple)
  static const Color accentPurple = Color(0xFF9C27B0);
  
  /// 蔚蓝色调 - 红色 (Danger Red)
  static const Color danger = Color(0xFFFF4757);
  
  /// 蔚蓝色调 - 橙色 (Warning Orange)
  static const Color warning = Color(0xFFFFA502);
  
  /// 蔚蓝色调 - 青色 (Success Cyan)
  static const Color success = Color(0xFF2ED573);
  
  // ========== 蔚蓝档案深色主题 ==========
  
  /// 深色主题 - 背景色 (深蓝渐变基础)
  static const Color darkBackground = Color(0xFF0F1626);
  
  /// 深色主题 - 表面色 (卡片背景)
  static const Color darkSurface = Color(0xFF1A2338);
  
  /// 深色主题 - 表面色变体 (内层卡片)
  static const Color darkSurfaceVariant = Color(0xFF242E47);
  
  /// 深色主题 - 表面色第三变体
  static const Color darkSurfaceTertiary = Color(0xFF2E3953);
  
  /// 深色主题 - 文本主要颜色
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  /// 深色主题 - 文本次要颜色
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  
  /// 深色主题 - 文本禁用颜色
  static const Color darkTextDisabled = Color(0xFF4B5563);
  
  /// 深色主题 - 边框颜色
  static const Color darkBorder = Color(0xFF374151);
  
  /// 深色主题 - 边框亮色
  static const Color darkBorderLight = Color(0xFF4B5563);
  
  /// 深色主题 - 毛玻璃效果背景色
  static const Color darkGlass = Color(0xCC0F1626);
  
  /// 深色主题 - 阴影颜色
  static const Color darkShadow = Color(0x80000000);
  
  /// 深色主题 - 高亮色 (背景渐变)
  static const Color darkHighlight = Color(0xFF165DFF);
  
  // ========== 蔚蓝档案浅色主题 ==========
  
  /// 浅色主题 - 背景色 (浅蓝渐变基础)
  static const Color lightBackground = Color(0xFFF8FAFC);
  
  /// 浅色主题 - 表面色 (卡片背景)
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// 浅色主题 - 表面色变体 (内层卡片)
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  
  /// 浅色主题 - 表面色第三变体
  static const Color lightSurfaceTertiary = Color(0xFFE2E8F0);
  
  /// 浅色主题 - 文本主要颜色
  static const Color lightTextPrimary = Color(0xFF0F172A);
  
  /// 浅色主题 - 文本次要颜色
  static const Color lightTextSecondary = Color(0xFF64748B);
  
  /// 浅色主题 - 文本禁用颜色
  static const Color lightTextDisabled = Color(0xFF94A3B8);
  
  /// 浅色主题 - 边框颜色
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  /// 浅色主题 - 边框亮色
  static const Color lightBorderLight = Color(0xFFCBD5E1);
  
  /// 浅色主题 - 毛玻璃效果背景色
  static const Color lightGlass = Color(0xCCF8FAFC);
  
  /// 浅色主题 - 阴影颜色
  static const Color lightShadow = Color(0x1A000000);
  
  /// 浅色主题 - 高亮色 (背景渐变)
  static const Color lightHighlight = Color(0xFF165DFF);

  /// 主色调上的文本颜色
  static const Color textOnPrimary = Colors.white;
  
  // ========== 蔚蓝档案渐变色 ==========
  
  /// 主色渐变 - 顶部到右下
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF748FFC), Color(0xFF5E81F4)],
  );
  
  /// 主色渐变 - 对角
  static const Gradient primaryDiagonalGradient = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF8AA3F7), Color(0xFF5E81F4), Color(0xFF3D5DD1)],
  );
  
  /// 粉色渐变
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFAEC5), Color(0xFFFF85B0)],
  );
  
  /// 深色背景渐变
  static const Gradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121A2E), Color(0xFF0F1626)],
  );
  
  /// 浅色背景渐变
  static const Gradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F4FF), Color(0xFFF8FAFC)],
  );
  
  /// 卡片高光渐变
  static const Gradient cardHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x665E81F4),
      Color(0x335E81F4),
      Color(0x1A5E81F4),
      Color(0x00000000),
    ],
  );
  
  // ========== 通用方法 ==========
  
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
  
  /// 根据当前主题获取表面色第三变体
  static Color surfaceTertiaryOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightSurfaceTertiary : darkSurfaceTertiary;
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
  
  /// 根据当前主题获取边框亮色
  static Color borderLightOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightBorderLight : darkBorderLight;
  }
  
  /// 根据当前主题获取阴影颜色
  static Color shadowOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadow : darkShadow;
  }
  
  /// 根据当前主题获取毛玻璃效果背景色
  static Color glassOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightGlass : darkGlass;
  }
  
  /// 根据当前主题获取背景渐变
  static Gradient backgroundGradientOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightBackgroundGradient : darkBackgroundGradient;
  }

  /// 根据当前主题获取主色调
  static Color primaryOf(BuildContext context) {
    return primary;
  }

  /// 根据当前主题获取危险色
  static Color dangerOf(BuildContext context) {
    return danger;
  }

  /// 根据当前主题获取警告色
  static Color warningOf(BuildContext context) {
    return warning;
  }

  /// 根据当前主题获取成功色
  static Color successOf(BuildContext context) {
    return success;
  }
  
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
}
