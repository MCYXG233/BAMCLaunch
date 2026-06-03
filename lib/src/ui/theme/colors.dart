import 'package:flutter/material.dart';

/// 蔚蓝档案风格 MC 启动器 - 完整色彩系统
/// 基于蔚蓝档案游戏 UI 设计规范
class BAColors {
  // ==================== 品牌核心色 ====================
  
  /// 主色调 - 柔和蔚蓝色 (Primary Blue)
  static const Color primary = Color(0xFF6B8EFF);
  
  /// 主色深版 (Primary Dark)
  static const Color primaryDark = Color(0xFF4A69CC);
  
  /// 主色浅版 (Primary Light)
  static const Color primaryLight = Color(0xFF9AB3FF);
  
  /// 辅助色 - 活力粉色 (Secondary Pink)
  static const Color secondary = Color(0xFFFF96B5);
  
  /// 辅助色深版
  static const Color secondaryDark = Color(0xFFFF6A92);
  
  /// 辅助色浅版
  static const Color secondaryLight = Color(0xFFFFB8CE);

  // ==================== 功能色 ====================
  
  /// 成功色 - 清新绿
  static const Color success = Color(0xFF6BCB77);
  
  /// 警告色 - 明亮黄
  static const Color warning = Color(0xFFFFD93D);
  
  /// 危险色 - 活力红
  static const Color danger = Color(0xFFFF6B6B);
  
  /// 信息色 - 活力青
  static const Color info = Color(0xFF4ECDC4);
  
  /// 成功色深版
  static const Color successDark = Color(0xFF4CAF50);
  
  /// 警告色深版
  static const Color warningDark = Color(0xFFFFC107);
  
  /// 危险色深版
  static const Color dangerDark = Color(0xFFE53935);

  // ==================== 深色主题 ====================
  
  /// 深色主题 - 主背景 (深蓝黑)
  static const Color darkBackground = Color(0xFF0A0F1E);
  
  /// 深色主题 - 次背景
  static const Color darkBackgroundSecondary = Color(0xFF141C33);
  
  /// 深色主题 - 表面色 (卡片背景)
  static const Color darkSurface = Color(0xFF1E2747);
  
  /// 深色主题 - 表面色变体
  static const Color darkSurfaceVariant = Color(0xFF263358);
  
  /// 深色主题 - 表面色第三变体
  static const Color darkSurfaceTertiary = Color(0xFF2E3D66);
  
  /// 深色主题 - 悬停状态
  static const Color darkSurfaceHover = Color(0xFF364A7A);
  
  /// 深色主题 - 文本主要颜色
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  /// 深色主题 - 文本次要颜色
  static const Color darkTextSecondary = Color(0xFFA0B0C8);
  
  /// 深色主题 - 文本禁用颜色
  static const Color darkTextDisabled = Color(0xFF5A6A85);
  
  /// 深色主题 - 边框颜色
  static const Color darkBorder = Color(0xFF3A4D7A);
  
  /// 深色主题 - 边框亮色
  static const Color darkBorderLight = Color(0xFF4A5D8A);
  
  /// 深色主题 - 分割线
  static const Color darkDivider = Color(0xFF2A3555);
  
  /// 深色主题 - 毛玻璃背景 (更通透的亚克力效果)
  static const Color darkGlass = Color(0x4D141C33);

  /// 深色主题 - 阴影颜色
  static const Color darkShadow = Color(0x80000000);

  // ==================== 浅色主题 ====================
  
  /// 浅色主题 - 主背景 (浅蓝白)
  static const Color lightBackground = Color(0xFFF5F8FF);
  
  /// 浅色主题 - 次背景
  static const Color lightBackgroundSecondary = Color(0xFFEEF2FF);
  
  /// 浅色主题 - 表面色 (卡片背景)
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// 浅色主题 - 表面色变体
  static const Color lightSurfaceVariant = Color(0xFFF0F4FF);
  
  /// 浅色主题 - 表面色第三变体
  static const Color lightSurfaceTertiary = Color(0xFFE8EDFF);
  
  /// 浅色主题 - 悬停状态
  static const Color lightSurfaceHover = Color(0xFFE8EDFF);
  
  /// 浅色主题 - 文本主要颜色
  static const Color lightTextPrimary = Color(0xFF1A2744);
  
  /// 浅色主题 - 文本次要颜色
  static const Color lightTextSecondary = Color(0xFF5A6A8A);
  
  /// 浅色主题 - 文本禁用颜色
  static const Color lightTextDisabled = Color(0xFFA0A8C0);
  
