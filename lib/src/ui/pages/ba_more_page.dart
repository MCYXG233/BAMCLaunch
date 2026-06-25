import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../components/ba_common_widgets.dart';
import '../components/ba_notification.dart';
import '../components/ba_settings_panel.dart';

/// 更多页面
/// 包含存档管理、Mod管理、资源包、光影包、联机大厅、日志、诊断工具等
class BAMorePage extends StatefulWidget {
  const BAMorePage({super.key});

  @override
  State<BAMorePage> createState() => _BAMorePageState();
}

class _BAMorePageState extends State<BAMorePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            _buildHeader(context),
            const SizedBox(height: 20),

            // 统计卡片
            _buildStatsRow(context),
            const SizedBox(height: 24),

            // 游戏管理
            _buildSectionTitle('游戏管理', Icons.sports_esports, context),
            const SizedBox(height: 12),
            _buildGameManagementRow(context),
            const SizedBox(height: 24),

            // 资源管理
            _buildSectionTitle('资源管理', Icons.inventory_2, context),
            const SizedBox(height: 12),
            _buildResourceManagementGrid(context),
            const SizedBox(height: 24),

            // 工具与设置
            _buildSectionTitle('工具与设置', Icons.build, context),
            const SizedBox(height: 12),
            _buildToolsAndSettingsRow(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== 标题 ====================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BAColors.primaryOf(context).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.more_horiz,
            color: BAColors.primaryOf(context),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '更多功能',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
        const Spacer(),
        // 搜索按钮
        BAGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 12,
          opacity: 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 16,
                color: BAColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                '搜索功能',
                style: TextStyle(
                  fontSize: 12,
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 统计卡片 ====================

  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      {'icon': Icons.folder, 'label': '游戏实例', 'value': '9', 'color': BAColors.primaryOf(context)},
      {'icon': Icons.extension, 'label': '已装 Mod', 'value': '24', 'color': BAColors.secondaryOf(context)},
      {'icon': Icons.palette, 'label': '资源包', 'value': '6', 'color': BAColors.accentPinkOf(context)},
      {'icon': Icons.save, 'label': '游戏存档', 'value': '12', 'color': BAColors.accentPinkOf(context)},
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _buildStatCard(
              stats[i]['icon'] as IconData,
              stats[i]['label'] as String,
              stats[i]['value'] as String,
              stats[i]['color'] as Color,
              context,
            ),
          ),
          if (i < stats.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return BAGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      opacity: 0.55,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BAColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 分组标题 ====================

  Widget _buildSectionTitle(String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: BAColors.textSecondaryOf(context),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: BAColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  // ==================== 游戏管理 ====================

  Widget _buildGameManagementRow(BuildContext context) {
    final items = [
      {'icon': Icons.save, 'title': '存档管理', 'subtitle': '导入导出备份', 'color': BAColors.primaryOf(context)},
      {'icon': Icons.upload_file, 'title': '版本隔离', 'subtitle': '独立版本目录', 'color': BAColors.successOf(context)},
      {'icon': Icons.wifi, 'title': '联机大厅', 'subtitle': '与朋友联机', 'color': const Color(0xFF7AA5D6)},
      {'icon': Icons.smart_display, 'title': '直播模式', 'subtitle': '直播优化设置', 'color': BAColors.accentPinkOf(context)},
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _buildLargeFunctionCard(
              items[i]['icon'] as IconData,
              items[i]['title'] as String,
              items[i]['subtitle'] as String,
              items[i]['color'] as Color,
              context,
              () => _showComingSoon(items[i]['title'] as String),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildLargeFunctionCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: BAGlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          opacity: 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BAColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: BAColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '打开',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 资源管理 ====================

  Widget _buildResourceManagementGrid(BuildContext context) {
    final items = [
      {'icon': Icons.extension, 'title': 'Mod 管理', 'subtitle': '安装启用禁用', 'color': BAColors.secondaryOf(context)},
      {'icon': Icons.palette, 'title': '资源包', 'subtitle': '材质包管理', 'color': BAColors.accentPinkOf(context)},
      {'icon': Icons.lightbulb, 'title': '光影包', 'subtitle': '光影效果', 'color': const Color(0xFFE6C46A)},
      {'icon': Icons.inventory_2, 'title': '整合包', 'subtitle': '一键安装', 'color': BAColors.primaryOf(context)},
      {'icon': Icons.map, 'title': '地图', 'subtitle': '地图存档', 'color': BAColors.accentPinkOf(context)},
      {'icon': Icons.dataset, 'title': '数据包', 'subtitle': '数据包管理', 'color': const Color(0xFF7AA5D6)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildSmallFunctionCard(
          items[index]['icon'] as IconData,
          items[index]['title'] as String,
          items[index]['subtitle'] as String,
          items[index]['color'] as Color,
          context,
          () => _showComingSoon(items[index]['title'] as String),
        );
      },
    );
  }

  Widget _buildSmallFunctionCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: BAGlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: 14,
          opacity: 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BAColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: BAColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 工具与设置 ====================

  Widget _buildToolsAndSettingsRow(BuildContext context) {
    final items = [
      {'icon': Icons.terminal, 'title': '游戏日志', 'subtitle': '查看启动日志', 'color': BAColors.textSecondaryOf(context)},
      {'icon': Icons.build, 'title': '诊断工具', 'subtitle': '问题排查', 'color': BAColors.warningOf(context)},
      {'icon': Icons.folder_open, 'title': '游戏目录', 'subtitle': '打开 .minecraft', 'color': BAColors.successOf(context)},
      {'icon': Icons.info_outline, 'title': '关于启动器', 'subtitle': '版本信息', 'color': BAColors.primaryOf(context)},
      {'icon': Icons.settings, 'title': '设置', 'subtitle': '应用设置', 'color': BAColors.textSecondaryOf(context)},
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _buildMediumFunctionCard(
              items[i]['icon'] as IconData,
              items[i]['title'] as String,
              items[i]['subtitle'] as String,
              items[i]['color'] as Color,
              context,
              items[i]['title'] == '设置' ? _openSettings : () => _showComingSoon(items[i]['title'] as String),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildMediumFunctionCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: BAGlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: 14,
          opacity: 0.5,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: BAColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: BAColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 操作方法 ====================

  void _openSettings() {
    SettingsPanel.show(context);
  }

  void _showComingSoon(String feature) {
    NotificationManager().showInfo(
      '功能开发中',
      message: '$feature 即将上线',
    );
  }
}
