import 'package:flutter/material.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import 'app_theme.dart';

/// 主题管理器，用于管理应用主题状态
class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;

  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = const Color(0xFF4A90D9);
  bool _useDynamicColor = true;
  bool _initialized = false;

  ThemeManager._internal();

  factory ThemeManager() {
    _instance ??= ThemeManager._internal();
    return _instance!;
  }

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;

  /// 获取当前主题的背景色（透明度基准）
  Color get backgroundColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFFF5F8FF)
        : const Color(0xFF0A0F1E);
  }

  /// 获取当前主题的表面色（透明度基准）
  Color get surfaceColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E2747);
  }

  /// 获取当前主题的边框色
  Color get borderColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFFD0D8EE)
        : const Color(0xFF3A4D7A);
  }

  /// 获取当前主题的文本主色
  Color get textPrimaryColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFF1A2744)
        : const Color(0xFFFFFFFF);
  }

  /// 获取当前主题的文本次色
  Color get textSecondaryColor {
    return _themeMode == ThemeMode.light
        ? const Color(0xFF5A6A8A)
        : const Color(0xFFA0B0C8);
  }

  /// 获取当前有效的主色（考虑莫奈取色）
  Color get currentPrimary {
    return _useDynamicColor ? _seedColor : const Color(0xFF4A90D9);
  }

  /// 根据主色生成毛玻璃背景色
  Color glassColor(double opacity) {
    final base = _themeMode == ThemeMode.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A2540);
    return base.withValues(alpha: opacity);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadTheme();
    _initialized = true;
  }

  Future<void> _loadTheme() async {
    final config = ConfigManager();
    await config.initialize();
    final savedTheme = config.getString(ConfigKeys.themeMode);
    final savedColor = config.getInt(ConfigKeys.themeColor);
    final savedUseDynamic = config.getBool(ConfigKeys.useDynamicColor);

    if (savedTheme != null) {
      _themeMode = _stringToThemeMode(savedTheme);
    }
    if (savedColor != null) {
      _seedColor = Color(savedColor);
    }
    if (savedUseDynamic != null) {
      _useDynamicColor = savedUseDynamic;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final config = ConfigManager();
    await config.initialize();
    await config.setString(ConfigKeys.themeMode, _themeModeToString(mode));
  }

  Future<void> setSeedColor(Color color) async {
    if (_seedColor.value == color.value) return;

    _seedColor = color;
    _useDynamicColor = true;
    notifyListeners();

    final config = ConfigManager();
    await config.initialize();
    await config.setInt(ConfigKeys.themeColor, color.value);
    await config.setBool(ConfigKeys.useDynamicColor, true);
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;

    _useDynamicColor = value;
    notifyListeners();

    final config = ConfigManager();
    await config.initialize();
    await config.setBool(ConfigKeys.useDynamicColor, value);
  }

  ThemeData get currentTheme => BATheme.getTheme(_themeMode, seedColor: _useDynamicColor ? _seedColor : null);

  ThemeData get lightTheme => BATheme.lightTheme;

  ThemeData get darkTheme => BATheme.darkTheme;

  /// 获取当前模式的主题（考虑动态颜色）
  ThemeData get themeByMode {
    return BATheme.getTheme(_themeMode, seedColor: _useDynamicColor ? _seedColor : null);
  }

  static ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
