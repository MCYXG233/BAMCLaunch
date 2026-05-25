import 'package:flutter/material.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import 'app_theme.dart';

/// 主题管理器，用于管理应用主题状态
class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;

  ThemeMode _themeMode = ThemeMode.dark;
  bool _initialized = false;

  ThemeManager._internal();

  factory ThemeManager() {
    _instance ??= ThemeManager._internal();
    return _instance!;
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadTheme();
    _initialized = true;
  }

  Future<void> _loadTheme() async {
    final config = ConfigManager();
    await config.initialize();
    final savedTheme = config.getString(ConfigKeys.themeMode);
    
    if (savedTheme != null) {
      _themeMode = _stringToThemeMode(savedTheme);
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

  ThemeData get currentTheme => BATheme.getTheme(_themeMode);

  ThemeData get lightTheme => BATheme.lightTheme;

  ThemeData get darkTheme => BATheme.darkTheme;

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
