import 'dart:io';
import 'package:path/path.dart' as p;

/// Java 环境检查结果类
///
/// 用于封装 Java 环境检测的所有相关信息，包括：
/// - Java 是否可用
/// - Java 可执行文件路径
/// - Java 版本信息
/// - 是否为 64 位 JVM
/// - 错误信息（如果检测失败）
class JavaCheckResult {
  /// Java 是否可用
  final bool isAvailable;

  /// Java 可执行文件的路径
  /// 当 [isAvailable] 为 true 时，此字段包含有效的路径
  final String? javaPath;

  /// Java 版本字符串（如 "1.8.0_301"、"17.0.1" 等）
  final String? javaVersion;

  /// Java 主版本号（如 8、11、17 等）
  /// 从 [javaVersion] 中提取的整数部分
  final int? majorVersion;

  /// 是否为 64 位 JVM
  /// 通过检测版本输出中是否包含 "64-Bit"、"amd64" 或 "x86_64" 来判断
  final bool? is64Bit;

  /// 错误信息
  /// 当 [isAvailable] 为 false 时，包含具体的错误描述
  final String? errorMessage;

  /// 构造函数
  ///
  /// 所有字段都是可选的，但 [isAvailable] 是必需的
  const JavaCheckResult({
    required this.isAvailable,
    this.javaPath,
    this.javaVersion,
    this.majorVersion,
    this.is64Bit,
    this.errorMessage,
  });

  /// 创建一个表示 Java 不可用的结果
  ///
  /// [message] 错误信息，描述 Java 不可用的原因
  factory JavaCheckResult.unavailable(String message) {
    return JavaCheckResult(
      isAvailable: false,
      errorMessage: message,
    );
  }

  /// 创建一个表示 Java 可用的结果
  ///
  /// [javaPath] Java 可执行文件的路径（必需）
  /// [javaVersion] Java 版本字符串（必需）
  /// [majorVersion] Java 主版本号（可选）
  /// [is64Bit] 是否为 64 位 JVM（可选）
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

/// Java 环境检查器
///
/// 提供检测系统中 Java 安装情况的功能。检测策略按优先级依次为：
/// 1. 系统默认 Java（通过 PATH 环境变量）
/// 2. JAVA_HOME 环境变量指定的 Java
/// 3. 常见安装路径中的 Java
///
/// 使用示例：
/// ```dart
/// final result = await JavaChecker.checkJava();
/// if (result.isAvailable) {
///   print('Java 版本: ${result.javaVersion}');
/// } else {
///   print('错误: ${result.errorMessage}');
/// }
/// ```
class JavaChecker {
  /// Windows 系统下常见的 Java 安装路径
  ///
  /// 包含主流 JDK 发行版的默认安装位置：
  /// - Oracle Java
  /// - Eclipse Adoptium (Temurin)
  /// - Microsoft JDK
  /// - Azul Zulu
  /// - BellSoft Liberica
  /// - Amazon Corretto
  static const List<String> _commonPaths = [
    r'C:\Program Files\Java',
    r'C:\Program Files (x86)\Java',
    r'C:\Program Files\Eclipse Adoptium',
    r'C:\Program Files\Microsoft\jdk',
    r'C:\Program Files\Zulu',
    r'C:\Program Files\BellSoft',
    r'C:\Program Files\Amazon Corretto',
  ];

  /// 检查系统中的 Java 安装
  ///
  /// 按优先级依次检测：
  /// 1. 系统默认 Java（通过 PATH 环境变量中的 java 命令）
  /// 2. JAVA_HOME 环境变量指定的 Java
  /// 3. 常见安装路径中的 Java
  ///
  /// 返回 [JavaCheckResult] 对象，包含检测结果
  /// 如果所有检测都失败，返回包含错误信息的结果
  static Future<JavaCheckResult> checkJava() async {
    // 首先尝试系统默认 Java（通过 PATH 环境变量）
    final systemResult = await _checkSystemJava();
    if (systemResult.isAvailable) return systemResult;

    // 其次尝试 JAVA_HOME 环境变量
    final javaHomeResult = await _checkJavaHome();
    if (javaHomeResult.isAvailable) return javaHomeResult;

    // 最后尝试常见安装路径
    final pathResult = await _checkCommonPaths();
    if (pathResult.isAvailable) return pathResult;

    // 所有检测都失败，返回不可用结果
    return JavaCheckResult.unavailable('未检测到 Java 安装，请安装 Java 8 或更高版本');
  }

