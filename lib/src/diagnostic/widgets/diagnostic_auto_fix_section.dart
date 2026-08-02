import 'package:flutter/material.dart';
import '../../ui/theme/colors.dart';
import '../auto_fixer.dart';
import 'diagnostic_action_button.dart';

/// 自动修复状态枚举
enum AutoFixStatus { idle, scanning, fixing, completed }

/// 自动修复部分
class DiagnosticAutoFixSection extends StatelessWidget {
  final AutoFixStatus status;
  final bool isScanning;
  final bool isFixing;
  final List<FixIssue> detectedIssues;
  final List<FixResult> fixResults;
  final VoidCallback onScanIssues;
  final VoidCallback onAutoFixIssues;

  const DiagnosticAutoFixSection({
    super.key,
    required this.status,
    required this.isScanning,
    required this.isFixing,
    required this.detectedIssues,
    required this.fixResults,
    required this.onScanIssues,
    required this.onAutoFixIssues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '自动修复', Icons.auto_fix_high_rounded),
        const SizedBox(height: 12),
        _buildAutoFixCard(context),
        if (detectedIssues.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildIssuesList(context),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BAColors.primaryOf(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: BAColors.primaryOf(context), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: BAColors.textPrimaryOf(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoFixCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: BAColors.primaryOf(context).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BAColors.primaryOf(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == AutoFixStatus.scanning
                      ? Icons.search_rounded
                      : status == AutoFixStatus.fixing
                          ? Icons.build_rounded
                          : Icons.auto_fix_high_rounded,
                  color: BAColors.primaryOf(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动修复状态',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAutoFixStatusText(),
                      style: TextStyle(
                        color: BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isScanning || isFixing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAColors.primaryOf(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DiagnosticActionButton(
                  onPressed: (isScanning || isFixing) ? null : onScanIssues,
                  icon: Icons.search_rounded,
                  label: '扫描问题',
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DiagnosticActionButton(
                  onPressed: (isScanning || isFixing || detectedIssues.isEmpty)
                      ? null
                      : onAutoFixIssues,
                  icon: Icons.build_rounded,
                  label: '自动修复问题',
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAutoFixStatusText() {
    switch (status) {
      case AutoFixStatus.idle:
        return detectedIssues.isEmpty
            ? '无问题'
            : '共 ${detectedIssues.length} 个问题，${detectedIssues.where((i) => i.canAutoFix).length} 个可修复问题';
      case AutoFixStatus.scanning:
        return '扫描中';
      case AutoFixStatus.fixing:
        return '修复中...';
      case AutoFixStatus.completed:
        return '修复完成';
    }
  }

  Widget _buildIssuesList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAColors.borderOf(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BAColors.warningOf(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '问题',
                    style: TextStyle(
                      color: BAColors.warningOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${detectedIssues.where((i) => i.canAutoFix).length} 个可修复问题',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(detectedIssues.length, (index) {
            final issue = detectedIssues[index];
            return _buildIssueItem(context, issue, index);
          }),
        ],
      ),
    );
  }

  Widget _buildIssueItem(BuildContext context, FixIssue issue, int index) {
    Color severityColor;
    switch (issue.severity) {
      case FixSeverity.low:
        severityColor = BAColors.infoOf(context);
        break;
      case FixSeverity.medium:
        severityColor = BAColors.warningOf(context);
        break;
      case FixSeverity.high:
        severityColor = BAColors.dangerOf(context);
        break;
      case FixSeverity.critical:
        severityColor = BAColors.dangerOf(context);
        break;
    }

    IconData categoryIcon;
    switch (issue.category) {
      case FixCategory.java:
        categoryIcon = Icons.coffee_rounded;
        break;
      case FixCategory.network:
        categoryIcon = Icons.wifi_rounded;
        break;
      case FixCategory.gameFiles:
        categoryIcon = Icons.folder_rounded;
        break;
      case FixCategory.config:
        categoryIcon = Icons.settings_rounded;
        break;
    }

    return ExpansionTile(
      leading: Icon(categoryIcon, color: severityColor, size: 20),
      title: Text(
        issue.title,
        style: TextStyle(
          color: BAColors.textPrimaryOf(context),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        issue.canAutoFix ? '可自动修复' : '需手动修复',
        style: TextStyle(
          color: issue.canAutoFix
              ? BAColors.successOf(context)
              : BAColors.textSecondaryOf(context),
          fontSize: 12,
        ),
      ),
      iconColor: BAColors.textSecondaryOf(context),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BAColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BAColors.borderOf(context).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  issue.description,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (issue.autoFixDescription != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: BAColors.primaryOf(context),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.autoFixDescription!,
                        style: TextStyle(
                          color: BAColors.primaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              Builder(
                builder: (context) {
                  final fixResult = fixResults
                      .where((r) => r.issueId == issue.id)
                      .firstOrNull;
                  if (fixResult == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: fixResult.isFixed
                              ? BAColors.successOf(context)
                                  .withValues(alpha: 0.1)
                              : BAColors.dangerOf(context)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: fixResult.isFixed
                                ? BAColors.successOf(context)
                                    .withValues(alpha: 0.3)
                                : BAColors.dangerOf(context)
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              fixResult.isFixed
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: fixResult.isFixed
                                  ? BAColors.successOf(context)
                                  : BAColors.dangerOf(context),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fixResult.message ??
                                    (fixResult.isFixed ? '修复成功' : '修复失败'),
                                style: TextStyle(
                                  color: fixResult.isFixed
                                      ? BAColors.successOf(context)
                                      : BAColors.dangerOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
