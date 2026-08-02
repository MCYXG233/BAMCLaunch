import 'package:flutter/material.dart';
import '../../ui/theme/colors.dart';
import '../network_diagnostic.dart';
import 'diagnostic_action_button.dart';

/// 网络诊断状态枚举
enum NetworkDiagnosticStatus { pending, running, passed, warning, failed }

/// 网络诊断部分
class DiagnosticNetworkSection extends StatelessWidget {
  final NetworkDiagnosticStatus status;
  final bool isRunning;
  final bool isDone;
  final NetworkDiagnosticReport? report;
  final VoidCallback onRunDiagnostic;
  final VoidCallback onExportReport;

  const DiagnosticNetworkSection({
    super.key,
    required this.status,
    required this.isRunning,
    required this.isDone,
    required this.report,
    required this.onRunDiagnostic,
    required this.onExportReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '网络诊断', Icons.signal_cellular_alt_rounded),
        const SizedBox(height: 12),
        _buildNetworkDiagnosticCard(context),
        if (isDone && report != null) ...[
          const SizedBox(height: 12),
          _buildNetworkResults(context),
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

  Widget _buildNetworkDiagnosticCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getNetworkBorderColor(context).withValues(alpha: 0.6),
          width: status == NetworkDiagnosticStatus.running ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getNetworkBorderColor(context).withValues(alpha: 0.1),
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
              _buildNetworkStatusIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '网络诊断',
                      style: TextStyle(
                        color: BAColors.textPrimaryOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRunning ? '诊断中...' : _getNetworkStatusText(),
                      style: TextStyle(
                        color: isRunning
                            ? BAColors.infoOf(context)
                            : BAColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRunning)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAColors.infoOf(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DiagnosticActionButton(
                  onPressed: isRunning ? null : onRunDiagnostic,
                  icon: Icons.play_arrow_rounded,
                  label: '开始诊断',
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DiagnosticActionButton(
                  onPressed: isDone ? onExportReport : null,
                  icon: Icons.download_rounded,
                  label: '导出报告',
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusIcon(BuildContext context) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (status) {
      case NetworkDiagnosticStatus.pending:
        icon = Icons.hourglass_empty_rounded;
        color = BAColors.textDisabledOf(context);
        bgColor = BAColors.surfaceVariantOf(context);
        break;
      case NetworkDiagnosticStatus.running:
        icon = Icons.sync_rounded;
        color = BAColors.infoOf(context);
        bgColor = BAColors.infoOf(context).withValues(alpha: 0.12);
        break;
      case NetworkDiagnosticStatus.passed:
        icon = Icons.check_circle_rounded;
        color = BAColors.successOf(context);
        bgColor = BAColors.successOf(context).withValues(alpha: 0.12);
        break;
      case NetworkDiagnosticStatus.warning:
        icon = Icons.warning_amber_rounded;
        color = BAColors.warningOf(context);
        bgColor = BAColors.warningOf(context).withValues(alpha: 0.12);
        break;
      case NetworkDiagnosticStatus.failed:
        icon = Icons.error_rounded;
        color = BAColors.dangerOf(context);
        bgColor = BAColors.dangerOf(context).withValues(alpha: 0.12);
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getNetworkBorderColor(BuildContext context) {
    switch (status) {
      case NetworkDiagnosticStatus.pending:
        return BAColors.borderOf(context);
      case NetworkDiagnosticStatus.running:
        return BAColors.infoOf(context);
      case NetworkDiagnosticStatus.passed:
        return BAColors.successOf(context);
      case NetworkDiagnosticStatus.warning:
        return BAColors.warningOf(context);
      case NetworkDiagnosticStatus.failed:
        return BAColors.dangerOf(context);
    }
  }

  String _getNetworkStatusText() {
    switch (status) {
      case NetworkDiagnosticStatus.pending:
        return '等待诊断...';
      case NetworkDiagnosticStatus.running:
        return '诊断中...';
      case NetworkDiagnosticStatus.passed:
        return '诊断通过';
      case NetworkDiagnosticStatus.warning:
        return '诊断警告';
      case NetworkDiagnosticStatus.failed:
        return '诊断失败';
    }
  }

  Widget _buildNetworkResults(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == NetworkDiagnosticStatus.passed
            ? BAColors.successOf(context).withValues(alpha: 0.08)
            : BAColors.warningOf(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == NetworkDiagnosticStatus.passed
              ? BAColors.successOf(context).withValues(alpha: 0.2)
              : BAColors.warningOf(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == NetworkDiagnosticStatus.passed
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: status == NetworkDiagnosticStatus.passed
                    ? BAColors.successOf(context)
                    : BAColors.warningOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status == NetworkDiagnosticStatus.passed
                    ? 'Network status OK'
                    : 'Network has issues',
                style: TextStyle(
                  color: status == NetworkDiagnosticStatus.passed
                      ? BAColors.successOf(context)
                      : BAColors.warningOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (report != null) ...[
            const SizedBox(height: 8),
            Text(
              '网络诊断详情',
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
