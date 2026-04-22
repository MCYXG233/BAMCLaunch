import 'package:flutter/material.dart';
import 'colors.dart';

class BamcTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: BamcColors.primary,
      primaryColorLight: BamcColors.primaryLight,
      primaryColorDark: BamcColors.primaryDark,
      backgroundColor: BamcColors.background,
      scaffoldBackgroundColor: BamcColors.background,

      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        backgroundColor: BamcColors.background,
      ).copyWith(
        secondary: BamcColors.secondary,
        error: BamcColors.warning,
        surface: BamcColors.surface,
      ),

      // 文本主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: BamcColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: BamcColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: BamcColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: BamcColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: BamcColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: BamcColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BamcColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BamcColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BamcColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BamcColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BamcColors.warning,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BamcColors.warning,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: BamcColors.textSecondary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: BamcColors.textPrimary,
          fontSize: 14,
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: BamcColors.card,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: BamcColors.divider,
        thickness: 1,
        space: 0,
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: BamcColors.textPrimary,
        size: 24,
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BamcColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary.withOpacity(0.3);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),

      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return BamcColors.textPrimary;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: BamcColors.primary,
        inactiveTrackColor: BamcColors.border,
        thumbColor: BamcColors.primary,
        overlayColor: BamcColors.primary.withOpacity(0.1),
        trackHeight: 4,
      ),

      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BamcColors.primary,
        linearMinHeight: 8,
      ),

      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: BamcColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BamcColors.surface,
        elevation: 8,
        selectedItemColor: BamcColors.primary,
        unselectedItemColor: BamcColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),

      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: BamcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
        elevation: 8,
      ),

      // 弹窗主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BamcColors.surface,
        contentTextStyle: const TextStyle(
          color: BamcColors.textPrimary,
        ),
        actionTextColor: BamcColors.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),

      // 时间选择器主题
      timePickerTheme: TimePickerThemeData(
        backgroundColor: BamcColors.surface,
        dialHandColor: BamcColors.primary,
        dialBackgroundColor: BamcColors.card,
        hourMinuteTextColor: BamcColors.textPrimary,
        dayPeriodTextColor: BamcColors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),

      // 日期选择器主题
      datePickerTheme: DatePickerThemeData(
        backgroundColor: BamcColors.surface,
        headerBackgroundColor: BamcColors.primary,
        headerForegroundColor: Colors.white,
        yearForegroundColor: BamcColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return BamcColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: BamcColors.border,
            width: 1,
          ),
        ),
      ),
    );
  }
}
