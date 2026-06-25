import 'package:flutter/material.dart';

/// Minecraft风格配色方案
///
/// 本类定义了 Minecraft 风格的配色系统，融合了：
/// - 草绿色（代表草地、树叶）
/// - 泥土棕（代表泥土、木材）
/// - 天蓝色（代表蓝天、水域）
/// - 石头灰（代表石头、矿物）
///
/// Minecraft 风格的配色特点：
/// - 低对比度、高明度的配色
/// - 大量使用圆角营造友好感
/// - 毛玻璃和半透明效果
/// - 柔和阴影
///
/// 使用方式：
/// ```dart
/// Container(
///   color: MCThemeColors.primary,
///   decoration: BoxDecoration(gradient: MCThemeColors.primaryGradient),
/// )
/// ```
class MCThemeColors {
  // ==================== 主色调（天蓝色 - 代表蓝天） ====================

  /// 主色调
  ///
  /// Minecraft 风格的核心品牌色（#7EB5F6），代表游戏中的蓝天和清澈水域。
  static const Color primary = Color(0xFF7EB5F6);

  /// 主色调浅色变体
  static const Color primaryLight = Color(0xFFA5C8FA);

  /// 主色调深色变体
  static const Color primaryDark = Color(0xFF5A9EE0);

  // ==================== 辅助色（草绿色 - 代表草地） ====================

  /// 辅助色
  ///
  /// Minecraft 风格的核心辅助色（#7BCB9E），代表草地、树叶、藤蔓。
  static const Color secondary = Color(0xFF7BCB9E);

  /// 辅助色浅色变体
  static const Color secondaryLight = Color(0xFFA8E6CF);

  /// 辅助色深色变体
  static const Color secondaryDark = Color(0xFF5BA88A);

  // ==================== 强调色（泥土棕 - 代表泥土） ====================

  /// 强调色
  ///
  /// Minecraft 风格的强调色（#C9A96E），代表泥土、橡树木材、告示牌。
  static const Color accent = Color(0xFFC9A96E);

  /// 强调色浅色变体
  static const Color accentLight = Color(0xFFE0C99A);

  /// 强调色深色变体
  static const Color accentDark = Color(0xFFB08D4F);

  // ==================== Minecraft 方块色调 ====================

  /// 石头色（#8B8B8B）
  ///
  /// 代表石头、圆石、安山岩等方块。
  static const Color stone = Color(0xFF8B8B8B);

  /// 泥土色（#8B5A2B）
  ///
  /// 代表泥土、耕地。
  static const Color dirt = Color(0xFF8B5A2B);

  /// 草地顶色（#7BCB9E）
  ///
  /// 草地方块的顶部颜色。
  static const Color grassTop = Color(0xFF7BCB9E);

  /// 草地侧色（#8B5A2B）
  ///
  /// 草地方块的侧面颜色。
  static const Color grassSide = Color(0xFF8B5A2B);

  /// 木原木色（#6D5330）
  ///
  /// 橡树原木侧面颜色。
  static const Color woodLog = Color(0xFF6D5330);

  /// 木木板色（#B8945F）
  ///
  /// 橡树木板颜色。
  static const Color woodPlanks = Color(0xFFB8945F);

  /// 羊毛白色（#D7D7D7）
  ///
  /// 白色羊毛颜色。
  static const Color woolWhite = Color(0xFFD7D7D7);

  /// 羊毛彩色（#E55C88）
  ///
  /// 粉色羊毛颜色，用于强调。
  static const Color woolPink = Color(0xFFE55C88);

  /// 铁锭色（#CACACA）
  ///
  /// 铁锭、盔甲等金属物品。
  static const Color iron = Color(0xFFCACACA);

  /// 金锭色（#F9D171）
  ///
  /// 金锭、金盔甲等贵金属物品。
  static const Color gold = Color(0xFFF9D171);

  /// 钻石色（#64C8C8）
  ///
  /// 钻石、青金石等宝石。
  static const Color diamond = Color(0xFF64C8C8);

  /// 红石色（#A42E2E）
  ///
  /// 红石、红石火把、红石粉。
  static const Color redstone = Color(0xFFA42E2E);

  /// 煤炭色（#3D3D3D）
  ///
  /// 煤炭、木炭。
  static const Color coal = Color(0xFF3D3D3D);

