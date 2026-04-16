import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';
import '../menus/bamc_context_menu.dart';

class BamcCardList<T> extends StatefulWidget {
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
  final double? cardWidth;
  final double? cardHeight;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;

  const BamcCardList({
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
    this.cardWidth,
    this.cardHeight,
    this.crossAxisCount = 1,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  State<BamcCardList<T>> createState() => _BamcCardListState<T>();
}

class _BamcCardListState<T> extends State<BamcCardList<T>> {
  FocusNode? _focusNode;
  int? _hoveredIndex;
  int? _keyboardSelectedIndex;
  final GlobalKey _listKey = GlobalKey();

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
        case LogicalKeyboardKey.arrowRight:
          _handleArrowRight();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowLeft:
          _handleArrowLeft();
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
    } else if (_keyboardSelectedIndex! + widget.crossAxisCount < widget.items.length) {
      setState(() {
        _keyboardSelectedIndex = _keyboardSelectedIndex! + widget.crossAxisCount;
      });
    }
    _scrollToIndex(_keyboardSelectedIndex!);
  }

  void _handleArrowUp() {
    if (_keyboardSelectedIndex == null) {
      setState(() {
        _keyboardSelectedIndex = widget.items.length - 1;
      });
    } else if (_keyboardSelectedIndex! - widget.crossAxisCount >= 0) {
      setState(() {
        _keyboardSelectedIndex = _keyboardSelectedIndex! - widget.crossAxisCount;
      });
    }
    _scrollToIndex(_keyboardSelectedIndex!);
  }

  void _handleArrowRight() {
    if (_keyboardSelectedIndex == null) {
      setState(() {
        _keyboardSelectedIndex = 0;
      });
    } else if (_keyboardSelectedIndex! + 1 < widget.items.length) {
      setState(() {
        _keyboardSelectedIndex = _keyboardSelectedIndex! + 1;
      });
    }
    _scrollToIndex(_keyboardSelectedIndex!);
  }

  void _handleArrowLeft() {
    if (_keyboardSelectedIndex == null) {
      setState(() {
        _keyboardSelectedIndex = widget.items.length - 1;
      });
    } else if (_keyboardSelectedIndex! - 1 >= 0) {
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
      final item = widget.items[_keyboardSelectedIndex!];
      if (widget.contextMenuItems != null) {
        final context = _listKey.currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            final center = renderBox.localToGlobal(Offset(size.width / 2, size.height / 2));
            _showContextMenuAtPosition(context, item, _keyboardSelectedIndex!, center);
          }
        }
      }
    }
  }

  void _showContextMenuAtPosition(BuildContext context, T item, int index, Offset position) {
    if (widget.contextMenuItems == null) return;
    
    final entries = widget.contextMenuItems!(item, index);
    if (entries.isEmpty) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        items: entries,
        onRemove: () {
          overlayEntry.remove();
        },
      ),
    );
    overlay.insert(overlayEntry);
  }

  void _scrollToIndex(int index) {
    if (widget.controller == null) return;
    
    final itemHeight = widget.cardHeight ?? 120.0;
    final rowsPerScroll = index ~/ widget.crossAxisCount;
    final targetOffset = rowsPerScroll * (itemHeight + widget.runSpacing);
    
    widget.controller!.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildCardItem(T item, int index) {
    final isSelected = widget.multiSelect
        ? widget.selectedItems?.contains(item) ?? false
        : widget.selectedItem == item;
    final isHovered = _hoveredIndex == index;
    final isKeyboardSelected = _keyboardSelectedIndex == index;

    Widget itemWidget = widget.itemBuilder(context, item, index, isSelected);

    if (widget.contextMenuItems != null) {
      itemWidget = _CardContextMenu(
        items: widget.contextMenuItems!(item, index),
        child: itemWidget,
      );
    }

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight,
      child: MouseRegion(
        onEnter: (_) => _handleHover(index),
        onExit: (_) => _handleHover(null),
        child: GestureDetector(
          onTap: () => _handleItemTap(item, index),
          onDoubleTap: () => _handleItemDoubleTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? BamcColors.primary.withOpacity(0.1)
                  : isHovered
                      ? BamcColors.background
                      : BamcColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? BamcColors.primary
                    : isKeyboardSelected
                        ? BamcColors.primaryLight
                        : isHovered
                            ? BamcColors.border
                            : BamcColors.transparent,
                width: isSelected || isKeyboardSelected ? 2 : 1,
              ),
              boxShadow: isHovered || isSelected || isKeyboardSelected
                  ? [
                      BamcEffects.standardShadow(
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: itemWidget,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: _listKey,
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.crossAxisCount > 1
          ? GridView.builder(
              controller: widget.controller,
              padding: widget.padding ?? const EdgeInsets.all(16),
              shrinkWrap: widget.shrinkWrap,
              scrollDirection: widget.scrollDirection,
              reverse: widget.reverse,
              physics: widget.physics,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                crossAxisSpacing: widget.spacing,
                mainAxisSpacing: widget.runSpacing,
                childAspectRatio: widget.cardWidth != null && widget.cardHeight != null
                    ? widget.cardWidth! / widget.cardHeight!
                    : 1.0,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return _buildCardItem(item, index);
              },
            )
          : ListView.builder(
              controller: widget.controller,
              padding: widget.padding ?? const EdgeInsets.all(16),
              shrinkWrap: widget.shrinkWrap,
              scrollDirection: widget.scrollDirection,
              reverse: widget.reverse,
              physics: widget.physics,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < widget.items.length - 1 ? widget.runSpacing : 0),
                  child: _buildCardItem(item, index),
                );
              },
            ),
    );
  }
}

