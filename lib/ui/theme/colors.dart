import 'package:flutter/material.dart';

/// BAMCLauncher 配色系统
///
/// 融合 Minecraft × 蔚蓝档案的清新桌面风格
/// 配色原则：
/// - 柔和清新，杜绝纯黑纯白
/// - 低饱和度，降低视觉疲劳
/// - 毛玻璃质感，通透感
class BamcColors {
  // ==================== 主色调 - 蔚蓝档案风格 ====================
  
  /// 主色 - 清新蓝
  static const Color primary = Color(0xFF5BA4E6);
  static const Color primaryLight = Color(0xFF8BC4F0);
  static const Color primaryDark = Color(0xFF3D8FD9);
  static const Color primarySurface = Color(0xFFE8F2FC);
  
  /// 主色渐变
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );
  
  /// 主色柔和渐变（用于背景）
  static const Gradient primarySoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F2FC),
      Color(0xFFF0F7FF),
    ],
  );

  // ==================== 辅助色 - Minecraft 风格 ====================
  
  /// 辅助色 - 草方块绿
  static const Color secondary = Color(0xFF6AAF3B);
  static const Color secondaryLight = Color(0xFF8BC765);
  static const Color secondaryDark = Color(0xFF529A2A);
  static const Color secondarySurface = Color(0xFFEDF7E6);
  
  /// 辅助色渐变
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary, secondaryDark],
  );

  // ==================== 强调色 ====================
  
  /// 强调色 - 蔚蓝档案粉（用于高亮、选中）
  static const Color accent = Color(0xFFE8A0BF);
  static const Color accentLight = Color(0xFFF0C0D5);
  static const Color accentDark = Color(0xFFD480A5);
  static const Color accentSurface = Color(0xFFFDF0F5);

  // ==================== 语义色 ====================
  
  /// 成功色 - 金块黄（柔和）
  static const Color success = Color(0xFFE8C547);
  static const Color successLight = Color(0xFFF0D870);
  static const Color successDark = Color(0xFFD4AD30);
  static const Color successSurface = Color(0xFFFBF5E0);
  
  /// 成功色渐变
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success, successDark],
  );
  
  /// 警告色 - 红石红（柔和）
  static const Color warning = Color(0xFFE07050);
  static const Color warningLight = Color(0xFFE89080);
  static const Color warningDark = Color(0xFFD05040);
  static const Color warningSurface = Color(0xFFFDF0EC);
  
  /// 警告色渐变
  static const Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningLight, warning, warningDark],
  );
  
  /// 错误色
  static const Color error = Color(0xFFE07050);
  static const Color errorLight = Color(0xFFE89080);
  static const Color errorDark = Color(0xFFD05040);
  static const Color errorSurface = Color(0xFFFDF0EC);
  
  /// 危险色（别名）
  static const Color danger = Color(0xFFE07050);
  static const Color dangerLight = Color(0xFFE89080);
  static const Color dangerDark = Color(0xFFD05040);
  static const Color dangerSurface = Color(0xFFFDF0EC);
  
  /// 信息色
  static const Color info = Color(0xFF5BA4E6);
  static const Color infoLight = Color(0xFF8BC4F0);
  static const Color infoDark = Color(0xFF3D8FD9);
  static const Color infoSurface = Color(0xFFE8F2FC);

  // ==================== 中性色 - 柔和米白、低饱和灰 ====================
  
  /// 背景色
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundLight = Color(0xFFFAFBFD);
  static const Color backgroundDark = Color(0xFFEDF0F5);
  
  /// 表面色
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFBFD);
  static const Color surfaceDark = Color(0xFFF0F2F5);
  
  /// 卡片色
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF8FAFC);
  static const Color cardActive = Color(0xFFF0F4F8);
  
  /// 文本色 - 杜绝纯黑
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C9B);
  static const Color textTertiary = Color(0xFFB0BEC5);
  static const Color textDisabled = Color(0xFFCFD8DC);
  static const Color textInverse = Color(0xFFFFFFFF);
  
  /// 边框色
  static const Color border = Color(0xFFE8ECF0);
  static const Color borderLight = Color(0xFFF0F2F5);
  static const Color borderHover = Color(0xFF5BA4E6);
  static const Color borderFocus = Color(0xFF5BA4E6);
  
  /// 分割线
  static const Color divider = Color(0xFFE8ECF0);
  static const Color dividerLight = Color(0xFFF0F2F5);
  
  /// 阴影色
  static const Color shadow = Color(0x0A000000);
  static const Color shadowLight = Color(0x05000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowHeavy = Color(0x1F000000);
  static const Color shadowHover = Color(0x1A000000);
  
  /// 毛玻璃效果
  static const Color glassBackground = Color(0xF0FFFFFF);
  static const Color glassBackgroundDark = Color(0xF02C3E50);
  static const Color glassBorder = Color(0x20000000);
  
  /// 遮罩层
  static const Color overlay = Color(0x40000000);
  static const Color overlayLight = Color(0x20000000);

  // ==================== 像素风格点缀 ====================
  
  /// 像素边框
  static const Color pixelBorder = Color(0xFF2C3E50);
  static const Color pixelAccent = Color(0xFFE07050);
  
  /// 透明色
  static const Color transparent = Colors.transparent;

  // ==================== 渐变预设 ====================
  
  /// 欢迎横幅渐变 - 蔚蓝档案风格多层次渐变
  static const Gradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64B5F6),
      Color(0xFF42A5F5),
      Color(0xFF5C6BC0),
      Color(0xFF7E57C2),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
  
  /// 侧边栏渐变
  static const Gradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );
  
  /// 卡片悬浮渐变
  static const Gradient cardHoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F2FC),
      Color(0xFFF0F7FF),
    ],
  );

  /// 主内容区背景渐变
  static const Gradient contentBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFD),
      Color(0xFFF0F4F8),
    ],
  );

  /// 侧边栏选中项渐变 - 更丰富的蓝色过渡
  static const Gradient sidebarSelectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF5BA4E6),
      Color(0xFF42A5F5),
      Color(0xFF5C6BC0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Logo 区域渐变
  static const Gradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64B5F6),
      Color(0xFF42A5F5),
      Color(0xFF5C6BC0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 统计卡片渐变 - 主色
  static const Gradient statPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64B5F6),
      Color(0xFF42A5F5),
    ],
  );

  /// 统计卡片渐变 - 辅助色
  static const Gradient statSecondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF81C784),
      Color(0xFF66BB6A),
    ],
  );

  /// 统计卡片渐变 - 强调色
  static const Gradient statAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF48FB1),
      Color(0xFFEC407A),
    ],
  );

  // ==================== 工具方法 ====================
  
  /// 获取语义色
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
  
  /// 获取语义色表面色
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
