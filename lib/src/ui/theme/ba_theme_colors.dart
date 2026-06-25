import 'package:flutter/material.dart';

/// 蔚蓝档案风格配色方案
///
/// 本类定义了完整模仿蔚蓝档案（Blue Archive）视觉风格的配色系统。
/// 蔚蓝档案的设计理念强调：
/// - 清新明亮的天蓝色作为主色调，代表游戏中的"蓝天"主题
/// - 柔和的樱花粉色作为辅助色，增添可爱与温馨感
/// - 低对比度、高明度的配色，营造轻松愉悦的视觉体验
/// - 大量使用圆角和柔和阴影，体现游戏界面的亲和力
///
/// 使用方式：
/// ```dart
/// Container(
///   color: BAThemeColors.primary,
///   decoration: BoxDecoration(gradient: BAThemeColors.primaryGradient),
/// )
/// ```
class BAThemeColors {
  // ==================== 背景色 ====================

  /// 主背景色
  ///
  /// 蔚蓝档案风格的主背景色，采用轻盈的浅白色（#FAFBFD）。
  /// 用于应用的主要背景区域，营造清新明亮的视觉感受。
  static const Color background = Color(0xFFFAFBFD);

  /// 深色背景变体
  ///
  /// 比主背景色略深的变体（#F0F3F8），用于区分不同层级的背景区域。
  /// 常用于侧边栏、次级页面或需要视觉分隔的区域。
  static const Color backgroundDark = Color(0xFFF0F3F8);

  /// 浅色背景变体
  ///
  /// 纯白色背景（#FFFFFF），用于需要最高亮度的区域。
  /// 常用于弹窗、对话框或需要突出显示的内容区域。
  static const Color backgroundLight = Color(0xFFFFFFFF);

  // ==================== 表面色 ====================

  /// 表面色（卡片背景）
  ///
  /// 用于卡片、面板等组件的背景色（#FFFFFF）。
  /// 在蔚蓝档案中，卡片通常采用纯白色背景配合柔和阴影，
  /// 营造出轻盈浮动的视觉效果。
  static const Color surface = Color(0xFFFFFFFF);

  /// 表面色变体
  ///
  /// 略带色调的表面色（#F8FAFD），用于需要轻微区分的表面。
  /// 常用于悬停状态或次要卡片的背景。
  static const Color surfaceVariant = Color(0xFFF8FAFD);

  /// 悬停状态表面色
  ///
  /// 用于交互元素悬停状态的表面色（#EDF2FC）。
  /// 在蔚蓝档案风格中，悬停效果通常采用柔和的蓝色调变化。
  static const Color surfaceHover = Color(0xFFEDF2FC);

  // ==================== 主强调色 ====================

  /// 主强调色（天蓝色）
  ///
  /// 蔚蓝档案的核心品牌色（#7EB5F6），代表游戏名称中的"蓝"。
  /// 用于主要按钮、选中状态、链接、进度条等需要强调的元素。
  /// 这种轻盈的天蓝色传达了游戏的清新、希望与青春主题。
  static const Color primary = Color(0xFF7EB5F6);

  /// 主强调色浅色变体
  ///
  /// 主色的浅色版本（#A5C8FA），用于悬停状态或需要柔和强调的场景。
  /// 常用于按钮悬停效果、选中项的背景等。
  static const Color primaryLight = Color(0xFFA5C8FA);

  /// 主强调色深色变体
  ///
  /// 主色的深色版本（#5A9EE0），用于按下状态或需要更强烈强调的场景。
  /// 常用于按钮按下效果、进度条的深色部分等。
  static const Color primaryDark = Color(0xFF5A9EE0);

  // ==================== 次强调色 ====================

  /// 次强调色（樱花粉）
  ///
  /// 蔚蓝档案的辅助品牌色（#FFB4C2），代表游戏中的可爱与温馨元素。
  /// 用于次要按钮、标签、特殊强调等场景。
  /// 这种柔和的粉色与天蓝色形成互补，增添界面的活泼感。
  static const Color secondary = Color(0xFFFFB4C2);

  /// 次强调色浅色变体
  ///
  /// 次色的浅色版本（#FFD1D8），用于悬停状态或柔和的背景强调。
  static const Color secondaryLight = Color(0xFFFFD1D8);

  /// 次强调色深色变体
  ///
  /// 次色的深色版本（#E89AAB），用于按下状态或更强烈的强调。
  static const Color secondaryDark = Color(0xFFE89AAB);

