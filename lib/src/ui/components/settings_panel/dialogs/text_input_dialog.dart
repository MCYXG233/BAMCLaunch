import 'package:flutter/material.dart';
import '../../../../ui/theme/colors.dart';
import '../../../components/ba_buttons.dart';
import '../../../components/ba_dialog.dart';

/// 通用文本输入对话框（符合设置面板设计语言）
///
/// 支持单个或多个字段输入，每个字段可指定：
/// - 标签、提示文字、是否必填、是否密码框、前缀图标
/// - 简单的校验回调（返回非 null 字符串即视为错误）
///
/// 使用方式：
/// ```dart
/// final result = await BATextInputDialog.show(
///   context: context,
///   title: '新建离线账号',
///   fields: [
///     BATextFieldConfig(
///       label: '用户名',
///       hint: '请输入离线账号用户名',
///       required: true,
///     ),
///   ],
/// );
/// ```
class BATextInputDialog extends StatefulWidget {
  /// 对话框标题
  final String title;

  /// 标题栏图标（可选）
  final IconData? titleIcon;

  /// 字段配置列表
  final List<BATextFieldConfig> fields;

  /// 确认按钮文字
  final String confirmText;

  /// 取消按钮文字
  final String cancelText;

  /// 对话框宽度
  final double width;

  /// 顶部说明文字（可选）
  final String? description;

  const BATextInputDialog({
    super.key,
    required this.title,
    this.titleIcon,
    required this.fields,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.width = 480,
    this.description,
  });

  /// 显示对话框，返回各字段的输入值（按 fields 顺序）
  /// 用户点击取消或关闭时返回 null
  static Future<List<String>?> show({
    required BuildContext context,
    required String title,
    IconData? titleIcon,
    required List<BATextFieldConfig> fields,
    String confirmText = '确定',
    String cancelText = '取消',
    double width = 480,
    String? description,
  }) {
    return showDialog<List<String>?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => BATextInputDialog(
        title: title,
        titleIcon: titleIcon,
        fields: fields,
        confirmText: confirmText,
        cancelText: cancelText,
        width: width,
        description: description,
      ),
    );
  }

  @override
  State<BATextInputDialog> createState() => _BATextInputDialogState();
}

class _BATextInputDialogState extends State<BATextInputDialog> {
  late List<TextEditingController> _controllers;
  late List<String?> _errors;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f.initialValue ?? ''))
        .toList();
    _errors = List.filled(widget.fields.length, null);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    for (int i = 0; i < widget.fields.length; i++) {
      final field = widget.fields[i];
      final value = _controllers[i].text.trim();
      String? err;
      if (field.required && value.isEmpty) {
        err = '${field.label}不能为空';
      } else if (field.validator != null) {
        err = field.validator!(value);
      }
      setState(() => _errors[i] = err);
      if (err != null) ok = false;
    }
    return ok;
  }

  void _onConfirm() {
    if (!_validate()) return;
    Navigator.of(context).pop(_controllers.map((c) => c.text.trim()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: widget.title,
      titleIcon: widget.titleIcon,
      width: widget.width,
      onClose: () => Navigator.of(context).pop(null),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.description != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: BAColors.primaryOf(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.description!,
                        style: TextStyle(
                          color: BAColors.textSecondaryOf(context),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            for (int i = 0; i < widget.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _buildField(i),
            ],
          ],
        ),
      ),
      actions: [
        BASecondaryButton(
          text: widget.cancelText,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        const SizedBox(width: 12),
        BAPrimaryButton(
          text: widget.confirmText,
          onPressed: _onConfirm,
        ),
      ],
    );
  }

  Widget _buildField(int index) {
    final field = widget.fields[index];
    final err = _errors[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (field.icon != null) ...[
              Icon(
                field.icon,
                size: 14,
                color: BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              field.label,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (field.required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: BAColors.dangerOf(context),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[index],
          obscureText: field.obscureText,
          keyboardType: field.keyboardType,
          maxLines: field.maxLines,
          autofocus: index == 0,
          decoration: InputDecoration(
            filled: true,
            fillColor: BAColors.surfaceOf(context),
            hintText: field.hint,
            hintStyle: TextStyle(color: BAColors.textDisabledOf(context)),
            errorText: err,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BAColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: BAColors.primaryOf(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: BAColors.dangerOf(context),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: BAColors.dangerOf(context),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: TextStyle(color: BAColors.textPrimaryOf(context), fontSize: 14),
          onSubmitted: (_) => _onConfirm(),
        ),
      ],
    );
  }
}

/// 文本输入对话框字段配置
class BATextFieldConfig {
  /// 字段标签
  final String label;

  /// 提示文字
  final String? hint;

  /// 是否必填
  final bool required;

  /// 是否密码框
  final bool obscureText;

  /// 前缀图标
  final IconData? icon;

  /// 输入类型
  final TextInputType? keyboardType;

  /// 最大行数（>1 时为多行）
  final int? maxLines;

  /// 初始值
  final String? initialValue;

  /// 校验函数（返回非 null 字符串即视为错误信息）
  final String? Function(String)? validator;

  const BATextFieldConfig({
    required this.label,
    this.hint,
    this.required = false,
    this.obscureText = false,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.initialValue,
    this.validator,
  });
}
