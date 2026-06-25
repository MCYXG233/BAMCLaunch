import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// 立体输入框组件
class BATextField extends StatefulWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 提示文字
  final String? hintText;

  /// 标签文字
  final String? labelText;

  /// 错误文字
  final String? errorText;

  /// 是否密码
  final bool obscureText;

  /// 是否启用
  final bool enabled;

  /// 是否只读
  final bool readOnly;

  /// 最大行数
  final int? maxLines;

  /// 最小行数
  final int? minLines;

  /// 最大长度
  final int? maxLength;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 文本改变回调
  final ValueChanged<String>? onChanged;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 点击回调
  final VoidCallback? onTap;

  /// 聚焦回调
  final ValueChanged<bool>? onFocusChange;

  /// 自动聚焦
  final bool autofocus;

  /// 输入类型
  final TextInputType? keyboardType;

  /// 文本对齐方式
  final TextAlign textAlign;

  /// 输入框高度
  final double? height;

  const BATextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onFocusChange,
    this.autofocus = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.height,
  });

  @override
  State<BATextField> createState() => _BATextFieldState();
}

class _BATextFieldState extends State<BATextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      widget.onFocusChange?.call(_focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? BAColors.dangerOf(context)
        : (_isFocused
              ? BAColors.primaryOf(context)
              : (_isHovered ? BAColors.borderOf(context) : BAColors.borderOf(context)));

    final shadowOpacity = _isFocused ? 0.4 : 0.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: BATypography.bodyMedium.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? BAColors.surfaceOf(context)
                  : BAColors.surfaceVariantOf(context),
              borderRadius: BATheme.borderRadius,
              border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: BAColors.shadowOf(context).withOpacity(shadowOpacity),
                        blurRadius: _isFocused ? 12 : 6,
                        offset: Offset(0, _isFocused ? 4 : 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              obscureText: _obscureText,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textAlign: widget.textAlign,
              style: BATypography.bodyMedium.copyWith(
                color: widget.enabled
                    ? BAColors.textPrimaryOf(context)
                    : BAColors.textDisabledOf(context),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: BATypography.bodyMedium.copyWith(
                  color: BAColors.textDisabledOf(context),
                ),
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: BAColors.textSecondaryOf(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : widget.suffixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: BATypography.bodySmall.copyWith(color: BAColors.dangerOf(context)),
          ),
        ],
      ],
    );
  }
}

/// 立体开关组件
class BASwitch extends StatefulWidget {
  /// 是否开启
  final bool value;

  /// 改变回调
  final ValueChanged<bool>? onChanged;

  /// 是否禁用
  final bool disabled;

  /// 开关文本
  final String? label;

  const BASwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.disabled = false,
    this.label,
  });

  @override
  State<BASwitch> createState() => _BASwitchState();
}

class _BASwitchState extends State<BASwitch> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.value
        ? (widget.disabled ? BAColors.primaryDarkOf(context) : BAColors.primaryOf(context))
        : (widget.disabled ? BAColors.surfaceVariantOf(context) : BAColors.surfaceOf(context));

    final thumbColor = widget.value
        ? Colors.white
        : (widget.disabled ? BAColors.textDisabledOf(context) : BAColors.textSecondaryOf(context));

    final shadowOpacity = widget.value && !widget.disabled ? 0.4 : 0.2;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: BATypography.bodyMedium.copyWith(
                color: widget.disabled
                    ? BAColors.textDisabledOf(context)
                    : BAColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: widget.disabled
                ? null
                : () => widget.onChanged?.call(!widget.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.value
                      ? Colors.transparent
                      : (widget.disabled
                            ? BAColors.textDisabledOf(context)
                            : BAColors.borderOf(context)),
                  width: 2,
                ),
                boxShadow: widget.disabled
                    ? null
                    : [
                        BoxShadow(
                          color: BAColors.shadowOf(context).withOpacity(shadowOpacity),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: widget.value ? 26 : 4,
                    top: 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        shape: BoxShape.circle,
                        boxShadow: widget.disabled
                            ? null
                            : [
                                BoxShadow(
                                  color: BAColors.shadowOf(context).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 立体滑块组件
class BASlider extends StatefulWidget {
  /// 当前值
  final double value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 改变回调
  final ValueChanged<double>? onChanged;

  /// 改变结束回调
  final ValueChanged<double>? onChangeEnd;

  /// 改变开始回调
  final ValueChanged<double>? onChangeStart;

  /// 是否禁用
  final bool disabled;

  /// 分割数
  final int? divisions;

  /// 滑块标签
  final String? label;

  const BASlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeStart,
    this.disabled = false,
    this.divisions,
    this.label,
  });

  @override
  State<BASlider> createState() => _BASliderState();
}

class _BASliderState extends State<BASlider> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.disabled
        ? BAColors.textDisabledOf(context)
        : BAColors.primaryOf(context);
    final inactiveColor = widget.disabled
        ? BAColors.textDisabledOf(context)
        : BAColors.surfaceVariantOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: BATypography.bodyMedium.copyWith(
              color: widget.disabled
                  ? BAColors.textDisabledOf(context)
                  : BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: activeColor,
              inactiveTrackColor: inactiveColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.1),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              thumbShape: _BAThumbShape(
                isHovered: _isHovered || _isDragging,
                isDisabled: widget.disabled,
                shadowColor: BAColors.shadowOf(context),
              ),
              trackShape: const RoundedRectSliderTrackShape(),
              valueIndicatorColor: BAColors.primaryOf(context),
              valueIndicatorTextStyle: BATypography.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: widget.disabled
                  ? null
                  : (value) {
                      widget.onChanged?.call(value);
                    },
              onChangeStart: widget.disabled
                  ? null
                  : (value) {
                      setState(() => _isDragging = true);
                      widget.onChangeStart?.call(value);
                    },
              onChangeEnd: widget.disabled
                  ? null
                  : (value) {
                      setState(() => _isDragging = false);
                      widget.onChangeEnd?.call(value);
                    },
            ),
          ),
        ),
      ],
    );
  }
}

/// 自定义滑块形状
class _BAThumbShape extends SliderComponentShape {
  final bool isHovered;
  final bool isDisabled;
  final Color shadowColor;

  const _BAThumbShape({
    required this.isHovered,
    required this.isDisabled,
    required this.shadowColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(isHovered ? 24 : 20, isHovered ? 24 : 20);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final radius = isHovered ? 12.0 : 10.0;
    final shadowRadius = isHovered ? 8.0 : 6.0;

    // 阴影
    if (!isDisabled) {
      final shadowPaint = Paint()
        ..color = shadowColor.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowRadius);
      canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);
    }

    // 滑块本体
    final thumbPaint = Paint()..color = sliderTheme.thumbColor!;
    canvas.drawCircle(center, radius, thumbPaint);

    // 滑块内圈
    final innerPaint = Paint()..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(center, radius * 0.4, innerPaint);
  }
}
