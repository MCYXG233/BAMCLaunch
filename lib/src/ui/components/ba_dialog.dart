import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_buttons.dart';

/// 毛玻璃弹窗组件
class BAFrostedDialog extends StatelessWidget {
  /// 弹窗标题
  final String title;

  /// 弹窗内容
  final Widget child;

  /// 操作按钮列表
  final List<Widget>? actions;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 弹窗宽度
  final double? width;

  /// 弹窗高度
  final double? height;

  const BAFrostedDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
    this.width,
    this.height,
  });

  /// 显示毛玻璃弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => BAFrostedDialog(
        title: title,
        child: child,
        actions: actions,
        showCloseButton: showCloseButton,
        onClose: () => Navigator.of(context).pop(),
        width: width,
        height: height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BATheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: BATheme.blurSigma,
            sigmaY: BATheme.blurSigma,
          ),
          child: Container(
            width: width,
            height: height,
            constraints: const BoxConstraints(maxWidth: 560, minWidth: 320),
            decoration: BoxDecoration(
              color: BAColors.glass,
              borderRadius: BATheme.borderRadius,
              border: Border.all(color: BAColors.border, width: 1),
              boxShadow: BATheme.shadows,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: BATypography.headlineMedium.copyWith(
                            color: BAColors.textPrimary,
                          ),
                        ),
                      ),
                      if (showCloseButton) _CloseButton(onPressed: onClose),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: child,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!.reversed.toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 确认弹窗
class BAConfirmDialog extends StatelessWidget {
  /// 标题
  final String title;

  /// 内容
  final String content;

  /// 确认按钮文字
  final String confirmText;

  /// 取消按钮文字
  final String cancelText;

  /// 确认回调
  final VoidCallback? onConfirm;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 确认按钮样式（主色/危险色/成功色）
  final BAButtonStyle confirmButtonStyle;

  const BAConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
    this.confirmButtonStyle = BAButtonStyle.primary,
  });

  /// 显示确认弹窗
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    BAButtonStyle confirmButtonStyle = BAButtonStyle.primary,
  }) async {
    final result = await BAFrostedDialog.show<bool>(
      context: context,
      title: title,
      child: Text(
        content,
        style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
      ),
      actions: [
        BASecondaryButton(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 12),
        _buildConfirmButton(
          confirmText,
          confirmButtonStyle,
          () => Navigator.of(context).pop(true),
        ),
      ],
      showCloseButton: false,
      barrierDismissible: false,
    );
    return result ?? false;
  }

  static Widget _buildConfirmButton(
    String text,
    BAButtonStyle style,
    VoidCallback onPressed,
  ) {
    switch (style) {
      case BAButtonStyle.danger:
        return BADangerButton(text: text, onPressed: onPressed);
      case BAButtonStyle.success:
        return BAButton(
          style: BAButtonStyle.success,
          onPressed: onPressed,
          child: Text(text),
        );
      default:
        return BAPrimaryButton(text: text, onPressed: onPressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BAFrostedDialog(
      title: title,
      child: Text(
        content,
        style: BATypography.bodyMedium.copyWith(color: BAColors.textSecondary),
      ),
      actions: [
        BASecondaryButton(
          text: cancelText,
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(width: 12),
        _buildConfirmButton(confirmText, confirmButtonStyle, () {
          onConfirm?.call();
          Navigator.of(context).pop();
        }),
      ],
      showCloseButton: false,
      onClose: onCancel,
    );
  }
}

/// 关闭按钮组件
class _CloseButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _CloseButton({this.onPressed});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? BAColors.surfaceVariant : Colors.transparent,
            borderRadius: BATheme.borderRadiusSmall,
          ),
          child: Icon(
            Icons.close,
            color: _isHovered ? BAColors.textPrimary : BAColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
