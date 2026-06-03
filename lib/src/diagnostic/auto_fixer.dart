import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import 'java_checker.dart';
import 'network_diagnostic.dart';

enum FixCategory { java, network, gameFiles, config }

enum FixSeverity { low, medium, high, critical }

class FixIssue {
  final String id;
  final String title;
  final String description;
  final FixCategory category;
  final FixSeverity severity;
  final bool canAutoFix;
  final String? autoFixDescription;

  const FixIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.canAutoFix,
    this.autoFixDescription,
  });
}

class FixOperation {
  final String issueId;
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  bool isSuccess;
  String? errorMessage;
  String? output;

  FixOperation({
    required this.issueId,
    required this.operationName,
    required this.startTime,
    this.endTime,
    this.isSuccess = false,
    this.errorMessage,
    this.output,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

class FixResult {
  final String issueId;
  final bool isFixed;
  final bool isSuccess;
  final String? message;
  final List<String> logs;

  const FixResult({
    required this.issueId,
    required this.isFixed,
    required this.isSuccess,
    this.message,
    this.logs = const [],
  });
}

class AutoFixer {
  static final AutoFixer _instance = AutoFixer._internal();
  factory AutoFixer() => _instance;
  AutoFixer._internal();

  final List<FixOperation> _fixHistory = [];
  final List<String> _fixLogs = [];

  List<FixOperation> get fixHistory => List.unmodifiable(_fixHistory);
  List<String> get fixLogs => List.unmodifiable(_fixLogs);

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final logMessage = '[$timestamp] $message';
    _fixLogs.add(logMessage);
  }

  Future<List<FixIssue>> detectAllIssues() async {
    final issues = <FixIssue>[];

    final javaIssues = await _detectJavaIssues();
    issues.addAll(javaIssues);

    final networkIssues = await _detectNetworkIssues();
    issues.addAll(networkIssues);

    final gameFileIssues = await _detectGameFileIssues();
    issues.addAll(gameFileIssues);

    final configIssues = await _detectConfigIssues();
    issues.addAll(configIssues);

    return issues;
  }

  Future<List<FixIssue>> _detectJavaIssues() async {
    final issues = <FixIssue>[];
    final javaResult = await JavaChecker.checkJava();

    if (!javaResult.isAvailable) {
      issues.add(const FixIssue(
        id: 'java_not_found',
        title: 'Java 未安装',
        description: '系统中未检测到 Java 安装，无法启动游戏',
        category: FixCategory.java,
        severity: FixSeverity.critical,
        canAutoFix: false,
      ));
    } else if (javaResult.majorVersion != null && javaResult.majorVersion! < 8) {
      issues.add(FixIssue(
        id: 'java_version_too_low',
        title: 'Java 版本过低',
        description: '当前 Java 版本 ${javaResult.javaVersion} 过低，建议升级到 Java 17+',
        category: FixCategory.java,
        severity: FixSeverity.high,
        canAutoFix: false,
        autoFixDescription: '请从 Eclipse Adoptium (adoptium.net) 下载 Java 17 或 21',
      ));
    }

    final config = ConfigManager();
    final configuredJavaPath = config.getString(ConfigKeys.javaPath);
    if (configuredJavaPath != null && configuredJavaPath.isNotEmpty) {
      final javaFile = File(configuredJavaPath);
      if (!javaFile.existsSync()) {
        issues.add(FixIssue(
          id: 'java_path_invalid',
          title: 'Java 路径无效',
          description: '配置的 Java 路径不存在: $configuredJavaPath',
          category: FixCategory.java,
          severity: FixSeverity.high,
          canAutoFix: true,
          autoFixDescription: '自动清除无效的 Java 路径配置',
        ));
      }
    }

    return issues;
  }

  Future<List<FixIssue>> _detectNetworkIssues() async {
    final issues = <FixIssue>[];

    try {
      final pingResults = await NetworkDiagnostic.pingAllNodes();
      final unreachableNodes = pingResults.where((r) => !r.isReachable).toList();

      if (unreachableNodes.length == pingResults.length) {
        issues.add(const FixIssue(
          id: 'network_all_unreachable',
          title: '网络完全不可用',
          description: '所有下载节点都无法访问，请检查网络连接',
          category: FixCategory.network,
          severity: FixSeverity.critical,
          canAutoFix: false,
        ));
      } else if (unreachableNodes.isNotEmpty) {
        final unreachableNames = unreachableNodes.map((r) => r.nodeName).join(', ');
        issues.add(FixIssue(
          id: 'network_partial_unreachable',
          title: '部分节点不可用',
          description: '以下节点无法访问: $unreachableNames',
          category: FixCategory.network,
          severity: FixSeverity.medium,
          canAutoFix: true,
          autoFixDescription: '自动切换到可用的镜像源',
        ));
      }

      final dnsResults = await NetworkDiagnostic.checkDns();
      final failedDns = dnsResults.where((r) => !r.isSuccess).toList();
      if (failedDns.isNotEmpty) {
        final failedHosts = failedDns.map((r) => r.hostname).join(', ');
        issues.add(FixIssue(
          id: 'dns_resolution_failed',
          title: 'DNS 解析失败',
          description: '以下主机名解析失败: $failedHosts',
          category: FixCategory.network,
          severity: FixSeverity.medium,
          canAutoFix: false,
        ));
      }
    } catch (e) {
      _log('网络检测失败: $e');
    }

    return issues;
  }

  Future<List<FixIssue>> _detectGameFileIssues() async {
    final issues = <FixIssue>[];
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    if (gameDir.isEmpty) {
      issues.add(const FixIssue(
        id: 'game_dir_not_set',
        title: '游戏目录未配置',
        description: '未设置游戏目录，请先配置游戏目录路径',
        category: FixCategory.gameFiles,
        severity: FixSeverity.high,
        canAutoFix: false,
      ));
    } else {
      final directory = Directory(gameDir);
      if (!await directory.exists()) {
        issues.add(FixIssue(
          id: 'game_dir_not_exist',
          title: '游戏目录不存在',
          description: '配置的游戏目录不存在: $gameDir',
          category: FixCategory.gameFiles,
          severity: FixSeverity.high,
          canAutoFix: true,
          autoFixDescription: '创建缺失的游戏目录',
        ));
      } else {
        final versionsDir = Directory(p.join(gameDir, 'versions'));
        if (!await versionsDir.exists()) {
          issues.add(FixIssue(
            id: 'versions_dir_missing',
            title: '游戏版本目录缺失',
            description: 'versions 目录不存在，游戏可能无法正常运行',
            category: FixCategory.gameFiles,
            severity: FixSeverity.medium,
            canAutoFix: true,
            autoFixDescription: '创建 versions 目录',
          ));
        }
      }
    }

    return issues;
  }

  Future<List<FixIssue>> _detectConfigIssues() async {
    final issues = <FixIssue>[];
    final config = ConfigManager();

    final memoryMB = config.getInt(ConfigKeys.memoryAllocation) ?? 2048;
    if (memoryMB < 1024) {
      issues.add(const FixIssue(
        id: 'memory_too_low',
        title: '内存分配过低',
        description: '游戏内存分配低于 1024 MB，可能导致游戏无法启动',
        category: FixCategory.config,
        severity: FixSeverity.high,
        canAutoFix: true,
        autoFixDescription: '自动将内存调整为 2048 MB',
      ));
    } else if (memoryMB > 12288) {
      issues.add(const FixIssue(
        id: 'memory_too_high',
        title: '内存分配过高',
        description: '内存分配超过 12 GB 可能导致 GC 停顿',
        category: FixCategory.config,
        severity: FixSeverity.low,
        canAutoFix: true,
        autoFixDescription: '自动将内存调整为 8192 MB',
      ));
    }

    return issues;
  }

  Future<FixResult> fixIssue(FixIssue issue) async {
    _log('开始修复: ${issue.title}');
    final operation = FixOperation(
      issueId: issue.id,
      operationName: issue.title,
      startTime: DateTime.now(),
    );
    _fixHistory.add(operation);

    try {
      FixResult result;

      switch (issue.id) {
        case 'java_path_invalid':
          result = await _fixJavaPathInvalid(operation);
          break;
        case 'network_partial_unreachable':
          result = await _fixNetworkSwitch(operation);
          break;
        case 'game_dir_not_exist':
          result = await _fixGameDirNotExist(operation);
          break;
        case 'versions_dir_missing':
          result = await _fixVersionsDirMissing(operation);
          break;
        case 'memory_too_low':
          result = await _fixMemoryTooLow(operation);
          break;
        case 'memory_too_high':
          result = await _fixMemoryTooHigh(operation);
          break;
        default:
          result = FixResult(
            issueId: issue.id,
            isFixed: false,
            isSuccess: false,
            message: '该问题不支持自动修复',
            logs: [],
          );
      }

      operation.endTime = DateTime.now();
      operation.isSuccess = result.isSuccess;
      operation.output = result.message;

      if (result.isSuccess) {
        _log('修复成功: ${issue.title}');
      } else {
        _log('修复失败: ${issue.title} - ${result.message}');
      }

      return result;
    } catch (e, stackTrace) {
      operation.endTime = DateTime.now();
      operation.isSuccess = false;
      operation.errorMessage = e.toString();
      operation.output = 'Stack trace: $stackTrace';
      _log('修复异常: ${issue.title} - $e');

      return FixResult(
        issueId: issue.id,
        isFixed: false,
        isSuccess: false,
        message: '修复过程中发生错误: $e',
        logs: [e.toString(), stackTrace.toString()],
      );
    }
  }

  Future<FixResult> _fixJavaPathInvalid(FixOperation operation) async {
    _log('正在清除无效的 Java 路径配置...');
    final config = ConfigManager();
    await config.remove(ConfigKeys.javaPath);

    final javaPath = await JavaChecker.findJavaExecutable();
    if (javaPath != null) {
      _log('找到可用的 Java: $javaPath');
      await config.setString(ConfigKeys.javaPath, javaPath);
      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已清除无效配置并设置为: $javaPath',
        logs: _fixLogs,
      );
    }

    return FixResult(
      issueId: operation.issueId,
      isFixed: false,
      isSuccess: true,
      message: '已清除无效的 Java 路径配置，但未找到可用的 Java',
      logs: _fixLogs,
    );
  }

  Future<FixResult> _fixNetworkSwitch(FixOperation operation) async {
    _log('正在测试并切换到可用的镜像源...');
    final mirrorManager = await _selectBestMirror();

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已切换到可用的镜像源: ${mirrorManager.name}',
      logs: _fixLogs,
    );
  }

