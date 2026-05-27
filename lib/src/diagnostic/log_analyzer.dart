class LogIssue {
  final String severity;
  final String message;
  final String? suggestion;
  final int? lineNumber;

  const LogIssue({
    required this.severity,
    required this.message,
    this.suggestion,
    this.lineNumber,
  });
}

class LogAnalysisResult {
  final String summary;
  final List<LogIssue> issues;
  final int errorCount;
  final int warningCount;

  const LogAnalysisResult({
    required this.summary,
    required this.issues,
    required this.errorCount,
    required this.warningCount,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasErrors => errorCount > 0;
}

class LogAnalyzer {
  static final List<_KeywordRule> _rules = [
    _KeywordRule(
      keywords: ['OutOfMemoryError', 'Java heap space', 'GC overhead'],
      severity: 'error',
      suggestion: '增大游戏内存分配，建议设置为 4096 MB 或更高',
    ),
    _KeywordRule(
      keywords: ['UnsupportedClassVersionError', 'class file version'],
      severity: 'error',
      suggestion: 'Java 版本不兼容，请安装正确版本的 Java',
    ),
    _KeywordRule(
      keywords: ['ModResolutionException', 'Missing or unsupported mandatory dependencies'],
      severity: 'error',
      suggestion: '缺少模组前置依赖，请安装缺失的模组',
    ),
    _KeywordRule(
      keywords: ['DuplicateModsFoundException'],
      severity: 'error',
      suggestion: '存在重复模组，请移除其中一个',
    ),
    _KeywordRule(
      keywords: ['FileNotFoundException', 'NoSuchFileException'],
      severity: 'error',
      suggestion: '文件缺失，请验证游戏完整性或重新安装',
    ),
    _KeywordRule(
      keywords: ['Connection refused', 'ConnectException'],
      severity: 'error',
      suggestion: '网络连接被拒绝，请检查服务器地址和网络状态',
    ),
    _KeywordRule(
      keywords: ['SocketTimeoutException', 'Timed out'],
      severity: 'error',
      suggestion: '网络连接超时，请检查网络状况或服务器状态',
    ),
    _KeywordRule(
      keywords: ['Authentication', 'Invalid session', 'Unauthorized'],
      severity: 'error',
      suggestion: '账户验证失败，请重新登录',
    ),
    _KeywordRule(
      keywords: ['IOException', 'Corrupted'],
      severity: 'warning',
      suggestion: '文件可能损坏，请检查磁盘健康状态',
    ),
    _KeywordRule(
      keywords: ["Can't keep up", 'Falling behind'],
      severity: 'warning',
      suggestion: '服务器/客户端性能不足，尝试增大内存或减少模组',
    ),
    _KeywordRule(
      keywords: ['WARN', 'WARNING'],
      severity: 'warning',
      suggestion: null,
    ),
    _KeywordRule(
      keywords: ['deprecated', 'DEPRECATED'],
      severity: 'info',
      suggestion: '使用了已弃用的 API，建议更新相关模组',
    ),
  ];

  static LogAnalysisResult analyze(List<String> logLines) {
    final issues = <LogIssue>[];
    final seenMessages = <String>{};

    for (var i = 0; i < logLines.length; i++) {
      final line = logLines[i];

      for (final rule in _rules) {
        if (_matchesAny(line, rule.keywords)) {
          final normalized = _normalizeMessage(line);
          if (seenMessages.contains(normalized)) continue;
          seenMessages.add(normalized);

          issues.add(LogIssue(
            severity: rule.severity,
            message: line.length > 200 ? '${line.substring(0, 200)}...' : line,
            suggestion: rule.suggestion,
            lineNumber: i + 1,
          ));
          break;
        }
      }
    }

    final errorCount = issues.where((i) => i.severity == 'error').length;
    final warningCount = issues.where((i) => i.severity == 'warning').length;

    final summary = _buildSummary(errorCount, warningCount, issues.length, logLines.length);

    return LogAnalysisResult(
      summary: summary,
      issues: issues,
      errorCount: errorCount,
      warningCount: warningCount,
    );
  }

  static bool _matchesAny(String line, List<String> keywords) {
    final lower = line.toLowerCase();
    for (final keyword in keywords) {
      if (lower.contains(keyword.toLowerCase())) return true;
    }
    return false;
  }

  static String _normalizeMessage(String line) {
    final timestampPattern = RegExp(r'\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}');
    var normalized = line.replaceAll(timestampPattern, '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length > 150) {
      normalized = normalized.substring(0, 150);
    }
    return normalized;
  }

  static String _buildSummary(int errors, int warnings, int totalIssues, int totalLines) {
    if (totalIssues == 0) {
      return '扫描了 $totalLines 行日志，未发现明显问题';
    }

    final parts = <String>[];
    parts.add('扫描了 $totalLines 行日志');
    if (errors > 0) parts.add('发现 $errors 个错误');
    if (warnings > 0) parts.add('$warnings 个警告');

    return parts.join('，');
  }
}

class _KeywordRule {
  final List<String> keywords;
  final String severity;
  final String? suggestion;

  const _KeywordRule({
    required this.keywords,
    required this.severity,
    this.suggestion,
  });
}
