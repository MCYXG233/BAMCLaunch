import 'package:flutter/material.dart';
import 'settings_theme.dart';

/// 设置面板侧栏导航项
class SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showChevron;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: SettingsPalette.glassWhiteHover(context),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? SettingsPalette.accentBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 选中指示条
            if (selected)
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: SettingsPalette.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(width: 11),
            Icon(
              icon,
              size: 16,
              color: selected
                  ? SettingsPalette.textPrimary(context)
                  : SettingsPalette.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? SettingsPalette.textPrimary(context)
                      : SettingsPalette.textSecondary(context),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 14,
                color: SettingsPalette.textHint(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// 侧栏分类标题（如"游戏"、"个性化"）
class SidebarSectionHeader extends StatelessWidget {
  final String label;

  const SidebarSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 16, bottom: 6, right: 14),
      child: Text(
        label,
        style: TextStyle(
          color: SettingsPalette.textHint(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 设置面板侧栏（含搜索 + 分组导航）
class SettingsSidebar extends StatefulWidget {
  final List<SidebarSection> sections;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onClose;

  const SettingsSidebar({
    super.key,
    required this.sections,
    required this.selectedId,
    required this.onSelected,
    required this.onClose,
  });

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: SettingsPalette.sidebarBackground(context),
        border: Border(
          right: BorderSide(
            color: SettingsPalette.cardBorder(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 顶部栏：返回 + 标题
          _buildHeader(context),
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: SettingsPalette.glassWhite(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SettingsPalette.cardBorder(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search,
                    size: 14,
                    color: SettingsPalette.textHint(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: SettingsPalette.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintText: '搜索...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: SettingsPalette.textHint(context),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 导航项
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              children: _buildSections(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: SettingsPalette.textSecondary(context),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: '关闭',
              ),
              const SizedBox(width: 8),
              // 模拟 Logo + 标题
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C5CFF), Color(0xFFE668A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BAMCLaunch',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SettingsPalette.textPrimary(context),
                      ),
                    ),
                    Text(
                      '本地设置',
                      style: TextStyle(
                        fontSize: 10,
                        color: SettingsPalette.textHint(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    for (final section in widget.sections) {
      widgets.add(SidebarSectionHeader(label: section.title));
      for (final item in section.items) {
        widgets.add(
          SidebarNavItem(
            icon: item.icon,
            label: item.label,
            selected: widget.selectedId == item.id,
            onTap: () => widget.onSelected(item.id),
          ),
        );
      }
    }
    return widgets;
  }
}

/// 侧栏分组定义
class SidebarSection {
  final String title;
  final List<SidebarItem> items;

  const SidebarSection({required this.title, required this.items});
}

class SidebarItem {
  final String id;
  final IconData icon;
  final String label;

  const SidebarItem({
    required this.id,
    required this.icon,
    required this.label,
  });
}
