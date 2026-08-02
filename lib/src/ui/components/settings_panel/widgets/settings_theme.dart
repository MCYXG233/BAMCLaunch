import 'package:flutter/material.dart';

/// 设置面板色板常量
///
/// 设计要点：
/// - 保留 BAMCLaunch 蔚蓝档案主题调性（紫色强调 + 蓝色基调）
/// - 半透明白色卡片营造亚克力质感
/// - 圆角统一 12px（卡片）/ 8px（控件）
/// - 自适应 dark / light 主题
class SettingsPalette {
  SettingsPalette._();

  /// 主面板背景（蔚蓝档案渐变 + 紫色光晕）
  static LinearGradient backgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF1A2240).withValues(alpha: 0.85),
              const Color(0xFF141A30).withValues(alpha: 0.85),
            ]
          : [
              const Color(0xFFF1ECFF).withValues(alpha: 0.85),
              const Color(0xFFDFE6FF).withValues(alpha: 0.85),
            ],
    );
  }

  /// 半透明白卡片底色（亚克力效果）
  static Color glassWhite(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.78);
  }

  /// 卡片悬停态底色
  static Color glassWhiteHover(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.92);
  }

  /// 实色卡片（用于提示/帮助说明）
  static Color cardSolid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.94);
  }

  /// 卡片边框
  static Color cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.7);
  }

  /// 左侧导航背景
  static Color sidebarBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.55);
  }

  /// 主文字色
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFE8ECF8) : const Color(0xFF1A1A2E);
  }

  /// 次文字色
  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFA0AAC4) : const Color(0xFF5A5A72);
  }

  /// 浅灰文字（描述用）
  static Color textHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF6E7896) : const Color(0xFF9696A8);
  }

  /// 强调色（紫色，继承蔚蓝档案主题）
  static const accent = Color(0xFF5C7CFA);

  /// 强调色浅版背景（用于左侧选中指示、提示卡片）
  static Color accentBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0x1A5C7CFA) : const Color(0xFFEDEFFC);
  }

  /// 成功绿
  static const success = Color(0xFF4CC68F);

  /// 警告橙（缺失依赖、状态提示）
  static const warning = Color(0xFFE6984E);

  /// 危险红
  static const danger = Color(0xFFE5616F);

  /// 卡片阴影
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
        blurRadius: 16,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// 主面板阴影（更明显）
  static List<BoxShadow> panelShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
        blurRadius: 40,
        offset: const Offset(-8, 0),
      ),
    ];
  }
}

/// 适配 dark/light 主题的常用色（沿用 BAColors 但覆盖关键 token）
class SettingsColors {
  SettingsColors._();

  static Color of(BuildContext context, Color lightColor, Color darkColor) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  /// 主文字
  static Color textPrimary(BuildContext c) => SettingsPalette.textPrimary(c);

  /// 次文字
  static Color textSecondary(BuildContext c) =>
      SettingsPalette.textSecondary(c);

  /// 浅灰
  static Color textHint(BuildContext c) => SettingsPalette.textHint(c);
}
