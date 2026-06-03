import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../ui/theme/ba_theme_colors.dart';
import 'network_diagnostic.dart';
import 'auto_fixer.dart';

enum NetworkDiagnosticStatus { pending, running, passed, warning, failed }
enum AutoFixStatus { idle, scanning, fixing, completed }

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage>
    with TickerProviderStateMixin {
  NetworkDiagnosticStatus _networkStatus = NetworkDiagnosticStatus.pending;
  AutoFixStatus _autoFixStatus = AutoFixStatus.idle;

  bool _isNetworkRunning = false;
  bool _isNetworkDone = false;
  NetworkDiagnosticReport? _networkReport;

  bool _isScanning = false;
  bool _isFixing = false;
  List<FixIssue> _detectedIssues = [];
  final List<FixResult> _fixResults = [];

  final Map<int, bool> _expandedStates = {};

  final AutoFixer _autoFixer = AutoFixer();

  @override
  void dispose() {
    NetworkDiagnostic.dispose();
    super.dispose();
  }

  Future<void> _runNetworkDiagnostic() async {
    setState(() {
      _isNetworkRunning = true;
      _isNetworkDone = false;
      _networkStatus = NetworkDiagnosticStatus.running;
    });

    try {
      final report = await NetworkDiagnostic.generateReport(
        onProgress: (stage, current, total) {
          setState(() {});
        },
      );

      if (!mounted) return;

      setState(() {
        _networkReport = report;
        _isNetworkRunning = false;
        _isNetworkDone = true;
        _networkStatus = report.isAllPassed
            ? NetworkDiagnosticStatus.passed
            : NetworkDiagnosticStatus.warning;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isNetworkRunning = false;
        _isNetworkDone = true;
        _networkStatus = NetworkDiagnosticStatus.failed;
      });
    }
  }

  Future<void> _scanIssues() async {
    setState(() {
      _isScanning = true;
      _autoFixStatus = AutoFixStatus.scanning;
      _detectedIssues.clear();
      _fixResults.clear();
    });

    try {
      final issues = await _autoFixer.detectAllIssues();
      if (!mounted) return;

      setState(() {
        _detectedIssues = issues;
        _isScanning = false;
        _autoFixStatus = issues.isEmpty
            ? AutoFixStatus.completed
            : AutoFixStatus.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _autoFixStatus = AutoFixStatus.idle;
      });
    }
  }

  Future<void> _autoFixIssues() async {
    final autoFixableIssues = _detectedIssues.where((i) => i.canAutoFix).toList();

    if (autoFixableIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有可自动修复的问题'),
          backgroundColor: BAThemeColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isFixing = true;
      _autoFixStatus = AutoFixStatus.fixing;
    });

    for (final issue in autoFixableIssues) {
      final result = await _autoFixer.fixIssue(issue);
      setState(() {
        _fixResults.add(result);
        if (result.isFixed) {
          _detectedIssues.removeWhere((i) => i.id == issue.id);
        }
      });
    }

    if (!mounted) return;
    setState(() {
      _isFixing = false;
      _autoFixStatus = AutoFixStatus.completed;
    });
  }

  Future<void> _exportReport() async {
    if (_networkReport == null || _networkReport!.htmlReport == null) return;

    try {
      final downloadsDir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      final timestamp = DateTime.now().toString().replaceAll(':', '-').substring(0, 19);
      final filePath = p.join(downloadsDir.path, 'network_report_$timestamp.html');

      await NetworkDiagnostic.saveReportToFile(_networkReport!, filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('报告已保存到: $filePath'),
          backgroundColor: BAThemeColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存报告失败: $e'),
          backgroundColor: BAThemeColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAThemeColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNetworkSection(),
                  const SizedBox(height: 24),
                  _buildAutoFixSection(),
                  const SizedBox(height: 24),
                  _buildFixLogSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        border: Border(
          bottom: BorderSide(
            color: BAThemeColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BAThemeColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: BAThemeColors.textSecondary, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BAThemeColors.primary, BAThemeColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: BAThemeColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            '网络诊断与修复',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('网络诊断', Icons.signal_cellular_alt_rounded),
        const SizedBox(height: 12),
        _buildNetworkDiagnosticCard(),
        if (_isNetworkDone && _networkReport != null) ...[
          const SizedBox(height: 12),
          _buildNetworkResults(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BAThemeColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: BAThemeColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: BAThemeColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkDiagnosticCard() {
    return Container(
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getNetworkBorderColor().withOpacity(0.6),
          width: _networkStatus == NetworkDiagnosticStatus.running ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getNetworkBorderColor().withOpacity(0.1),
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
              _buildNetworkStatusIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '网络连接检测',
                      style: TextStyle(
                        color: BAThemeColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isNetworkRunning
                          ? '正在检测网络状态...'
                          : _getNetworkStatusText(),
                      style: TextStyle(
                        color: _isNetworkRunning
                            ? BAThemeColors.info
                            : BAThemeColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isNetworkRunning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAThemeColors.info,
                  ),
                ),
            ],
          ),
          if (_isNetworkDone) ...[
            const SizedBox(height: 16),
            _buildExpandableDetails(),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: _isNetworkRunning ? null : _runNetworkDiagnostic,
                  icon: Icons.play_arrow_rounded,
                  label: '开始检测',
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _isNetworkDone ? _exportReport : null,
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

  Widget _buildNetworkStatusIcon() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (_networkStatus) {
      case NetworkDiagnosticStatus.pending:
        icon = Icons.hourglass_empty_rounded;
        color = BAThemeColors.textDisabled;
        bgColor = BAThemeColors.surfaceVariant;
        break;
      case NetworkDiagnosticStatus.running:
        icon = Icons.sync_rounded;
        color = BAThemeColors.info;
        bgColor = BAThemeColors.info.withOpacity(0.12);
        break;
      case NetworkDiagnosticStatus.passed:
        icon = Icons.check_circle_rounded;
        color = BAThemeColors.success;
        bgColor = BAThemeColors.success.withOpacity(0.12);
        break;
      case NetworkDiagnosticStatus.warning:
        icon = Icons.warning_amber_rounded;
        color = BAThemeColors.warning;
        bgColor = BAThemeColors.warning.withOpacity(0.12);
        break;
      case NetworkDiagnosticStatus.failed:
        icon = Icons.error_rounded;
        color = BAThemeColors.danger;
        bgColor = BAThemeColors.danger.withOpacity(0.12);
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

  Color _getNetworkBorderColor() {
    switch (_networkStatus) {
      case NetworkDiagnosticStatus.pending:
        return BAThemeColors.border;
      case NetworkDiagnosticStatus.running:
        return BAThemeColors.info;
      case NetworkDiagnosticStatus.passed:
        return BAThemeColors.success;
      case NetworkDiagnosticStatus.warning:
        return BAThemeColors.warning;
      case NetworkDiagnosticStatus.failed:
        return BAThemeColors.danger;
    }
  }

  String _getNetworkStatusText() {
    switch (_networkStatus) {
      case NetworkDiagnosticStatus.pending:
        return '点击开始检测网络状态';
      case NetworkDiagnosticStatus.running:
        return '正在检测中...';
      case NetworkDiagnosticStatus.passed:
        return '所有节点连接正常';
      case NetworkDiagnosticStatus.warning:
        return '部分节点连接异常';
      case NetworkDiagnosticStatus.failed:
        return '网络连接失败';
    }
  }

  Widget _buildExpandableDetails() {
    return ExpansionTile(
      title: const Text(
        '查看详细结果',
        style: TextStyle(
          color: BAThemeColors.textSecondary,
          fontSize: 13,
        ),
      ),
      iconColor: BAThemeColors.textSecondary,
      children: [
        if (_networkReport != null) ...[
          _buildPingResults(),
          const Divider(),
          _buildDnsResults(),
          const Divider(),
          _buildDownloadResults(),
        ],
      ],
    );
  }

  Widget _buildPingResults() {
    final results = _networkReport!.pingResults;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ping 延迟检测',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...results.map((r) => _buildPingResultItem(r)),
        ],
      ),
    );
  }

  Widget _buildPingResultItem(PingResult result) {
    Color latencyColor;
    if (!result.isReachable) {
      latencyColor = BAThemeColors.danger;
    } else if (result.latencyMs == null || result.latencyMs! < 100) {
      latencyColor = BAThemeColors.success;
    } else if (result.latencyMs! < 200) {
      latencyColor = BAThemeColors.warning;
    } else {
      latencyColor = BAThemeColors.danger;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            result.isReachable ? Icons.check_circle : Icons.cancel,
            color: result.isReachable ? BAThemeColors.success : BAThemeColors.danger,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.nodeName,
              style: const TextStyle(
                color: BAThemeColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            result.isReachable ? '${result.latencyMs} ms' : result.errorMessage ?? '不可达',
            style: TextStyle(
              color: latencyColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnsResults() {
    final results = _networkReport!.dnsResults;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DNS 解析检测',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...results.map((r) => _buildDnsResultItem(r)),
        ],
      ),
    );
  }

  Widget _buildDnsResultItem(DnsResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.cancel,
            color: result.isSuccess ? BAThemeColors.success : BAThemeColors.danger,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.hostname,
                  style: const TextStyle(
                    color: BAThemeColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (result.ipAddresses.isNotEmpty)
                  Text(
                    result.ipAddresses.join(', '),
                    style: const TextStyle(
                      color: BAThemeColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${result.resolutionTimeMs} ms',
            style: TextStyle(
              color: result.resolutionTimeMs < 100
                  ? BAThemeColors.success
                  : result.resolutionTimeMs < 500
                      ? BAThemeColors.warning
                      : BAThemeColors.danger,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadResults() {
    final results = _networkReport!.downloadResults;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '下载速度测试',
            style: TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...results.map((r) => _buildDownloadResultItem(r)),
        ],
      ),
    );
  }

  Widget _buildDownloadResultItem(DownloadSpeedResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.cancel,
            color: result.isSuccess ? BAThemeColors.success : BAThemeColors.danger,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.url.length > 40
                  ? '${result.url.substring(0, 40)}...'
                  : result.url,
              style: const TextStyle(
                color: BAThemeColors.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            result.speedText,
            style: TextStyle(
              color: result.isSuccess
                  ? (result.speedMbps > 5
                      ? BAThemeColors.success
                      : result.speedMbps > 1
                          ? BAThemeColors.warning
                          : BAThemeColors.danger)
                  : BAThemeColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _networkStatus == NetworkDiagnosticStatus.passed
            ? BAThemeColors.success.withOpacity(0.08)
            : BAThemeColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _networkStatus == NetworkDiagnosticStatus.passed
              ? BAThemeColors.success.withOpacity(0.2)
              : BAThemeColors.warning.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _networkStatus == NetworkDiagnosticStatus.passed
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: _networkStatus == NetworkDiagnosticStatus.passed
                    ? BAThemeColors.success
                    : BAThemeColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _networkStatus == NetworkDiagnosticStatus.passed
                    ? '网络状态良好'
                    : '网络存在一些问题',
                style: TextStyle(
                  color: _networkStatus == NetworkDiagnosticStatus.passed
                      ? BAThemeColors.success
                      : BAThemeColors.warning,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_networkReport != null) ...[
            const SizedBox(height: 8),
            Text(
              '检测时间: ${_networkReport!.timestamp.toString().substring(0, 19)}',
              style: const TextStyle(
                color: BAThemeColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoFixSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('一键修复', Icons.auto_fix_high_rounded),
        const SizedBox(height: 12),
        _buildAutoFixCard(),
        if (_detectedIssues.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildIssuesList(),
        ],
      ],
    );
  }

  Widget _buildAutoFixCard() {
    return Container(
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: BAThemeColors.primary.withOpacity(0.05),
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
                  color: BAThemeColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _autoFixStatus == AutoFixStatus.scanning
                      ? Icons.search_rounded
                      : _autoFixStatus == AutoFixStatus.fixing
                          ? Icons.build_rounded
                          : Icons.auto_fix_high_rounded,
                  color: BAThemeColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '自动修复问题',
                      style: TextStyle(
                        color: BAThemeColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAutoFixStatusText(),
                      style: const TextStyle(
                        color: BAThemeColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isScanning || _isFixing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAThemeColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: (_isScanning || _isFixing) ? null : _scanIssues,
                  icon: Icons.search_rounded,
                  label: '扫描问题',
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: (_isScanning || _isFixing || _detectedIssues.isEmpty)
                      ? null
                      : _autoFixIssues,
                  icon: Icons.build_rounded,
                  label: '自动修复',
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
    switch (_autoFixStatus) {
      case AutoFixStatus.idle:
        return _detectedIssues.isEmpty
            ? '点击扫描检测潜在问题'
            : '发现 ${_detectedIssues.length} 个问题，${_detectedIssues.where((i) => i.canAutoFix).length} 个可自动修复';
      case AutoFixStatus.scanning:
        return '正在扫描系统中...';
      case AutoFixStatus.fixing:
        return '正在修复问题...';
      case AutoFixStatus.completed:
        return '修复完成';
    }
  }

  Widget _buildIssuesList() {
    return Container(
      decoration: BoxDecoration(
        color: BAThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BAThemeColors.border.withOpacity(0.6),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BAThemeColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_detectedIssues.length} 个问题',
                    style: const TextStyle(
                      color: BAThemeColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_detectedIssues.where((i) => i.canAutoFix).length} 个可修复',
                  style: const TextStyle(
                    color: BAThemeColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(_detectedIssues.length, (index) {
            final issue = _detectedIssues[index];
            return _buildIssueItem(issue, index);
          }),
        ],
      ),
    );
  }

  Widget _buildIssueItem(FixIssue issue, int index) {
    Color severityColor;
    switch (issue.severity) {
      case FixSeverity.low:
        severityColor = BAThemeColors.info;
        break;
      case FixSeverity.medium:
        severityColor = BAThemeColors.warning;
        break;
      case FixSeverity.high:
        severityColor = BAThemeColors.danger;
        break;
      case FixSeverity.critical:
        severityColor = BAThemeColors.danger;
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
        style: const TextStyle(
          color: BAThemeColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        issue.canAutoFix ? '可自动修复' : '需手动修复',
        style: TextStyle(
          color: issue.canAutoFix ? BAThemeColors.success : BAThemeColors.textSecondary,
          fontSize: 12,
        ),
      ),
      iconColor: BAThemeColors.textSecondary,
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
                  color: BAThemeColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BAThemeColors.border.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  issue.description,
                  style: const TextStyle(
                    color: BAThemeColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (issue.autoFixDescription != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: BAThemeColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.autoFixDescription!,
                        style: const TextStyle(
                          color: BAThemeColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              final fixResult = _fixResults.where((r) => r.issueId == issue.id).firstOrNull;
              if (fixResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: fixResult.isFixed
                        ? BAThemeColors.success.withOpacity(0.1)
                        : BAThemeColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: fixResult.isFixed
                          ? BAThemeColors.success.withOpacity(0.3)
                          : BAThemeColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        fixResult.isFixed
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: fixResult.isFixed
                            ? BAThemeColors.success
                            : BAThemeColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fixResult.message ?? (fixResult.isFixed ? '已修复' : '修复失败'),
                          style: TextStyle(
                            color: fixResult.isFixed
                                ? BAThemeColors.success
                                : BAThemeColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFixLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('修复日志', Icons.history_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BAThemeColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BAThemeColors.border.withOpacity(0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BAThemeColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_autoFixer.fixHistory.length} 条记录',
                      style: const TextStyle(
                        color: BAThemeColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_autoFixer.fixHistory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _autoFixer.clearLogs();
                        });
                      },
                      child: const Text(
                        '清除日志',
                        style: TextStyle(
                          color: BAThemeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_autoFixer.fixHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '暂无修复记录',
                      style: TextStyle(
                        color: BAThemeColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ..._autoFixer.fixHistory.reversed.take(10).map((op) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          op.isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: op.isSuccess
                              ? BAThemeColors.success
                              : BAThemeColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            op.operationName,
                            style: const TextStyle(
                              color: BAThemeColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          op.duration?.inMilliseconds.toString() ?? '-',
                          style: const TextStyle(
                            color: BAThemeColors.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ms',
                          style: TextStyle(
                            color: BAThemeColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? (onPressed == null
                    ? BAThemeColors.primary.withOpacity(0.4)
                    : BAThemeColors.primary)
                : BAThemeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : BAThemeColors.border.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : (onPressed == null
                        ? BAThemeColors.textDisabled
                        : BAThemeColors.textPrimary),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : (onPressed == null
                          ? BAThemeColors.textDisabled
                          : BAThemeColors.textPrimary),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