  // ==================== 强调色 ====================

  /// 特殊强调色（柔和紫色）
  ///
  /// 用于特殊场景的强调色（#B8A4FF），如稀有物品、特殊成就等。
  /// 在蔚蓝档案中，紫色常用于表示神秘、高级或特殊的内容。
  static const Color accent = Color(0xFFB8A4FF);

  // ==================== 文字色 ====================

  /// 主要文字色
  ///
  /// 用于主要文本内容的颜色（#2D3748）。
  /// 采用较低对比度的深灰色而非纯黑色，符合蔚蓝档案柔和的视觉风格。
  /// 确保长时间阅读的舒适性。
  static const Color textPrimary = Color(0xFF2D3748);

  /// 次要文字色
  ///
  /// 用于次要文本、说明文字、提示信息的颜色（#718096）。
  /// 比主要文字色更浅，用于层级较低的文本内容。
  static const Color textSecondary = Color(0xFF718096);

  /// 禁用状态文字色
  ///
  /// 用于禁用状态或占位符文本的颜色（#A0AEC0）。
  /// 表示不可交互或无内容的状态。
  static const Color textDisabled = Color(0xFFA0AEC0);

  // ==================== 功能色 ====================

  /// 成功色
  ///
  /// 表示成功、完成、正确状态的柔和绿色（#7BCB9E）。
  /// 用于成功提示、完成标记、正向反馈等场景。
  /// 采用柔和的绿色而非刺眼的亮绿，保持整体风格的一致性。
  static const Color success = Color(0xFF7BCB9E);

  /// 警告色
  ///
  /// 表示警告、注意、提醒状态的柔和黄色（#F5D76E）。
  /// 用于警告提示、需要注意的信息等场景。
  static const Color warning = Color(0xFFF5D76E);

  /// 危险色
  ///
  /// 表示错误、危险、删除等状态的柔和红色（#E88B8B）。
  /// 用于错误提示、删除确认、危险操作等场景。
  /// 采用柔和的红色，避免过于刺激的视觉效果。
  static const Color danger = Color(0xFFE88B8B);

  /// 信息色
  ///
  /// 表示一般信息、提示、说明的颜色（#7EB5F6）。
  /// 与主强调色相同，用于信息性提示和说明。
  static const Color info = Color(0xFF7EB5F6);

  // ==================== 游戏特定色 ====================

  /// 体力色
  ///
  /// 蔚蓝档案中体力值的颜色（#FFE066）。
  /// 在游戏中，体力通常以黄色/金色显示，代表玩家的行动能量。
  static const Color stamina = Color(0xFFFFE066);

  /// 信用点货币色
  ///
  /// 游戏内信用点货币的颜色（#7BCB9E），采用柔和的绿色。
  /// 与成功色相同，代表游戏中的基础货币。
  static const Color credit = Color(0xFF7BCB9E);

  /// 蓝宝石货币色
  ///
  /// 游戏内蓝宝石货币的颜色（#7EB5F6），采用天蓝色。
  /// 与主强调色相同，代表游戏中的高级货币。
  static const Color blueGem = Color(0xFF7EB5F6);

  // ==================== 边框色 ====================

  /// 标准边框色
  ///
  /// 用于组件边框的柔和灰色（#E2E8F0）。
  /// 蔚蓝档案风格采用细且柔和的边框，避免视觉干扰。
  static const Color border = Color(0xFFE2E8F0);

  /// 浅色边框变体
  ///
  /// 更浅的边框色（#EDF2F7），用于需要更柔和分隔的场景。
  static const Color borderLight = Color(0xFFEDF2F7);

  // ==================== 渐变色 ====================

