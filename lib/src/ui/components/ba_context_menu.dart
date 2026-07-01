import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';

/// 右键菜单项
class BAContextMenuItem {
  /// 图标
  final IconData? icon;

  /// 文字
  final String label;

  /// 快捷键提示
  final String? shortcut;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否禁用
  final bool disabled;

  /// 是否是危险操作
  final bool danger;

  const BAContextMenuItem({
    this.icon,
    required this.label,
    this.shortcut,
    this.onTap,
    this.disabled = false,
    this.danger = false,
  });
}

/// 右键菜单分隔线
class BAContextMenuDivider extends BAContextMenuItem {
  const BAContextMenuDivider() : super(label: '', disabled: true);
}

/// 右键菜单组件
class BAContextMenu extends StatefulWidget {
  /// 菜单项列表
  final List<BAContextMenuItem> items;

  /// 子组件
  final Widget child;

  const BAContextMenu({super.key, required this.items, required this.child});

  @override
  State<BAContextMenu> createState() => _BAContextMenuState();
}

class _BAContextMenuState extends State<BAContextMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showMenu(BuildContext context, Offset position) {
    _hideMenu();

    _overlayEntry = OverlayEntry(
      builder: (context) => _BAContextMenuOverlay(
        layerLink: _layerLink,
        position: position,
        items: widget.items,
        onClose: _hideMenu,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _showMenu(context, details.globalPosition);
        },
        child: widget.child,
      ),
    );
  }
}

/// 右键菜单覆盖层
class _BAContextMenuOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final Offset position;
  final List<BAContextMenuItem> items;
  final VoidCallback onClose;

  const _BAContextMenuOverlay({
    required this.layerLink,
    required this.position,
    required this.items,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: CompositedTransformTarget(
              link: layerLink,
              child: _BAContextMenuContent(items: items, onClose: onClose),
            ),
          ),
        ],
      ),
    );
  }
}

/// 右键菜单内容
class _BAContextMenuContent extends StatelessWidget {
  final List<BAContextMenuItem> items;
  final VoidCallback onClose;

  const _BAContextMenuContent({required this.items, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BATheme.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: BATheme.blurSigma,
            sigmaY: BATheme.blurSigma,
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BATheme.borderRadius,
              border: Border.all(color: BAColors.borderOf(context), width: 1),
              boxShadow: BATheme.shadowsOf(context),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.asMap().entries.map((entry) {
                  final item = entry.value;

                  if (item is BAContextMenuDivider) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: BAColors.borderOf(context),
                      ),
                    );
                  }

                  return _BAContextMenuItemWidget(
                    item: item,
                    onTap: () {
                      onClose();
                      item.onTap?.call();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 右键菜单项组件
class _BAContextMenuItemWidget extends StatefulWidget {
  final BAContextMenuItem item;
  final VoidCallback onTap;

  const _BAContextMenuItemWidget({required this.item, required this.onTap});

  @override
  State<_BAContextMenuItemWidget> createState() =>
      _BAContextMenuItemWidgetState();
}

class _BAContextMenuItemWidgetState extends State<_BAContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.item.disabled;
    final textColor = isEnabled
        ? (widget.item.danger ? BAColors.dangerOf(context) : BAColors.textPrimaryOf(context))
        : BAColors.textDisabledOf(context);
    final iconColor = isEnabled
        ? (widget.item.danger ? BAColors.dangerOf(context) : BAColors.textSecondaryOf(context))
        : BAColors.textDisabledOf(context);
    final primaryColor = BAColors.primaryOf(context);
    final dangerColor = BAColors.dangerOf(context);

    return MouseRegion(
      onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _isHovered
              ? (widget.item.danger
                    ? dangerColor.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.15))
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (widget.item.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(widget.item.icon, color: iconColor, size: 18),
                ),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: BATypography.bodyMedium.copyWith(color: textColor),
                ),
              ),
              if (widget.item.shortcut != null)
                Text(
                  widget.item.shortcut!,
                  style: BATypography.bodySmall.copyWith(
                    color: BAColors.textDisabledOf(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
