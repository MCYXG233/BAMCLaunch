import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Ping检测结果
///
/// 用于存储单个节点的Ping检测结果，包含节点名称、URL、延迟、可达性等信息。
/// 该类是不可变的，所有字段在构造时确定。
class PingResult {
  /// 节点名称，如 "Mojang"、"BMCLAPI" 等
  final String nodeName;

  /// 节点的完整URL地址
  final String nodeUrl;

  /// 延迟时间（毫秒），如果节点不可达则为null
  final int? latencyMs;

  /// 节点是否可达
  final bool isReachable;

  /// 错误信息，当节点不可达时包含具体的错误描述
  final String? errorMessage;

  /// 构造函数
  ///
  /// [nodeName] 和 [nodeUrl] 为必填参数
  /// [latencyMs] 和 [errorMessage] 根据检测结果确定
  /// [isReachable] 必须提供
  const PingResult({
    required this.nodeName,
    required this.nodeUrl,
    this.latencyMs,
    required this.isReachable,
    this.errorMessage,
  });

  /// 获取状态文本描述
  ///
  /// 根据可达性和延迟返回用户友好的状态描述：
  /// - 不可达时返回 "不可达"
  /// - 检测中返回 "检测中..."
  /// - 延迟 < 50ms 返回 "优秀"
  /// - 延迟 < 100ms 返回 "良好"
  /// - 延迟 < 200ms 返回 "一般"
  /// - 延迟 >= 200ms 返回 "较慢"
  String get statusText {
    if (!isReachable) return '不可达';
    if (latencyMs == null) return '检测中...';
    if (latencyMs! < 50) return '优秀 ($latencyMs ms)';
    if (latencyMs! < 100) return '良好 ($latencyMs ms)';
    if (latencyMs! < 200) return '一般 ($latencyMs ms)';
    return '较慢 ($latencyMs ms)';
  }
}

/// DNS解析结果
///
/// 用于存储单个主机名的DNS解析结果，包含解析出的IP地址列表、解析耗时等信息。
class DnsResult {
  /// 主机名，如 "launcher.mojang.com"
  final String hostname;

  /// 解析出的IP地址列表
  final List<String> ipAddresses;

  /// DNS解析耗时（毫秒）
  final int resolutionTimeMs;

  /// 解析是否成功
  final bool isSuccess;

  /// 错误信息，当解析失败时包含具体的错误描述
  final String? errorMessage;

  /// 构造函数
  ///
  /// 所有参数均为必填，[errorMessage] 在成功时可为null
  const DnsResult({
    required this.hostname,
    required this.ipAddresses,
    required this.resolutionTimeMs,
    required this.isSuccess,
    this.errorMessage,
  });
}

/// 下载速度测试结果
///
/// 用于存储单个URL的下载速度测试结果，包含下载速度、响应时间、数据大小等信息。
class DownloadSpeedResult {
  /// 测试的URL地址
  final String url;

  /// 下载速度（Mbps）
  final double speedMbps;

  /// 响应时间（毫秒）
  final int responseTimeMs;

  /// 下载的内容大小（字节）
  final int contentLength;

  /// 测试是否成功
  final bool isSuccess;

  /// 错误信息，当测试失败时包含具体的错误描述
  final String? errorMessage;

  /// 构造函数
  const DownloadSpeedResult({
    required this.url,
    required this.speedMbps,
    required this.responseTimeMs,
    required this.contentLength,
    required this.isSuccess,
    this.errorMessage,
  });

  /// 获取速度文本描述
  ///
  /// 根据测试结果和速度返回用户友好的描述：
  /// - 失败时返回 "失败"
  /// - 速度 < 1 Mbps 时显示 KB/s 单位
  /// - 速度 >= 1 Mbps 时显示 Mbps 单位
  String get speedText {
    if (!isSuccess) return '失败';
    if (speedMbps < 1) return '${(speedMbps * 1024).toStringAsFixed(1)} KB/s';
    return '${speedMbps.toStringAsFixed(2)} Mbps';
  }
}

/// 网络诊断报告
///
/// 包含完整的网络诊断结果，汇总了Ping检测、DNS解析和下载速度测试的所有结果。
/// 可以转换为JSON格式以便于存储和传输。
class NetworkDiagnosticReport {
  /// 报告生成的时间戳
  final DateTime timestamp;

  /// 所有节点的Ping检测结果列表
  final List<PingResult> pingResults;

  /// 所有主机名的DNS解析结果列表
  final List<DnsResult> dnsResults;

  /// 所有URL的下载速度测试结果列表
  final List<DownloadSpeedResult> downloadResults;