  /// 主渐变色
  ///
  /// 从天蓝色到淡紫色的对角渐变。
  /// 蔚蓝档案常用的蓝紫渐变效果，用于标题栏、特色区域等。
  /// 体现了游戏梦幻、青春的视觉风格。
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 主垂直渐变色
  ///
  /// 主色的垂直渐变，从浅到深。
  /// 用于按钮、进度条等需要垂直渐变效果的场景。
  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [Color(0xFF7EB5F6), Color(0xFF5A9EE0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 次渐变色
  ///
  /// 樱花粉色的柔和渐变。
  /// 用于需要粉色渐变效果的场景，如特殊标签、女性角色相关内容等。
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFFE4E1), Color(0xFFFFB6C1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 背景渐变色
  ///
  /// 背景色的垂直渐变，用于页面背景的微妙变化。
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 金色渐变
  ///
  /// 从亮黄色到橙色的渐变。
  /// 用于金色/黄色相关的特殊效果，如奖励、成就、稀有物品等。
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE066), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 经验条渐变
  ///
  /// 用于经验值进度条的蓝色渐变。
  /// 从浅蓝到稍深的蓝色，表示角色的成长进度。
  static const LinearGradient expGradient = LinearGradient(
    colors: [Color(0xFF8EC5FC), Color(0xFFA5C8FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ==================== 毛玻璃效果 ====================

  /// 轻量毛玻璃效果色
  ///
  /// 用于轻量级毛玻璃效果的颜色（表面色35%不透明度）。
  /// 蔚蓝档案风格常用半透明效果营造层次感。
  static Color get frostedGlassLight => surface.withOpacity(0.35);

  /// 中等毛玻璃效果色
  ///
  /// 用于中等强度毛玻璃效果的颜色（表面色25%不透明度）。
  static Color get frostedGlassMedium => surface.withOpacity(0.25);

  /// 重度毛玻璃效果色
  ///
  /// 用于重度毛玻璃效果的颜色（表面色15%不透明度）。
  /// 更透明的效果，用于需要更多底层内容透出的场景。
  static Color get frostedGlassHeavy => surface.withOpacity(0.15);

  /// 标准毛玻璃效果色
  ///
  /// 用于标准毛玻璃效果的颜色（表面色30%不透明度）。
  static Color get frostedGlass => surface.withOpacity(0.30);

  // ==================== 阴影效果 ====================

  /// 卡片阴影
  ///
  /// 标准卡片阴影效果，采用柔和的大范围模糊。
  /// 蔚蓝档案风格的阴影特点是：低透明度、大模糊半径、柔和的偏移。
  /// 用于卡片、面板等组件的浮起效果。
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  /// 卡片悬停阴影
  ///
  /// 卡片悬停状态的增强阴影效果。
  /// 当用户悬停在卡片上时，阴影会变得更明显，提供交互反馈。
  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ];

  /// 发光阴影（蓝色）
  ///
  /// 带有主色调的发光阴影效果。
  /// 用于需要强调或突出显示的元素，如选中项、焦点元素等。
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// 发光阴影（粉色）
  ///
  /// 带有次色调的发光阴影效果。
  /// 用于需要粉色强调的特殊元素。
  static List<BoxShadow> get glowShadowPink => [
        BoxShadow(
          color: secondary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A1B1E);
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF373A40);
  }
}

/// 蔚蓝档案风格主题数据配置
///
/// 本类定义了蔚蓝档案风格的尺寸、间距、动画时长等非颜色相关的主题数据。
/// 这些数值参数与 [BAThemeColors] 配合使用，共同构成完整的视觉风格。
///
/// 蔚蓝档案的设计特点：
/// - 大圆角：营造友好、亲和的视觉感受
/// - 宽松间距：提供舒适的阅读和操作空间
/// - 柔和动画：过渡自然流畅，不突兀
class BAThemeData {
  // ==================== 圆角 ====================

  /// 小圆角半径
  ///
  /// 用于小型组件如标签、小按钮的圆角（12.0）。
  static const double radiusSmall = 12.0;

  /// 标准圆角半径
  ///
  /// 用于大多数组件的标准圆角（16.0）。
  /// 蔚蓝档案风格的核心圆角值，广泛应用于卡片、按钮等。
  static const double radius = 16.0;

  /// 大圆角半径
  ///
  /// 用于大型组件如对话框、大卡片的圆角（20.0）。
  static const double radiusLarge = 20.0;

  /// 超大圆角半径
  ///
  /// 用于特殊大型组件的圆角（28.0）。
  static const double radiusXLarge = 28.0;

  /// 圆形圆角半径
  ///
  /// 用于完全圆形组件的圆角（999.0），如圆形头像、圆形按钮。
  static const double radiusCircle = 999.0;

  // ==================== 间距 ====================

  /// 极小间距
  ///
  /// 用于紧凑布局的间距（8.0）。
  static const double spacingXSmall = 8.0;

  /// 小间距
  ///
  /// 用于小型组件内部或相邻元素的间距（12.0）。
  static const double spacingSmall = 12.0;

  /// 标准间距
  ///
  /// 用于大多数场景的标准间距（18.0）。
  static const double spacing = 18.0;

  /// 中等间距
  ///
  /// 用于组件之间或区块分隔的间距（24.0）。
  static const double spacingMedium = 24.0;

  /// 大间距
  ///
  /// 用于较大区块分隔的间距（32.0）。
  static const double spacingLarge = 32.0;

  /// 超大间距
  ///
  /// 用于页面级分隔的间距（48.0）。
  static const double spacingXLarge = 48.0;

  // ==================== 动画时长 ====================

  /// 极短动画时长
  ///
  /// 用于微小交互的动画时长（100毫秒）。
  /// 如按钮按下反馈、开关切换等。
  static const Duration animationMicro = Duration(milliseconds: 100);

  /// 快速动画时长
  ///
  /// 用于快速过渡的动画时长（200毫秒）。
  /// 如悬停效果、小型展开收起等。
  static const Duration animationFast = Duration(milliseconds: 200);

  /// 标准动画时长
  ///
  /// 用于大多数动画的标准时长（350毫秒）。
  /// 蔚蓝档案风格的核心动画时长，过渡自然流畅。
  static const Duration animation = Duration(milliseconds: 350);

  /// 慢速动画时长
  ///
  /// 用于大型动画或需要强调的动画时长（500毫秒）。
  /// 如页面切换、大型组件展开等。
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ==================== 字体 ====================

  /// 主字体
  ///
  /// 应用使用的主字体名称。
  /// Inter 字体具有良好的可读性和现代感，适合蔚蓝档案风格。
  static const String fontFamily = 'Inter';
}

/// 蔚蓝档案风格圆角常量
///
/// 提供预设的 [BorderRadius] 值，方便在组件中直接使用。
/// 配合 [BAThemeData] 中定义的圆角半径值。
///
/// 使用示例：
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BARadius.normal,
///   ),
/// )
/// ```
class BARadius {
  /// 小圆角
  static const BorderRadius small = BorderRadius.all(Radius.circular(BAThemeData.radiusSmall));

  /// 标准圆角
  static const BorderRadius normal = BorderRadius.all(Radius.circular(BAThemeData.radius));

  /// 大圆角
  static const BorderRadius large = BorderRadius.all(Radius.circular(BAThemeData.radiusLarge));

  /// 超大圆角
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(BAThemeData.radiusXLarge));

  /// 圆形圆角
  static const BorderRadius circle = BorderRadius.all(Radius.circular(BAThemeData.radiusCircle));
}

/// 蔚蓝档案风格间距常量
///
/// 提供预设的 [EdgeInsets] 值，方便在组件中直接使用。
/// 配合 [BAThemeData] 中定义的间距值。
///
/// 使用示例：
/// ```dart
/// Padding(
///   padding: BASpacing.normal,
///   child: Text('内容'),
/// )
/// ```
class BASpacing {
  /// 极小间距
  static const EdgeInsets xSmall = EdgeInsets.all(BAThemeData.spacingXSmall);