  /// 绿宝石色（#17DD8E）
  ///
  /// 绿宝石、綠宝石矿石。
  static const Color emerald = Color(0xFF17DD8E);

  /// 熔岩色（#E87D17）
  ///
  /// 熔岩、熔炉火焰。
  static const Color lava = Color(0xFFE87D17);

  /// 水色（#3498DB）
  ///
  /// 水、水蒸气。
  static const Color water = Color(0xFF3498DB);

  /// 天空色（#7EC8E3）
  ///
  /// Minecraft 天空背景色。
  static const Color sky = Color(0xFF7EC8E3);

  /// 末地色（#1A1A2E）
  ///
  /// 末地、下界天空色。
  static const Color end = Color(0xFF1A1A2E);

  /// 下界色（#5C1E1E）
  ///
  /// 下界、灵魂沙。
  static const Color nether = Color(0xFF5C1E1E);

  // ==================== 背景色 ====================

  /// 主背景色
  static const Color background = Color(0xFFFAFBFD);

  /// 深色背景变体
  static const Color backgroundDark = Color(0xFFF0F3F8);

  /// 浅色背景变体
  static const Color backgroundLight = Color(0xFFFFFFFF);

  // ==================== 表面色 ====================

  /// 表面色（卡片背景）
  static const Color surface = Color(0xFFFFFFFF);

  /// 表面色变体
  static const Color surfaceVariant = Color(0xFFF8FAFD);

  /// 悬停状态表面色
  static const Color surfaceHover = Color(0xFFEDF2FC);

  // ==================== 文字色 ====================

  /// 主要文字色
  static const Color textPrimary = Color(0xFF2D3748);

  /// 次要文字色
  static const Color textSecondary = Color(0xFF718096);

  /// 禁用状态文字色
  static const Color textDisabled = Color(0xFFA0AEC0);

  // ==================== 功能色 ====================

  /// 成功色（草绿色）
  static const Color success = Color(0xFF7BCB9E);

  /// 警告色（金色）
  static const Color warning = Color(0xFFF5D76E);

  /// 危险色（红色）
  static const Color danger = Color(0xFFE88B8B);

  /// 信息色（天蓝色）
  static const Color info = Color(0xFF7EB5F6);

  // ==================== Minecraft 特定功能色 ====================

  /// 体力/生命值色（红色）
  static const Color health = Color(0xFFDE3F3F);

  /// 饥饿值色（棕色）
  static const Color hunger = Color(0xFFBC8238);

  /// 经验条色（黄绿色）
  static const Color experience = Color(0xFF5BBF54);

  /// 附魔色（紫色）
  static const Color enchantment = Color(0xFF9B59B6);

  /// 酿造/药水色（紫粉色）
  static const Color potion = Color(0xFF913D91);

  /// 鞘翅火焰色（橙黄色）
  static const Color elytraFire = Color(0xFFE87D17);

  // ==================== 边框色 ====================

  /// 标准边框色
  static const Color border = Color(0xFFE2E8F0);

  /// 浅色边框变体
  static const Color borderLight = Color(0xFFEDF2F7);

  // ==================== 渐变色 ====================