  /// HTML格式的完整报告，可为null
  final String? htmlReport;

  /// 所有检测是否都通过
  ///
  /// 当且仅当所有Ping检测、DNS解析和下载测试都成功时为true
  final bool isAllPassed;

  /// 构造函数
  const NetworkDiagnosticReport({
    required this.timestamp,
    required this.pingResults,
    required this.dnsResults,
    required this.downloadResults,
    this.htmlReport,
    required this.isAllPassed,
  });

  /// 将报告转换为JSON格式
  ///
  /// 返回一个Map，包含所有诊断结果的结构化数据，
  /// 便于序列化存储或传输。
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

/// 网络诊断工具类
///
/// 提供网络诊断功能的静态方法集合，包括：
/// - Ping延迟检测：检测各镜像节点的连通性和延迟
/// - DNS解析检测：检测DNS解析是否正常
/// - 下载速度测试：测试下载带宽
/// - 报告生成：生成HTML格式的诊断报告
///
/// 使用示例：
/// ```dart
/// final report = await NetworkDiagnostic.generateReport();
/// await NetworkDiagnostic.saveReportToFile(report, 'report.html');
/// NetworkDiagnostic.dispose(); // 使用完毕后释放资源
/// ```
class NetworkDiagnostic {
  /// 预定义的Ping检测节点列表
  ///
  /// 每个节点包含名称和URL，用于检测各镜像源的连通性和延迟
  static const List<Map<String, String>> _pingNodes = [
    {'name': 'Mojang', 'url': 'https://launcher.mojang.com'},
    {'name': 'BMCLAPI-2', 'url': 'https://bmclapi2.bangbang93.com'},
    {'name': 'BMCLAPI', 'url': 'https://bmclapi.bangbang93.com'},
    {'name': 'MCBBS', 'url': 'https://download.mcbbs.net'},
  ];

  /// 预定义的DNS解析检测主机名列表
  ///
  /// 这些主机名是Minecraft启动器常用的服务地址
  static const List<String> _dnsHosts = [
    'launcher.mojang.com',
    'bmclapi2.bangbang93.com',
    'download.mcbbs.net',
    'api.modrinth.com',
  ];

  /// 预定义的下载速度测试URL列表
  ///
  /// 这些URL用于测试实际下载速度
  static const List<String> _downloadTestUrls = [
    'https://bmclapi2.bangbang93.com/minecraft/version/1.20.4',
    'https://bmclapi2.bangbang93.com/mirrors.json',
  ];

  /// HTTP客户端实例（懒加载单例）
  static http.Client? _client;

  /// 获取HTTP客户端实例
  ///
  /// 使用懒加载模式创建HTTP客户端，避免重复创建连接池
  static http.Client get _httpClient {
    _client ??= http.Client();
    return _client!;
  }

  /// 释放HTTP客户端资源
  ///
  /// 在完成所有网络诊断后调用此方法以释放HTTP客户端占用的资源
  static void dispose() {
    _client?.close();
    _client = null;
  }

  /// Ping检测所有预定义节点
  ///
  /// 依次对 [_pingNodes] 中的每个节点执行Ping检测，
  /// 返回所有节点的检测结果列表。
  ///
  /// [onProgress] 可选的进度回调函数，参数为：
  /// - 当前检测的节点名称
  /// - 当前检测序号（从1开始）
  /// - 总节点数
  ///
  /// 返回所有节点的 [PingResult] 列表
  static Future<List<PingResult>> pingAllNodes({
    void Function(String nodeName, int current, int total)? onProgress,
  }) async {
    final results = <PingResult>[];
    final total = _pingNodes.length;

    // 遍历所有节点，逐个执行Ping检测
    for (var i = 0; i < _pingNodes.length; i++) {
      final node = _pingNodes[i];
      // 报告当前进度
      onProgress?.call(node['name']!, i + 1, total);
      // 执行单个节点的Ping检测
      final result = await _pingNode(node['name']!, node['url']!);
      results.add(result);
    }

    return results;
  }