  /// 小间距
  static const EdgeInsets small = EdgeInsets.all(BAThemeData.spacingSmall);

  /// 标准间距
  static const EdgeInsets normal = EdgeInsets.all(BAThemeData.spacing);

  /// 中等间距
  static const EdgeInsets medium = EdgeInsets.all(BAThemeData.spacingMedium);

  /// 大间距
  static const EdgeInsets large = EdgeInsets.all(BAThemeData.spacingLarge);

  /// 超大间距
  static const EdgeInsets xLarge = EdgeInsets.all(BAThemeData.spacingXLarge);
}

/// 蔚蓝档案风格标签样式
///
/// 提供标签（Tag）组件的构建方法，用于分类、筛选等场景。
/// 标签样式符合蔚蓝档案的圆润、柔和视觉风格。
class BABadgeStyle {
  /// 构建标签组件
  ///
  /// 创建一个蔚蓝档案风格的标签组件。
  ///
  /// 参数：
  /// - [label]: 标签显示的文本内容
  /// - [isSelected]: 是否为选中状态，选中状态会显示主色调高亮
  ///
  /// 返回：一个带有蔚蓝档案风格样式的标签 [Widget]
  ///
  /// 使用示例：
  /// ```dart
  /// BABadgeStyle.buildTag(label: '角色', isSelected: true)
  /// ```
  static Widget buildTag({required String label, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? BAThemeColors.primary.withOpacity(0.12)
            : BAThemeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? BAThemeColors.primary.withOpacity(0.4)
              : BAThemeColors.border.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? BAThemeColors.primary
              : BAThemeColors.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// 蔚蓝档案风格卡片样式
///
/// 提供卡片组件的样式配置，包括内边距、装饰等。
/// 卡片是蔚蓝档案界面的核心组件，采用毛玻璃效果和柔和阴影。
class BACardStyle {
  /// 卡片内容内边距
  ///
  /// 卡片内部内容的标准内边距。
  static EdgeInsets get contentPadding => const EdgeInsets.all(BAThemeData.spacingMedium);

  /// 卡片区块内边距
  ///
  /// 卡片内部区块之间的垂直内边距。
  static EdgeInsets get sectionPadding => const EdgeInsets.symmetric(vertical: BAThemeData.spacingSmall);

  /// 列表项间距
  ///
  /// 卡片内列表项之间的标准间距。
  static const double listItemSpacing = 12.0;

  /// 毛玻璃效果装饰
  ///
  /// 返回一个带有毛玻璃效果的 [BoxDecoration]。
  /// 包含半透明背景、圆角和细边框。
  static BoxDecoration get frostedGlass => BoxDecoration(
        color: BAThemeColors.surface.withOpacity(0.25),
        borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.15),
        ),
      );

  /// 卡片装饰
  ///
  /// 返回一个标准的卡片装饰 [BoxDecoration]。
  ///
  /// 参数：
  /// - [opacity]: 背景透明度，默认为 0.35
  ///
  /// 返回：包含背景色、圆角和边框的装饰对象
  static BoxDecoration cardDecoration({double? opacity}) => BoxDecoration(
        color: BAThemeColors.surface.withOpacity(opacity ?? 0.35),
        borderRadius: BorderRadius.circular(BAThemeData.radiusLarge),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.15),
          width: 1,
        ),
      );
}

