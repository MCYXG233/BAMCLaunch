import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// BakaXL 风格设置面板的色板常量
///
/// 设计要点：
/// - 浅色基调，白色磨砂亚克力卡片
/// - 紫色作为强调色（左侧导航选中指示、关键按钮）
/// - 文字分层：primary 主体 + secondary 描述 + disabled 占位
/// - 圆角统一 10px（卡片）/ 8px（控件）
class SettingsPalette {
  SettingsPalette._();

  /// 背景渐变（左紫→右粉，呼应 BakaXL 截图）
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE9D8FE), Color(0xFFFCE4F2), Color(0xFFEDE9FE)],
    stops: [0.0, 0.5, 1.0],
  );

  /// 整体背景灰底（兜底）
  static const surfaceBase = Color(0xFFF5F5F7);

  /// 半透明白卡片底色（亚克力效果）
  static Color glassWhite(BuildContext context) =>
      Colors.white.withValues(alpha: 0.7);

  /// 卡片悬停态底色
  static Color glassWhiteHover(BuildContext context) =>
      Colors.white.withValues(alpha: 0.85);

  /// 浅色卡片纯白态（用于重要分组如 Java 帮助说明）
  static Color cardSolid(BuildContext context) =>
      Colors.white.withValues(alpha: 0.92);

  /// 卡片分割线
  static Color cardBorder(BuildContext context) =>
      Colors.white.withValues(alpha: 0.6);

  /// 左侧导航背景
  static Color sidebarBackground(BuildContext context) =>
      Colors.white.withValues(alpha: 0.5);

  /// 主文字色
  static Color textPrimary(BuildContext context) => const Color(0xFF1F1F23);

  /// 次文字色
  static Color textSecondary(BuildContext context) => const Color(0xFF6B6B72);

  /// 浅灰文字（描述用）
  static Color textHint(BuildContext context) => const Color(0xFF9A9AA1);

  /// 强调色（紫色，呼应 BakaXL）
  static const accent = Color(0xFF7C5CFF);

  /// 强调色浅版背景（用于左侧选中指示）
  static Color accentBackground = const Color(0xFFEFE9FF);

  /// 警告橙（缺失依赖、状态提示）
  static const warning = Color(0xFFE6984E);

  /// 成功绿
  static const success = Color(0xFF4CC68F);

  /// 危险红
  static const danger = Color(0xFFE5616F);

  /// 卡片阴影
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 2),
    ),
  ];

  /// 主面板阴影（更明显）
  static List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(-8, 0),
    ),
  ];
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
