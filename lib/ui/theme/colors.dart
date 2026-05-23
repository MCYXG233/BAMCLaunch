import 'package:flutter/material.dart';

class BamcColors {
  // ==================== 主色调 - 星空蓝 ====================
  
  static const Color primary = Color(0xFF00A8FF);
  static const Color primaryLight = Color(0xFF5CB8FF);
  static const Color primaryDark = Color(0xFF0077B6);
  static const Color primarySurface = Color(0xFFE6F7FF);
  
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const Gradient primarySoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE6F7FF),
      Color(0xFFF0F9FF),
    ],
  );

  // ==================== 辅助色 - 科技青 ====================
  
  static const Color secondary = Color(0xFF00E5CC);
  static const Color secondaryLight = Color(0xFF5CFFEB);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondarySurface = Color(0xFFE3FFFB);
  
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary, secondaryDark],
  );

  // ==================== 强调色 - 樱花粉 ====================
  
  static const Color accent = Color(0xFFFF6B9D);
  static const Color accentLight = Color(0xFFFFB3C6);
  static const Color accentDark = Color(0xFFE6396E);
  static const Color accentSurface = Color(0xFFFFF0F5);

  // ==================== 语义色 ====================
  
  static const Color success = Color(0xFF00E676);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color successDark = Color(0xFF00C853);
  static const Color successSurface = Color(0xFFE8F5E9);
  
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success, successDark],
  );
  
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningLight = Color(0xFFFFD740);
  static const Color warningDark = Color(0xFFFF9100);
  static const Color warningSurface = Color(0xFFFFF8E1);
  
  static const Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningLight, warning, warningDark],
  );
  
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFF8A80);
  static const Color errorDark = Color(0xFFE53935);
  static const Color errorSurface = Color(0xFFFFEBEE);
  
  static const Color danger = Color(0xFFFF5252);
  static const Color dangerLight = Color(0xFFFF8A80);
  static const Color dangerDark = Color(0xFFE53935);
  static const Color dangerSurface = Color(0xFFFFEBEE);
  
  static const Color info = Color(0xFF00A8FF);
  static const Color infoLight = Color(0xFF5CB8FF);
  static const Color infoDark = Color(0xFF0077B6);
  static const Color infoSurface = Color(0xFFE6F7FF);

  // ==================== 中性色 - 深邃夜空 ====================
  
  static const Color background = Color(0xFF0A1628);
  static const Color backgroundLight = Color(0xFF101F35);
  static const Color backgroundDark = Color(0xFF050D18);
  
  static const Color surface = Color(0xFF14213D);
  static const Color surfaceLight = Color(0xFF1A2B4A);
  static const Color surfaceDark = Color(0xFF0E1A2D);
  
  static const Color card = Color(0xFF1A2B4A);
  static const Color cardHover = Color(0xFF24385E);
  static const Color cardActive = Color(0xFF1E3A5F);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA3BF);
  static const Color textTertiary = Color(0xFF5A708C);
  static const Color textDisabled = Color(0xFF3D4F66);
  static const Color textInverse = Color(0xFF0A1628);
  
  static const Color border = Color(0xFF2A4365);
  static const Color borderLight = Color(0xFF1E3A5F);
  static const Color borderHover = Color(0xFF00A8FF);
  static const Color borderFocus = Color(0xFF00C8E6);
  
  static const Color divider = Color(0xFF2A4365);
  static const Color dividerLight = Color(0xFF1E3A5F);
  
  static const Color shadow = Color(0x20000000);
  static const Color shadowLight = Color(0x10000000);
  static const Color shadowMedium = Color(0x2A000000);
  static const Color shadowHeavy = Color(0x3F000000);
  static const Color shadowHover = Color(0x2A000000);
  
  static const Color glassBackground = Color(0x20FFFFFF);
  static const Color glassBackgroundDark = Color(0x200A1628);
  static const Color glassBorder = Color(0x30FFFFFF);
  
  static const Color overlay = Color(0x60000000);
  static const Color overlayLight = Color(0x30000000);

  // ==================== 像素风格点缀 ====================
  
  static const Color pixelBorder = Color(0xFF0A1628);
  static const Color pixelAccent = Color(0xFFFF6B9D);
  
  static const Color transparent = Colors.transparent;

  // ==================== 渐变预设 ====================
  
  static const Gradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A8FF),
      Color(0xFF0077B6),
      Color(0xFF4361EE),
      Color(0xFF7209B7),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const Gradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF14213D),
      Color(0xFF0E1A2D),
    ],
  );

  static const Gradient cardHoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF24385E),
      Color(0xFF1A2B4A),
    ],
  );

  static const Gradient contentBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1628),
      Color(0xFF050D18),
    ],
  );

  static const Gradient sidebarSelectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00A8FF),
      Color(0xFF0077B6),
      Color(0xFF4361EE),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A8FF),
      Color(0xFF00C8E6),
      Color(0xFF00E5CC),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient statPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A8FF),
      Color(0xFF0077B6),
    ],
  );

  static const Gradient statSecondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00E5CC),
      Color(0xFF00B894),
    ],
  );

  static const Gradient statAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B9D),
      Color(0xFFE6396E),
    ],
  );

  static const Gradient backgroundStarsGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1628),
      Color(0xFF050D18),
    ],
  );

  // ==================== 工具方法 ====================
  
  static Color getSemanticColor(String type) {
    switch (type) {
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'error':
      case 'danger':
        return error;
      case 'info':
        return info;
      default:
        return primary;
    }
  }
  
  static Color getSemanticSurfaceColor(String type) {
    switch (type) {
      case 'success':
        return successSurface;
      case 'warning':
        return warningSurface;
      case 'error':
      case 'danger':
        return errorSurface;
      case 'info':
        return infoSurface;
      default:
        return primarySurface;
    }
  }
}