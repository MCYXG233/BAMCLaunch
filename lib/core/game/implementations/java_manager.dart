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
      final result = await _checkJavaVersion(path);
      if (result.found) {
        results.add(result);
      }
    }

    return results;
  }

  Future<JavaDetectionResult> _checkJavaVersion(String javaPath) async {
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
    final result = await _checkJavaVersion(javaPath);
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