  /// 检查系统默认 Java
  ///
  /// 通过执行 `java -version` 命令来检测系统 PATH 中是否有可用的 Java
  /// 注意：`java -version` 的输出在 stderr 中，而非 stdout
  ///
  /// 返回检测结果，如果检测失败则返回包含错误信息的结果
  static Future<JavaCheckResult> _checkSystemJava() async {
    try {
      // 执行 java -version 命令
      final result = await Process.run(
        'java',
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      // java -version 的版本信息输出在 stderr 中
      final output = (result.stderr as String?) ?? '';

      // 检查命令是否成功执行且输出包含版本信息
      if (result.exitCode == 0 && output.contains('version')) {
        // 解析版本号
        final version = parseJavaVersion(output);
        // 提取主版本号
        final majorVersion = _parseMajorVersion(version);
        // 检测是否为 64 位 JVM
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
    } catch (_) {
      // 捕获所有异常，表示系统 Java 不可用
    }

    return JavaCheckResult.unavailable('系统默认 Java 不可用');
  }

  /// 检查 JAVA_HOME 环境变量指定的 Java
  ///
  /// 读取 JAVA_HOME 环境变量，并在其 bin 目录下查找 java 可执行文件
  /// 如果找到则验证其可用性并获取版本信息
  ///
  /// 返回检测结果，如果检测失败则返回包含错误信息的结果
  static Future<JavaCheckResult> _checkJavaHome() async {
    // 获取 JAVA_HOME 环境变量
    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome == null || javaHome.isEmpty) {
      return JavaCheckResult.unavailable('JAVA_HOME 环境变量未设置');
    }

    // 构建 java 可执行文件的完整路径
    // Windows 下为 java.exe，其他平台为 java
    final javaExe = Platform.isWindows
        ? p.join(javaHome, 'bin', 'java.exe')
        : p.join(javaHome, 'bin', 'java');

    // 检查可执行文件是否存在
    if (!await File(javaExe).exists()) {
      return JavaCheckResult.unavailable('JAVA_HOME 路径下未找到 java 可执行文件: $javaHome');
    }

    // 获取 Java 信息
    final info = await _getJavaInfo(javaExe);
    if (info != null) return info;

    return JavaCheckResult.unavailable('JAVA_HOME 指向的 Java 无法正常运行');
  }

  /// 检查常见安装路径中的 Java
  ///
  /// 在预定义的常见 Java 安装路径中查找 Java 可执行文件
  /// 如果找到则验证其可用性并获取版本信息
  ///
  /// 返回检测结果，如果检测失败则返回包含错误信息的结果
  static Future<JavaCheckResult> _checkCommonPaths() async {
    // 在常见路径中查找 Java 可执行文件
    final executable = await findJavaExecutable();
    if (executable == null) {
      return JavaCheckResult.unavailable('在常见安装路径中未找到 Java');
    }

    // 获取 Java 信息
    final info = await _getJavaInfo(executable);
    if (info != null) return info;

    return JavaCheckResult.unavailable('找到 Java 但无法获取版本信息');
  }

  /// 在常见路径中查找 Java 可执行文件
  ///
  /// 搜索策略：
  /// - Windows: 在 [_commonPaths] 列出的路径和 PATH 环境变量中查找 java.exe
  /// - 其他平台: 在 /usr/lib/jvm、/usr/java、/opt/java、/opt/jdk 和 PATH 环境变量中查找 java
  ///
  /// 返回找到的第一个 Java 可执行文件的完整路径，如果未找到则返回 null
  static Future<String?> findJavaExecutable() async {
    if (Platform.isWindows) {
      // Windows 平台：遍历常见安装路径
      for (final basePath in _commonPaths) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        try {
          // 遍历目录下的子目录（每个子目录通常是一个 JDK 版本）
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              // 检查 bin/java.exe 是否存在
              final javaExe = p.join(entity.path, 'bin', 'java.exe');
              if (await File(javaExe).exists()) {
                return javaExe;
              }
            }
          }
        } catch (_) {
          // 忽略权限错误等异常，继续检查下一个路径
        }
      }

