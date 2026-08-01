import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'ba_buttons.dart';

/// 蔚蓝档案风格对话框组件
///
/// 设计要点：
/// - 透明亚克力（Acrylic）：双层 BackdropFilter 制造深度磨砂感
/// - 顶部彩色光带：呼应蔚蓝档案主题色
/// - 噪点纹理叠加：消除大块纯色的塑料感
/// - 内外阴影组合：营造漂浮层次
class BADialog extends StatelessWidget {
  /// 对话框标题
  final String title;

  /// 标题栏前的小图标（可选）
  final IconData? titleIcon;

  /// 对话框内容
  final Widget child;

  /// 操作按钮列表
  final List<Widget>? actions;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 对话框宽度
  final double? width;

  /// 对话框高度
  final double? height;

  const BADialog({
    super.key,
    required this.title,
    required this.child,
    this.titleIcon,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
    this.width,
    this.height,
  });

  /// 显示蔚蓝档案风格对话框
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    IconData? titleIcon,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => BADialog(
        title: title,
        titleIcon: titleIcon,
        actions: actions,
        showCloseButton: showCloseButton,
        onClose: () => Navigator.of(context).pop(),
        width: width,
        height: height,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final primaryColor = BAColors.primaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? 1200,
          minWidth: 360,
          // 当显式传入 height 时强制设最小高度；否则允许内容自适应收缩
          minHeight: height ?? 0,
          maxHeight: height ?? MediaQuery.of(context).size.height - 48,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // 底层磨砂（远景模糊）
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // 表层渐变 + 半透明背景
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xCC1E2747),
                              const Color(0xCC141C33),
                            ]
                          : [
                              const Color(0xE6FFFFFF),
                              const Color(0xCCF5F8FF),
                            ],
                    ),
                    borderRadius: radius,
                  ),
                ),
              ),
              // 细噪点纹理层（亚克力质感关键）
              Positioned.fill(
                child: CustomPaint(
                  painter: _NoiseTexturePainter(
                    baseColor: isDark
                        ? const Color(0x14FFFFFF)
                        : const Color(0x0A1A2744),
                  ),
                ),
              ),
              // 边框 + 阴影
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              // 顶部彩色光带
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.0),
                            primaryColor.withValues(alpha: 0.7),
                            BAColors.accentPink.withValues(alpha: 0.6),
                            primaryColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 主内容
              Column(
                mainAxisSize: height != null
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, primaryColor),
                  // 内容区：
                  // - height 不为空时用 Flexible（垂直有界，调用方传任意 child）
                  // - height 为空时直接放 child，由调用方自己控制尺寸
                  if (height != null)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                        child: child,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                      child: child,
                    ),
                  if (actions != null && actions!.isNotEmpty)
                    _buildActions(context),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (titleIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.28),
                    primaryColor.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(
                titleIcon,
                size: 16,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (showCloseButton)
            _CloseButton(onTap: onClose),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            actions![i],
          ],
        ],
      ),
    );
  }
}

/// 关闭按钮（圆角磨砂小图标）
class _CloseButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CloseButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: BAColors.textSecondaryOf(context),
          ),
        ),
      ),
    );
  }
}

/// 细噪点纹理 Painter
///
/// 在大块玻璃面上绘制细密的随机微亮点，消除"塑料感"，呈现真实亚克力材质。
class _NoiseTexturePainter extends CustomPainter {
  final Color baseColor;
  const _NoiseTexturePainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    final rng = _NoiseRng(0xBA5112);
    const step = 3.5;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (rng.next() < 0.18) {
          canvas.drawCircle(Offset(x, y), 0.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 简易确定性伪随机（避免每次重绘抖动）
class _NoiseRng {
  int _state;
  _NoiseRng(int seed) : _state = seed;
  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state / 0x7fffffff);
  }
}

/// 向后兼容别名
typedef BAFrostedDialog = BADialog;

/// 确认对话框（向后兼容）
class BAConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    IconData? titleIcon,
    BAButtonStyle confirmButtonStyle = BAButtonStyle.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BADialog(
        title: title,
        titleIcon: titleIcon,
        actions: [
          BASecondaryButton(
            text: cancelText,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 10),
          confirmButtonStyle == BAButtonStyle.danger
              ? BADangerButton(
                  text: confirmText,
                  onPressed: () => Navigator.of(context).pop(true),
                )
              : BAPrimaryButton(
                  text: confirmText,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
        ],
        child: Text(
          content,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
    return result ?? false;
  }
}