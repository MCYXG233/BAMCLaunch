import 'package:flutter/material.dart';
import '../../components/layout/breadcrumb_navigation.dart';
import '../../components/tabs/bamc_tab_bar.dart';
import '../../components/lists/bamc_card_list.dart';
import '../../components/menus/bamc_context_menu.dart';
import '../../theme/colors.dart';

class CardListDemoPage extends StatefulWidget {
  const CardListDemoPage({super.key});

  @override
  State<CardListDemoPage> createState() => _CardListDemoPageState();
}

class _CardListDemoPageState extends State<CardListDemoPage> {
  List<DemoItem> singleColumnItems = [];
  List<DemoItem> gridItems = [];
  DemoItem? selectedSingleItem;
  List<DemoItem> selectedMultiItems = [];

  @override
  void initState() {
    super.initState();
    _initDemoData();
  }

  void _initDemoData() {
    singleColumnItems = List.generate(10, (index) => DemoItem(
      id: index + 1,
      title: '单栏卡片 ${index + 1}',
      subtitle: '这是卡片 ${index + 1} 的描述信息',
      icon: Icons.folder,
    ));

    gridItems = List.generate(12, (index) => DemoItem(
      id: index + 100,
      title: '网格卡片 ${index + 1}',
      subtitle: '网格布局卡片',
      icon: Icons.image,
    ));
  }

  List<ContextMenuEntry> _buildContextMenuItems(DemoItem item, int index) {
    return [
      ContextMenuItem(
        text: '打开',
        icon: Icons.open_in_new,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('正在打开: ${item.title}')),
          );
        },
      ),
      ContextMenuItem(
        text: '编辑',
        icon: Icons.edit,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('正在编辑: ${item.title}')),
          );
        },
      ),
      ContextMenuDivider(),
      ContextMenuItem(
        text: '复制',
        icon: Icons.copy,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已复制: ${item.title}')),
          );
        },
      ),
      ContextMenuItem(
        text: '删除',
        icon: Icons.delete,
        onTap: () {
          setState(() {
            singleColumnItems.remove(item);
            gridItems.remove(item);
            if (selectedSingleItem == item) {
              selectedSingleItem = null;
            }
            selectedMultiItems.remove(item);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除: ${item.title}')),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BamcColors.background,
      body: Column(
        children: [
          BreadcrumbNavigation(
            items: [
              BreadcrumbItem(
                title: '首页',
                onTap: () {},
              ),
              BreadcrumbItem(
                title: '组件库',
                onTap: () {},
              ),
              BreadcrumbItem(
                title: '卡片列表',
                isActive: true,
              ),
            ],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '卡片列表组件示例',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '支持悬浮效果、选中边框、右键菜单和键盘导航',
                    style: TextStyle(
                      fontSize: 14,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: BamcTabBar(
                      tabs: [
                        BamcTab(
                          title: '单栏列表',
                          content: _buildSingleColumnList(),
                        ),
                        BamcTab(
                          title: '网格列表',
                          content: _buildGridList(),
                        ),
                        BamcTab(
                          title: '多选列表',
                          content: _buildMultiSelectList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleColumnList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '单栏卡片列表',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    final newId = singleColumnItems.length + 1;
                    singleColumnItems.add(DemoItem(
                      id: newId,
                      title: '新卡片 $newId',
                      subtitle: '刚添加的新卡片',
                      icon: Icons.note_add,
                    ));
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加卡片'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '使用方向键导航，按 Enter 选择，按 Menu 键打开右键菜单',
            style: TextStyle(
              fontSize: 12,
              color: BamcColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BamcCardList<DemoItem>(
              items: singleColumnItems,
              selectedItem: selectedSingleItem,
              onSelectionChanged: (item) {
                setState(() {
                  selectedSingleItem = item;
                });
              },
              onTap: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('点击了: ${item.title}')),
                );
              },
              contextMenuItems: _buildContextMenuItems,
              cardHeight: 100,
              itemBuilder: (context, item, index, isSelected) {
                return BamcCardItem(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BamcColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: BamcColors.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: BamcColors.textTertiary,
                  ),
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '网格卡片列表 (3列)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '支持网格布局，可设置列数、间距和卡片尺寸',
            style: TextStyle(
              fontSize: 12,
              color: BamcColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BamcCardList<DemoItem>(
              items: gridItems,
              selectedItem: selectedSingleItem,
              onSelectionChanged: (item) {
                setState(() {
                  selectedSingleItem = item;
                });
              },
              onTap: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('点击了: ${item.title}')),
                );
              },
              contextMenuItems: _buildContextMenuItems,
              crossAxisCount: 3,
              cardHeight: 180,
              itemBuilder: (context, item, index, isSelected) {
                return BamcCardItem(
                  thumbnail: Container(
                    color: BamcColors.primary.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        item.icon,
                        size: 48,
                        color: BamcColors.primary,
                      ),
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  footer: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: BamcColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${100 + index}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: BamcColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: BamcColors.textTertiary,
                      ),
                    ],
                  ),
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '多选卡片列表',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.textPrimary,
                ),
              ),
              if (selectedMultiItems.isNotEmpty)
                Text(
                  '已选择 ${selectedMultiItems.length} 项',
                  style: const TextStyle(
                    fontSize: 14,
                    color: BamcColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '支持多选模式，点击卡片切换选中状态',
            style: TextStyle(
              fontSize: 12,
              color: BamcColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BamcCardList<DemoItem>(
              items: singleColumnItems,
              multiSelect: true,
              selectedItems: selectedMultiItems,
              onMultiSelectionChanged: (items) {
                setState(() {
                  selectedMultiItems = items;
                });
              },
              contextMenuItems: _buildContextMenuItems,
              cardHeight: 80,
              itemBuilder: (context, item, index, isSelected) {
                return BamcCardItem(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: null,
                    activeColor: BamcColors.primary,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DemoItem {
  final int id;
  final String title;
  final String subtitle;
  final IconData icon;

  DemoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DemoItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