      // 在 PATH 环境变量中查找
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
      // 非 Windows 平台（Linux、macOS 等）
      // 定义常见的 Java 安装路径
      for (final basePath in ['/usr/lib/jvm', '/usr/java', '/opt/java', '/opt/jdk']) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        try {
          // 遍历目录下的子目录
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              // 检查 bin/java 是否存在
              final javaExe = p.join(entity.path, 'bin', 'java');
              if (await File(javaExe).exists()) {
                return javaExe;
              }
            }
          }
        } catch (_) {
          // 忽略权限错误等异常，继续检查下一个路径
        }
      }

      // 在 PATH 环境变量中查找（使用 : 作为分隔符）
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

  /// 获取指定 Java 可执行文件的版本信息
  ///
  /// 执行 `java -version` 命令并解析输出，获取版本号和架构信息
  ///
  /// [javaPath] Java 可执行文件的完整路径
  ///
  /// 返回 [JavaCheckResult] 对象，如果执行失败则返回 null
  static Future<JavaCheckResult?> _getJavaInfo(String javaPath) async {
    try {
      // 执行 java -version 命令
      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      // java -version 的版本信息输出在 stderr 中
      final output = (result.stderr as String?) ?? '';

      // 检查命令是否成功执行
      if (result.exitCode != 0) return null;

      // 解析版本号
      final version = parseJavaVersion(output);
      if (version == null) return null;

      // 提取主版本号
      final majorVersion = _parseMajorVersion(version);
      // 检测是否为 64 位 JVM
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
      // 捕获所有异常，返回 null 表示获取信息失败
      return null;
    }
  }

  /// 从 java -version 命令的输出中解析 Java 版本字符串
  ///
  /// 使用正则表达式匹配双引号包围的版本号
  /// 例如：从 'java version "1.8.0_301"' 中提取 "1.8.0_301"
  ///       从 'openjdk version "17.0.1"' 中提取 "17.0.1"
  ///
  /// [versionOutput] java -version 命令的输出字符串
  ///
  /// 返回解析出的版本字符串，如果未找到则返回 null
  static String? parseJavaVersion(String versionOutput) {
    // 匹配双引号中的版本号，支持以下格式：
    // - 1.8.0_301（Java 8 及更早版本）
    // - 17.0.1（Java 9 及更高版本）
    // - 11.0.12+7（包含构建号的版本）
    final match = RegExp(r'"(\d+(?:\.\d+)*(?:[_.][^"]*)?)"').firstMatch(versionOutput);
    return match?.group(1);
  }

  /// 从版本字符串中解析主版本号
  ///
  /// 提取版本字符串的第一个数字部分作为主版本号
  /// 例如：
  /// - "1.8.0_301" -> 1（注意：Java 8 的实际主版本号需要特殊处理）
  /// - "17.0.1" -> 17
  /// - "11.0.12" -> 11
  ///
  /// [version] 版本字符串
  ///
  /// 返回主版本号，如果解析失败则返回 null
  static int? _parseMajorVersion(String? version) {
    if (version == null) return null;
    // 取版本字符串的第一个部分（以 . 分隔）
    final firstPart = version.split('.').first;
    return int.tryParse(firstPart);
  }
}