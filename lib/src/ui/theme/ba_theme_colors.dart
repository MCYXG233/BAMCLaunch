import 'package:flutter/material.dart';

/// 蔚蓝档案风格配色
/// 完全模仿蔚蓝档案的配色方案
class BAThemeColors {
  // 主背景色（蔚蓝档案风格 - 浅白色）
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFFEBEEF5);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  // 表面色（卡片背景 - 浅白色）
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFD);
  static const Color surfaceHover = Color(0xFFEDF2FC);

  // 主强调色（柔和蓝色）
  static const Color primary = Color(0xFF6B9BF2);
  static const Color primaryLight = Color(0xFF8BABF7);
  static const Color primaryDark = Color(0xFF4D80E0);

  // 次强调色（柔和粉色）
  static const Color secondary = Color(0xFFFF8B9D);
  static const Color secondaryLight = Color(0xFFFFAAB8);
  static const Color secondaryDark = Color(0xFFE56B7D);

  // 强调色（柔和紫色）
  static const Color accent = Color(0xFFA87AFF);

  // 文字色
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFA0AEC0);

  // 功能色
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFECC94B);
  static const Color danger = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);

  // 体力色（蔚蓝档案的体力是黄色的）
  static const Color stamina = Color(0xFFFFE066);

  // 货币色
  static const Color credit = Color(0xFF48BB78);
  static const Color blueGem = Color(0xFF4299E1);

  // 边框色
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [primary, primaryDark],
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
    colors: [Color(0xFFFFE066), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 经验条渐变
  static const LinearGradient expGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // 毛玻璃效果
  static Color get frostedGlass => surface.withOpacity(0.9);

  // 阴影（柔和风格）
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadowPink => [
        BoxShadow(
          color: secondary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}

/// 蔚蓝档案风格主题数据
class BAThemeData {
  // 圆角（更大的圆角符合蔚蓝档案风格）
  static const double radiusSmall = 8.0;
  static const double radius = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // 间距（更宽松的间距）
  static const double spacingXSmall = 6.0;
  static const double spacingSmall = 10.0;
  static const double spacing = 14.0;
  static const double spacingMedium = 18.0;
  static const double spacingLarge = 26.0;
  static const double spacingXLarge = 36.0;

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
