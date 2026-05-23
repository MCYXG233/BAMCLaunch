import 'package:flutter/material.dart';

class BamcColors {
  // ==================== 主色调 - 深空蓝 ====================
  
  static const Color primary = Color(0xFF00B4D8);
  static const Color primaryLight = Color(0xFF90E0EF);
  static const Color primaryDark = Color(0xFF023E8A);
  static const Color primarySurface = Color(0xFFCAF0F8);
  
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const Gradient primaryGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
      Color(0xFF48CAE4),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== 辅助色 - 霓虹青 ====================
  
  static const Color secondary = Color(0xFF00FF88);
  static const Color secondaryLight = Color(0xFF98FFE8);
  static const Color secondaryDark = Color(0xFF00CC6A);
  static const Color secondarySurface = Color(0xFFE8FFF3);
  
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

  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );

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
  
  static const Color info = Color(0xFF00B4D8);
  static const Color infoLight = Color(0xFF90E0EF);
  static const Color infoDark = Color(0xFF023E8A);
  static const Color infoSurface = Color(0xFFCAF0F8);

  // ==================== 中性色 - 深邃夜空 ====================
  
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundLight = Color(0xFF111827);
  static const Color backgroundDark = Color(0xFF050810);
  
  static const Color surface = Color(0xFF1A2332);
  static const Color surfaceLight = Color(0xFF243044);
  static const Color surfaceDark = Color(0xFF121927);
  
  static const Color card = Color(0xFF1E293B);
  static const Color cardHover = Color(0xFF2D3A4F);
  static const Color cardActive = Color(0xFF253248);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);
  static const Color textInverse = Color(0xFF0A0E1A);
  
  static const Color border = Color(0xFF334155);
  static const Color borderLight = Color(0xFF1E293B);
  static const Color borderHover = Color(0xFF00B4D8);
  static const Color borderFocus = Color(0xFF00D4FF);
  static const Color borderGlow = Color(0xFF00B4D8);
  
  static const Color divider = Color(0xFF334155);
  static const Color dividerLight = Color(0xFF1E293B);
  
  static const Color shadow = Color(0x40000000);
  static const Color shadowLight = Color(0x20000000);
  static const Color shadowMedium = Color(0x3A000000);
  static const Color shadowHeavy = Color(0x50000000);
  static const Color shadowHover = Color(0x3A000000);
  
  static const Color glassBackground = Color(0x15FFFFFF);
  static const Color glassBackgroundDark = Color(0x150A0E1A);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color glassBorderGlow = Color(0x4000B4D8);
  
  static const Color overlay = Color(0x70000000);
  static const Color overlayLight = Color(0x30000000);

  // ==================== 霓虹光效色 ====================
  
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonCyan = Color(0xFF00FFE5);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonPink = Color(0xFFFF6B9D);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonOrange = Color(0xFFFF9500);
  
  static const Color glowBlue = Color(0x3000D4FF);
  static const Color glowCyan = Color(0x3000FFE5);
  static const Color glowGreen = Color(0x3000FF88);
  static const Color glowPink = Color(0x30FF6B9D);
  static const Color glowPurple = Color(0x30A855F7);

  // ==================== 渐变预设 ====================
  
  static const Gradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
      Color(0xFF4361EE),
      Color(0xFF7209B7),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const Gradient welcomeGradientEnhanced = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
      Color(0xFF023E8A),
      Color(0xFF4361EE),
      Color(0xFF7209B7),
    ],
    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
  );

  static const Gradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A2332),
      Color(0xFF121927),
      Color(0xFF0A0E1A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient cardHoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D3A4F),
      Color(0xFF1E293B),
    ],
  );

  static const Gradient contentBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0E1A),
      Color(0xFF050810),
    ],
  );

  static const Gradient sidebarSelectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
      Color(0xFF4361EE),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF00D4FF),
      Color(0xFF00FFE5),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient statPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
    ],
  );

  static const Gradient statSecondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00FF88),
      Color(0xFF00CC6A),
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
      Color(0xFF0A0E1A),
      Color(0xFF050810),
    ],
  );

  static const Gradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  static const Gradient buttonGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
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