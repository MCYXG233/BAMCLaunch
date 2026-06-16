import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// 蔚蓝档案（Blue Archive）UI 主题数据
///
/// 本类提供完整的 Flutter [ThemeData] 配置，完全按照蔚蓝档案的视觉风格设计。
/// 支持莫奈取色（Monet）动态主题：通过 seedColor 自动生成整套配色方案。
///
/// 设计风格特点：
/// - **清新明亮的配色**：以天蓝色为主色调，搭配樱花粉色作为辅助色
/// - **圆润柔和的形状**：大量使用圆角设计，营造亲和力
/// - **轻盈的视觉层次**：低对比度配色、柔和阴影、半透明效果
///
/// 使用示例：
/// ```dart
/// MaterialApp(
///   theme: BATheme.lightTheme,
///   darkTheme: BATheme.darkTheme,
///   themeMode: ThemeMode.system,
/// )
/// ```
class BATheme {
  /// 向后兼容：获取默认主题数据（浅色）
  static ThemeData get theme => lightTheme;

  /// 获取深色主题数据（支持莫奈取色动态主题）
  ///
  /// 参数 [seedColor]：可选的动态主题色，传 null 则使用蔚蓝档案默认天蓝色
  static ThemeData buildDarkTheme({Color? seedColor}) {
    final Color primary = seedColor ?? BAColors.primary;
    return ThemeData(
      useMaterial3: true,
      colorScheme: _buildColorScheme(Brightness.dark, primary),
      scaffoldBackgroundColor: BAColors.darkBackground,
      cardColor: BAColors.darkSurface,
      textTheme: _textTheme,
      iconTheme: _darkIconTheme,
      dividerTheme: _darkDividerTheme,
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
            return primary;
          }
          return BAColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.3);
          }
          return BAColors.darkSurfaceVariant;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: BAColors.darkSurfaceVariant,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
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
        selectedColor: primary.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: BAColors.darkBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
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
            return primary;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: BAColors.darkSurfaceVariant,
        circularTrackColor: BAColors.darkSurfaceVariant,
        color: primary,
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
      appBarTheme: AppBarTheme(
        backgroundColor: BAColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: BATypography.titleBar.copyWith(
          color: BAColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: BAColors.darkTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BAColors.darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: BAColors.darkTextSecondary,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BAColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(color: BAColors.darkTextDisabled, fontSize: 14),
        labelStyle: const TextStyle(color: BAColors.darkTextSecondary, fontSize: 14),
        errorStyle: const TextStyle(color: BAColors.danger, fontSize: 12),
      ),
    );
  }

  /// 获取浅色主题数据（支持莫奈取色动态主题）
  ///
  /// 参数 [seedColor]：可选的动态主题色，传 null 则使用蔚蓝档案默认天蓝色
  static ThemeData buildLightTheme({Color? seedColor}) {
    final Color primary = seedColor ?? BAColors.primary;
    return ThemeData(
      useMaterial3: true,
      colorScheme: _buildColorScheme(Brightness.light, primary),
      scaffoldBackgroundColor: BAColors.lightBackground,
      cardColor: BAColors.lightSurface,
      textTheme: _textTheme,
      iconTheme: _lightIconTheme,
      dividerTheme: _lightDividerTheme,
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
            return primary;
          }
          return BAColors.lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.3);
          }
          return BAColors.lightSurfaceVariant;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: BAColors.lightSurfaceVariant,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
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
        selectedColor: primary.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: BAColors.lightBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
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
            return primary;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: BAColors.lightSurfaceVariant,
        circularTrackColor: BAColors.lightSurfaceVariant,
        color: primary,
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
      appBarTheme: AppBarTheme(
        backgroundColor: BAColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: BATypography.titleBar.copyWith(
          color: BAColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: BAColors.lightTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BAColors.lightSurface,
        selectedItemColor: primary,
        unselectedItemColor: BAColors.lightTextSecondary,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BAColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BAColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(color: BAColors.lightTextDisabled, fontSize: 14),
        labelStyle: const TextStyle(color: BAColors.lightTextSecondary, fontSize: 14),
        errorStyle: const TextStyle(color: BAColors.danger, fontSize: 12),
      ),
    );
  }

  /// 向后兼容：获取默认深色主题
  static ThemeData get darkTheme => buildDarkTheme();

  /// 向后兼容：获取默认浅色主题
  static ThemeData get lightTheme => buildLightTheme();

  /// 获取指定主题模式的主题数据（支持莫奈取色动态主题）
  ///
  /// 参数：
  /// - [mode]: 主题模式（light/dark/system）
  /// - [seedColor]: 可选的动态主题色，传 null 则使用蔚蓝档案默认天蓝色
  static ThemeData getTheme(ThemeMode mode, {Color? seedColor}) {
    switch (mode) {
      case ThemeMode.light:
        return buildLightTheme(seedColor: seedColor);
      case ThemeMode.dark:
        return buildDarkTheme(seedColor: seedColor);
      case ThemeMode.system:
        return buildLightTheme(seedColor: seedColor);
    }
  }

  /// 生成颜色方案（支持莫奈取色动态主题）
  ///
  /// 如果提供 [seedColor]，则使用 Material You 的动态颜色方案生成。
  /// 否则使用蔚蓝档案的默认固定配色。
  static ColorScheme _buildColorScheme(Brightness brightness, Color? seedColor) {
    final basePrimary = seedColor ?? BAColors.primary;
    final isDark = brightness == Brightness.dark;

    // 生成基于 seed 的柔和配色（莫奈取色风格）
    final hsl = HSLColor.fromColor(basePrimary);
    final primary = basePrimary;
    final primaryLight = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    final primaryDark = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    // 辅助色（粉色系，蔚蓝档案风格）
    final secondaryHsl = HSLColor.fromColor(const Color(0xFFFFB4C2));
    final secondary = secondaryHsl.toColor();
    final secondaryDark = secondaryHsl.withLightness((secondaryHsl.lightness - 0.15).toDouble()).toColor();

    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryDark,
        onSecondaryContainer: Colors.white,
        error: BAColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFF4A1F1F),
        onErrorContainer: const Color(0xFFFFCDD2),
        surface: BAColors.darkSurface,
        onSurface: BAColors.darkTextPrimary,
        surfaceVariant: BAColors.darkSurfaceVariant,
        onSurfaceVariant: BAColors.darkTextSecondary,
        outline: BAColors.darkBorder,
        shadow: BAColors.darkShadow,
        background: BAColors.darkBackground,
        onBackground: BAColors.darkTextPrimary,
        surfaceTint: primary,
      );
    } else {
      return ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: const Color(0xFF1A2744),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFFFD1D8),
        onSecondaryContainer: const Color(0xFF1A2744),
        error: BAColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFCDD2),
        onErrorContainer: const Color(0xFFB71C1C),
        surface: BAColors.lightSurface,
        onSurface: BAColors.lightTextPrimary,
        surfaceVariant: BAColors.lightSurfaceVariant,
        onSurfaceVariant: BAColors.lightTextSecondary,
        outline: BAColors.lightBorder,
        shadow: BAColors.lightShadow,
        background: BAColors.lightBackground,
        onBackground: BAColors.lightTextPrimary,
        surfaceTint: primary,
      );
    }
  }

  /// 深色主题颜色方案（兼容旧代码）
  static ColorScheme get _darkColorScheme => _buildColorScheme(Brightness.dark, null);

  /// 浅色主题颜色方案（兼容旧代码）
  static ColorScheme get _lightColorScheme => _buildColorScheme(Brightness.light, null);

  /// 文本主题（通用）
  ///
  /// 返回应用通用的 [TextTheme] 配置。
  /// 文本主题定义了各种文本样式的层级关系，
  /// 从大标题到小标签，形成完整的文本样式体系。
  ///
  /// 文本主题使用 [BATypography] 中定义的样式，
  /// 确保字体、大小、粗细等参数的一致性。
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
  ///
  /// 返回深色主题下输入框的 [InputDecorationTheme] 配置。
  /// 定义了输入框的填充色、边框样式、提示文本样式等。
  ///
  /// 深色输入框的特点：
  /// - 填充色采用深色表面变体色
  /// - 边框采用深色边框色，聚焦时显示主色调
  /// - 提示文本采用深色禁用文本色
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
  ///
  /// 返回浅色主题下输入框的 [InputDecorationTheme] 配置。
  /// 这是蔚蓝档案风格输入框的核心样式定义。
  ///
  /// 浅色输入框的特点：
  /// - 填充色采用浅色表面变体色，营造柔和的背景
  /// - 边框采用浅色边框色，聚焦时显示天蓝色主色调
  /// - 圆角设计，符合蔚蓝档案的圆润风格
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
  ///
  /// 返回深色主题下图标的标准样式配置。
  /// 定义了图标的颜色和默认大小。
  static IconThemeData get _darkIconTheme {
    return const IconThemeData(color: BAColors.darkTextPrimary, size: 24);
  }

  /// 浅色主题图标主题
  ///
  /// 返回浅色主题下图标的标准样式配置。
  /// 图标颜色采用主要文本色，确保与整体配色的一致性。
  static IconThemeData get _lightIconTheme {
    return const IconThemeData(color: BAColors.lightTextPrimary, size: 24);
  }

  /// 深色主题分割线主题
  ///
  /// 返回深色主题下分割线的样式配置。
  /// 定义了分割线的颜色、粗细和间距。
  static DividerThemeData get _darkDividerTheme {
    return const DividerThemeData(
      color: BAColors.darkBorder,
      thickness: 1,
      space: 1,
    );
  }

  /// 浅色主题分割线主题
  ///
  /// 返回浅色主题下分割线的样式配置。
  /// 分割线采用柔和的边框色，避免视觉干扰。
  static DividerThemeData get _lightDividerTheme {
    return const DividerThemeData(
      color: BAColors.lightBorder,
      thickness: 1,
      space: 1,
    );
  }

  /// 深色主题应用栏主题
  ///
  /// 返回深色主题下顶部应用栏（AppBar）的样式配置。
  /// 定义了应用栏的背景色、标题样式、图标颜色等。
  ///
  /// 深色应用栏的特点：
  /// - 背景色采用深色表面色
  /// - 无阴影（elevation: 0），保持简洁
  /// - 标题不居中，采用左对齐布局
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
  ///
  /// 返回浅色主题下顶部应用栏（AppBar）的样式配置。
  /// 这是蔚蓝档案风格应用栏的核心样式定义。
  ///
  /// 浅色应用栏的特点：
  /// - 背景色采用浅色表面色，与页面背景协调
  /// - 无阴影，营造轻盈的视觉感受
  /// - 标题采用标题栏样式，左对齐布局
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
  ///
  /// 返回深色主题下底部导航栏的样式配置。
  /// 定义了导航栏的背景色、选中/未选中项的颜色等。
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
  ///
  /// 返回浅色主题下底部导航栏的样式配置。
  /// 选中项采用天蓝色主色调，未选中项采用次要文本色。
  static BottomNavigationBarThemeData get _lightBottomNavBarTheme {
    return const BottomNavigationBarThemeData(
      backgroundColor: BAColors.lightSurface,
      selectedItemColor: BAColors.primary,
      unselectedItemColor: BAColors.lightTextSecondary,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
    );
  }

  // ==================== 圆角半径 ====================

  /// 标准圆角半径
  ///
  /// 返回蔚蓝档案风格的标准圆角 [BorderRadius]（16像素）。
  /// 这是应用中最常用的圆角值，用于卡片、按钮等大多数组件。
  static BorderRadius get borderRadius => BorderRadius.circular(16);

  /// 小圆角半径
  ///
  /// 返回较小的圆角 [BorderRadius]（10像素）。
  /// 用于小型组件如标签、小按钮、输入框等。
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(10);

  /// 中圆角半径
  ///
  /// 返回中等大小的圆角 [BorderRadius]（14像素）。
  /// 用于需要介于小圆角和标准圆角之间的组件。
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(14);

  /// 大圆角半径
  ///
  /// 返回较大的圆角 [BorderRadius]（20像素）。
  /// 用于大型组件如对话框、大卡片、底部弹窗等。
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(20);

  /// 超大圆角半径
  ///
  /// 返回超大的圆角 [BorderRadius]（28像素）。
  /// 用于特殊大型组件或需要更圆润效果的场景。
  static BorderRadius get borderRadiusExtraLarge => BorderRadius.circular(28);

  // ==================== 阴影效果 ====================

  /// 向后兼容：获取标准阴影（默认浅色）
  ///
  /// 此属性为向后兼容而保留，返回浅色主题的标准阴影。
  /// 建议使用 [lightShadows] 或 [darkShadows] 明确指定阴影类型，
  /// 或使用 [shadowsOf] 方法根据当前主题动态获取阴影。
  static List<BoxShadow> get shadows => lightShadows;

  /// 向后兼容：获取小阴影（默认浅色）
  ///
  /// 此属性为向后兼容而保留，返回浅色主题的小阴影。
  /// 建议使用 [lightShadowsSmall] 或 [darkShadowsSmall] 明确指定阴影类型。
  static List<BoxShadow> get shadowsSmall => lightShadowsSmall;

  /// 获取深色主题标准阴影
  ///
  /// 返回深色主题下组件的标准阴影效果。
  /// 深色阴影采用较深的阴影色，配合较大的模糊半径，
  /// 在深色背景上呈现明显的浮起效果。
  static List<BoxShadow> get darkShadows => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// 获取浅色主题标准阴影
  ///
  /// 返回浅色主题下组件的标准阴影效果。
  /// 蔚蓝档案风格的阴影特点：
  /// - 低透明度（6%），避免视觉干扰
  /// - 大模糊半径（16像素），营造柔和的浮起效果
  /// - 向下偏移（4像素），模拟自然光照
  static List<BoxShadow> get lightShadows => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// 获取深色主题小阴影
  ///
  /// 返回深色主题下组件的小型阴影效果。
  /// 用于需要轻微浮起效果的小型组件。
  static List<BoxShadow> get darkShadowsSmall => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// 获取浅色主题小阴影
  ///
  /// 返回浅色主题下组件的小型阴影效果。
  /// 用于小型卡片、按钮等需要轻微浮起效果的组件。
  static List<BoxShadow> get lightShadowsSmall => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// 获取深色主题大阴影
  ///
  /// 返回深色主题下组件的大型阴影效果。
  /// 用于对话框、底部弹窗等需要明显浮起效果的大型组件。
  static List<BoxShadow> get darkShadowsLarge => [
        BoxShadow(
          color: BAColors.darkShadow.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// 获取浅色主题大阴影
  ///
  /// 返回浅色主题下组件的大型阴影效果。
  /// 用于对话框、底部弹窗等需要明显浮起效果的大型组件。
  /// 阴影参数更大，营造更强的层次感。
  static List<BoxShadow> get lightShadowsLarge => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// 根据当前主题获取标准阴影
  ///
  /// 根据传入的 [BuildContext] 判断当前主题模式，
  /// 返回相应的标准阴影效果。
  ///
  /// 参数：
  /// - [context]: Flutter 构建上下文，用于获取当前主题信息
  ///
  /// 返回：
  /// - 浅色主题时返回 [lightShadows]
  /// - 深色主题时返回 [darkShadows]
  ///
  /// 使用示例：
  /// ```dart
  /// Container(
  ///   decoration: BoxDecoration(
  ///     boxShadow: BATheme.shadowsOf(context),
  ///   ),
  /// )
  /// ```
  static List<BoxShadow> shadowsOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadows : darkShadows;
  }

  /// 根据当前主题获取小阴影
  ///
  /// 根据传入的 [BuildContext] 判断当前主题模式，
  /// 返回相应的小阴影效果。
  ///
  /// 参数：
  /// - [context]: Flutter 构建上下文，用于获取当前主题信息
  ///
  /// 返回：
  /// - 浅色主题时返回 [lightShadowsSmall]
  /// - 深色主题时返回 [darkShadowsSmall]
  static List<BoxShadow> shadowsSmallOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadowsSmall : darkShadowsSmall;
  }

  /// 根据当前主题获取大阴影
  ///
  /// 根据传入的 [BuildContext] 判断当前主题模式，
  /// 返回相应的大阴影效果。
  ///
  /// 参数：
  /// - [context]: Flutter 构建上下文，用于获取当前主题信息
  ///
  /// 返回：
  /// - 浅色主题时返回 [lightShadowsLarge]
  /// - 深色主题时返回 [darkShadowsLarge]
  static List<BoxShadow> shadowsLargeOf(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightShadowsLarge : darkShadowsLarge;
  }

  // ==================== 毛玻璃效果 ====================

  /// 毛玻璃效果标准模糊值
  ///
  /// 用于毛玻璃效果的标准模糊强度（10）。
  /// 此值用于 [BackdropFilter] 的模糊参数。
  static const double blurSigma = 10;

  /// 毛玻璃效果轻量模糊值
  ///
  /// 用于毛玻璃效果的轻量模糊强度（5）。
  /// 用于需要更轻微模糊效果的场景。
  static const double blurSigmaLight = 5;
}