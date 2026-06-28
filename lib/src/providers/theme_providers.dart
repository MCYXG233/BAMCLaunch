import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式枚举扩展
enum AppThemeMode {
  system,
  light,
  dark,
  blueArchive,
}

/// 主题状态管理
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system);

  /// 切换主题模式
  void setTheme(AppThemeMode mode) {
    state = mode;
  }

  /// 获取对应的 ThemeMode
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.blueArchive:
        return ThemeMode.dark;
    }
  }
}

/// 主题 Provider
/// 
/// 管理应用主题模式
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// 当前 ThemeData Provider
///
/// 根据主题模式返回对应的 ThemeData
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);

  switch (themeMode) {
    case AppThemeMode.blueArchive:
      return _blueArchiveTheme;
    case AppThemeMode.dark:
      return ThemeData.dark();
    case AppThemeMode.light:
      return ThemeData.light();
    case AppThemeMode.system:
      return ThemeData.light();
  }
});

/// 蔚蓝档案风格主题
final ThemeData _blueArchiveTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4A90D9),
    secondary: Color(0xFFE8B84A),
    surface: Color(0xFF1A1A2E),
  ),
  scaffoldBackgroundColor: const Color(0xFF16213E),
  cardColor: const Color(0xFF1F3460),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFFFFFFF)),
    displayMedium: TextStyle(color: Color(0xFFFFFFFF)),
    bodyLarge: TextStyle(color: Color(0xFFE8E8E8)),
    bodyMedium: TextStyle(color: Color(0xFFB8B8B8)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F3460),
    foregroundColor: Color(0xFFFFFFFF),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4A90D9),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1F3460),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF4A90D9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE8B84A)),
    ),
  ),
);
