import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 蔚蓝档案风格通用组件库
/// 提供毛玻璃效果、动画按钮、缩放过渡等通用组件

// ==================== 动画常量 ====================

/// 动画时长常量
class BAAnimationDurations {
  /// 快速动画 - 150ms（微交互）
  static const Duration micro = Duration(milliseconds: 150);
  
  /// 标准动画 - 300ms（页面切换、卡片展开）
  static const Duration standard = Duration(milliseconds: 300);
  
  /// 慢速动画 - 500ms（大型过渡）
  static const Duration slow = Duration(milliseconds: 500);
  
  /// 页面缩放动画 - 300ms
  static const Duration pageScale = Duration(milliseconds: 300);
}

/// 动画曲线常量
class BAAnimationCurves {
  /// 标准缓出曲线
  static const Curve standard = Curves.easeOutCubic;
  
  /// 弹性曲线（用于缩放效果）
  static const Curve elastic = Curves.elasticOut;
  
  /// 平滑曲线
  static const Curve smooth = Curves.easeInOutCubic;
}

// ==================== 毛玻璃组件 ====================

/// 毛玻璃容器组件
/// 用于顶部栏、底部导航、悬浮按钮等需要模糊背景的元素
/// 自动适配深浅色主题
class BAGlassContainer extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 模糊强度
  final double blur;

  /// 背景透明度 (0.0 - 1.0)
  final double opacity;

  /// 圆角
  final double borderRadius;

  /// 内边距
  final EdgeInsets? padding;

  /// 外边距
  final EdgeInsets? margin;

  /// 是否显示边框
  final bool showBorder;

  /// 自定义装饰
  final BoxDecoration? decoration;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  const BAGlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.75,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.showBorder = true,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: decoration ?? BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: borderColor.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// 半透明卡片（用于内容区卡片）
/// 自动适配深浅色主题
class BASurfaceCard extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 圆角
  final double borderRadius;

  /// 内边距
  final EdgeInsets? padding;

  /// 外边距
  final EdgeInsets? margin;

  /// 是否可点击
  final VoidCallback? onTap;

  /// 是否显示边框
  final bool showBorder;

  /// 边框颜色
  final Color? borderColor;

  /// 背景颜色（覆盖自动配色）
  final Color? backgroundColor;

  /// 阴影颜色
  final Color? shadowColor;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  const BASurfaceCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
    this.backgroundColor,
    this.shadowColor,
    this.width,
    this.height,
  });

  @override
  State<BASurfaceCard> createState() => _BASurfaceCardState();
}

class _BASurfaceCardState extends State<BASurfaceCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final defaultBg = BAColors.surfaceOf(context);
    final defaultBorder = BAColors.borderOf(context);
    const defaultShadow = Color(0xFF000000);
    final baseOpacity = isLight ? 0.92 : 0.96;
    final hoverOpacity = isLight ? 0.96 : 0.98;

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          curve: BAAnimationCurves.standard,
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? defaultBg.withValues(alpha: _isHovered ? hoverOpacity : baseOpacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.showBorder
                ? Border.all(
                    color: widget.borderColor ?? defaultBorder.withValues(alpha: _isHovered ? 0.7 : 0.5),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor ?? defaultShadow.withValues(alpha: _isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: BAAnimationDurations.micro,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }
}

// ==================== 窗口控制按钮 ====================

/// 窗口控制按钮组件
/// 自动适配深浅色主题
class BAWindowButton extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback onTap;

  /// 是否为关闭按钮（红色悬停）
  final bool isClose;

  /// 尺寸
  final double size;

  const BAWindowButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isClose = false,
    this.size = 36.0,
  });

  @override
  State<BAWindowButton> createState() => _BAWindowButtonState();
}

class _BAWindowButtonState extends State<BAWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgBase = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isClose
                    ? BAColors.dangerOf(context)
                    : BAColors.surfaceHoverOf(context))
                : bgBase.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(widget.size / 3),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            widget.icon,
            color: _isHovered
                ? Colors.white
                : BAColors.textPrimaryOf(context).withValues(alpha: isLight ? 0.8 : 0.75),
            size: widget.size * 0.45,
          ),
        ),
      ),
    );
  }
}

// ==================== 页面缩放过渡动画 ====================

/// 页面缩放过渡动画
class BAScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  BAScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 缩放动画：0.9 → 1.0
            final scaleAnimation = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: BAAnimationCurves.standard,
            ));
            
            // 淡入淡出动画
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ));
            
            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: BAAnimationDurations.pageScale,
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

// ==================== 缩放切换动画包装器 ====================