  Future<_MirrorSourceInfo> _selectBestMirror() async {
    final mirrors = [
      {'name': 'BMCLAPI-2', 'url': 'https://bmclapi2.bangbang93.com'},
      {'name': 'BMCLAPI', 'url': 'https://bmclapi.bangbang93.com'},
      {'name': 'MCBBS', 'url': 'https://download.mcbbs.net'},
    ];

    for (final mirror in mirrors) {
      try {
        final uri = Uri.parse(mirror['url']!);
        final request = await HttpClient()
            .getUrl(uri.replace(path: '/mirrors.json'))
            .timeout(const Duration(seconds: 5));
        final response = await request.close().timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          _log('镜像源可用: ${mirror['name']}');
          return _MirrorSourceInfo(mirror['name']!, mirror['url']!);
        }
      } catch (_) {
        _log('镜像源不可用: ${mirror['name']}');
      }
    }

    return _MirrorSourceInfo('BMCLAPI-2', 'https://bmclapi2.bangbang93.com');
  }

  Future<FixResult> _fixGameDirNotExist(FixOperation operation) async {
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    _log('正在创建游戏目录: $gameDir');
    try {
      await Directory(gameDir).create(recursive: true);
      _log('游戏目录创建成功');
      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已创建游戏目录: $gameDir',
        logs: _fixLogs,
      );
    } catch (e) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '创建目录失败: $e',
        logs: _fixLogs,
      );
    }
  }

  Future<FixResult> _fixVersionsDirMissing(FixOperation operation) async {
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    if (gameDir.isEmpty) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '游戏目录未配置',
        logs: _fixLogs,
      );
    }

    _log('正在创建 versions 目录...');
    try {
      final versionsDir = Directory(p.join(gameDir, 'versions'));
      await versionsDir.create(recursive: true);
      _log('versions 目录创建成功');

      final librariesDir = Directory(p.join(gameDir, 'libraries'));
      await librariesDir.create(recursive: true);
      _log('libraries 目录创建成功');

      final modsDir = Directory(p.join(gameDir, 'mods'));
      await modsDir.create(recursive: true);
      _log('mods 目录创建成功');

      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已创建必要的游戏目录结构',
        logs: _fixLogs,
      );
    } catch (e) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '创建目录失败: $e',
        logs: _fixLogs,
      );
    }
  }

  Future<FixResult> _fixMemoryTooLow(FixOperation operation) async {
    _log('正在调整内存分配...');
    final config = ConfigManager();
    await config.setInt(ConfigKeys.memoryAllocation, 2048);
    _log('内存已调整为 2048 MB');

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已将内存分配从 1024 MB 以下调整为 2048 MB',
      logs: _fixLogs,
    );
  }

  Future<FixResult> _fixMemoryTooHigh(FixOperation operation) async {
    _log('正在调整内存分配...');
    final config = ConfigManager();
    await config.setInt(ConfigKeys.memoryAllocation, 8192);
    _log('内存已调整为 8192 MB');

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已将内存分配从 12 GB 以上调整为 8192 MB',
      logs: _fixLogs,
    );
  }

  Future<FixResult> autoFixAll(List<FixIssue> issues) async {
    var allFixed = true;
    final allLogs = <String>[];
    String? lastMessage;

    for (final issue in issues) {
      if (issue.canAutoFix) {
        final result = await fixIssue(issue);
        allLogs.addAll(result.logs);
        if (!result.isFixed) {
          allFixed = false;
        }
        lastMessage = result.message;
      }
    }

    return FixResult(
      issueId: 'auto_fix_all',
      isFixed: allFixed,
      isSuccess: true,
      message: lastMessage ?? (allFixed ? '所有问题已修复' : '部分问题修复失败'),
      logs: allLogs,
    );
  }

  String getFixLogSummary() {
    if (_fixLogs.isEmpty) return '暂无修复日志';

    final buffer = StringBuffer();
    buffer.writeln('=== 修复日志摘要 ===');
    buffer.writeln('总操作数: ${_fixHistory.length}');

    final successCount = _fixHistory.where((o) => o.isSuccess).length;
    final failCount = _fixHistory.length - successCount;
    buffer.writeln('成功: $successCount, 失败: $failCount');

    if (_fixHistory.isNotEmpty) {
      buffer.writeln('\n最近的操作:');
      for (final op in _fixHistory.reversed.take(5)) {
        final status = op.isSuccess ? '✓' : '✗';
        final duration = op.duration?.inMilliseconds ?? 0;
        buffer.writeln('  $status ${op.operationName} (${duration}ms)');
      }
    }

    return buffer.toString();
  }

  void clearLogs() {
    _fixLogs.clear();
    _fixHistory.clear();
  }
}

class _MirrorSourceInfo {
  final String name;
  final String url;
  _MirrorSourceInfo(this.name, this.url);
}
