import 'package:flutter/material.dart';
import '../../../../ui/theme/colors.dart';
import '../../../components/ba_buttons.dart';
import '../../../components/ba_dialog.dart';

/// 更新日志条目
class ChangelogEntry {
  /// 版本号
  final String version;

  /// 发布日期
  final String date;

  /// 更新类型（new / improved / fixed）
  final ChangelogCategory category;

  /// 更新内容标题
  final String title;

  /// 更新内容详细描述
  final String description;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.category,
    required this.title,
    required this.description,
  });
}

/// 更新日志分类
enum ChangelogCategory {
  /// 新功能
  feature,

  /// 改进
  improvement,

  /// 修复
  bugfix,
}

/// 更新日志对话框
///
/// 以卡片形式展示版本更新内容，按版本分组，每个条目带分类徽章。
class ChangelogDialog extends StatefulWidget {
  /// 更新日志条目列表（按版本从新到旧排序）
  final List<ChangelogEntry> entries;

  /// 当前启动器版本（用于高亮）
  final String currentVersion;

  const ChangelogDialog({
    super.key,
    required this.entries,
    required this.currentVersion,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ChangelogEntry> entries,
    required String currentVersion,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => ChangelogDialog(
        entries: entries,
        currentVersion: currentVersion,
      ),
    );
  }

  @override
  State<ChangelogDialog> createState() => _ChangelogDialogState();
}

class _ChangelogDialogState extends State<ChangelogDialog> {
  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '更新日志',
      titleIcon: Icons.auto_awesome_rounded,
      width: 560,
      onClose: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 460,
        child: widget.entries.isEmpty
            ? _buildEmpty()
            : _buildList(),
      ),
      actions: [
        BASecondaryButton(
          text: '关闭',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 56,
            color: BAColors.textDisabledOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无更新日志',
            style: TextStyle(
              color: BAColors.textSecondaryOf(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    // 按版本分组
    final groups = <String, List<ChangelogEntry>>{};
    for (final e in widget.entries) {
      groups.putIfAbsent(e.version, () => []).add(e);
    }
    final versions = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(right: 4),
      itemCount: versions.length,
      itemBuilder: (_, index) {
        final v = versions[index];
        final items = groups[v]!;
        final isCurrent = v == widget.currentVersion;
        return Padding(
          padding: EdgeInsets.only(bottom: index < versions.length - 1 ? 16 : 0),
          child: _buildVersionBlock(v, items, isCurrent: isCurrent),
        );
      },
    );
  }

  Widget _buildVersionBlock(
    String version,
    List<ChangelogEntry> items, {
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? BAColors.primaryOf(context).withValues(alpha: 0.06)
            : BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? BAColors.primaryOf(context).withValues(alpha: 0.55)
              : BAColors.borderOf(context),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BAColors.primaryOf(context).withValues(alpha: 0.20),
                      BAColors.primaryOf(context).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: BAColors.primaryOf(context).withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Text(
                  'v$version',
                  style: TextStyle(
                    color: BAColors.primaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: BAColors.primaryOf(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '当前版本',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (items.first.date.isNotEmpty)
                Text(
                  items.first.date,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((e) => _buildEntry(e)),
        ],
      ),
    );
  }

  Widget _buildEntry(ChangelogEntry e) {
    final (color, icon, label) = switch (e.category) {
      ChangelogCategory.feature => (
        BAColors.successOf(context),
        Icons.fiber_new,
        '新增',
      ),
      ChangelogCategory.improvement => (
        BAColors.primaryOf(context),
        Icons.trending_up,
        '改进',
      ),
      ChangelogCategory.bugfix => (
        BAColors.warningOf(context),
        Icons.bug_report_outlined,
        '修复',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (e.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.description,
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
