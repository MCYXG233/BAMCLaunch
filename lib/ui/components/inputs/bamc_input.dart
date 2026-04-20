import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum BamcInputSize {
  small,
  medium,
  large,
}

class BamcInput extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final BamcInputSize size;
  final bool fullWidth;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const BamcInput({
    super.key,
    this.hintText,
    this.labelText,
    this.errorText,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onTap,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.size = BamcInputSize.medium,
    this.fullWidth = false,
    this.borderRadius,
    this.fillColor,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<BamcInput> createState() => _BamcInputState();
}

class _BamcInputState extends State<BamcInput> {
  late TextEditingController _controller;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant BamcInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange(bool isFocused) {
    setState(() {
      _isFocused = isFocused;
    });
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  double _getPaddingVertical() {
    switch (widget.size) {
      case BamcInputSize.small:
        return 8;
      case BamcInputSize.medium:
        return 12;
      case BamcInputSize.large:
        return 16;
    }
  }

  double _getPaddingHorizontal() {
    switch (widget.size) {
      case BamcInputSize.small:
        return 12;
      case BamcInputSize.medium:
        return 16;
      case BamcInputSize.large:
        return 20;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case BamcInputSize.small:
        return 12;
      case BamcInputSize.medium:
        return 14;
      case BamcInputSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case BamcInputSize.small:
        return 16;
      case BamcInputSize.medium:
        return 20;
      case BamcInputSize.large:
        return 24;
    }
  }

  InputBorder _getBorder() {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8);

    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: BamcColors.warning,
          width: 2,
        ),
      );
    }

    if (_isFocused) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(
          color: BamcColors.primary,
          width: 2,
        ),
      );
    }

    if (_isHovered && widget.enabled) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: BamcColors.primary.withOpacity(0.6),
          width: 1,
        ),
      );
    }

    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(
        color: BamcColors.border,
        width: 1,
        style: BorderStyle.solid,
      ),
    );
  }

  List<BoxShadow>? _getBoxShadow() {
    if (_isFocused && widget.enabled) {
      return [
        BoxShadow(
          color: BamcColors.primary.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: BamcColors.primary.withOpacity(0.15),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.readOnly;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.labelText!,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? BamcColors.textDisabled
                        : (_isFocused
                            ? BamcColors.primary
                            : BamcColors.textPrimary),
                    fontFamily: 'Minecraft',
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                boxShadow: _getBoxShadow(),
              ),
              child: TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                maxLength: widget.maxLength,
                maxLines: widget.maxLines,
                minLines: widget.minLines ?? widget.maxLines,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                validator: widget.validator,
                autofocus: widget.autofocus,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onSubmitted,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  color: isDisabled
                      ? BamcColors.textDisabled
                      : BamcColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: _getFontSize(),
                    color: BamcColors.textSecondary,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Container(
                          margin: const EdgeInsets.only(left: 12, right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? BamcColors.background
                                : (_isFocused
                                    ? BamcColors.primary.withOpacity(0.15)
                                    : BamcColors.background),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDisabled
                                  ? BamcColors.border
                                  : (_isFocused
                                      ? BamcColors.primary
                                      : BamcColors.border),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.prefixIcon,
                            size: _getIconSize() - 4,
                            color: isDisabled
                                ? BamcColors.textDisabled
                                : (_isFocused
                                    ? BamcColors.primary
                                    : BamcColors.textSecondary),
                          ),
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? IconButton(
                          icon: Icon(
                            widget.suffixIcon,
                            size: _getIconSize(),
                            color: isDisabled
                                ? BamcColors.textDisabled
                                : (_isFocused
                                    ? BamcColors.primary
                                    : BamcColors.textSecondary),
                          ),
                          onPressed: widget.onSuffixIconPressed,
                          padding: const EdgeInsets.all(8),
                          constraints: BoxConstraints(
                            minWidth: _getIconSize() + 16,
                            minHeight: _getIconSize() + 16,
                          ),
                        )
                      : null,
                  filled: widget.fillColor != null,
                  fillColor: widget.fillColor,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: _getPaddingVertical(),
                    horizontal: widget.prefixIcon != null
                        ? 12
                        : _getPaddingHorizontal(),
                  ),
                  border: _getBorder(),
                  enabledBorder: _getBorder(),
                  focusedBorder: _getBorder(),
                  errorBorder: _getBorder(),
                  focusedErrorBorder: _getBorder(),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: BamcColors.border,
                      width: 1,
                    ),
                  ),
                  errorText: widget.errorText,
                  errorStyle: TextStyle(
                    fontSize: _getFontSize() - 2,
                    color: BamcColors.warning,
                  ),
                  counterStyle: TextStyle(
                    fontSize: _getFontSize() - 2,
                    color: BamcColors.textSecondary,
                  ),
                ),
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
