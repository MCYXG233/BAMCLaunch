import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../di/service_locator.dart';
import 'app_theme.dart';
import 'colors.dart';
import 'custom_theme_colors.dart';

/// 主题管理器
/// 支持蔚蓝档案风格和Minecraft风格双主题
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _blueArchiveKey = 'blue_archive';
  static const String _minecraftKey = 'minecraft';
  static const String _customColorsKey = 'custom_colors';

  /// 单例实例
  static ThemeManager? _instance;

  /// 获取单例实例
  static ThemeManager get instance {
    return ServiceLocator.instance.tryGet<ThemeManager>() ??
        (_instance ??= ThemeManager._internal());
  }

  /// 工厂构造函数，返回单例实例
  factory ThemeManager() => instance;

  /// 私有构造函数
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.system;
  String _currentTheme = _blueArchiveKey;
  CustomThemeColors _customColors = const CustomThemeColors();

  ThemeMode get themeMode => _themeMode;
  String get currentTheme => _currentTheme;
  CustomThemeColors get customColors => _customColors;

  /// 初始化主题管理器
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? _blueArchiveKey;
    _currentTheme = savedTheme;
    BAColors.setScheme(savedTheme);

    final savedMode = prefs.getString('theme_mode');
    if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // 加载自定义颜色
    final savedColors = prefs.getString(_customColorsKey);
    if (savedColors != null && savedColors.isNotEmpty) {
      _customColors = CustomThemeColors.fromJsonString(savedColors);
      BAColors.setCustomColors(_customColors);
    }

    notifyListeners();
  }

  /// 获取当前主题的 ThemeData
  ThemeData getTheme(Brightness brightness) {
    if (_currentTheme == _minecraftKey) {
      return _getMinecraftTheme(brightness);
    } else {
      // 使用 BATheme 的完整主题定义
      return brightness == Brightness.light
          ? BATheme.buildLightTheme()
          : BATheme.buildDarkTheme();
    }
  }

  /// Minecraft主题
  ThemeData _getMinecraftTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: const Color(0xFF4A752C), // 草方块绿色
        secondary: const Color(0xFF8B4513), // 泥土棕色
        surface: isLight ? const Color(0xFFD7C9A8) : const Color(0xFF2D2D2D),
        error: const Color(0xFFB22222),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: isLight ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isLight ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Minecraft',
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight
            ? const Color(0xFFD7C9A8).withValues(alpha: 0.9)
            : const Color(0xFF2D2D2D).withValues(alpha: 0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Minecraft风格方角
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A752C),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? const Color(0xFFC4B896).withValues(alpha: 0.5)
            : const Color(0xFF3D3D3D).withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Color(0xFF8B7355),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Color(0xFF4A752C),
            width: 2,
          ),
        ),
      ),
    );
  }

  /// 切换主题
  Future<void> setTheme(String theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    BAColors.setScheme(theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    notifyListeners();
  }

  /// 切换到蔚蓝档案主题
  Future<void> setBlueArchiveTheme() async {
    await setTheme(_blueArchiveKey);
  }

  /// 切换到Minecraft主题
  Future<void> setMinecraftTheme() async {
    await setTheme(_minecraftKey);
  }

  /// 切换主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  /// 切换亮色/暗色模式
  Future<void> toggleBrightness() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// 是否是蔚蓝档案主题
  bool get isBlueArchive => _currentTheme == _blueArchiveKey;

  /// 是否是Minecraft主题
  bool get isMinecraft => _currentTheme == _minecraftKey;

  /// 设置自定义颜色
  Future<void> setCustomColors(CustomThemeColors colors) async {
    _customColors = colors;
    BAColors.setCustomColors(colors);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customColorsKey, colors.toJsonString());
    notifyListeners();
  }

  /// 恢复默认颜色
  Future<void> resetCustomColors() async {
    _customColors = const CustomThemeColors();
    BAColors.setCustomColors(_customColors);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customColorsKey);
    notifyListeners();
  }

  /// 单独设置某个主题+模式的主色（便捷方法）
  Future<void> setPrimaryColor({
    required String theme,
    required Brightness brightness,
    required int colorValue,
  }) async {
    final isLight = brightness == Brightness.light;
    final updated = theme == _minecraftKey
        ? _customColors.copyWith(
            minecraftLight: isLight ? colorValue : null,
            minecraftDark: !isLight ? colorValue : null,
          )
        : _customColors.copyWith(
            blueArchiveLight: isLight ? colorValue : null,
            blueArchiveDark: !isLight ? colorValue : null,
          );
    await setCustomColors(updated);
  }
}
