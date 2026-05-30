import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'ba_buttons.dart';

/// 蔚蓝档案风格对话框组件
class BADialog extends StatelessWidget {
  /// 对话框标题
  final String title;

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
    bool showCloseButton = true,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BADialog(
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            width: width,
            height: height,
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 360),
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BAColors.shadowOf(context),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题栏 - 带渐变装饰
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BAColors.primary.withOpacity(0.2),
                        BAColors.primary.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: BAColors.borderOf(context).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: BAColors.textPrimaryOf(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (showCloseButton)
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: BAColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 内容区域
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: child,
                  ),
                ),
                // 按钮区域
                if (actions != null && actions!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: BAColors.borderOf(context).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index > 0 ? 12 : 0,
                          ),
                          child: action,
                        );
                      }).toList(),
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

// 向后兼容别名
typedef BAFrostedDialog = BADialog;

/// 确认对话框（向后兼容）
class BAConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    BAButtonStyle confirmButtonStyle = BAButtonStyle.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BADialog(
        title: title,
        child: Text(
          content,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        actions: [
          BASecondaryButton(
            text: cancelText,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 12),
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
      ),
    );
    return result ?? false;
  }
}
