import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

class BamcDropdown<T> extends StatefulWidget {
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool fullWidth;

  const BamcDropdown({
    super.key,
    required this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.fullWidth = false,
  });

  @override
  State<BamcDropdown<T>> createState() => _BamcDropdownState<T>();
}

class _BamcDropdownState<T> extends State<BamcDropdown<T>> {
  bool _isFocused = false;
  bool _isHovered = false;

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

  InputBorder _getBorder() {
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: BamcColors.warning,
          width: 2,
        ),
      );
    }

    if (_isFocused) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: BamcColors.primary,
          width: 2,
        ),
      );
    }

    if (_isHovered && widget.enabled) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: BamcColors.primary.withOpacity(0.5),
          width: 1,
        ),
      );
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: BamcColors.border,
        width: 1,
      ),
    );
  }

  List<BoxShadow>? _getBoxShadow() {
    if (_isFocused && widget.enabled) {
      return [
        BamcEffects.glowEffect(
          color: BamcColors.primary,
          blurRadius: 20,
        ),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: _getBoxShadow(),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: widget.value,
            hint: Text(
              widget.hintText,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled
                    ? BamcColors.textDisabled
                    : BamcColors.textSecondary,
              ),
            ),
            items: widget.items,
            onChanged: widget.enabled ? widget.onChanged : null,
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: isDisabled
                          ? BamcColors.textDisabled
                          : (_isFocused
                              ? BamcColors.primary
                              : BamcColors.textSecondary),
                    )
                  : null,
              suffixIcon: widget.suffixIcon ??
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 24,
                    color: BamcColors.textSecondary,
                  ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: _getBorder(),
              enabledBorder: _getBorder(),
              focusedBorder: _getBorder(),
              errorBorder: _getBorder(),
              focusedErrorBorder: _getBorder(),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: BamcColors.border,
                  width: 1,
                ),
              ),
              errorText: widget.errorText,
              errorStyle: const TextStyle(
                fontSize: 12,
                color: BamcColors.warning,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color:
                  isDisabled ? BamcColors.textDisabled : BamcColors.textPrimary,
            ),
            iconEnabledColor:
                isDisabled ? BamcColors.textDisabled : BamcColors.textSecondary,
            dropdownColor: BamcColors.surface,
          ),
        ),
      ),
    );
  }
}
