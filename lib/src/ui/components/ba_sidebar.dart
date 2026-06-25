import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/animations.dart';

/// 侧边栏导航项
class BASidebarItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badge;
  final VoidCallback onTap;

  const BASidebarItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    required this.onTap,
  });
}

/// 简化的侧边栏组件
class BASidebar extends StatefulWidget {
  final List<BASidebarItem> items;
  final String selectedId;
  final void Function(String id) onSelected;
  final bool collapsible;
  final bool initiallyCollapsed;
  final Widget? header;
  final Widget? footer;

  const BASidebar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.collapsible = true,
    this.initiallyCollapsed = false,
    this.header,
    this.footer,
  });

  @override
  State<BASidebar> createState() => _BASidebarState();
}

class _BASidebarState extends State<BASidebar>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.initiallyCollapsed;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(
      begin: 72.0,
      end: 240.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.elasticInOut,
      ),
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.smooth,
      ),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: BAColors.surfaceOf(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              if (widget.header != null) widget.header!,
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return _buildSidebarItem(context, index);
                  },
                ),
              ),
              if (widget.footer != null) widget.footer!,
              if (widget.collapsible) _buildToggleButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(BuildContext context, int index) {
    final item = widget.items[index];
    final isSelected = item.id == widget.selectedId;

    return BAFloatBuilder(
      enabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onSelected(item.id);
              if (!_isExpanded) {
                _toggle();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: BAAnimations.smooth,
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 16 : 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? BAColors.primaryOf(context).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: BAColors.primaryOf(context).withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? (item.selectedIcon ?? item.icon)
                        : item.icon,
                    color: isSelected
                        ? BAColors.primaryOf(context)
                        : BAColors.textSecondaryOf(context),
                    size: 24,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.2, 0),
                            end: Offset.zero,
                          ).animate(_textAnimation),
                          child: Text(
                            item.label,
                            style: BATypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? BAColors.primaryOf(context)
                                  : BAColors.textPrimaryOf(context),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 8),
                      FadeTransition(
                        opacity: _textAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BAColors.dangerOf(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.badge!,
                            style: BATypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                  color: BAColors.textSecondaryOf(context),
                  size: 24,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 8),
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Text(
                      '收起',
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 增强的侧边栏组件
class BAAnimatedSidebar extends StatefulWidget {
  final List<BASidebarItem> items;
  final int selectedIndex;
  final bool expanded;
  final Duration animationDuration;
  final double collapsedWidth;
  final double expandedWidth;
  final VoidCallback? onToggle;
  final Widget? header;
  final Widget? footer;

  const BAAnimatedSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.expanded = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.collapsedWidth = 72.0,
    this.expandedWidth = 240.0,
    this.onToggle,
    this.header,
    this.footer,
  });

  @override
  State<BAAnimatedSidebar> createState() => _BAAnimatedSidebarState();
}

class _BAAnimatedSidebarState extends State<BAAnimatedSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _rotateAnimation;

  bool _isExpanded = true;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.expandedWidth,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.elasticInOut,
      ),
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.smooth,
      ),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: BAAnimations.smooth,
      ),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
                  blurRadius: _isHovered ? 10 : 5,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                if (widget.header != null) widget.header!,
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      return _buildSidebarItem(context, index);
                    },
                  ),
                ),
                if (widget.footer != null) widget.footer!,
                _buildToggleButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, int index) {
    final item = widget.items[index];
    final isSelected = index == widget.selectedIndex;

    return BAFloatBuilder(
      enabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              item.onTap();
              if (!_isExpanded) {
                _toggle();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: BAAnimations.smooth,
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 16 : 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? BAColors.primaryOf(context).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: BAColors.primaryOf(context).withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? (item.selectedIcon ?? item.icon)
                        : item.icon,
                    color: isSelected
                        ? BAColors.primaryOf(context)
                        : BAColors.textSecondaryOf(context),
                    size: 24,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.2, 0),
                            end: Offset.zero,
                          ).animate(_textAnimation),
                          child: Text(
                            item.label,
                            style: BATypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? BAColors.primaryOf(context)
                                  : BAColors.textPrimaryOf(context),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 8),
                      FadeTransition(
                        opacity: _textAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BAColors.dangerOf(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.badge!,
                            style: BATypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _rotateAnimation,
                  child: Icon(
                    Icons.chevron_right,
                    color: BAColors.textSecondaryOf(context),
                    size: 24,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 8),
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Text(
                      '收起',
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
