import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class BamcTable<T> extends StatelessWidget {
  final List<String> headers;
  final List<T> data;
  final List<Widget Function(T)> columnBuilders;
  final Function(T)? onRowTap;
  final Function(T)? onRowDoubleTap;
  final Function(T)? onRowLongPress;
  final bool hoverable;
  final bool striped;
  final double? rowHeight;
  final Color? headerColor;
  final Color? stripeColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const BamcTable({
    super.key,
    required this.headers,
    required this.data,
    required this.columnBuilders,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.hoverable = true,
    this.striped = false,
    this.rowHeight,
    this.headerColor,
    this.stripeColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: BamcColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            height: rowHeight ?? 50,
            decoration: BoxDecoration(
              color: headerColor ?? BamcColors.surface,
              border: const Border(
                bottom: BorderSide(
                  color: BamcColors.border,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: headers.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;
                final isLast = index == headers.length - 1;

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              right: BorderSide(
                                color: BamcColors.border,
                                width: 1,
                              ),
                            ),
                    ),
                    child: Text(
                      header,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BamcColors.textPrimary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Data Rows
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, rowIndex) {
                final item = data[rowIndex];
                final isEven = rowIndex % 2 == 0;

                return MouseRegion(
                  onHover: (_) {},
                  onExit: (_) {},
                  child: GestureDetector(
                    onTap: () => onRowTap?.call(item),
                    onDoubleTap: () => onRowDoubleTap?.call(item),
                    onLongPress: () => onRowLongPress?.call(item),
                    child: Container(
                      height: rowHeight ?? 48,
                      decoration: BoxDecoration(
                        color: hoverable
                            ? null
                            : (striped && !isEven
                                ? stripeColor ?? BamcColors.background
                                : BamcColors.surface),
                        border: Border(
                          bottom: rowIndex == data.length - 1
                              ? BorderSide.none
                              : const BorderSide(
                                  color: BamcColors.border,
                                  width: 1,
                                ),
                        ),
                      ),
                      child: Row(
                        children: columnBuilders.asMap().entries.map((entry) {
                          final index = entry.key;
                          final builder = entry.value;
                          final isLast = index == columnBuilders.length - 1;

                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
                                        right: BorderSide(
                                          color: BamcColors.border,
                                          width: 1,
                                        ),
                                      ),
                              ),
                              child: builder(item),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
