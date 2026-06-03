import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class PingResult {
  final String nodeName;
  final String nodeUrl;
  final int? latencyMs;
  final bool isReachable;
  final String? errorMessage;

  const PingResult({
    required this.nodeName,
    required this.nodeUrl,
    this.latencyMs,
    required this.isReachable,
    this.errorMessage,
  });

  String get statusText {
    if (!isReachable) return '不可达';
    if (latencyMs == null) return '检测中...';
    if (latencyMs! < 50) return '优秀 ($latencyMs ms)';
    if (latencyMs! < 100) return '良好 ($latencyMs ms)';
    if (latencyMs! < 200) return '一般 ($latencyMs ms)';
    return '较慢 ($latencyMs ms)';
  }
}

class DnsResult {
  final String hostname;
  final List<String> ipAddresses;
  final int resolutionTimeMs;
  final bool isSuccess;
  final String? errorMessage;

  const DnsResult({
    required this.hostname,
    required this.ipAddresses,
    required this.resolutionTimeMs,
    required this.isSuccess,
    this.errorMessage,
  });
}

class DownloadSpeedResult {
  final String url;
  final double speedMbps;
  final int responseTimeMs;
  final int contentLength;
  final bool isSuccess;
  final String? errorMessage;

  const DownloadSpeedResult({
    required this.url,
    required this.speedMbps,
    required this.responseTimeMs,
    required this.contentLength,
    required this.isSuccess,
    this.errorMessage,
  });

  String get speedText {
    if (!isSuccess) return '失败';
    if (speedMbps < 1) return '${(speedMbps * 1024).toStringAsFixed(1)} KB/s';
    return '${speedMbps.toStringAsFixed(2)} Mbps';
  }
}

class NetworkDiagnosticReport {
  final DateTime timestamp;
  final List<PingResult> pingResults;
  final List<DnsResult> dnsResults;
  final List<DownloadSpeedResult> downloadResults;
  final String? htmlReport;
  final bool isAllPassed;

  const NetworkDiagnosticReport({
    required this.timestamp,
    required this.pingResults,
    required this.dnsResults,
    required this.downloadResults,
    this.htmlReport,
    required this.isAllPassed,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'pingResults': pingResults.map((r) => {
      'nodeName': r.nodeName,
      'nodeUrl': r.nodeUrl,
      'latencyMs': r.latencyMs,
      'isReachable': r.isReachable,
      'errorMessage': r.errorMessage,
    }).toList(),
    'dnsResults': dnsResults.map((r) => {
      'hostname': r.hostname,
      'ipAddresses': r.ipAddresses,
      'resolutionTimeMs': r.resolutionTimeMs,
      'isSuccess': r.isSuccess,
      'errorMessage': r.errorMessage,
    }).toList(),
    'downloadResults': downloadResults.map((r) => {
      'url': r.url,
      'speedMbps': r.speedMbps,
      'responseTimeMs': r.responseTimeMs,
      'contentLength': r.contentLength,
      'isSuccess': r.isSuccess,
      'errorMessage': r.errorMessage,
    }).toList(),
    'isAllPassed': isAllPassed,
  };
}

class NetworkDiagnostic {
  static const List<Map<String, String>> _pingNodes = [
    {'name': 'Mojang', 'url': 'https://launcher.mojang.com'},
    {'name': 'BMCLAPI-2', 'url': 'https://bmclapi2.bangbang93.com'},
    {'name': 'BMCLAPI', 'url': 'https://bmclapi.bangbang93.com'},
    {'name': 'MCBBS', 'url': 'https://download.mcbbs.net'},
  ];

  static const List<String> _dnsHosts = [
    'launcher.mojang.com',
    'bmclapi2.bangbang93.com',
    'download.mcbbs.net',
    'api.modrinth.com',
  ];

  static const List<String> _downloadTestUrls = [
    'https://bmclapi2.bangbang93.com/minecraft/version/1.20.4',
    'https://bmclapi2.bangbang93.com/mirrors.json',
  ];

  static http.Client? _client;

  static http.Client get _httpClient {
    _client ??= http.Client();
    return _client!;
  }

