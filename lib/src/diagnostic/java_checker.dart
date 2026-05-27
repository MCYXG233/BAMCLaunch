import 'dart:io';
import 'package:path/path.dart' as p;

class JavaCheckResult {
  final bool isAvailable;
  final String? javaPath;
  final String? javaVersion;
  final int? majorVersion;
  final bool? is64Bit;
  final String? errorMessage;

  const JavaCheckResult({
    required this.isAvailable,
    this.javaPath,
    this.javaVersion,
    this.majorVersion,
    this.is64Bit,
    this.errorMessage,
  });

  factory JavaCheckResult.unavailable(String message) {
    return JavaCheckResult(
      isAvailable: false,
      errorMessage: message,
    );
  }

  factory JavaCheckResult.available({
    required String javaPath,
    required String javaVersion,
    int? majorVersion,
    bool? is64Bit,
  }) {
    return JavaCheckResult(
      isAvailable: true,
      javaPath: javaPath,
      javaVersion: javaVersion,
      majorVersion: majorVersion,
      is64Bit: is64Bit,
    );
  }
}

class JavaChecker {
  static const List<String> _commonPaths = [
    r'C:\Program Files\Java',
    r'C:\Program Files (x86)\Java',
    r'C:\Program Files\Eclipse Adoptium',
    r'C:\Program Files\Microsoft\jdk',
    r'C:\Program Files\Zulu',
    r'C:\Program Files\BellSoft',
    r'C:\Program Files\Amazon Corretto',
  ];

  static Future<JavaCheckResult> checkJava() async {
    final systemResult = await _checkSystemJava();
    if (systemResult.isAvailable) return systemResult;

    final javaHomeResult = await _checkJavaHome();
    if (javaHomeResult.isAvailable) return javaHomeResult;

    final pathResult = await _checkCommonPaths();
    if (pathResult.isAvailable) return pathResult;

    return JavaCheckResult.unavailable('未检测到 Java 安装，请安装 Java 8 或更高版本');
  }

  static Future<JavaCheckResult> _checkSystemJava() async {
    try {
      final result = await Process.run(
        'java',
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      final output = (result.stderr as String?) ?? '';

      if (result.exitCode == 0 && output.contains('version')) {
        final version = parseJavaVersion(output);
        final majorVersion = _parseMajorVersion(version);
        final is64Bit = output.contains('64-Bit') ||
            output.contains('amd64') ||
            output.contains('x86_64');

        return JavaCheckResult.available(
          javaPath: 'java',
          javaVersion: version ?? 'unknown',
          majorVersion: majorVersion,
          is64Bit: is64Bit,
        );
      }
    } catch (_) {}

    return JavaCheckResult.unavailable('系统默认 Java 不可用');
  }

  static Future<JavaCheckResult> _checkJavaHome() async {
    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome == null || javaHome.isEmpty) {
      return JavaCheckResult.unavailable('JAVA_HOME 环境变量未设置');
    }

    final javaExe = Platform.isWindows
        ? p.join(javaHome, 'bin', 'java.exe')
        : p.join(javaHome, 'bin', 'java');

    if (!await File(javaExe).exists()) {
      return JavaCheckResult.unavailable('JAVA_HOME 路径下未找到 java 可执行文件: $javaHome');
    }

    final info = await _getJavaInfo(javaExe);
    if (info != null) return info;

    return JavaCheckResult.unavailable('JAVA_HOME 指向的 Java 无法正常运行');
  }

  static Future<JavaCheckResult> _checkCommonPaths() async {
    final executable = await findJavaExecutable();
    if (executable == null) {
      return JavaCheckResult.unavailable('在常见安装路径中未找到 Java');
    }

    final info = await _getJavaInfo(executable);
    if (info != null) return info;

    return JavaCheckResult.unavailable('找到 Java 但无法获取版本信息');
  }

  static Future<String?> findJavaExecutable() async {
    if (Platform.isWindows) {
      for (final basePath in _commonPaths) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        try {
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              final javaExe = p.join(entity.path, 'bin', 'java.exe');
              if (await File(javaExe).exists()) {
                return javaExe;
              }
            }
          }
        } catch (_) {}
      }

      final pathEnv = Platform.environment['PATH'];
      if (pathEnv != null) {
        for (final dir in pathEnv.split(';')) {
          final javaExe = p.join(dir, 'java.exe');
          if (await File(javaExe).exists()) {
            return javaExe;
          }
        }
      }
    } else {
      for (final basePath in ['/usr/lib/jvm', '/usr/java', '/opt/java', '/opt/jdk']) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        try {
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              final javaExe = p.join(entity.path, 'bin', 'java');
              if (await File(javaExe).exists()) {
                return javaExe;
              }
            }
          }
        } catch (_) {}
      }

      final pathEnv = Platform.environment['PATH'];
      if (pathEnv != null) {
        for (final dir in pathEnv.split(':')) {
          final javaExe = p.join(dir, 'java');
          if (await File(javaExe).exists()) {
            return javaExe;
          }
        }
      }
    }

    return null;
  }

  static Future<JavaCheckResult?> _getJavaInfo(String javaPath) async {
    try {
      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      final output = (result.stderr as String?) ?? '';

      if (result.exitCode != 0) return null;

      final version = parseJavaVersion(output);
      if (version == null) return null;

      final majorVersion = _parseMajorVersion(version);
      final is64Bit = output.contains('64-Bit') ||
          output.contains('amd64') ||
          output.contains('x86_64');

      return JavaCheckResult.available(
        javaPath: javaPath,
        javaVersion: version,
        majorVersion: majorVersion,
        is64Bit: is64Bit,
      );
    } catch (_) {
      return null;
    }
  }

  static String? parseJavaVersion(String versionOutput) {
    final match = RegExp(r'"(\d+(?:\.\d+)*(?:[_.][^"]*)?)"').firstMatch(versionOutput);
    return match?.group(1);
  }

  static int? _parseMajorVersion(String? version) {
    if (version == null) return null;
    final firstPart = version.split('.').first;
    return int.tryParse(firstPart);
  }
}
