import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

const int kSecondaryMouseButton = 0x02;

class BamcContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuEntry> items;
  final bool enabled;
  final Offset? preferredPosition;

  const BamcContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.enabled = true,
    this.preferredPosition,
  });

  @override
  State<BamcContextMenu> createState() => _BamcContextMenuState();
}

class _BamcContextMenuState extends State<BamcContextMenu> {
  OverlayEntry? _overlayEntry;
  Offset? _menuPosition;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _menuPosition = null;
  }

  void _showMenu(BuildContext context, Offset position) {
    if (!widget.enabled || widget.items.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _menuPosition = widget.preferredPosition ??
        Offset(
          position.dx + offset.dx,
          position.dy + offset.dy,
        );

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildContextMenu(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildContextMenu() {
    if (_menuPosition == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _removeMenu,
      child: Stack(
        children: [
          // 透明背景，点击关闭菜单
          Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
          // 菜单内容
          Positioned(
            left: _menuPosition!.dx,
            top: _menuPosition!.dy,
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
                  children: widget.items.asMap().entries.map((entry) {
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
                      return _buildMenuItem(item, index);
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

  Widget _buildMenuItem(ContextMenuItem item, int index) {
    return MouseRegion(
      onEnter: (_) {
        // 可以添加悬停效果
      },
      child: GestureDetector(
        onTap: () {
          item.onTap?.call();
          _removeMenu();
        },
        child: Container(
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

abstract class ContextMenuEntry {}

class ContextMenuItem extends ContextMenuEntry {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final String? shortcut;

  ContextMenuItem({
    required this.text,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.shortcut,
  });
}

class ContextMenuDivider extends ContextMenuEntry {
  ContextMenuDivider();
}