  /// 浅色主题 - 边框颜色
  static const Color lightBorder = Color(0xFFD0D8EE);
  
  /// 浅色主题 - 边框亮色
  static const Color lightBorderLight = Color(0xFFE0E6F5);
  
  /// 浅色主题 - 分割线
  static const Color lightDivider = Color(0xFFE8EEFF);
  
  /// 浅色主题 - 毛玻璃背景 (更通透的亚克力效果)
  static const Color lightGlass = Color(0x4DFFFFFF);
  
  /// 浅色主题 - 阴影颜色
  static const Color lightShadow = Color(0x1A000000);

  // ==================== 主按钮文字色 ====================
  
  /// 主按钮文字色
  static const Color textOnPrimary = Colors.white;
  
  /// 次按钮文字色
  static const Color textOnSecondary = Colors.white;

  // ==================== 渐变色系统 ====================
  
  /// 主色渐变 - 按钮、强调元素
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8EAAFF), Color(0xFF6B8EFF)],
  );
  
  /// 主色对角渐变
  static const Gradient primaryDiagonalGradient = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF9AB3FF), Color(0xFF6B8EFF), Color(0xFF4A69CC)],
  );
  
  /// 辅助色渐变 - 粉色
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB8CE), Color(0xFFFF96B5)],
  );
  
  /// 成功渐变
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8AE89A), Color(0xFF6BCB77)],
  );
  
  /// 警告渐变
  static const Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE066), Color(0xFFFFD93D)],
  );
  
  /// 危险渐变
  static const Gradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A8A), Color(0xFFFF6B6B)],
  );
  
  /// 深色背景渐变
  static const Gradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackgroundSecondary, darkBackground],
  );
  
  /// 浅色背景渐变
  static const Gradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightSurface, lightBackground],
  );
  
  /// 卡片高光渐变
  static const Gradient cardHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A6B8EFF),
      Color(0x0D6B8EFF),
      Color(0x056B8EFF),
      Color(0x00000000),
    ],
  );
  
  /// 封面渐变
  static const Gradient coverGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x006B8EFF),
      Color(0x806B8EFF),
    ],
  );

  // ==================== 主题感知方法 ====================
  
  /// 获取背景色
  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightBackground 
        : darkBackground;
  }
  
  /// 获取次背景色
  static Color backgroundSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightBackgroundSecondary 
        : darkBackgroundSecondary;
  }
  
  /// 获取表面色
  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightSurface 
        : darkSurface;
  }
  
  /// 获取表面色变体
  static Color surfaceVariantOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightSurfaceVariant 
        : darkSurfaceVariant;
  }
  
  /// 获取表面色第三变体
  static Color surfaceTertiaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightSurfaceTertiary 
        : darkSurfaceTertiary;
  }
  
  /// 获取悬停状态色
  static Color surfaceHoverOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightSurfaceHover 
        : darkSurfaceHover;
  }
  
  /// 获取主文本色
  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightTextPrimary 
        : darkTextPrimary;
  }
  
  /// 获取次文本色
  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightTextSecondary 
        : darkTextSecondary;
  }
  
  /// 获取禁用文本色
  static Color textDisabledOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightTextDisabled 
        : darkTextDisabled;
  }
  
  /// 获取边框色
  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightBorder 
        : darkBorder;
  }
  
  /// 获取边框亮色
  static Color borderLightOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightBorderLight 
        : darkBorderLight;
  }
  
  /// 获取分割线色
  static Color dividerOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightDivider 
        : darkDivider;
  }
  
  /// 获取阴影色
  static Color shadowOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightShadow 
        : darkShadow;
  }
  
  /// 获取毛玻璃背景色
  static Color glassOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightGlass 
        : darkGlass;
  }
  
  /// 获取背景渐变
  static Gradient backgroundGradientOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? lightBackgroundGradient 
        : darkBackgroundGradient;
  }
  
  /// 获取主色
  static Color primaryOf(BuildContext context) {
    return primary;
  }
  
  /// 获取成功色
  static Color successOf(BuildContext context) {
    return success;
  }
  
  /// 获取警告色
  static Color warningOf(BuildContext context) {
    return warning;
  }
  
  /// 获取危险色
  static Color dangerOf(BuildContext context) {
    return danger;
  }
  
  /// 获取信息色
  static Color infoOf(BuildContext context) {
    return info;
  }

  // ==================== 向后兼容 ====================
  
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
