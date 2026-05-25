import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pp;
import 'platform_adapter.dart';

/// Windows平台适配器实现
class WindowsAdapter implements IPlatformAdapter {
  @override
  bool get isWindows => true;

  @override
  bool get isMacOS => false;

  @override
  bool get isLinux => false;

  @override
  Future<String> getApplicationSupportDirectory() async {
    final appDocDir = await pp.getApplicationSupportDirectory();
    return path.join(appDocDir.path, '.bamclauncher');
  }

  @override
  Future<String> getDefaultGameDirectory() async {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      return path.join(appData, '.bamclauncher');
    }
    return getApplicationSupportDirectory();
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

    final commonPaths = [
      r'C:\Program Files\Java',
      r'C:\Program Files (x86)\Java',
      r'C:\Program Files\Eclipse Adoptium',
      r'C:\Program Files\Microsoft\jdk',
    ];

    for (final basePath in commonPaths) {
      final dir = Directory(basePath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            final javaExe = path.join(entity.path, 'bin', 'java.exe');
            if (await File(javaExe).exists()) {
              javaPaths.add(javaExe);
            }
          }
        }
      }
    }

    final pathEnv = Platform.environment['PATH'];
    if (pathEnv != null) {
      for (final p in pathEnv.split(';')) {
        final javaExe = path.join(p, 'java.exe');
        if (await File(javaExe).exists() && !javaPaths.contains(javaExe)) {
          javaPaths.add(javaExe);
        }
      }
    }

    return javaPaths;
  }
}
