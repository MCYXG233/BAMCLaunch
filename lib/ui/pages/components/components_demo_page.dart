import 'package:flutter/material.dart';
import '../../components/layout/breadcrumb_navigation.dart';
import '../../components/tabs/bamc_tab_bar.dart';
import '../../components/layout/bamc_card.dart';
import '../../theme/colors.dart';

class ComponentsDemoPage extends StatelessWidget {
  const ComponentsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BamcColors.background,
      body: Column(
        children: [
          // 面包屑导航
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
                title: '布局组件',
                isActive: true,
              ),
            ],
          ),
          // 主内容区
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '布局组件示例',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标签页切换
                  Expanded(
                    child: BamcTabBar(
                      tabs: [
                        BamcTab(
                          title: '卡片布局',
                          content: _buildCardLayout(),
                        ),
                        BamcTab(
                          title: '网格布局',
                          content: _buildGridLayout(),
                        ),
                        BamcTab(
                          title: '列表布局',
                          content: _buildListLayout(),
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

  Widget _buildCardLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '卡片布局示例',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: BamcColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // 卡片1
            BamcCard(
              title: '功能卡片',
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '这是一个功能卡片示例，展示了如何使用BamcCard组件创建带有标题和内容的卡片。',
                    style: TextStyle(
                      fontSize: 14,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BamcColors.primary,
                          foregroundColor: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('操作按钮'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: BamcColors.primary,
                        ),
                        child: const Text('次要操作'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 卡片2
            BamcCard(
              title: '信息卡片',
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '这是一个信息卡片示例，用于展示详细信息。卡片支持自定义边距、填充和边框样式。',
                    style: TextStyle(
                      fontSize: 14,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    color: BamcColors.border,
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '状态: 已完成',
                        style: TextStyle(
                          fontSize: 14,
                          color: BamcColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '更新时间: 2026-04-16',
                        style: TextStyle(
                          fontSize: 12,
                          color: BamcColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 卡片3
            BamcCard(
              title: '统计卡片',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '1,234',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BamcColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '总用户数',
                          style: TextStyle(
                            fontSize: 14,
                            color: BamcColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    color: BamcColors.border,
                    thickness: 1,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '567',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BamcColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '活跃用户',
                          style: TextStyle(
                            fontSize: 14,
                            color: BamcColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    color: BamcColors.border,
                    thickness: 1,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '89%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BamcColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '转化率',
                          style: TextStyle(
                            fontSize: 14,
                            color: BamcColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '网格布局示例',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return BamcCard(
                  hoverable: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: BamcColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 32,
                          color: BamcColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '卡片 ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BamcColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '这是一个网格卡片',
                        style: TextStyle(
                          fontSize: 14,
                          color: BamcColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '列表布局示例',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: BamcCard(
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: BamcColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.list_alt,
                            size: 24,
                            color: BamcColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '列表项 ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: BamcColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '这是一个列表项的描述文本，展示了如何在列表中使用卡片组件。',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BamcColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.chevron_right,
                          color: BamcColors.textTertiary,
                        ),
                      ],
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
