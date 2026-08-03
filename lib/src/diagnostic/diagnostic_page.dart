import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../ui/theme/colors.dart';
import 'network_diagnostic.dart';
import 'auto_fixer.dart';
import 'widgets/index.dart';

/// 诊断页面
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
    final autoFixableIssues = _detectedIssues
        .where((i) => i.canAutoFix)
        .toList();

    if (autoFixableIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('暂无可修复的问题'),
          backgroundColor: BAColors.warningOf(context),
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
      final downloadsDir = Directory(
        '${Platform.environment['USERPROFILE']}\\Downloads',
      );
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filePath = p.join(
        downloadsDir.path,
        'network_report_$timestamp.html',
      );

      await NetworkDiagnostic.saveReportToFile(_networkReport!, filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('报告已导出到: $filePath'),
          backgroundColor: BAColors.successOf(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出报告失败，错误信息: $e'),
          backgroundColor: BAColors.dangerOf(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: Column(
        children: [
          DiagnosticHeader(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiagnosticNetworkSection(
                    status: _networkStatus,
                    isRunning: _isNetworkRunning,
                    isDone: _isNetworkDone,
                    report: _networkReport,
                    onRunDiagnostic: _runNetworkDiagnostic,
                    onExportReport: _exportReport,
                  ),
                  const SizedBox(height: 24),
                  DiagnosticAutoFixSection(
                    status: _autoFixStatus,
                    isScanning: _isScanning,
                    isFixing: _isFixing,
                    detectedIssues: _detectedIssues,
                    fixResults: _fixResults,
                    onScanIssues: _scanIssues,
                    onAutoFixIssues: _autoFixIssues,
                  ),
                  const SizedBox(height: 24),
                  DiagnosticFixLogSection(
                    autoFixer: _autoFixer,
                    onClearLogs: () {
                      setState(() {
                        _autoFixer.clearLogs();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