/// 带缩放动画的内容切换器
class BAScaleContentSwitcher extends StatelessWidget {
  /// 当前显示的内容
  final Widget child;
  
  /// 切换动画时长
  final Duration duration;

  const BAScaleContentSwitcher({
    super.key,
    required this.child,
    this.duration = BAAnimationDurations.standard,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: duration,
      curve: BAAnimationCurves.standard,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: duration,
        child: child,
      ),
    );
  }
}

// ==================== 图标按钮 ====================

/// 蔚蓝档案风格图标按钮
/// 自动适配深浅色主题
class BAIconButton extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback? onTap;

  /// 尺寸
  final double size;

  /// 图标大小
  final double iconSize;

  /// 背景颜色（覆盖自动配色）
  final Color? backgroundColor;

  /// 图标颜色
  final Color? iconColor;

  /// 提示文字
  final String? tooltip;

  /// 是否禁用
  final bool enabled;

  const BAIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.enabled = true,
  });

  @override
  State<BAIconButton> createState() => _BAIconButtonState();
}

class _BAIconButtonState extends State<BAIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final defaultBg = BAColors.surfaceOf(context);
    final borderColor = BAColors.borderOf(context);
    final effectiveOnTap = widget.enabled ? widget.onTap : null;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = widget.enabled),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: effectiveOnTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: effectiveOnTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? defaultBg.withValues(alpha: _isHovered ? 0.9 : 0.85),
            borderRadius: BorderRadius.circular(widget.size / 3),
            border: Border.all(
              color: borderColor.withValues(alpha: _isHovered ? 0.7 : 0.5),
            ),
          ),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0),
            duration: BAAnimationDurations.micro,
            child: Icon(
              widget.icon,
              color: widget.iconColor ??
                  BAColors.textPrimaryOf(context).withValues(alpha: widget.enabled ? 1.0 : 0.4),
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

// ==================== 小红点提示 ====================

/// 带小红点提示的组件包装器
class BABadge extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 是否显示红点
  final bool showBadge;
  
  /// 红点大小
  final double badgeSize;
  
  /// 红点颜色
  final Color badgeColor;

  const BABadge({
    super.key,
    required this.child,
    this.showBadge = true,
    this.badgeSize = 8.0,
    this.badgeColor = const Color(0xFFFF6B6B),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showBadge)
          Positioned(
            right: -badgeSize / 2,
            top: -badgeSize / 2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== 标签芯片 ====================

/// 蔚蓝档案风格标签芯片
class BAChip extends StatefulWidget {
  /// 标签文本
  final String label;
  
  /// 图标（可选）
  final IconData? icon;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否选中
  final bool isSelected;
  
  /// 颜色
  final Color? color;
  
  /// 是否可关闭
  final bool showClose;
  
  /// 关闭回调
  final VoidCallback? onClose;

  const BAChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isSelected = false,
    this.color,
    this.showClose = false,
    this.onClose,
  });

  @override
  State<BAChip> createState() => _BAChipState();
}

class _BAChipState extends State<BAChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? BAColors.primaryOf(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BAAnimationDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? effectiveColor.withValues(alpha: 0.25)
                : effectiveColor.withValues(alpha: _isHovered ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: effectiveColor.withValues(alpha: widget.isSelected ? 0.6 : 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.showClose) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.close,
                    color: effectiveColor.withValues(alpha: 0.7),
                    size: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 加载状态 ====================

/// 加载状态组件
/// 显示居中的加载指示器和可选的提示文字
class BALoadingState extends StatelessWidget {
  /// 提示文字
  final String? message;

  /// 指示器大小
  final double size;

  const BALoadingState({
    super.key,
    this.message,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: BAColors.primaryOf(context),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== 空状态 ====================

/// 空状态组件
/// 显示居中的图标、标题、副标题和可选的操作按钮
class BAEmptyState extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 操作按钮文字
  final String? actionLabel;

  /// 操作按钮回调
  final VoidCallback? onAction;

  const BAEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: BAColors.textSecondaryOf(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context).withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAction,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== 错误状态 ====================

/// 错误状态组件
/// 显示居中的错误图标、标题、错误信息和重试按钮
class BAErrorState extends StatelessWidget {
  /// 标题
  final String title;

  /// 错误信息
  final String? message;

  /// 重试回调
  final VoidCallback? onRetry;

  const BAErrorState({
    super.key,
    this.title = '加载失败',
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: BAColors.dangerOf(context).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message!,
                style: TextStyle(
                  color: BAColors.textSecondaryOf(context).withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '重试',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
