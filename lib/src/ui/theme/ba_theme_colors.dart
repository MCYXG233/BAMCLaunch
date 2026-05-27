import 'package:flutter/material.dart';

/// 蔚蓝档案风格配色
/// 完全模仿蔚蓝档案的配色方案
class BAThemeColors {
  // 主背景色（蔚蓝档案风格 - 深蓝紫色）
  static const Color background = Color(0xFF0B0B1A);
  static const Color backgroundDark = Color(0xFF070710);
  static const Color backgroundLight = Color(0xFF12122A);

  // 表面色（卡片背景 - 稍浅的深色）
  static const Color surface = Color(0xFF15152E);
  static const Color surfaceVariant = Color(0xFF1C1C3A);
  static const Color surfaceHover = Color(0xFF232350);

  // 主强调色（蓝色）
  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryLight = Color(0xFF7BA3F5);
  static const Color primaryDark = Color(0xFF3D6FCC);

  // 次强调色（粉色/红色）
  static const Color secondary = Color(0xFFFF6B8A);
  static const Color secondaryLight = Color(0xFFFF8FA8);
  static const Color secondaryDark = Color(0xFFE54560);

  // 强调色（紫色）
  static const Color accent = Color(0xFF9B6BFF);

  // 文字色
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA8A8C0);
  static const Color textDisabled = Color(0xFF5C5C70);

  // 功能色
  static const Color success = Color(0xFF5BD38D);
  static const Color warning = Color(0xFFFFB84D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4DD4FF);

  // 体力色（蔚蓝档案的体力是黄色的）
  static const Color stamina = Color(0xFFFFD93D);

  // 货币色
  static const Color credit = Color(0xFF5BD38D);
  static const Color blueGem = Color(0xFF4DD4FF);

  // 边框色
  static const Color border = Color(0xFF2A2A4A);
  static const Color borderLight = Color(0xFF3A3A60);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF7BA3F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [primary, Color(0xFF3D6FCC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 经验条渐变
  static const LinearGradient expGradient = LinearGradient(
    colors: [Color(0xFF5B8DEF), Color(0xFF7BA3F5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // 毛玻璃效果
  static Color get frostedGlass => surface.withOpacity(0.8);

  // 阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withOpacity(0.5),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadowPink => [
        BoxShadow(
          color: secondary.withOpacity(0.5),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// 蔚蓝档案风格主题数据
class BAThemeData {
  // 圆角
  static const double radiusSmall = 6.0;
  static const double radius = 10.0;
  static const double radiusLarge = 14.0;
  static const double radiusXLarge = 20.0;

  // 间距
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacing = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // 动画时长
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animation = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);

  // 字体
  static const String fontFamily = 'Inter';
}

/// 圆角常量
class BARadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(BAThemeData.radiusSmall));
  static const BorderRadius normal = BorderRadius.all(Radius.circular(BAThemeData.radius));
  static const BorderRadius large = BorderRadius.all(Radius.circular(BAThemeData.radiusLarge));
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(BAThemeData.radiusXLarge));
}

/// 间距常量
class BASpacing {
  static const EdgeInsets xSmall = EdgeInsets.all(BAThemeData.spacingXSmall);
  static const EdgeInsets small = EdgeInsets.all(BAThemeData.spacingSmall);
  static const EdgeInsets normal = EdgeInsets.all(BAThemeData.spacing);
  static const EdgeInsets medium = EdgeInsets.all(BAThemeData.spacingMedium);
  static const EdgeInsets large = EdgeInsets.all(BAThemeData.spacingLarge);
  static const EdgeInsets xLarge = EdgeInsets.all(BAThemeData.spacingXLarge);
}

class BABadgeStyle {
  static Widget buildTag({required String label, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? BAThemeColors.primary.withOpacity(0.15)
            : BAThemeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? BAThemeColors.primary
              : BAThemeColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? BAThemeColors.textPrimary
              : BAThemeColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class BACardStyle {
  static EdgeInsets get contentPadding => const EdgeInsets.all(16);
  static EdgeInsets get sectionPadding => const EdgeInsets.symmetric(vertical: 12);

  static BoxDecoration get frostedGlass => BoxDecoration(
        color: BAThemeColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BAThemeColors.border,
        ),
      );
}

class BAInputStyle {
  static InputDecoration searchDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: BAThemeColors.textDisabled),
      filled: true,
      fillColor: BAThemeColors.surface.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BAThemeColors.border.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BAThemeColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }
}

class BAAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