  static void dispose() {
    _client?.close();
    _client = null;
  }

  static Future<List<PingResult>> pingAllNodes({
    void Function(String nodeName, int current, int total)? onProgress,
  }) async {
    final results = <PingResult>[];
    final total = _pingNodes.length;

    for (var i = 0; i < _pingNodes.length; i++) {
      final node = _pingNodes[i];
      onProgress?.call(node['name']!, i + 1, total);
      final result = await _pingNode(node['name']!, node['url']!);
      results.add(result);
    }

    return results;
  }

  static Future<PingResult> _pingNode(String name, String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(url);
      final request = http.Request('HEAD', uri);
      request.headers['User-Agent'] = 'BAMCLauncher/2.0.0';

      final response = await _httpClient.send(request).timeout(
        const Duration(seconds: 10),
      );

      stopwatch.stop();
      await response.stream.drain<void>();

      return PingResult(
        nodeName: name,
        nodeUrl: url,
        latencyMs: stopwatch.elapsedMilliseconds,
        isReachable: response.statusCode >= 200 && response.statusCode < 400,
      );
    } on TimeoutException {
      stopwatch.stop();
      return PingResult(
        nodeName: name,
        nodeUrl: url,
        isReachable: false,
        errorMessage: '连接超时',
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return PingResult(
        nodeName: name,
        nodeUrl: url,
        isReachable: false,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      return PingResult(
        nodeName: name,
        nodeUrl: url,
        isReachable: false,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<List<DnsResult>> checkDns({
    void Function(String hostname, int current, int total)? onProgress,
  }) async {
    final results = <DnsResult>[];
    final total = _dnsHosts.length;

    for (var i = 0; i < _dnsHosts.length; i++) {
      final hostname = _dnsHosts[i];
      onProgress?.call(hostname, i + 1, total);
      final result = await _resolveDns(hostname);
      results.add(result);
    }

    return results;
  }

  static Future<DnsResult> _resolveDns(String hostname) async {
    final stopwatch = Stopwatch()..start();

    try {
      final addresses = await InternetAddress.lookup(hostname)
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      return DnsResult(
        hostname: hostname,
        ipAddresses: addresses.map((a) => a.address).toList(),
        resolutionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccess: addresses.isNotEmpty,
      );
    } on TimeoutException {
      stopwatch.stop();
      return DnsResult(
        hostname: hostname,
        ipAddresses: [],
        resolutionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
        errorMessage: 'DNS解析超时',
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return DnsResult(
        hostname: hostname,
        ipAddresses: [],
        resolutionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
        errorMessage: 'DNS解析失败: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      return DnsResult(
        hostname: hostname,
        ipAddresses: [],
        resolutionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<List<DownloadSpeedResult>> testDownloadSpeed({
    void Function(String url, int current, int total)? onProgress,
  }) async {
    final results = <DownloadSpeedResult>[];
    final total = _downloadTestUrls.length;

    for (var i = 0; i < _downloadTestUrls.length; i++) {
      final url = _downloadTestUrls[i];
      onProgress?.call(url, i + 1, total);
      final result = await _testDownloadSpeed(url);
      results.add(result);
    }

    return results;
  }

  static Future<DownloadSpeedResult> _testDownloadSpeed(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      request.headers['User-Agent'] = 'BAMCLauncher/2.0.0';

      final streamedResponse = await _httpClient.send(request).timeout(
        const Duration(seconds: 15),
      );

      final statusCode = streamedResponse.statusCode;
      final contentLength = streamedResponse.contentLength ?? 0;
      final bytesReceived = <int>[];

      await for (final chunk in streamedResponse.stream) {
        bytesReceived.addAll(chunk);
      }

      stopwatch.stop();

      if (statusCode != 200) {
        return DownloadSpeedResult(
          url: url,
          speedMbps: 0,
          responseTimeMs: stopwatch.elapsedMilliseconds,
          contentLength: 0,
          isSuccess: false,
          errorMessage: 'HTTP $statusCode',
        );
      }

      final totalBytes = bytesReceived.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final speedBps = seconds > 0 ? totalBytes / seconds : 0;
      final speedMbps = (speedBps * 8) / (1024 * 1024);

      return DownloadSpeedResult(
        url: url,
        speedMbps: speedMbps,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        contentLength: totalBytes,
        isSuccess: true,
      );
    } on TimeoutException {
      stopwatch.stop();
      return DownloadSpeedResult(
        url: url,
        speedMbps: 0,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        contentLength: 0,
        isSuccess: false,
        errorMessage: '下载超时',
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return DownloadSpeedResult(
        url: url,
        speedMbps: 0,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        contentLength: 0,
        isSuccess: false,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      return DownloadSpeedResult(
        url: url,
        speedMbps: 0,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        contentLength: 0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<NetworkDiagnosticReport> generateReport({
    void Function(String stage, int current, int total)? onProgress,
  }) async {
    final totalStages = 3;
    var currentStage = 0;

    onProgress?.call('Ping延迟检测', ++currentStage, totalStages);
    final pingResults = await pingAllNodes();

    onProgress?.call('DNS解析检测', ++currentStage, totalStages);
    final dnsResults = await checkDns();

    onProgress?.call('下载速度测试', ++currentStage, totalStages);
    final downloadResults = await testDownloadSpeed();

    final isAllPassed = pingResults.every((r) => r.isReachable) &&
        dnsResults.every((r) => r.isSuccess) &&
        downloadResults.every((r) => r.isSuccess);

    final htmlReport = _generateHtmlReport(
      timestamp: DateTime.now(),
      pingResults: pingResults,
      dnsResults: dnsResults,
      downloadResults: downloadResults,
      isAllPassed: isAllPassed,
    );

    return NetworkDiagnosticReport(
      timestamp: DateTime.now(),
      pingResults: pingResults,
      dnsResults: dnsResults,
      downloadResults: downloadResults,
      htmlReport: htmlReport,
      isAllPassed: isAllPassed,
    );
  }

  static String _generateHtmlReport({
    required DateTime timestamp,
    required List<PingResult> pingResults,
    required List<DnsResult> dnsResults,
    required List<DownloadSpeedResult> downloadResults,
    required bool isAllPassed,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>网络诊断报告 - BAMCLauncher</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 20px;
    }
    .container { max-width: 900px; margin: 0 auto; }
    .card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.15);
      overflow: hidden;
      margin-bottom: 20px;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
    }
    .header h1 { font-size: 24px; margin-bottom: 8px; }
    .header p { opacity: 0.9; font-size: 14px; }
    .status-badge {
      display: inline-block;
      padding: 8px 20px;
      border-radius: 30px;
      font-weight: 600;
      margin-top: 15px;
    }
    .status-success { background: #10b981; color: white; }
    .status-warning { background: #f59e0b; color: white; }
    .status-error { background: #ef4444; color: white; }
    .section { padding: 25px 30px; border-bottom: 1px solid #e5e7eb; }
    .section:last-child { border-bottom: none; }
    .section-title {
      font-size: 16px;
      font-weight: 600;
      color: #374151;
      margin-bottom: 15px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .section-title::before {
      content: '';
      width: 4px;
      height: 18px;
      background: linear-gradient(180deg, #667eea 0%, #764ba2 100%);
      border-radius: 2px;
    }
    table { width: 100%; border-collapse: collapse; }
    th, td {
      padding: 12px 15px;
      text-align: left;
      border-bottom: 1px solid #f3f4f6;
    }
    th {
      background: #f9fafb;
      font-weight: 600;
      color: #6b7280;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    tr:hover { background: #f9fafb; }
    .node-name { font-weight: 600; color: #374151; }
    .latency { font-family: 'Consolas', monospace; }
    .latency-good { color: #10b981; }
    .latency-medium { color: #f59e0b; }
    .latency-bad { color: #ef4444; }
    .status-icon { font-size: 18px; }
    .footer {
      text-align: center;
      padding: 20px;
      color: #9ca3af;
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <h1>🌐 BAMCLauncher 网络诊断报告</h1>
        <p>生成时间: ${timestamp.toString().substring(0, 19)}</p>
        <div class="status-badge ${isAllPassed ? 'status-success' : 'status-warning'}">
          ${isAllPassed ? '✓ 所有检测通过' : '⚠ 部分检测异常'}
        </div>
      </div>
''');

    buffer.writeln('''
      <div class="section">
        <div class="section-title">📡 Ping 延迟检测</div>
        <table>
          <thead>
            <tr>
              <th>节点</th>
              <th>状态</th>
              <th>延迟</th>
              <th>详情</th>
            </tr>
          </thead>
          <tbody>
''');

    for (final result in pingResults) {
      final latencyClass = result.latencyMs == null
          ? 'latency-bad'
          : result.latencyMs! < 100
              ? 'latency-good'
              : result.latencyMs! < 200
                  ? 'latency-medium'
                  : 'latency-bad';
      final statusIcon = result.isReachable ? '✓' : '✗';
      final statusText = result.isReachable
          ? (result.latencyMs == null ? '检测中' : '${result.latencyMs} ms')
          : (result.errorMessage ?? '不可达');

      buffer.writeln('''
            <tr>
              <td class="node-name">${result.nodeName}</td>
              <td><span class="status-icon">$statusIcon</span></td>
              <td class="latency $latencyClass">$statusText</td>
              <td>${result.nodeUrl}</td>
            </tr>
''');
    }

    buffer.writeln('''
          </tbody>
        </table>
      </div>
''');

    buffer.writeln('''
      <div class="section">
        <div class="section-title">🔍 DNS 解析检测</div>
        <table>
          <thead>
            <tr>
              <th>主机名</th>
              <th>状态</th>
              <th>解析时间</th>
              <th>IP地址</th>
            </tr>
          </thead>
          <tbody>
''');

    for (final result in dnsResults) {
      final statusIcon = result.isSuccess ? '✓' : '✗';
      final timeClass = result.resolutionTimeMs < 100
          ? 'latency-good'
          : result.resolutionTimeMs < 500
              ? 'latency-medium'
              : 'latency-bad';
      final ips = result.ipAddresses.isNotEmpty
          ? result.ipAddresses.join(', ')
          : (result.errorMessage ?? '解析失败');

      buffer.writeln('''
            <tr>
              <td class="node-name">${result.hostname}</td>
              <td><span class="status-icon">$statusIcon</span></td>
              <td class="latency $timeClass">${result.resolutionTimeMs} ms</td>
              <td style="font-size: 12px; color: #6b7280;">$ips</td>
            </tr>
''');
    }

    buffer.writeln('''
          </tbody>
        </table>
      </div>
''');

    buffer.writeln('''
      <div class="section">
        <div class="section-title">📥 下载速度测试</div>
        <table>
          <thead>
            <tr>
              <th>测试URL</th>
              <th>状态</th>
              <th>速度</th>
              <th>响应时间</th>
            </tr>
          </thead>
          <tbody>
''');

    for (final result in downloadResults) {
      final statusIcon = result.isSuccess ? '✓' : '✗';
      final speedClass = !result.isSuccess
          ? 'latency-bad'
          : result.speedMbps > 5
              ? 'latency-good'
              : result.speedMbps > 1
                  ? 'latency-medium'
                  : 'latency-bad';

      buffer.writeln('''
            <tr>
              <td class="node-name" style="font-size: 11px; max-width: 300px; overflow: hidden; text-overflow: ellipsis;">${result.url}</td>
              <td><span class="status-icon">$statusIcon</span></td>
              <td class="latency $speedClass">${result.speedText}</td>
              <td class="latency">${result.responseTimeMs} ms</td>
            </tr>
''');
    }

    buffer.writeln('''
          </tbody>
        </table>
      </div>
''');

    buffer.writeln('''
    </div>
    <div class="footer">
      <p>由 BAMCLauncher 自动生成 | 诊断时间: ${timestamp.toIso8601String()}</p>
    </div>
  </div>
</body>
</html>
''');

    return buffer.toString();
  }

  static Future<void> saveReportToFile(
    NetworkDiagnosticReport report,
    String filePath,
  ) async {
    if (report.htmlReport == null) return;
    final file = File(filePath);
    await file.writeAsString(report.htmlReport!);
  }
}
