import 'dart:convert';

enum BackgroundType {
  solid,
  gradient,
  image,
  blur,
}

class BackgroundConfig {
  final BackgroundType type;
  final int? solidColor;
  final List<int>? gradientColors;
  final String? imagePath;
  final double blur;
  final double opacity;
  final int? alignment;

  const BackgroundConfig({
    required this.type,
    this.solidColor,
    this.gradientColors,
    this.imagePath,
    this.blur = 0.0,
    this.opacity = 1.0,
    this.alignment,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'solidColor': solidColor,
      'gradientColors': gradientColors,
      'imagePath': imagePath,
      'blur': blur,
      'opacity': opacity,
      'alignment': alignment,
    };
  }

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundConfig(
      type: BackgroundType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackgroundType.gradient,
      ),
      solidColor: json['solidColor'] as int?,
      gradientColors: (json['gradientColors'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      imagePath: json['imagePath'] as String?,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      alignment: json['alignment'] as int?,
    );
  }

  BackgroundConfig copyWith({
    BackgroundType? type,
    int? solidColor,
    List<int>? gradientColors,
    String? imagePath,
    double? blur,
    double? opacity,
    int? alignment,
  }) {
    return BackgroundConfig(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      imagePath: imagePath ?? this.imagePath,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      alignment: alignment ?? this.alignment,
    );
  }

  static BackgroundConfig get classic => const BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColors: [0xFFE0ECFF, 0xFFC9D8FF],
        blur: 0,
        opacity: 1.0,
        alignment: 0,
      );

  static BackgroundConfig get sakura => const BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColors: [0xFFFFE0E6, 0xFFFFB3C1],
        blur: 0,
        opacity: 1.0,
        alignment: 0,
      );

  static BackgroundConfig get night => const BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColors: [0xFF0D1B2A, 0xFF1B263B],
        blur: 0,
        opacity: 1.0,
        alignment: 0,
      );

  static BackgroundConfig get mint => const BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColors: [0xFFB8E6C9, 0xFF81C784],
        blur: 0,
        opacity: 1.0,
        alignment: 0,
      );

  static BackgroundConfig get sunset => const BackgroundConfig(
        type: BackgroundType.gradient,
        gradientColors: [0xFFFFCC80, 0xFFFF8A65],
        blur: 0,
        opacity: 1.0,
        alignment: 0,
      );
}
