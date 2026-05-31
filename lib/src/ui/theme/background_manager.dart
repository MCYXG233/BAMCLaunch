import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../config/background_config.dart';

class BackgroundManager extends ChangeNotifier {
  static BackgroundManager? _instance;
  final ConfigManager _configManager = ConfigManager();
  
  BackgroundConfig _currentConfig = BackgroundConfig.classic;
  
  BackgroundManager._internal();
  
  static BackgroundManager get instance {
    _instance ??= BackgroundManager._internal();
    return _instance!;
  }
  
  factory BackgroundManager() => instance;
  
  BackgroundConfig get currentConfig => _currentConfig;
  
  Future<void> initialize() async {
    await loadBackgroundConfig();
  }
  
  Future<void> loadBackgroundConfig() async {
    try {
      final jsonStr = _configManager.getString(ConfigKeys.backgroundChoice);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _currentConfig = BackgroundConfig.fromJson(json);
      }
    } catch (e) {
      _currentConfig = BackgroundConfig.classic;
    }
    notifyListeners();
  }
  
  Future<void> saveBackgroundConfig(BackgroundConfig config) async {
    try {
      final jsonStr = jsonEncode(config.toJson());
      await _configManager.setString(ConfigKeys.backgroundChoice, jsonStr);
      _currentConfig = config;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save background config: $e');
    }
  }
  
  Widget buildBackground({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: _getDecoration(),
      child: child,
    );
  }
  
  BoxDecoration _getDecoration() {
    switch (_currentConfig.type) {
      case BackgroundType.solid:
        return BoxDecoration(
          color: _currentConfig.solidColor != null
              ? Color(_currentConfig.solidColor!).withOpacity(_currentConfig.opacity)
              : Colors.white.withOpacity(_currentConfig.opacity),
        );
        
      case BackgroundType.gradient:
        final colors = _currentConfig.gradientColors
            ?.map((c) => Color(c).withOpacity(_currentConfig.opacity))
            .toList() ?? [Colors.white, Colors.grey.shade200];
        return BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: _getAlignment(_currentConfig.alignment),
            end: Alignment.bottomRight,
          ),
        );
        
      case BackgroundType.image:
        return BoxDecoration(
          color: Color(0xFFF8F9FF).withOpacity(_currentConfig.opacity),
          image: _currentConfig.imagePath != null
              ? DecorationImage(
                  image: FileImage(File(_currentConfig.imagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        );
        
      case BackgroundType.blur:
        return BoxDecoration(
          color: Colors.white.withOpacity(_currentConfig.opacity * 0.5),
        );
    }
  }
  
  Alignment _getAlignment(int? alignment) {
    switch (alignment) {
      case 0:
        return Alignment.topLeft;
      case 1:
        return Alignment.topCenter;
      case 2:
        return Alignment.topRight;
      case 3:
        return Alignment.centerLeft;
      case 4:
        return Alignment.center;
      case 5:
        return Alignment.centerRight;
      case 6:
        return Alignment.bottomLeft;
      case 7:
        return Alignment.bottomCenter;
      case 8:
        return Alignment.bottomRight;
      default:
        return Alignment.topLeft;
    }
  }
}
