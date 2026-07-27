import 'package:flutter/material.dart';
import 'settings_theme.dart';

/// 设置面板分组分隔标题（如 "通用设置"、"关于"）
class SectionSeparator extends StatelessWidget {
  final String label;

  const SectionSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: SettingsPalette.textPrimary(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
