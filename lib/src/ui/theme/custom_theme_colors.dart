import 'package:flutter/material.dart';

/// 自定义主题颜色模型
/// 存储用户在设置中自定义的主色调
/// 自动生成浅色/深色变体
class CustomThemeColors {
  /// 蔚蓝档案主题预设方案（8个）
  static const List<PresetColor> blueArchivePresets = [
    PresetColor(name: '蔚蓝档案', primaryValue: 0xFF4A90D9),
    PresetColor(name: '樱花粉', primaryValue: 0xFFFF6B9D),
    PresetColor(name: '薄荷绿', primaryValue: 0xFF4ECDC4),
    PresetColor(name: '暗夜紫', primaryValue: 0xFF7B68EE),
    PresetColor(name: '琥珀橙', primaryValue: 0xFFFF8C42),
    PresetColor(name: '翡翠绿', primaryValue: 0xFF2ECC71),
    PresetColor(name: '玫瑰红', primaryValue: 0xFFE74C3C),
    PresetColor(name: '星空蓝', primaryValue: 0xFF2C3E50),
  ];

  /// Minecraft主题预设方案（8个）
  static const List<PresetColor> minecraftPresets = [
    PresetColor(name: '草方块绿', primaryValue: 0xFF4A752C),
    PresetColor(name: '天空蓝', primaryValue: 0xFF7EB5F6),
    PresetColor(name: '红石红', primaryValue: 0xFFC41E1E),
    PresetColor(name: '末地紫', primaryValue: 0xFF8B5CF6),
    PresetColor(name: '钻石青', primaryValue: 0xFF64C8C8),
    PresetColor(name: '下界橙', primaryValue: 0xFFFF6B35),
    PresetColor(name: '金锭黄', primaryValue: 0xFFFFD700),
    PresetColor(name: '海晶石', primaryValue: 0xFF3DDC84),
  ];

  /// 蔚蓝档案 - 浅色模式的主色调（hex value）
  final int blueArchiveLight;
  /// 蔚蓝档案 - 深色模式的主色调
  final int blueArchiveDark;
  /// Minecraft - 浅色模式的主色调
  final int minecraftLight;
  /// Minecraft - 深色模式的主色调
  final int minecraftDark;

  const CustomThemeColors({
    this.blueArchiveLight = 0xFF4A90D9,
    this.blueArchiveDark = 0xFF4A90D9,
    this.minecraftLight = 0xFF4A752C,
    this.minecraftDark = 0xFF4A752C,
  });

  /// 获取指定主题+模式的主色
  Color getPrimary(String theme, Brightness brightness) {
    return Color(_getValue(theme, brightness));
  }

  /// 获取指定主题+模式的浅色变体（自动从主色派生）
  Color getPrimaryLight(String theme, Brightness brightness) {
    final hsl = HSLColor.fromColor(getPrimary(theme, brightness));
    final lighter = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0));
    return lighter.toColor();
  }

  /// 获取指定主题+模式的深色变体（自动从主色派生）
  Color getPrimaryDark(String theme, Brightness brightness) {
    final hsl = HSLColor.fromColor(getPrimary(theme, brightness));
    final darker = hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0));
    return darker.toColor();
  }

  int _getValue(String theme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    if (theme == 'minecraft') {
      return isLight ? minecraftLight : minecraftDark;
    }
    return isLight ? blueArchiveLight : blueArchiveDark;
  }

  CustomThemeColors copyWith({
    int? blueArchiveLight,
    int? blueArchiveDark,
    int? minecraftLight,
    int? minecraftDark,
  }) {
    return CustomThemeColors(
      blueArchiveLight: blueArchiveLight ?? this.blueArchiveLight,
      blueArchiveDark: blueArchiveDark ?? this.blueArchiveDark,
      minecraftLight: minecraftLight ?? this.minecraftLight,
      minecraftDark: minecraftDark ?? this.minecraftDark,
    );
  }

  /// 序列化为 JSON 字符串用于 SharedPreferences
  String toJsonString() {
    final map = <String, int>{
      'blueArchiveLight': blueArchiveLight,
      'blueArchiveDark': blueArchiveDark,
      'minecraftLight': minecraftLight,
      'minecraftDark': minecraftDark,
    };
    final parts = map.entries.map((e) => '${e.key}:${e.value}').join(',');
    return parts;
  }

  /// 从 JSON 字符串反序列化
  factory CustomThemeColors.fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const CustomThemeColors();
    final map = <String, int>{};
    for (final pair in raw.split(',')) {
      final idx = pair.indexOf(':');
      if (idx <= 0) continue;
      final key = pair.substring(0, idx);
      final val = int.tryParse(pair.substring(idx + 1));
      if (val != null) map[key] = val;
    }
    return CustomThemeColors(
      blueArchiveLight: map['blueArchiveLight'] ?? 0xFF4A90D9,
      blueArchiveDark: map['blueArchiveDark'] ?? 0xFF4A90D9,
      minecraftLight: map['minecraftLight'] ?? 0xFF4A752C,
      minecraftDark: map['minecraftDark'] ?? 0xFF4A752C,
    );
  }

  /// 是否为默认值
  bool get isDefault =>
      blueArchiveLight == 0xFF4A90D9 &&
      blueArchiveDark == 0xFF4A90D9 &&
      minecraftLight == 0xFF4A752C &&
      minecraftDark == 0xFF4A752C;
}

/// 预设颜色项
class PresetColor {
  final String name;
  final int primaryValue;

  const PresetColor({
    required this.name,
    required this.primaryValue,
  });

  Color get color => Color(primaryValue);
}