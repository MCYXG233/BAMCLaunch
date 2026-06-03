import 'package:flutter/material.dart';

/// 蔚蓝档案风格配色
/// 完全模仿蔚蓝档案的配色方案 - 优化版
class BAThemeColors {
  // 主背景色（蔚蓝档案风格 - 更轻盈的浅白色）
  static const Color background = Color(0xFFFAFBFD);
  static const Color backgroundDark = Color(0xFFF0F3F8);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  // 表面色（卡片背景 - 浅白色，更通透）
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFD);
  static const Color surfaceHover = Color(0xFFEDF2FC);

  // 主强调色（更轻盈的天蓝色）
  static const Color primary = Color(0xFF7EB5F6);
  static const Color primaryLight = Color(0xFFA5C8FA);
  static const Color primaryDark = Color(0xFF5A9EE0);

  // 次强调色（更淡的樱花粉）
  static const Color secondary = Color(0xFFFFB4C2);
  static const Color secondaryLight = Color(0xFFFFD1D8);
  static const Color secondaryDark = Color(0xFFE89AAB);

  // 强调色（柔和紫色）
  static const Color accent = Color(0xFFB8A4FF);

  // 文字色（降低对比度，更柔和）
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFA0AEC0);

  // 功能色（更柔和的色调）
  static const Color success = Color(0xFF7BCB9E);
  static const Color warning = Color(0xFFF5D76E);
  static const Color danger = Color(0xFFE88B8B);
  static const Color info = Color(0xFF7EB5F6);

  // 体力色（蔚蓝档案的体力是黄色的）
  static const Color stamina = Color(0xFFFFE066);

  // 货币色
  static const Color credit = Color(0xFF7BCB9E);
  static const Color blueGem = Color(0xFF7EB5F6);

  // 边框色（更淡）
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);

  // 渐变色（更柔和的蓝紫渐变）
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [Color(0xFF7EB5F6), Color(0xFF5A9EE0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1)],
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
    colors: [Color(0xFF8EC5FC), Color(0xFFA5C8FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // 毛玻璃效果分级（更通透的亚克力效果）
  static Color get frostedGlassLight => surface.withOpacity(0.35);
  static Color get frostedGlassMedium => surface.withOpacity(0.25);
  static Color get frostedGlassHeavy => surface.withOpacity(0.15);
  static Color get frostedGlass => surface.withOpacity(0.30);

  // 阴影（更柔和）
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 10),
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
  // 圆角（更大的圆角，更圆润）
  static const double radiusSmall = 12.0;
  static const double radius = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  static const double radiusCircle = 999.0;

  // 间距（更宽松的间距）
  static const double spacingXSmall = 8.0;
  static const double spacingSmall = 12.0;
  static const double spacing = 18.0;
  static const double spacingMedium = 24.0;
  static const double spacingLarge = 32.0;
  static const double spacingXLarge = 48.0;

  // 动画时长（更柔和的过渡）
  static const Duration animationMicro = Duration(milliseconds: 100);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animation = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // 字体
  static const String fontFamily = 'Inter';
}

/// 圆角常量
class BARadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(BAThemeData.radiusSmall));
  static const BorderRadius normal = BorderRadius.all(Radius.circular(BAThemeData.radius));
  static const BorderRadius large = BorderRadius.all(Radius.circular(BAThemeData.radiusLarge));
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(BAThemeData.radiusXLarge));
  static const BorderRadius circle = BorderRadius.all(Radius.circular(BAThemeData.radiusCircle));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? BAThemeColors.primary.withOpacity(0.12)
            : BAThemeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? BAThemeColors.primary.withOpacity(0.4)
              : BAThemeColors.border.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? BAThemeColors.primary
              : BAThemeColors.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class BACardStyle {
  static EdgeInsets get contentPadding => const EdgeInsets.all(BAThemeData.spacingMedium);
  static EdgeInsets get sectionPadding => const EdgeInsets.symmetric(vertical: BAThemeData.spacingSmall);
  static const double listItemSpacing = 12.0;

  static BoxDecoration get frostedGlass => BoxDecoration(
        color: BAThemeColors.surface.withOpacity(0.25),
        borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.15),
        ),
      );

  static BoxDecoration cardDecoration({double? opacity}) => BoxDecoration(
        color: BAThemeColors.surface.withOpacity(opacity ?? 0.35),
        borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.15),
          width: 1,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BAThemeData.radius),
        borderSide: BorderSide(
          color: BAThemeColors.border.withOpacity(0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BAThemeData.radius),
        borderSide: BorderSide(
          color: BAThemeColors.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
    );
  }
}

class BAAnimation {
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}
