import 'package:flutter/material.dart';

class BamcColors {
  // 主色调 - 蔚蓝档案风格
  static const Color primary = Color(0xFF64B5F6); // 蔚蓝档案经典清新蓝
  static const Color primaryLight = Color(0xFF90CAF9);
  static const Color primaryDark = Color(0xFF42A5F5);
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  // 辅助色 - Minecraft风格
  static const Color secondary = Color(0xFF7CB342); // MC草方块绿
  static const Color secondaryLight = Color(0xFFAED581);
  static const Color secondaryDark = Color(0xFF689F38);
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary, secondaryDark],
  );

  // 强调色 - 融合风格
  static const Color accent = Color(0xFFF8BBD0); // 蔚蓝档案粉
  static const Color accentLight = Color(0xFFFCE4EC);
  static const Color accentDark = Color(0xFFF48FB1);
  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );

  // 警告色
  static const Color warning = Color(0xFFE53935); // MC红石红
  static const Color warningLight = Color(0xFFEF5350);
  static const Color warningDark = Color(0xFFD32F2F);
  static const Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningLight, warning, warningDark],
  );

  // 错误色
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFD32F2F);

  // 危险色
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFEF5350);
  static const Color dangerDark = Color(0xFFD32F2F);

  // 信息色
  static const Color info = Color(0xFF64B5F6);
  static const Color infoLight = Color(0xFF90CAF9);
  static const Color infoDark = Color(0xFF42A5F5);

  // 成功色
  static const Color success = Color(0xFFFDD835); // MC金块黄
  static const Color successLight = Color(0xFFFFEB3B);
  static const Color successDark = Color(0xFFFBC02D);
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success, successDark],
  );

  // 中性色 - 柔和米白、低饱和浅灰/深灰
  static const Color background = Color(0xFFF8F9FA); // 柔和米白
  static const Color surface = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFAFAFA);
  static const Color cardHover = Color(0xFFF0F4F8);
  
  static const Color textPrimary = Color(0xFF333333); // 低饱和深灰，杜绝纯黑
  static const Color textSecondary = Color(0xFF666666); // 低饱和中灰
  static const Color textTertiary = Color(0xFF999999); // 低饱和浅灰
  static const Color textDisabled = Color(0xFFBDBDBD);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderHover = Color(0xFF64B5F6);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowHover = Color(0x33000000);

  // 毛玻璃效果背景色
  static const Color glassBackground = Color(0xCCF8F9FA);
  static const Color glassBackgroundDark = Color(0xCC333333);

  // 像素风格颜色
  static const Color pixelBorder = Color(0xFF333333);
  static const Color pixelAccent = Color(0xFFFF6B6B);

  // 透明色
  static const Color transparent = Colors.transparent;

  // 动画相关颜色
  static const Color animationStart = Color(0xFF64B5F6);
  static const Color animationEnd = Color(0xFF7CB342);
}