  /// 对单个节点执行Ping检测
  ///
  /// 使用HEAD请求检测节点的连通性和响应延迟。
  /// 设置10秒超时，超时或发生错误时返回不可达结果。
  ///
  /// [name] 节点名称
  /// [url] 节点URL
  ///
  /// 返回该节点的 [PingResult]
  static Future<PingResult> _pingNode(String name, String url) async {
    // 使用秒表记录响应时间
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(url);
      // 使用HEAD请求，只获取响应头，减少数据传输
      final request = http.Request('HEAD', uri);
      request.headers['User-Agent'] = 'BAMCLauncher/2.0.0';

      // 发送请求，设置10秒超时
      final response = await _httpClient.send(request).timeout(
        const Duration(seconds: 10),
      );

      stopwatch.stop();
      // 清空响应流，释放连接资源
      await response.stream.drain<void>();

      return PingResult(
        nodeName: name,
        nodeUrl: url,
        latencyMs: stopwatch.elapsedMilliseconds,
        // HTTP状态码 2xx 和 3xx 视为可达
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

  /// 检测所有预定义主机名的DNS解析
  ///
  /// 依次对 [_dnsHosts] 中的每个主机名执行DNS解析，
  /// 返回所有解析结果列表。
  ///
  /// [onProgress] 可选的进度回调函数，参数为：
  /// - 当前解析的主机名
  /// - 当前解析序号（从1开始）
  /// - 总主机名数
  ///
  /// 返回所有主机名的 [DnsResult] 列表
  static Future<List<DnsResult>> checkDns({
    void Function(String hostname, int current, int total)? onProgress,
  }) async {
    final results = <DnsResult>[];
    final total = _dnsHosts.length;

    // 遍历所有主机名，逐个执行DNS解析
    for (var i = 0; i < _dnsHosts.length; i++) {
      final hostname = _dnsHosts[i];
      // 报告当前进度
      onProgress?.call(hostname, i + 1, total);
      // 执行单个主机名的DNS解析
      final result = await _resolveDns(hostname);
      results.add(result);
    }

    return results;
  }

  /// 解析单个主机名的DNS
  ///
  /// 使用系统DNS解析器解析主机名，获取其IP地址列表。
  /// 设置5秒超时，超时或发生错误时返回失败结果。
  ///
  /// [hostname] 要解析的主机名
  ///
  /// 返回该主机名的 [DnsResult]
  static Future<DnsResult> _resolveDns(String hostname) async {
    // 使用秒表记录解析时间
    final stopwatch = Stopwatch()..start();

    try {
      // 执行DNS解析，设置5秒超时
      final addresses = await InternetAddress.lookup(hostname)
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      return DnsResult(
        hostname: hostname,
        // 提取所有IP地址
        ipAddresses: addresses.map((a) => a.address).toList(),
        resolutionTimeMs: stopwatch.elapsedMilliseconds,
        // 解析成功且有IP地址返回
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

  /// 测试所有预定义URL的下载速度
  ///
  /// 依次对 [_downloadTestUrls] 中的每个URL执行下载速度测试，
  /// 返回所有测试结果列表。
  ///
  /// [onProgress] 可选的进度回调函数，参数为：
  /// - 当前测试的URL
  /// - 当前测试序号（从1开始）
  /// - 总URL数
  ///
  /// 返回所有URL的 [DownloadSpeedResult] 列表
  static Future<List<DownloadSpeedResult>> testDownloadSpeed({
    void Function(String url, int current, int total)? onProgress,
  }) async {
    final results = <DownloadSpeedResult>[];
    final total = _downloadTestUrls.length;

    // 遍历所有URL，逐个执行下载速度测试
    for (var i = 0; i < _downloadTestUrls.length; i++) {
      final url = _downloadTestUrls[i];
      // 报告当前进度
      onProgress?.call(url, i + 1, total);
      // 执行单个URL的下载速度测试
      final result = await _testDownloadSpeed(url);
      results.add(result);
    }

    return results;
  }

  /// 测试单个URL的下载速度
  ///
  /// 通过下载指定URL的内容来测量实际下载速度。
  /// 设置15秒超时，下载完成后计算速度（Mbps）。
  ///
  /// [url] 要测试的URL
  ///
  /// 返回该URL的 [DownloadSpeedResult]
  static Future<DownloadSpeedResult> _testDownloadSpeed(String url) async {
    // 使用秒表记录总时间
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(url);
      // 使用GET请求下载完整内容
      final request = http.Request('GET', uri);
      request.headers['User-Agent'] = 'BAMCLauncher/2.0.0';

      // 发送请求，设置15秒超时
      final streamedResponse = await _httpClient.send(request).timeout(
        const Duration(seconds: 15),
      );

      final statusCode = streamedResponse.statusCode;
      final contentLength = streamedResponse.contentLength ?? 0;
      // 用于存储接收到的所有字节数据
      final bytesReceived = <int>[];

      // 读取响应流中的所有数据块
      await for (final chunk in streamedResponse.stream) {
        bytesReceived.addAll(chunk);
      }

      stopwatch.stop();

      // 检查HTTP状态码是否为200
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

      // 计算下载速度
      final totalBytes = bytesReceived.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      // 计算字节/秒
      final speedBps = seconds > 0 ? totalBytes / seconds : 0;
      // 转换为Mbps（兆比特/秒）
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

  /// 生成完整的网络诊断报告
  ///
  /// 依次执行以下检测：
  /// 1. Ping延迟检测
  /// 2. DNS解析检测
  /// 3. 下载速度测试
  ///
  /// 最后生成包含所有结果的HTML格式报告。
  ///
  /// [onProgress] 可选的进度回调函数，参数为：
  /// - 当前阶段名称（如 "Ping延迟检测"）
  /// - 当前阶段序号（从1开始）
  /// - 总阶段数（固定为3）
  ///
  /// 返回完整的 [NetworkDiagnosticReport]
  static Future<NetworkDiagnosticReport> generateReport({
    void Function(String stage, int current, int total)? onProgress,
  }) async {
    final totalStages = 3;
    var currentStage = 0;

    // 阶段1：Ping延迟检测
    onProgress?.call('Ping延迟检测', ++currentStage, totalStages);
    final pingResults = await pingAllNodes();

    // 阶段2：DNS解析检测
    onProgress?.call('DNS解析检测', ++currentStage, totalStages);
    final dnsResults = await checkDns();

    // 阶段3：下载速度测试
    onProgress?.call('下载速度测试', ++currentStage, totalStages);
    final downloadResults = await testDownloadSpeed();

    // 判断所有检测是否都通过
    final isAllPassed = pingResults.every((r) => r.isReachable) &&
        dnsResults.every((r) => r.isSuccess) &&
        downloadResults.every((r) => r.isSuccess);

    // 生成HTML格式的报告
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

  /// 生成HTML格式的诊断报告
  ///
  /// 创建一个格式美观的HTML报告，包含：
  /// - 报告标题和生成时间
  /// - 总体状态徽章（通过/异常）
  /// - Ping延迟检测表格
  /// - DNS解析检测表格
  /// - 下载速度测试表格
  ///
  /// 所有参数均为必填
  /// - [timestamp] 报告时间戳
  /// - [pingResults] Ping检测结果列表
  /// - [dnsResults] DNS解析结果列表
  /// - [downloadResults] 下载速度测试结果列表
  /// - [isAllPassed] 所有检测是否通过
  ///
  /// 返回完整的HTML字符串
  static String _generateHtmlReport({
    required DateTime timestamp,
    required List<PingResult> pingResults,
    required List<DnsResult> dnsResults,
    required List<DownloadSpeedResult> downloadResults,
    required bool isAllPassed,
  }) {
    final buffer = StringBuffer();

    // 写入HTML文档头部和样式
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

    // 写入Ping延迟检测表格
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

    // 遍历Ping结果，生成表格行
    for (final result in pingResults) {
      // 根据延迟值确定CSS类名
      final latencyClass = result.latencyMs == null
          ? 'latency-bad'
          : result.latencyMs! < 100
              ? 'latency-good'
              : result.latencyMs! < 200
                  ? 'latency-medium'
                  : 'latency-bad';
      // 确定状态图标
      final statusIcon = result.isReachable ? '✓' : '✗';
      // 确定状态文本
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

    // 写入DNS解析检测表格
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

    // 遍历DNS结果，生成表格行
    for (final result in dnsResults) {
      final statusIcon = result.isSuccess ? '✓' : '✗';
      // 根据解析时间确定CSS类名
      final timeClass = result.resolutionTimeMs < 100
          ? 'latency-good'
          : result.resolutionTimeMs < 500
              ? 'latency-medium'
              : 'latency-bad';
      // 格式化IP地址列表
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

    // 写入下载速度测试表格
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

    // 遍历下载速度结果，生成表格行
    for (final result in downloadResults) {
      final statusIcon = result.isSuccess ? '✓' : '✗';
      // 根据下载速度确定CSS类名
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

    // 写入HTML文档尾部
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

  /// 将诊断报告保存到文件
  ///
  /// 将HTML格式的报告写入指定路径的文件。
  /// 如果报告没有HTML内容，则不执行任何操作。
  ///
  /// [report] 要保存的诊断报告
  /// [filePath] 目标文件路径
  static Future<void> saveReportToFile(
    NetworkDiagnosticReport report,
    String filePath,
  ) async {
    // 检查是否有HTML报告内容
    if (report.htmlReport == null) return;
    final file = File(filePath);
    await file.writeAsString(report.htmlReport!);
  }
}