  /// 主渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 辅助渐变色（草绿色）
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 强调渐变色（泥土棕）
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 背景渐变色
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Minecraft 草地渐变
  static const LinearGradient grassGradient = LinearGradient(
    colors: [Color(0xFF5BBF54), Color(0xFF7BCB9E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 天空渐变（白天）
  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF7EC8E3), Color(0xFFB8E0F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 天空渐变（傍晚）
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF7EC8E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 下界渐变
  static const LinearGradient netherGradient = LinearGradient(
    colors: [Color(0xFF5C1E1E), Color(0xFF8B2500)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 末地渐变
  static const LinearGradient endGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D1B4E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 经验条渐变
  static const LinearGradient experienceGradient = LinearGradient(
    colors: [Color(0xFFF9D71C), Color(0xFF5BBF54)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// 钻石渐变
  static const LinearGradient diamondGradient = LinearGradient(
    colors: [Color(0xFF64C8C8), Color(0xFF3AAFBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== 毛玻璃效果 ====================

  /// 轻量毛玻璃效果色
  static Color get frostedGlassLight => surface.withOpacity(0.35);

  /// 中等毛玻璃效果色
  static Color get frostedGlassMedium => surface.withOpacity(0.25);

  /// 重度毛玻璃效果色
  static Color get frostedGlassHeavy => surface.withOpacity(0.15);

  /// 标准毛玻璃效果色
  static Color get frostedGlass => surface.withOpacity(0.30);

  // ==================== 阴影效果 ====================

  /// 卡片阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  /// 卡片悬停阴影
  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ];

  /// 发光阴影（蓝色）
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// 发光阴影（草绿色）
  static List<BoxShadow> get glowShadowGreen => [
        BoxShadow(
          color: secondary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// 发光阴影（金色）
  static List<BoxShadow> get glowShadowGold => [
        BoxShadow(
          color: gold.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}

/// 深色模式的 Minecraft 风格配色
class MCThemeColorsDark {
  // ==================== 主色调（深色模式） ====================

  /// 主色调（深色模式）
  static const Color primary = Color(0xFF7EB5F6);

  /// 主色调浅色变体（深色模式）
  static const Color primaryLight = Color(0xFFA5C8FA);

  /// 主色调深色变体（深色模式）
  static const Color primaryDark = Color(0xFF5A9EE0);

  // ==================== 辅助色（深色模式） ====================

  /// 辅助色（深色模式）
  static const Color secondary = Color(0xFF7BCB9E);

  /// 辅助色浅色变体（深色模式）
  static const Color secondaryLight = Color(0xFFA8E6CF);

  /// 辅助色深色变体（深色模式）
  static const Color secondaryDark = Color(0xFF5BA88A);

  // ==================== 强调色（深色模式） ====================

  /// 强调色（深色模式）
  static const Color accent = Color(0xFFC9A96E);

  /// 强调色浅色变体（深色模式）
  static const Color accentLight = Color(0xFFE0C99A);

  /// 强调色深色变体（深色模式）
  static const Color accentDark = Color(0xFFB08D4F);

  // ==================== 背景色（深色模式） ====================

  /// 主背景色（深色模式）
  ///
  /// Minecraft 风格深色主题背景（#1A1B1E），模拟 Minecraft 深色模式的视觉风格。
  static const Color background = Color(0xFF1A1B1E);

  /// 次要背景色（深色模式）
  static const Color backgroundVariant = Color(0xFF25262B);

  /// 表面色（深色模式）
  static const Color surface = Color(0xFF2D2E32);

  /// 表面色变体（深色模式）
  static const Color surfaceVariant = Color(0xFF373A40);

  /// 悬停状态表面色（深色模式）
  static const Color surfaceHover = Color(0xFF3F4147);

  // ==================== 文字色（深色模式） ====================

  /// 主要文字色（深色模式）
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// 次要文字色（深色模式）
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// 禁用状态文字色（深色模式）
  static const Color textDisabled = Color(0xFF6B7280);

  // ==================== 功能色（深色模式） ====================

  /// 成功色（深色模式）
  static const Color success = Color(0xFF7BCB9E);

  /// 警告色（深色模式）
  static const Color warning = Color(0xFFF5D76E);

  /// 危险色（深色模式）
  static const Color danger = Color(0xFFE88B8B);

  /// 信息色（深色模式）
  static const Color info = Color(0xFF7EB5F6);

  // ==================== 边框色（深色模式） ====================

  /// 标准边框色（深色模式）
  static const Color border = Color(0xFF373A40);

  /// 浅色边框变体（深色模式）
  static const Color borderLight = Color(0xFF4A4D55);

  // ==================== Minecraft 方块色调（深色模式） ====================

  /// 石头色（深色模式）
  static const Color stone = Color(0xFF4A4A4A);

  /// 泥土色（深色模式）
  static const Color dirt = Color(0xFF5A3A1B);

  /// 草地顶色（深色模式）
  static const Color grassTop = Color(0xFF5BA88A);

  /// 草地侧色（深色模式）
  static const Color grassSide = Color(0xFF5A3A1B);

  /// 木原木色（深色模式）
  static const Color woodLog = Color(0xFF4D3318);

  /// 木木板色（深色模式）
  static const Color woodPlanks = Color(0xFF8B6D3F);

  // ==================== 毛玻璃效果（深色模式） ====================

  /// 轻量毛玻璃效果色（深色模式）
  static Color get frostedGlassLight => surface.withOpacity(0.35);

  /// 中等毛玻璃效果色（深色模式）
  static Color get frostedGlassMedium => surface.withOpacity(0.25);

  /// 重度毛玻璃效果色（深色模式）
  static Color get frostedGlassHeavy => surface.withOpacity(0.15);

  /// 标准毛玻璃效果色（深色模式）
  static Color get frostedGlass => surface.withOpacity(0.30);
}

/// Minecraft 风格的尺寸、间距、动画配置
class MCThemeData {
  // ==================== 圆角 ====================

  /// 小圆角半径
  static const double radiusSmall = 8.0;

  /// 标准圆角半径
  static const double radius = 12.0;

  /// 大圆角半径
  static const double radiusLarge = 16.0;

  /// 超大圆角半径
  static const double radiusXLarge = 20.0;

  /// 圆形圆角半径
  static const double radiusCircle = 999.0;

  // ==================== 间距 ====================

  /// 极小间距
  static const double spacingXSmall = 8.0;

  /// 小间距
  static const double spacingSmall = 12.0;

  /// 标准间距
  static const double spacing = 16.0;

  /// 中等间距
  static const double spacingMedium = 20.0;

  /// 大间距
  static const double spacingLarge = 24.0;

  /// 超大间距
  static const double spacingXLarge = 32.0;

  // ==================== 动画时长 ====================

  /// 极短动画时长
  static const Duration animationMicro = Duration(milliseconds: 100);

  /// 快速动画时长
  static const Duration animationFast = Duration(milliseconds: 200);

  /// 标准动画时长
  static const Duration animation = Duration(milliseconds: 300);

  /// 慢速动画时长
  static const Duration animationSlow = Duration(milliseconds: 400);

  // ==================== 字体 ====================

  /// 主字体
  static const String fontFamily = 'Inter';

  /// Minecraft 风格字体（需要下载对应字体包）
  static const String minecraftFontFamily = 'Minecraft';
}

/// Minecraft 风格的圆角常量
class MCRadius {
  /// 小圆角
  static const BorderRadius small = BorderRadius.all(Radius.circular(MCThemeData.radiusSmall));

  /// 标准圆角
  static const BorderRadius normal = BorderRadius.all(Radius.circular(MCThemeData.radius));

  /// 大圆角
  static const BorderRadius large = BorderRadius.all(Radius.circular(MCThemeData.radiusLarge));

  /// 超大圆角
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(MCThemeData.radiusXLarge));

  /// 圆形圆角
  static const BorderRadius circle = BorderRadius.all(Radius.circular(MCThemeData.radiusCircle));
}

/// Minecraft 风格的间距常量
class MCSpacing {
  /// 极小间距
  static const EdgeInsets xSmall = EdgeInsets.all(MCThemeData.spacingXSmall);

  /// 小间距
  static const EdgeInsets small = EdgeInsets.all(MCThemeData.spacingSmall);

  /// 标准间距
  static const EdgeInsets normal = EdgeInsets.all(MCThemeData.spacing);

  /// 中等间距
  static const EdgeInsets medium = EdgeInsets.all(MCThemeData.spacingMedium);

  /// 大间距
  static const EdgeInsets large = EdgeInsets.all(MCThemeData.spacingLarge);

  /// 超大间距
  static const EdgeInsets xLarge = EdgeInsets.all(MCThemeData.spacingXLarge);
}

/// Minecraft 风格的动画配置
class MCAnimation {
  /// 极短动画时长
  static const Duration micro = Duration(milliseconds: 100);

  /// 快速动画时长
  static const Duration fast = Duration(milliseconds: 200);

  /// 标准动画时长
  static const Duration normal = Duration(milliseconds: 300);

  /// 慢速动画时长
  static const Duration slow = Duration(milliseconds: 400);

  /// 默认动画曲线
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// 弹性动画曲线
  static const Curve bounceCurve = Curves.elasticOut;

  /// 平滑动画曲线
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// Minecraft 风格的字体排版规范
class MCTypography {
  /// 主字体
  static const String fontFamily = 'Inter';

  /// Minecraft 风格字体
  static const String minecraftFontFamily = 'Minecraft';

  /// 标题1
  static const double h1 = 32.0;

  /// 标题2
  static const double h2 = 24.0;

  /// 标题3
  static const double h3 = 18.0;

  /// 正文
  static const double body = 14.0;

  /// 辅助文字
  static const double caption = 12.0;

  /// 小字
  static const double small = 10.0;
}