/// 蔚蓝档案风格输入框样式
///
/// 提供输入框组件的样式配置，符合蔚蓝档案的圆润、柔和视觉风格。
class BAInputStyle {
  /// 搜索框输入装饰
  ///
  /// 创建一个蔚蓝档案风格的搜索框输入装饰。
  ///
  /// 参数：
  /// - [hintText]: 占位提示文本
  ///
  /// 返回：配置好的 [InputDecoration] 对象
  ///
  /// 使用示例：
  /// ```dart
  /// TextField(
  ///   decoration: BAInputStyle.searchDecoration(hintText: '搜索...'),
  /// )
  /// ```
  static InputDecoration searchDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: BAThemeColors.textDisabled),
      filled: true,
      fillColor: BAThemeColors.surface.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BAThemeData.radius),
        borderSide: BorderSide(
          color: BAThemeColors.border.withOpacity(0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BAThemeData.radius),
        borderSide: BorderSide(
          color: BAThemeColors.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
    );
  }
}

/// 蔚蓝档案风格动画配置
///
/// 提供动画相关的时长和曲线配置。
/// 蔚蓝档案风格的动画特点是柔和、自然、不突兀。
class BAAnimation {
  /// 极短动画时长
  ///
  /// 用于微小交互反馈（100毫秒）。
  static const Duration micro = Duration(milliseconds: 100);

  /// 快速动画时长
  ///
  /// 用于快速过渡效果（200毫秒）。
  static const Duration fast = Duration(milliseconds: 200);

  /// 标准动画时长
  ///
  /// 用于大多数动画效果（350毫秒）。
  static const Duration normal = Duration(milliseconds: 350);

  /// 慢速动画时长
  ///
  /// 用于大型动画或需要强调的效果（500毫秒）。
  static const Duration slow = Duration(milliseconds: 500);

  /// 默认动画曲线
  ///
  /// 使用 easeOutCubic 曲线，开始快结束慢，过渡自然。
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// 弹性动画曲线
  ///
  /// 使用 elasticOut 曲线，带有弹性回弹效果。
  /// 用于需要活泼感的动画，如弹出效果。
  static const Curve bounceCurve = Curves.elasticOut;

  /// 平滑动画曲线
  ///
  /// 使用 easeInOutCubic 曲线，开始和结束都慢，中间快。
  /// 用于需要平滑过渡的动画。
  static const Curve smoothCurve = Curves.easeInOutCubic;
}