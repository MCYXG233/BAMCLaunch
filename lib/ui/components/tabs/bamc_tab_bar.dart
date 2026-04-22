import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/effects.dart';

class BamcTab {
  final String title;
  final Widget content;

  BamcTab({
    required this.title,
    required this.content,
  });
}

class BamcTabBar extends StatefulWidget {
  final List<BamcTab> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;
  final bool useGradient;
  final bool hoverable;

  const BamcTabBar({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.useGradient = false,
    this.hoverable = true,
  });

  @override
  State<BamcTabBar> createState() => _BamcTabBarState();
}

class _BamcTabBarState extends State<BamcTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BamcTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: _tabController.index.clamp(0, widget.tabs.length - 1),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateHoverState(int index, bool isHovering) {
    setState(() {
      _hoverStates[index] = isHovering;
    });
  }

  Widget _buildTab(int index) {
    final isSelected = _tabController.index == index;
    final isHovering = _hoverStates[index] ?? false;
    final tab = widget.tabs[index];

    return MouseRegion(
      onEnter: (_) => _updateHoverState(index, true),
      onExit: (_) => _updateHoverState(index, false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.useGradient
                  ? null
                  : BamcColors.primary.withOpacity(0.1)
              : isHovering && widget.hoverable
                  ? BamcColors.primary.withOpacity(0.05)
                  : Colors.transparent,
          gradient: isSelected && widget.useGradient
              ? BamcColors.primaryGradient
              : null,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Text(
          tab.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (widget.useGradient ? Colors.white : BamcColors.primary)
                : BamcColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: BamcColors.border,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: widget.tabs.asMap().entries.map((entry) {
              return Tab(
                child: _buildTab(entry.key),
              );
            }).toList(),
            indicator: const BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: BamcColors.primary,
                  width: 3,
                ),
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            isScrollable: true,
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }
}
