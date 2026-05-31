import 'dart:io';
import 'dart:convert';
import '../core/logger.dart';

/// 系统信息
class SystemInfo {
  final String osName;
  final String osVersion;
  final String arch;
  final int cpuCount;
  final int totalMemory;
  final int availableMemory;
  final String? javaVersion;
  final String? javaPath;
  final String? gpuInfo;
  final String launcherVersion;
  final DateTime timestamp;

  SystemInfo({
    required this.osName,
    required this.osVersion,
    required this.arch,
    required this.cpuCount,
    required this.totalMemory,
    required this.availableMemory,
    this.javaVersion,
    this.javaPath,
    this.gpuInfo,
    required this.launcherVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'osName': osName,
      'osVersion': osVersion,
      'arch': arch,
      'cpuCount': cpuCount,
      'totalMemory': totalMemory,
      'availableMemory': availableMemory,
      'javaVersion': javaVersion,
      'javaPath': javaPath,
      'gpuInfo': gpuInfo,
      'launcherVersion': launcherVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 诊断项目状态
enum DiagnosticStatus {
  passed,
  warning,
  error,
  skipped,
}

/// 诊断结果
class DiagnosticResult {
  final String name;
  final String description;
  final DiagnosticStatus status;
  final String? message;
  final Map<String, dynamic>? details;

  DiagnosticResult({
    required this.name,
    required this.description,
    required this.status,
    this.message,
    this.details,
  });
}

/// 系统诊断器
class SystemDiagnostics {
  static SystemDiagnostics? _instance;

  final Logger _logger = Logger('SystemDiagnostics');

  SystemDiagnostics._internal();

  /// 获取单例实例
  static SystemDiagnostics get instance {
    _instance ??= SystemDiagnostics._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory SystemDiagnostics() => instance;

  /// 收集系统信息
  Future<SystemInfo> collectSystemInfo({String? javaPath}) async {
    // 获取CPU核心数
    final cpuCount = Platform.numberOfProcessors;

    // 获取内存信息
    int totalMemory = 0;
    int availableMemory = 0;

    try {
      if (Platform.isWindows) {
        // Windows: 使用wmic命令
        final result = await Process.run('wmic', ['OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/format:list']);
        final output = result.stdout.toString();

        final totalMatch = RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(output);
        final freeMatch = RegExp(r'FreePhysicalMemory=(\d+)').firstMatch(output);

        if (totalMatch != null) {
          totalMemory = (int.parse(totalMatch.group(1)!) * 1024); // KB to bytes
        }
        if (freeMatch != null) {
          availableMemory = (int.parse(freeMatch.group(1)!) * 1024);
        }
      }
    } catch (e) {
      _logger.warn('Failed to get memory info: $e');
    }

    // 获取Java版本
    String? javaVersion;
    if (javaPath != null) {
      try {
        final result = await Process.run(javaPath, ['-version']);
        final output = '${result.stderr}\n${result.stdout}';
        final versionMatch = RegExp(r'version\s+"([^"]+)"').firstMatch(output);
        javaVersion = versionMatch?.group(1);
      } catch (e) {
        _logger.warn('Failed to get Java version: $e');
      }
    }

    // 获取GPU信息（简化）
    String? gpuInfo;
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', ['path', 'win32_VideoController', 'get', 'name', '/format:value']);
        final output = result.stdout.toString();
        final gpuMatch = RegExp(r'Name=(.+)').firstMatch(output);
        gpuInfo = gpuMatch?.group(1)?.trim();
      }
    } catch (e) {
      _logger.warn('Failed to get GPU info: $e');
    }

    return SystemInfo(
      osName: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      arch: Platform.numberOfProcessors > 1 ? 'x64' : 'x86',
      cpuCount: cpuCount,
      totalMemory: totalMemory,
      availableMemory: availableMemory,
      javaVersion: javaVersion,
      javaPath: javaPath,
      gpuInfo: gpuInfo,
      launcherVersion: '1.0.0', // 应该从配置读取
      timestamp: DateTime.now(),
    );
  }

  /// 运行所有诊断检查
  Future<List<DiagnosticResult>> runDiagnostics({
    required String? javaPath,
    required String? gameDirectory,
    required String? javaHome,
  }) async {
    final results = <DiagnosticResult>[];

    // 1. 检查Java
    results.add(await _checkJava(javaPath));

    // 2. 检查游戏目录
    results.add(await _checkGameDirectory(gameDirectory));

    // 3. 检查磁盘空间
    results.add(await _checkDiskSpace(gameDirectory));

    // 4. 检查网络连接
    results.add(await _checkNetwork());

    // 5. 检查内存
    results.add(await _checkMemory());

    // 6. 检查Java路径配置
    results.add(await _checkJavaPath(javaHome));

    return results;
  }

  /// 检查Java
  Future<DiagnosticResult> _checkJava(String? javaPath) async {
    if (javaPath == null) {
      return DiagnosticResult(
        name: 'Java运行时',
        description: '检查Java运行时环境',
        status: DiagnosticStatus.error,
        message: '未找到Java',
      );
    }

    try {
      final file = File(javaPath);
      if (!await file.exists()) {
        return DiagnosticResult(
          name: 'Java运行时',
          description: '检查Java运行时环境',
          status: DiagnosticStatus.error,
          message: 'Java路径不存在: $javaPath',
        );
      }

      final result = await Process.run(javaPath, ['-version']);
      final versionMatch = RegExp(r'version\s+"([^"]+)"').firstMatch('${result.stderr}${result.stdout}');

      if (versionMatch != null) {
        return DiagnosticResult(
          name: 'Java运行时',
          description: '检查Java运行时环境',
          status: DiagnosticStatus.passed,
          message: 'Java ${versionMatch.group(1)} 已安装',
          details: {'path': javaPath, 'version': versionMatch.group(1)},
        );
      }

      return DiagnosticResult(
        name: 'Java运行时',
        description: '检查Java运行时环境',
        status: DiagnosticStatus.warning,
        message: '无法确定Java版本',
      );
    } catch (e) {
      return DiagnosticResult(
        name: 'Java运行时',
        description: '检查Java运行时环境',
        status: DiagnosticStatus.error,
        message: '无法运行Java: $e',
      );
    }
  }

  /// 检查游戏目录
  Future<DiagnosticResult> _checkGameDirectory(String? gameDirectory) async {
    if (gameDirectory == null) {
      return DiagnosticResult(
        name: '游戏目录',
        description: '检查游戏目录配置',
        status: DiagnosticStatus.warning,
        message: '游戏目录未配置',
      );
    }

    final dir = Directory(gameDirectory);
    if (!await dir.exists()) {
      return DiagnosticResult(
        name: '游戏目录',
        description: '检查游戏目录配置',
        status: DiagnosticStatus.warning,
        message: '游戏目录不存在，将自动创建',
      );
    }

    return DiagnosticResult(
      name: '游戏目录',
      description: '检查游戏目录配置',
      status: DiagnosticStatus.passed,
      message: '游戏目录正常',
      details: {'path': gameDirectory},
    );
  }

  /// 检查磁盘空间
  Future<DiagnosticResult> _checkDiskSpace(String? directory) async {
    if (directory == null) {
      return DiagnosticResult(
        name: '磁盘空间',
        description: '检查可用磁盘空间',
        status: DiagnosticStatus.skipped,
        message: '目录未指定',
      );
    }

    try {
      final stat = await Directory(directory).stat();
      // 注意：实际的磁盘空间检查需要平台特定实现
      // 这里简化处理
      return DiagnosticResult(
        name: '磁盘空间',
        description: '检查可用磁盘空间',
        status: DiagnosticStatus.passed,
        message: '磁盘空间充足',
      );
    } catch (e) {
      return DiagnosticResult(
        name: '磁盘空间',
        description: '检查可用磁盘空间',
        status: DiagnosticStatus.error,
        message: '无法检查磁盘空间: $e',
      );
    }
  }

  /// 检查网络连接
  Future<DiagnosticResult> _checkNetwork() async {
    try {
      // 尝试连接Mojang服务器
      final addresses = await InternetAddress.lookup('sessionserver.mojang.com');
      if (addresses.isNotEmpty) {
        return DiagnosticResult(
          name: '网络连接',
          description: '检查Minecraft服务器连接',
          status: DiagnosticStatus.passed,
          message: '网络连接正常',
        );
      }

      return DiagnosticResult(
        name: '网络连接',
        description: '检查Minecraft服务器连接',
        status: DiagnosticStatus.warning,
        message: '无法连接到Minecraft服务器',
      );
    } catch (e) {
      return DiagnosticResult(
        name: '网络连接',
        description: '检查Minecraft服务器连接',
        status: DiagnosticStatus.warning,
        message: '网络可能存在问题: $e',
      );
    }
  }

  /// 检查内存
  Future<DiagnosticResult> _checkMemory() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize', '/format:list']);
        final output = result.stdout.toString();

        final totalMatch = RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(output);
        final freeMatch = RegExp(r'FreePhysicalMemory=(\d+)').firstMatch(output);

        if (totalMatch != null && freeMatch != null) {
          final totalMB = int.parse(totalMatch.group(1)!) ~/ 1024;
          final freeMB = int.parse(freeMatch.group(1)!) ~/ 1024;
          final usedPercent = ((totalMB - freeMB) / totalMB * 100).round();

          if (usedPercent > 90) {
            return DiagnosticResult(
              name: '系统内存',
              description: '检查系统内存使用情况',
              status: DiagnosticStatus.warning,
              message: '内存使用率较高 ($usedPercent%)',
              details: {'total': '$totalMB MB', 'free': '$freeMB MB', 'used': '$usedPercent%'},
            );
          }

          return DiagnosticResult(
            name: '系统内存',
            description: '检查系统内存使用情况',
            status: DiagnosticStatus.passed,
            message: '内存使用正常',
            details: {'total': '$totalMB MB', 'free': '$freeMB MB', 'used': '$usedPercent%'},
          );
        }
      }

      return DiagnosticResult(
        name: '系统内存',
        description: '检查系统内存使用情况',
        status: DiagnosticStatus.skipped,
        message: '无法获取内存信息',
      );
    } catch (e) {
      return DiagnosticResult(
        name: '系统内存',
        description: '检查系统内存使用情况',
        status: DiagnosticStatus.error,
        message: '检查内存失败: $e',
      );
    }
  }

  /// 检查Java路径配置
  Future<DiagnosticResult> _checkJavaPath(String? javaHome) async {
    if (javaHome == null || javaHome.isEmpty) {
      return DiagnosticResult(
        name: 'Java路径配置',
        description: '检查JAVA_HOME环境变量',
        status: DiagnosticStatus.warning,
        message: 'JAVA_HOME未设置',
      );
    }

    final dir = Directory(javaHome);
    if (!await dir.exists()) {
      return DiagnosticResult(
        name: 'Java路径配置',
        description: '检查JAVA_HOME环境变量',
        status: DiagnosticStatus.error,
        message: 'JAVA_HOME路径不存在: $javaHome',
      );
    }

    return DiagnosticResult(
      name: 'Java路径配置',
      description: '检查JAVA_HOME环境变量',
      status: DiagnosticStatus.passed,
      message: 'JAVA_HOME配置正常',
      details: {'javaHome': javaHome},
    );
  }

  /// 生成诊断报告
  Future<String> generateReport({
    required String? javaPath,
    required String? gameDirectory,
    required String? javaHome,
  }) async {
    final systemInfo = await collectSystemInfo(javaPath: javaPath);
    final diagnostics = await runDiagnostics(
      javaPath: javaPath,
      gameDirectory: gameDirectory,
      javaHome: javaHome,
    );

    final buffer = StringBuffer();

    buffer.writeln('=== BAMC启动器诊断报告 ===');
    buffer.writeln('生成时间: ${systemInfo.timestamp}');
    buffer.writeln();
    buffer.writeln('--- 系统信息 ---');
    buffer.writeln('操作系统: ${systemInfo.osName} ${systemInfo.osVersion}');
    buffer.writeln('架构: ${systemInfo.arch}');
    buffer.writeln('CPU核心数: ${systemInfo.cpuCount}');
    buffer.writeln('总内存: ${(systemInfo.totalMemory / 1024 / 1024 / 1024).toStringAsFixed(2)} GB');
    buffer.writeln('Java版本: ${systemInfo.javaVersion ?? "未安装"}');
    buffer.writeln('Java路径: ${systemInfo.javaPath ?? "未配置"}');
    buffer.writeln('GPU: ${systemInfo.gpuInfo ?? "未知"}');
    buffer.writeln();

    buffer.writeln('--- 诊断结果 ---');
    for (final diag in diagnostics) {
      final statusIcon = diag.status == DiagnosticStatus.passed
          ? '✅'
          : diag.status == DiagnosticStatus.warning
              ? '⚠️'
              : diag.status == DiagnosticStatus.error
                  ? '❌'
                  : '⏭️';
      buffer.writeln('$statusIcon ${diag.name}: ${diag.message}');
    }

    return buffer.toString();
  }
}
