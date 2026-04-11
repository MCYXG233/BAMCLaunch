import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';
import '../menus/bamc_context_menu.dart';

class BamcList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int, bool) itemBuilder;
  final ValueChanged<T>? onTap;
  final ValueChanged<T>? onDoubleTap;
  final List<ContextMenuEntry> Function(T, int)? contextMenuItems;
  final T? selectedItem;
  final ValueChanged<T>? onSelectionChanged;
  final bool multiSelect;
  final List<T>? selectedItems;
  final ValueChanged<List<T>>? onMultiSelectionChanged;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;

  const BamcList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onTap,
    this.onDoubleTap,
    this.contextMenuItems,
    this.selectedItem,
    this.onSelectionChanged,
    this.multiSelect = false,
    this.selectedItems,
    this.onMultiSelectionChanged,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
  });

  @override
  State<BamcList<T>> createState() => _BamcListState<T>();
}

class _BamcListState<T> extends State<BamcList<T>> {
  FocusNode? _focusNode;
  int? _hoveredIndex;
  int? _keyboardSelectedIndex;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _handleItemTap(T item, int index) {
    if (widget.multiSelect) {
      final currentSelected = widget.selectedItems?.toList() ?? [];
      if (currentSelected.contains(item)) {
        currentSelected.remove(item);
      } else {
        currentSelected.add(item);
      }
      widget.onMultiSelectionChanged?.call(currentSelected);
    } else {
      widget.onSelectionChanged?.call(item);
    }
    widget.onTap?.call(item);
  }

  void _handleItemDoubleTap(T item) {
    widget.onDoubleTap?.call(item);
  }

  void _handleHover(int? index) {
    setState(() {
      _hoveredIndex = index;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _handleArrowDown();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
          _handleArrowUp();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          _handleEnter();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.contextMenu:
          _handleContextMenu();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _handleArrowDown() {
    if (_keyboardSelectedIndex == null) {
      setState(() {
        _keyboardSelectedIndex = 0;
      });
    } else if (_keyboardSelectedIndex! < widget.items.length - 1) {
      setState(() {
        _keyboardSelectedIndex = _keyboardSelectedIndex! + 1;
      });
    }
    _scrollToIndex(_keyboardSelectedIndex!);
  }

  void _handleArrowUp() {
    if (_keyboardSelectedIndex == null) {
      setState(() {
        _keyboardSelectedIndex = widget.items.length - 1;
      });
    } else if (_keyboardSelectedIndex! > 0) {
      setState(() {
        _keyboardSelectedIndex = _keyboardSelectedIndex! - 1;
      });
    }
    _scrollToIndex(_keyboardSelectedIndex!);
  }

  void _handleEnter() {
    if (_keyboardSelectedIndex != null &&
        _keyboardSelectedIndex! < widget.items.length) {
      final item = widget.items[_keyboardSelectedIndex!];
      _handleItemTap(item, _keyboardSelectedIndex!);
    }
  }

  void _handleContextMenu() {
    if (_keyboardSelectedIndex != null &&
        _keyboardSelectedIndex! < widget.items.length) {
      // 显示右键菜单
    }
  }

  void _scrollToIndex(int index) {
    widget.controller?.animateTo(
      index * 60.0, // 假设每个项高度为60
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildListItem(T item, int index) {
    final isSelected = widget.multiSelect
        ? widget.selectedItems?.contains(item) ?? false
        : widget.selectedItem == item;
    final isHovered = _hoveredIndex == index;
    final isKeyboardSelected = _keyboardSelectedIndex == index;

    Widget itemWidget = widget.itemBuilder(context, item, index, isSelected);

    // 添加右键菜单支持
    if (widget.contextMenuItems != null) {
      itemWidget = BamcContextMenu(
        items: widget.contextMenuItems!(item, index),
        child: itemWidget,
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHover(index),
      onExit: (_) => _handleHover(null),
      child: GestureDetector(
        onTap: () => _handleItemTap(item, index),
        onDoubleTap: () => _handleItemDoubleTap(item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? BamcColors.primary.withOpacity(0.1)
                : isHovered
                    ? BamcColors.background
                    : BamcColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? BamcColors.primary
                  : isHovered
                      ? BamcColors.border
                      : BamcColors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isHovered || isSelected
                ? [
                    BamcEffects.standardShadow(
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: itemWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: ListView.builder(
        controller: widget.controller,
        padding: widget.padding ?? const EdgeInsets.all(8),
        shrinkWrap: widget.shrinkWrap,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: widget.physics,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _buildListItem(item, index);
        },
      ),
    );
  }
}

class BamcListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool selected;
  final EdgeInsets? padding;

  const BamcListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: leading,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? BamcColors.primary : BamcColors.textPrimary,
                  ),
                  child: title,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 12,
                        color: BamcColors.textSecondary,
                      ),
                      child: subtitle!,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: trailing,
            ),
        ],
      ),
    );
  }
}
