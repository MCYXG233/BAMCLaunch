import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// 蔚蓝档案UI主题数据
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
      cardTheme: _darkCardTheme,
      buttonTheme: _buttonTheme,
      textTheme: _textTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      iconTheme: _darkIconTheme,
      dividerTheme: _darkDividerTheme,
      dialogTheme: _darkDialogTheme,
      tooltipTheme: _darkTooltipTheme,
      appBarTheme: _darkAppBarTheme,
    );
  }

  /// 获取浅色主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: BAColors.lightBackground,
      cardColor: BAColors.lightSurface,
      cardTheme: _lightCardTheme,
      buttonTheme: _buttonTheme,
      textTheme: _textTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      iconTheme: _lightIconTheme,
      dividerTheme: _lightDividerTheme,
      dialogTheme: _lightDialogTheme,
      tooltipTheme: _lightTooltipTheme,
      appBarTheme: _lightAppBarTheme,
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
      errorContainer: BAColors.dangerDark,
      onErrorContainer: Colors.white,
      surface: BAColors.darkSurface,
      onSurface: BAColors.darkTextPrimary,
      surfaceVariant: BAColors.darkSurfaceVariant,
      onSurfaceVariant: BAColors.darkTextSecondary,
      outline: BAColors.darkBorder,
      shadow: BAColors.darkShadow,
      background: BAColors.darkBackground,
      onBackground: BAColors.darkTextPrimary,
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
      errorContainer: BAColors.dangerLight,
      onErrorContainer: Colors.white,
      surface: BAColors.lightSurface,
      onSurface: BAColors.lightTextPrimary,
      surfaceVariant: BAColors.lightSurfaceVariant,
      onSurfaceVariant: BAColors.lightTextSecondary,
      outline: BAColors.lightBorder,
      shadow: BAColors.lightShadow,
      background: BAColors.lightBackground,
      onBackground: BAColors.lightTextPrimary,
    );
  }

  /// 深色主题卡片主题
  static CardThemeData get _darkCardTheme {
    return CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: BAColors.darkSurface,
      shadowColor: BAColors.darkShadow,
      margin: EdgeInsets.zero,
    );
  }

  /// 浅色主题卡片主题
  static CardThemeData get _lightCardTheme {
    return CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: BAColors.lightSurface,
      shadowColor: BAColors.lightShadow,
      margin: EdgeInsets.zero,
    );
  }

  /// 按钮主题（通用）
  static ButtonThemeData get _buttonTheme {
    return ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      buttonColor: BAColors.primary,
      textTheme: ButtonTextTheme.primary,
    );
  }

  /// 文本主题（通用）
  static TextTheme get _textTheme {
    return const TextTheme(
      displayLarge: BATypography.headlineLarge,
      displayMedium: BATypography.headlineMedium,
      displaySmall: BATypography.headlineSmall,
      bodyLarge: BATypography.bodyLarge,
      bodyMedium: BATypography.bodyMedium,
      bodySmall: BATypography.bodySmall,
      labelLarge: BATypography.button,
      labelMedium: BATypography.label,
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.2,
      ),
    );
  }

  /// 深色主题输入框装饰主题
  static InputDecorationTheme get _darkInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: BAColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
      fillColor: BAColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BAColors.danger, width: 2),
      ),
      hintStyle: const TextStyle(color: BAColors.lightTextDisabled, fontSize: 14),
      labelStyle: const TextStyle(color: BAColors.lightTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(color: BAColors.danger, fontSize: 12),
    );
  }

  /// 深色主题图标主题
  static IconThemeData get _darkIconTheme {
    return const IconThemeData(color: BAColors.darkTextPrimary, size: 20);
  }

  /// 浅色主题图标主题
  static IconThemeData get _lightIconTheme {
    return const IconThemeData(color: BAColors.lightTextPrimary, size: 20);
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

  /// 深色主题对话框主题
  static DialogThemeData get _darkDialogTheme {
    return DialogThemeData(
      backgroundColor: BAColors.darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: BATypography.headlineMedium.copyWith(
        color: BAColors.darkTextPrimary,
      ),
      contentTextStyle: BATypography.bodyMedium.copyWith(
        color: BAColors.darkTextSecondary,
      ),
    );
  }

  /// 浅色主题对话框主题
  static DialogThemeData get _lightDialogTheme {
    return DialogThemeData(
      backgroundColor: BAColors.lightSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: BATypography.headlineMedium.copyWith(
        color: BAColors.lightTextPrimary,
      ),
      contentTextStyle: BATypography.bodyMedium.copyWith(
        color: BAColors.lightTextSecondary,
      ),
    );
  }

  /// 深色主题工具提示主题
  static TooltipThemeData get _darkTooltipTheme {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: BAColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: BATypography.bodySmall.copyWith(color: BAColors.darkTextPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// 浅色主题工具提示主题
  static TooltipThemeData get _lightTooltipTheme {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: BAColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: BATypography.bodySmall.copyWith(color: BAColors.lightTextPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  /// 标准圆角半径
  static BorderRadius get borderRadius => BorderRadius.circular(12);

  /// 小圆角半径
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(8);

  /// 向后兼容：获取标准阴影（默认深色）
  static List<BoxShadow> get shadows => darkShadows;

  /// 向后兼容：获取小阴影（默认深色）
  static List<BoxShadow> get shadowsSmall => darkShadowsSmall;

  /// 获取深色主题标准阴影
  static List<BoxShadow> get darkShadows => [
    BoxShadow(
      color: BAColors.darkShadow.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: BAColors.darkShadow.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// 获取浅色主题标准阴影
  static List<BoxShadow> get lightShadows => [
    BoxShadow(
      color: BAColors.lightShadow.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: BAColors.lightShadow.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// 获取深色主题小阴影
  static List<BoxShadow> get darkShadowsSmall => [
    BoxShadow(
      color: BAColors.darkShadow.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// 获取浅色主题小阴影
  static List<BoxShadow> get lightShadowsSmall => [
    BoxShadow(
      color: BAColors.lightShadow.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
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

  /// 毛玻璃效果模糊值
  static const double blurSigma = 10;
}
