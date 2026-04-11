import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'logger.dart';

class CrashAnalyzer {
  static final CrashAnalyzer _instance = CrashAnalyzer._internal();

  factory CrashAnalyzer() => _instance;

  CrashAnalyzer._internal();

  List<CrashReport> analyzeCrashLogs(String logDirectory) {
    final crashReports = <CrashReport>[];
    final directory = Directory(logDirectory);

    if (!directory.existsSync()) {
      logger.warn('Log directory does not exist', {'directory': logDirectory});
      return crashReports;
    }

    final logFiles = directory
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .cast<File>()
        .toList();

    for (final file in logFiles) {
      try {
        final reports = _analyzeLogFile(file);
        crashReports.addAll(reports);
      } catch (e) {
        logger.error('Failed to analyze log file', {'file': file.path}, e);
      }
    }

    return crashReports;
  }

  List<CrashReport> _analyzeLogFile(File logFile) {
    final reports = <CrashReport>[];
    final lines = logFile.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('[ERROR]')) {
        final crashReport = _parseCrashFromLine(line, lines, i);
        if (crashReport != null) {
          reports.add(crashReport);
        }
      }
    }

    return reports;
  }

  CrashReport? _parseCrashFromLine(
      String line, List<String> lines, int startIndex) {
    try {
      // 解析时间戳和错误级别
      final timestampMatch =
          RegExp(r'\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)\]')
              .firstMatch(line);
      final errorTypeMatch = RegExp(r'\[ERROR\]').firstMatch(line);

      if (timestampMatch == null || errorTypeMatch == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampMatch.group(1)!);

      // 提取错误信息
      String errorMessage = line.substring(errorTypeMatch.end).trim();
      if (errorMessage.startsWith('[APP]')) {
        errorMessage = errorMessage.substring(5).trim();
      }

      // 收集堆栈跟踪
      final stackTraceBuilder = StringBuffer();
      int stackTraceStart = startIndex + 1;

      while (stackTraceStart < lines.length) {
        final stackLine = lines[stackTraceStart];
        if (stackLine.startsWith('Stack Trace:') ||
            stackLine.contains('Exception:')) {
          stackTraceBuilder.writeln(stackLine);
          stackTraceStart++;
        } else if (stackTraceBuilder.isNotEmpty &&
            (stackLine.startsWith('\t') ||
                stackLine.contains('dart:') ||
                stackLine.contains('package:'))) {
          stackTraceBuilder.writeln(stackLine);
          stackTraceStart++;
        } else {
          break;
        }
      }

      final stackTrace = stackTraceBuilder.toString();

      // 确定错误类型
      final errorType = _determineErrorType(errorMessage, stackTrace);

      return CrashReport(
        reportId: _generateReportId(timestamp, errorType),
        timestamp: timestamp,
        appVersion: '1.0.0', // 需要从配置中获取
        osVersion: Platform.operatingSystemVersion,
        deviceInfo:
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        errorType: errorType,
        errorMessage: errorMessage,
        stackTrace: stackTrace,
      );
    } catch (e) {
      logger.error('Failed to parse crash report', null, e);
      return null;
    }
  }

  ErrorType _determineErrorType(String errorMessage, String stackTrace) {
    errorMessage = errorMessage.toLowerCase();
    stackTrace = stackTrace.toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('http') ||
        errorMessage.contains('socket')) {
      return ErrorType.network;
    } else if (errorMessage.contains('file') ||
        errorMessage.contains('io') ||
        errorMessage.contains('path')) {
      return ErrorType.file;
    } else if (errorMessage.contains('auth') ||
        errorMessage.contains('login') ||
        errorMessage.contains('token')) {
      return ErrorType.authentication;
    } else if (errorMessage.contains('version') ||
        errorMessage.contains('manifest')) {
      return ErrorType.version;
    } else if (errorMessage.contains('download') ||
        errorMessage.contains('download')) {
      return ErrorType.download;
    } else if (errorMessage.contains('launch') ||
        errorMessage.contains('java') ||
        errorMessage.contains('process')) {
      return ErrorType.gameLaunch;
    } else if (errorMessage.contains('mod') ||
        errorMessage.contains('resource') ||
        errorMessage.contains('shader')) {
      return ErrorType.content;
    } else if (errorMessage.contains('modpack') ||
        errorMessage.contains('zip')) {
      return ErrorType.modpack;
    } else if (errorMessage.contains('server') ||
        errorMessage.contains('port')) {
      return ErrorType.server;
    } else if (errorMessage.contains('config') ||
        errorMessage.contains('json')) {
      return ErrorType.configuration;
    } else if (errorMessage.contains('widget') ||
        errorMessage.contains('render') ||
        errorMessage.contains('build')) {
      return ErrorType.ui;
    } else {
      return ErrorType.unknown;
    }
  }

  String _generateReportId(DateTime timestamp, ErrorType errorType) {
    final timestampStr =
        timestamp.toIso8601String().replaceAll(RegExp(r'[^\w]'), '');
    final errorTypeStr = errorType.name.substring(0, 3).toUpperCase();
    final random = Random().nextInt(10000).toString().padLeft(4, '0');
    return '${errorTypeStr}_${timestampStr}_$random';
  }

  Map<String, dynamic> getCrashStatistics(List<CrashReport> reports) {
    final stats = <String, dynamic>{
      'totalCrashes': reports.length,
      'crashesByType': <String, int>{},
      'crashesByDate': <String, int>{},
      'mostFrequentErrors': <String, int>{},
    };

    for (final report in reports) {
      // 按错误类型统计
      final typeName = report.errorType.name;
      stats['crashesByType'][typeName] =
          (stats['crashesByType'][typeName] ?? 0) + 1;

      // 按日期统计
      final dateStr = report.timestamp.toIso8601String().split('T')[0];
      stats['crashesByDate'][dateStr] =
          (stats['crashesByDate'][dateStr] ?? 0) + 1;

      // 按错误消息统计（截取前100个字符）
      final messageKey = report.errorMessage.length > 100
          ? '${report.errorMessage.substring(0, 100)}...'
          : report.errorMessage;
      stats['mostFrequentErrors'][messageKey] =
          (stats['mostFrequentErrors'][messageKey] ?? 0) + 1;
    }

    return stats;
  }

  void exportCrashReport(CrashReport report, String outputPath) {
    final reportFile = File(outputPath);
    final reportJson =
        const JsonEncoder.withIndent('  ').convert(report.toJson());

    try {
      reportFile.writeAsStringSync(reportJson);
      logger.info('Crash report exported',
          {'reportId': report.reportId, 'path': outputPath});
    } catch (e) {
      logger.error(
          'Failed to export crash report', {'reportId': report.reportId}, e);
    }
  }

  void exportAllCrashReports(
      List<CrashReport> reports, String outputDirectory) {
    final directory = Directory(outputDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    for (final report in reports) {
      final reportPath =
          '${directory.path}${Platform.pathSeparator}crash_${report.reportId}.json';
      exportCrashReport(report, reportPath);
    }
  }
}
