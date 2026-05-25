import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'ba_buttons.dart';

/// 侧边栏导航项
class BASidebarItem {
  /// 图标
  final IconData icon;

  /// 标签
  final String label;

  /// 唯一标识符
  final String id;

  /// 是否启用
  final bool enabled;

  const BASidebarItem({
    required this.icon,
    required this.label,
    required this.id,
    this.enabled = true,
  });
}

/// 左侧固定侧边栏
class BASidebar extends StatefulWidget {
  /// 导航项列表
  final List<BASidebarItem> items;

  /// 当前选中项的ID
  final String? selectedId;

  /// 选中项变化回调
  final ValueChanged<String>? onSelected;

  /// 是否可折叠
  final bool collapsible;

  /// 初始是否折叠
  final bool initiallyCollapsed;

  /// 折叠状态变化回调
  final ValueChanged<bool>? onCollapsedChanged;

  /// 头部组件
  final Widget? header;

  /// 底部组件
  final Widget? footer;

  /// 宽度（展开时）
  final double expandedWidth;

  /// 宽度（折叠时）
  final double collapsedWidth;

  const BASidebar({
    super.key,
    required this.items,
    this.selectedId,
    this.onSelected,
    this.collapsible = true,
    this.initiallyCollapsed = false,
    this.onCollapsedChanged,
    this.header,
    this.footer,
    this.expandedWidth = 240,
    this.collapsedWidth = 72,
  });

  @override
  State<BASidebar> createState() => _BASidebarState();
}

class _BASidebarState extends State<BASidebar>
    with SingleTickerProviderStateMixin {
  late bool _isCollapsed;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
    _breathController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    widget.onCollapsedChanged?.call(_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: _isCollapsed ? widget.collapsedWidth : widget.expandedWidth,
      decoration: BoxDecoration(
        color: BAColors.surface,
        border: Border(right: BorderSide(color: BAColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: BAColors.shadow.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const Divider(height: 1, thickness: 1, color: BAColors.border),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedId == item.id;
                return _BASidebarItemWidget(
                  item: item,
                  isSelected: isSelected,
                  isCollapsed: _isCollapsed,
                  breathAnimation: _breathAnimation,
                  onTap: item.enabled
                      ? () => widget.onSelected?.call(item.id)
                      : null,
                );
              },
            ),
          ),
          if (widget.collapsible || widget.footer != null) ...[
            const Divider(height: 1, thickness: 1, color: BAColors.border),
            if (widget.footer != null) widget.footer!,
            if (widget.collapsible)
              Padding(
                padding: const EdgeInsets.all(12),
                child: BASecondaryButton(
                  text: _isCollapsed ? '' : '折叠',
                  leadingIcon: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  ),
                  onPressed: _toggleCollapsed,
                  height: 40,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// 侧边栏项组件
class _BASidebarItemWidget extends StatefulWidget {
  final BASidebarItem item;
  final bool isSelected;
  final bool isCollapsed;
  final Animation<double> breathAnimation;
  final VoidCallback? onTap;

  const _BASidebarItemWidget({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.breathAnimation,
    this.onTap,
  });

  @override
  State<_BASidebarItemWidget> createState() => _BASidebarItemWidgetState();
}

class _BASidebarItemWidgetState extends State<_BASidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.item.enabled;

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.breathAnimation,
          builder: (context, child) {
            final breathScale = widget.isSelected
                ? 1.0 + (widget.breathAnimation.value * 0.02)
                : 1.0;
            final breathOpacity = widget.isSelected
                ? 0.15 + (widget.breathAnimation.value * 0.1)
                : 0.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Transform.scale(
                scale: breathScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCollapsed ? 12 : 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? BAColors.primary.withOpacity(breathOpacity + 0.15)
                        : (_isHovered
                              ? BAColors.surfaceVariant
                              : Colors.transparent),
                    borderRadius: BATheme.borderRadius,
                    border: Border.all(
                      color: widget.isSelected
                          ? BAColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: BAColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.item.icon,
                        color: enabled
                            ? (widget.isSelected
                                  ? BAColors.primary
                                  : (_isHovered
                                        ? BAColors.textPrimary
                                        : BAColors.textSecondary))
                            : BAColors.textDisabled,
                        size: 24,
                      ),
                      if (!widget.isCollapsed) ...[
                        const SizedBox(width: 12),
                        Text(
                          widget.item.label,
                          style: BATypography.bodyMedium.copyWith(
                            color: enabled
                                ? (widget.isSelected
                                      ? BAColors.primary
                                      : (_isHovered
                                            ? BAColors.textPrimary
                                            : BAColors.textSecondary))
                                : BAColors.textDisabled,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
