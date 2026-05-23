import '../models/game_launch_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import 'dart:io';

class JavaManager {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;

  JavaManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
  })  : _platformAdapter = platformAdapter,
        _logger = logger;

  Future<List<JavaDetectionResult>> detectAllJavaVersions() async {
    final results = <JavaDetectionResult>[];
    final javaPaths = _platformAdapter.javaPaths;

    for (final path in javaPaths) {
      final result = await checkJavaVersion(path);
      if (result.found) {
        results.add(result);
      }
    }

    return results;
  }

  Future<JavaDetectionResult> checkJavaVersion(String javaPath) async {
    try {
      final result = await Process.run(javaPath, ['-version']);
      if (result.exitCode == 0) {
        final errorOutput = result.stderr.toString();
        final version = _parseJavaVersion(errorOutput);
        return JavaDetectionResult(
          found: true,
          javaPath: javaPath,
          version: version,
        );
      }
    } catch (e) {
      _logger.debug('Failed to check Java at $javaPath: $e');
    }
    return JavaDetectionResult(
      found: false,
      javaPath: javaPath,
      error: 'Java execution failed',
    );
  }

  Future<JavaDetectionResult> detectJava() async {
    try {
      _logger.info('开始检测Java环境');

      String? javaPath = await _platformAdapter.findJava();
      if (javaPath != null) {
        final result = await Process.run(javaPath, ['-version']);
        if (result.exitCode == 0) {
          final errorOutput = result.stderr.toString();
          final version = _parseJavaVersion(errorOutput);
          _logger.info('检测到Java: $version, 路径: $javaPath');
          return JavaDetectionResult(
            found: true,
            javaPath: javaPath,
            version: version,
          );
        }
      }

      String? envJavaPath = Platform.environment['JAVA_HOME'];
      if (envJavaPath != null) {
        String javaExecPath = Platform.isWindows
            ? '$envJavaPath\\bin\\java.exe'
            : '$envJavaPath/bin/java';
        if (await File(javaExecPath).exists()) {
          final result = await Process.run(javaExecPath, ['-version']);
          if (result.exitCode == 0) {
            final errorOutput = result.stderr.toString();
            final version = _parseJavaVersion(errorOutput);
            _logger.info('通过JAVA_HOME检测到Java: $version, 路径: $javaExecPath');
            return JavaDetectionResult(
              found: true,
              javaPath: javaExecPath,
              version: version,
            );
          }
        }
      }

      List<String> commonJavaPaths = Platform.isWindows
          ? [
              'C:\\Program Files\\Java\\jdk-17\\bin\\java.exe',
              'C:\\Program Files\\Java\\jdk-16\\bin\\java.exe',
              'C:\\Program Files\\Java\\jdk-15\\bin\\java.exe',
              'C:\\Program Files (x86)\\Java\\jdk-17\\bin\\java.exe',
              'C:\\Program Files (x86)\\Java\\jdk-16\\bin\\java.exe',
            ]
          : Platform.isMacOS
              ? [
                  '/usr/bin/java',
                  '/usr/local/bin/java',
                  '/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java',
                ]
              : [
                  '/usr/bin/java',
                  '/usr/local/bin/java',
                  '/opt/java/bin/java',
                ];

      for (String path in commonJavaPaths) {
        if (await File(path).exists()) {
          try {
            final result = await Process.run(path, ['-version']);
            if (result.exitCode == 0) {
              final errorOutput = result.stderr.toString();
              final version = _parseJavaVersion(errorOutput);
              _logger.info('通过常见路径检测到Java: $version, 路径: $path');
              return JavaDetectionResult(
                found: true,
                javaPath: path,
                version: version,
              );
            }
          } catch (e) {
            _logger.warn('尝试路径 $path 失败: $e');
          }
        }
      }

      return JavaDetectionResult(
        found: false,
        error: '未找到Java环境，请手动安装Java 17或更高版本',
      );
    } catch (e) {
      _logger.error('Java检测异常: $e');
      return JavaDetectionResult(
        found: false,
        error: '检测异常: $e',
      );
    }
  }

  String _parseJavaVersion(String output) {
    final versionRegex = RegExp(r'version "(\d+(?:\.\d+)*)"');
    final match = versionRegex.firstMatch(output);
    return match?.group(1) ?? 'Unknown';
  }

  String? getRecommendedJavaVersion(String gameVersion) {
    final versionParts = gameVersion.split('.');
    if (versionParts.length >= 2) {
      final major = int.tryParse(versionParts[0]);
      final minor = int.tryParse(versionParts[1]);
      
      if (major != null && minor != null) {
        if (major >= 1 && minor >= 17) {
          return '17';
        } else if (major >= 1 && minor >= 16) {
          return '16';
        } else {
          return '8';
        }
      }
    }
    return '8';
  }

  Future<JavaDetectionResult?> findRecommendedJava(String gameVersion) async {
    final recommendedVersion = getRecommendedJavaVersion(gameVersion);
    final javaVersions = await detectAllJavaVersions();
    
    for (final java in javaVersions) {
      if (java.version != null && java.version!.startsWith(recommendedVersion!)) {
        return java;
      }
    }

    for (final java in javaVersions) {
      if (java.version != null) {
        final javaMajor = int.tryParse(java.version!.split('.').first);
        final recommendedMajor = int.tryParse(recommendedVersion!);
        
        if (javaMajor != null && recommendedMajor != null) {
          if (javaMajor >= recommendedMajor) {
            _logger.warn(
              'Using Java ${java.version} instead of recommended Java $recommendedVersion',
            );
            return java;
          }
        }
      }
    }

    return null;
  }

  Future<bool> validateJavaVersion(String javaPath, String gameVersion) async {
    final result = await checkJavaVersion(javaPath);
    if (!result.found) {
      return false;
    }

    final recommendedVersion = getRecommendedJavaVersion(gameVersion);
    if (result.version != null) {
      final javaMajor = int.tryParse(result.version!.split('.').first);
      final recommendedMajor = int.tryParse(recommendedVersion!);
      
      if (javaMajor != null && recommendedMajor != null) {
        return javaMajor >= recommendedMajor;
      }
    }

    return false;
  }
}
