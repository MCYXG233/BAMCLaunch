import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// 蔚蓝档案 (Blue Archive) UI 主题数据
/// 完全按照蔚蓝档案的视觉风格设计
class BATheme {
  /// 向后兼容：获取默认主题数据（深色）
  static ThemeData get theme => darkTheme;

  /// 获取深色主题数据
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: BAColors.darkBackground,
      cardColor: BAColors.darkSurface,
      textTheme: _textTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      iconTheme: _darkIconTheme,
      dividerTheme: _darkDividerTheme,
      appBarTheme: _darkAppBarTheme,
      bottomNavigationBarTheme: _darkBottomNavBarTheme,
      cardTheme: CardThemeData(
        color: BAColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return BAColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary.withOpacity(0.3);
          }
          return BAColors.darkSurfaceVariant;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BAColors.primary,
        inactiveTrackColor: BAColors.darkSurfaceVariant,
        thumbColor: BAColors.primary,
        overlayColor: BAColors.primary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BAColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BAColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BAColors.primary,
          side: const BorderSide(color: BAColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BAColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: BAColors.darkSurfaceTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BAColors.darkBorder),
        ),
        textStyle: const TextStyle(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BAColors.darkSurfaceVariant,
        selectedColor: BAColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: BAColors.darkBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: BAColors.darkSurfaceVariant,
        circularTrackColor: BAColors.darkSurfaceVariant,
        color: BAColors.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: BAColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: BAColors.darkTextPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 13,
          color: BAColors.darkTextSecondary,
        ),
        headingRowColor: WidgetStateProperty.all(BAColors.darkSurfaceVariant),
        dividerThickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BAColors.darkSurface,
        contentTextStyle: BATypography.bodyMedium.copyWith(
          color: BAColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 获取浅色主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: BAColors.lightBackground,
      cardColor: BAColors.lightSurface,
      textTheme: _textTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      iconTheme: _lightIconTheme,
      dividerTheme: _lightDividerTheme,
      appBarTheme: _lightAppBarTheme,
      bottomNavigationBarTheme: _lightBottomNavBarTheme,
      cardTheme: CardThemeData(
        color: BAColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return BAColors.lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary.withOpacity(0.3);
          }
          return BAColors.lightSurfaceVariant;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BAColors.primary,
        inactiveTrackColor: BAColors.lightSurfaceVariant,
        thumbColor: BAColors.primary,
        overlayColor: BAColors.primary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BAColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BAColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BAColors.primary,
          side: const BorderSide(color: BAColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BAColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: BAColors.lightSurfaceTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BAColors.lightBorder),
        ),
        textStyle: const TextStyle(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BAColors.lightSurfaceVariant,
        selectedColor: BAColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: BAColors.lightBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BAColors.primary;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: BAColors.lightSurfaceVariant,
        circularTrackColor: BAColors.lightSurfaceVariant,
        color: BAColors.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: BAColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: BAColors.lightTextPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 13,
          color: BAColors.lightTextSecondary,
        ),
        headingRowColor: WidgetStateProperty.all(BAColors.lightSurfaceVariant),
        dividerThickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BAColors.lightSurface,
        contentTextStyle: BATypography.bodyMedium.copyWith(
          color: BAColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 获取指定主题模式的主题数据
  static ThemeData getTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
      default:
        return darkTheme;
    }
  }

  /// 深色主题颜色方案
  static ColorScheme get _darkColorScheme {
    return const ColorScheme.dark(
      primary: BAColors.primary,
      onPrimary: Colors.white,
      primaryContainer: BAColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: BAColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: BAColors.secondaryDark,
      onSecondaryContainer: Colors.white,
      error: BAColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      surface: BAColors.darkSurface,
      onSurface: BAColors.darkTextPrimary,
      surfaceVariant: BAColors.darkSurfaceVariant,
      onSurfaceVariant: BAColors.darkTextSecondary,
      outline: BAColors.darkBorder,
      shadow: BAColors.darkShadow,
      background: BAColors.darkBackground,
      onBackground: BAColors.darkTextPrimary,
      surfaceTint: BAColors.primary,
    );
  }

  /// 浅色主题颜色方案
  static ColorScheme get _lightColorScheme {
    return const ColorScheme.light(
      primary: BAColors.primary,
      onPrimary: Colors.white,
      primaryContainer: BAColors.primaryLight,
      onPrimaryContainer: Color(0xFF1A1A2E),
      secondary: BAColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: BAColors.secondaryLight,
      onSecondaryContainer: Color(0xFF1A1A2E),
      error: BAColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      surface: BAColors.lightSurface,
      onSurface: BAColors.lightTextPrimary,
      surfaceVariant: BAColors.lightSurfaceVariant,
      onSurfaceVariant: BAColors.lightTextSecondary,
      outline: BAColors.lightBorder,
      shadow: BAColors.lightShadow,
      background: BAColors.lightBackground,
      onBackground: BAColors.lightTextPrimary,
      surfaceTint: BAColors.primary,
    );
  }

  /// 文本主题（通用）
  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: BATypography.headlineLarge,
      displayMedium: BATypography.headlineMedium,
      displaySmall: BATypography.headlineSmall,
      headlineLarge: BATypography.headlineLarge,
      headlineMedium: BATypography.headlineMedium,
      headlineSmall: BATypography.headlineSmall,
      titleLarge: BATypography.titleLarge,
      titleMedium: BATypography.titleMedium,
      titleSmall: BATypography.titleSmall,
      bodyLarge: BATypography.bodyLarge,
      bodyMedium: BATypography.bodyMedium,
      bodySmall: BATypography.bodySmall,
      labelLarge: BATypography.button,
      labelMedium: BATypography.label,
      labelSmall: BATypography.labelSmall,
    );
  }

  /// 深色主题输入框装饰主题
  static InputDecorationTheme get _darkInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: BAColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      hintStyle: const TextStyle(color: BAColors.darkTextDisabled, fontSize: 14),
      labelStyle: const TextStyle(color: BAColors.darkTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(color: BAColors.danger, fontSize: 12),
    );
  }

  /// 浅色主题输入框装饰主题
  static InputDecorationTheme get _lightInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: BAColors.lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      hintStyle: const TextStyle(color: BAColors.lightTextDisabled, fontSize: 14),
      labelStyle: const TextStyle(color: BAColors.lightTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(color: BAColors.danger, fontSize: 12),
    );
  }

  /// 深色主题图标主题
  static IconThemeData get _darkIconTheme {
    return const IconThemeData(color: BAColors.darkTextPrimary, size: 24);
  }

  /// 浅色主题图标主题
  static IconThemeData get _lightIconTheme {
    return const IconThemeData(color: BAColors.lightTextPrimary, size: 24);
  }

  /// 深色主题分割线主题
  static DividerThemeData get _darkDividerTheme {
    return const DividerThemeData(
      color: BAColors.darkBorder,
      thickness: 1,
      space: 1,
    );
  }

  /// 浅色主题分割线主题
  static DividerThemeData get _lightDividerTheme {
    return const DividerThemeData(
      color: BAColors.lightBorder,
      thickness: 1,
      space: 1,
    );
  }

  /// 深色主题应用栏主题
  static AppBarTheme get _darkAppBarTheme {
    return AppBarTheme(
      backgroundColor: BAColors.darkSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: BATypography.titleBar.copyWith(
        color: BAColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: BAColors.darkTextPrimary),
    );
  }

  /// 浅色主题应用栏主题
  static AppBarTheme get _lightAppBarTheme {
    return AppBarTheme(
      backgroundColor: BAColors.lightSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: BATypography.titleBar.copyWith(
        color: BAColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: BAColors.lightTextPrimary),
    );
  }

  /// 深色主题底部导航栏主题
  static BottomNavigationBarThemeData get _darkBottomNavBarTheme {
    return const BottomNavigationBarThemeData(
      backgroundColor: BAColors.darkSurface,
      selectedItemColor: BAColors.primary,
      unselectedItemColor: BAColors.darkTextSecondary,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
    );
  }

  /// 浅色主题底部导航栏主题
  static BottomNavigationBarThemeData get _lightBottomNavBarTheme {
    return const BottomNavigationBarThemeData(
      backgroundColor: BAColors.lightSurface,
      selectedItemColor: BAColors.primary,
      unselectedItemColor: BAColors.lightTextSecondary,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
    );
  }

  // ========== 圆角半径 ==========
  
  /// 标准圆角半径
  static BorderRadius get borderRadius => BorderRadius.circular(12);

  /// 小圆角半径
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(8);

  /// 中圆角半径
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(12);

  /// 大圆角半径
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(16);

  /// 超大圆角半径
  static BorderRadius get borderRadiusExtraLarge => BorderRadius.circular(24);

  // ========== 阴影 ==========

  /// 向后兼容：获取标准阴影（默认深色）
  static List<BoxShadow> get shadows => darkShadows;

  /// 向后兼容：获取小阴影（默认深色）
  static List<BoxShadow> get shadowsSmall => darkShadowsSmall;

  /// 获取深色主题标准阴影
  static List<BoxShadow> get darkShadows => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// 获取浅色主题标准阴影
  static List<BoxShadow> get lightShadows => [
        BoxShadow(
          color: BAColors.lightShadow.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// 获取深色主题小阴影
  static List<BoxShadow> get darkShadowsSmall => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// 获取浅色主题小阴影
  static List<BoxShadow> get lightShadowsSmall => [
        BoxShadow(
          color: BAColors.lightShadow.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// 获取深色主题大阴影
  static List<BoxShadow> get darkShadowsLarge => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// 获取浅色主题大阴影
  static List<BoxShadow> get lightShadowsLarge => [
        BoxShadow(
          color: BAColors.lightShadow.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// 根据当前主题获取标准阴影
  static List<BoxShadow> shadowsOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadows : darkShadows;
  }

  /// 根据当前主题获取小阴影
  static List<BoxShadow> shadowsSmallOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadowsSmall : darkShadowsSmall;
  }

  /// 根据当前主题获取大阴影
  static List<BoxShadow> shadowsLargeOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadowsLarge : darkShadowsLarge;
  }

  // ========== 毛玻璃效果 ==========
  
  /// 毛玻璃效果模糊值
  static const double blurSigma = 10;
  
  /// 毛玻璃效果轻量模糊值
  static const double blurSigmaLight = 5;
}
