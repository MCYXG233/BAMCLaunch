import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pp;
import 'platform_adapter.dart';

/// MacOS平台适配器实现
class MacOSAdapter implements IPlatformAdapter {
  @override
  bool get isWindows => false;

  @override
  bool get isMacOS => true;

  @override
  bool get isLinux => false;

  @override
  Future<String> getApplicationSupportDirectory() async {
    final appSupportDir = await pp.getApplicationSupportDirectory();
    return path.join(appSupportDir.path, 'BAMCLauncher');
  }

  @override
  Future<String> getDefaultGameDirectory() async {
    final appSupportDir = await pp.getApplicationSupportDirectory();
    return path.join(appSupportDir.path, 'BAMCLauncher');
  }

  @override
  Future<String> getDefaultJavaPath() async {
    final javaPaths = await findJavaInstallations();
    if (javaPaths.isNotEmpty) {
      return javaPaths.first;
    }
    return 'java';
  }

  @override
  Future<String> getTempDirectory() async {
    final tempDir = await pp.getTemporaryDirectory();
    return tempDir.path;
  }

  @override
  Future<void> ensureDirectoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<bool> hasWritePermission(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testFile = File(path.join(dirPath, '.write_test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> findJavaInstallations() async {
    final List<String> javaPaths = [];

    final commonPaths = ['/Library/Java/JavaVirtualMachines', '/usr/lib/jvm'];

    for (final basePath in commonPaths) {
      final dir = Directory(basePath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            final javaExe = path.join(
              entity.path,
              'Contents',
              'Home',
              'bin',
              'java',
            );
            if (await File(javaExe).exists()) {
              javaPaths.add(javaExe);
            }
          }
        }
      }
    }

    final pathEnv = Platform.environment['PATH'];
    if (pathEnv != null) {
      for (final p in pathEnv.split(':')) {
        final javaExe = path.join(p, 'java');
        if (await File(javaExe).exists() && !javaPaths.contains(javaExe)) {
          javaPaths.add(javaExe);
        }
      }
    }

    return javaPaths;
  }
}