class _CardContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuEntry> items;

  const _CardContextMenu({
    required this.child,
    required this.items,
  });

  @override
  State<_CardContextMenu> createState() => _CardContextMenuState();
}

class _CardContextMenuState extends State<_CardContextMenu> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showMenu(BuildContext context, Offset position) {
    if (widget.items.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        items: widget.items,
        onRemove: _removeMenu,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          _showMenu(context, event.position);
        }
      },
      child: widget.child,
    );
  }
}

class _ContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final List<ContextMenuEntry> items;
  final VoidCallback onRemove;

  const _ContextMenuOverlay({
    required this.position,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Stack(
        children: [
          Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: BamcEffects.glassEffect(
              backgroundColor: BamcColors.glassBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BamcColors.border,
                width: 1,
              ),
              shadow: BamcEffects.standardShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 180,
                  maxWidth: 300,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    if (item is ContextMenuDivider) {
                      return const Divider(
                        height: 1,
                        thickness: 1,
                        color: BamcColors.divider,
                      );
                    }

                    if (item is ContextMenuItem) {
                      return _ContextMenuItem(
                        item: item,
                        onTap: () {
                          item.onTap?.call();
                          onRemove();
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;

  const _ContextMenuItem({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          color: Colors.transparent,
          child: Row(
            children: [
              if (item.icon != null)
                Icon(
                  item.icon,
                  size: 16,
                  color: item.enabled
                      ? BamcColors.textPrimary
                      : BamcColors.textDisabled,
                ),
              if (item.icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.enabled
                        ? BamcColors.textPrimary
                        : BamcColors.textDisabled,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.shortcut != null)
                Text(
                  item.shortcut!,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.enabled
                        ? BamcColors.textSecondary
                        : BamcColors.textDisabled,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BamcCardItem extends StatelessWidget {
  final Widget? leading;
  final Widget? thumbnail;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? footer;
  final bool selected;
  final EdgeInsets? padding;
  final double? aspectRatio;

  const BamcCardItem({
    super.key,
    this.leading,
    this.thumbnail,
    required this.title,
    this.subtitle,
    this.trailing,
    this.footer,
    this.selected = false,
    this.padding,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumbnail != null)
          AspectRatio(
            aspectRatio: aspectRatio ?? 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: thumbnail!,
            ),
          ),
        Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected ? BamcColors.primary : BamcColors.textPrimary,
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
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: footer!,
                ),
            ],
          ),
        ),
      ],
    );

    return content;
  }
}
