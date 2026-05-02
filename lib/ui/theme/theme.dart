import 'package:flutter/material.dart';
import 'colors.dart';

/// BAMCLauncher 主题配置
///
/// 融合 Minecraft × 蔚蓝档案的清新桌面风格
/// 特点：
/// - 毛玻璃质感
/// - 柔和圆角
/// - 精致阴影
/// - 像素风点缀
class BamcTheme {
  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 配色方案
      colorScheme: ColorScheme.light(
        primary: BamcColors.primary,
        primaryContainer: BamcColors.primarySurface,
        secondary: BamcColors.secondary,
        secondaryContainer: BamcColors.secondarySurface,
        tertiary: BamcColors.accent,
        tertiaryContainer: BamcColors.accentSurface,
        error: BamcColors.error,
        errorContainer: BamcColors.errorSurface,
        surface: BamcColors.surface,
        surfaceContainerHighest: BamcColors.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: BamcColors.textPrimary,
        outline: BamcColors.border,
        outlineVariant: BamcColors.borderLight,
        shadow: BamcColors.shadow,
      ),
      
      // 脚手架背景
      scaffoldBackgroundColor: BamcColors.background,
      
      // 文本主题 - 使用 Inter 字体
      textTheme: const TextTheme(
        // 大标题
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: BamcColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        // 中标题
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: BamcColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        // 小标题
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        // 大标题
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        // 中标题
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
          height: 1.4,
        ),
        // 小标题
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BamcColors.textSecondary,
          height: 1.4,
        ),
        // 大正文
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BamcColors.textPrimary,
          height: 1.6,
        ),
        // 中正文
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: BamcColors.textPrimary,
          height: 1.5,
        ),
        // 小正文
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: BamcColors.textSecondary,
          height: 1.5,
        ),
        // 大标签
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
          letterSpacing: 0.1,
        ),
        // 中标签
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
          letterSpacing: 0.1,
        ),
        // 小标签
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: BamcColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
      
      // 图标主题
      iconTheme: const IconThemeData(
        color: BamcColors.textSecondary,
        size: 20,
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BamcColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BamcColors.textDisabled,
          disabledForegroundColor: BamcColors.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BamcColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 轮廓按钮主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BamcColors.primary,
          side: const BorderSide(
            color: BamcColors.border,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BamcColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        
        // 边框样式
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.border,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.border,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.borderFocus,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: BamcColors.borderLight,
            width: 1.5,
          ),
        ),
        
        // 文本样式
        hintStyle: const TextStyle(
          color: BamcColors.textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: BamcColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: BamcColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        
        // 前缀/后缀图标
        prefixIconColor: BamcColors.textTertiary,
        suffixIconColor: BamcColors.textTertiary,
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        color: BamcColors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
      
      // 浮动操作按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BamcColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        hoverElevation: 4,
        focusElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary;
          }
          return BamcColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary.withValues(alpha: 0.3);
          }
          return BamcColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return BamcColors.borderLight;
        }),
      ),
      
      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BamcColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return BamcColors.textSecondary;
        }),
        side: const BorderSide(
          color: BamcColors.border,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: BamcColors.primary,
        inactiveTrackColor: BamcColors.border,
        thumbColor: BamcColors.primary,
        overlayColor: BamcColors.primary.withValues(alpha: 0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 16,
        ),
      ),
      
      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BamcColors.primary,
        linearMinHeight: 6,
        linearTrackColor: BamcColors.border,
        circularTrackColor: BamcColors.border,
      ),
      
      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: BamcColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BamcColors.textPrimary,
        ),
      ),
      
      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: BamcColors.surface,
        elevation: 8,
        shadowColor: BamcColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: BamcColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: BamcColors.textSecondary,
          height: 1.5,
        ),
      ),
      
      // 底部弹窗主题
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BamcColors.surface,
        elevation: 8,
        shadowColor: BamcColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      
      // 弹窗消息主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BamcColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: BamcColors.primaryLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 工具提示主题
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: BamcColors.textPrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: BamcColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // 菜单主题
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(BamcColors.surface),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(BamcColors.shadowMedium),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      
      // 标签栏主题
      tabBarTheme: const TabBarThemeData(
        labelColor: BamcColors.primary,
        unselectedLabelColor: BamcColors.textSecondary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: BamcColors.primary,
        dividerColor: BamcColors.divider,
        dividerHeight: 1,
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BamcColors.surface,
        elevation: 8,
        selectedItemColor: BamcColors.primary,
        unselectedItemColor: BamcColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
