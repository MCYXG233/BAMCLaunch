import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// 紧凑下拉选择 - 用于筛选版本/加载器等
class CompactDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final List<String>? displayItems;
  final ValueChanged<String?> onChanged;
  final Color textPrimary;

  const CompactDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    this.displayItems,
    required this.onChanged,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: textPrimary.withValues(alpha: 0.5),
              fontSize: 11.5,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: textPrimary.withValues(alpha: 0.6),
          ),
          dropdownColor: BAColors.surfaceOf(context),
          style: TextStyle(color: textPrimary, fontSize: 11.5),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                '全部',
                style: TextStyle(fontSize: 11.5, color: textPrimary),
              ),
            ),
            ...List.generate(items.length, (i) {
              return DropdownMenuItem<String>(
                value: items[i],
                child: Text(displayItems != null ? displayItems![i] : items[i]),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
