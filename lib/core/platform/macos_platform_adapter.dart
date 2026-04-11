import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'i_platform_adapter.dart';

class MacOSPlatformAdapter implements IPlatformAdapter {
  @override
  String get appDataDirectory {
    final home = Platform.environment['HOME'];
    return '${home!}/Library/Application Support/BAMCLauncher';
  }

  @override
  String get cacheDirectory {
    return '$appDataDirectory/cache';
  }

  @override
  String get configDirectory {
    return '$appDataDirectory/config';
  }

  @override
  String get logsDirectory {
    return '$appDataDirectory/logs';
  }

  @override
  String get gameDirectory {
    return '$appDataDirectory/games';
  }

  @override
  List<String> get javaPaths {
    final paths = <String>[];

    paths.add(
        '/Library/Java/JavaVirtualMachines/jdk1.8.0_301.jdk/Contents/Home/bin/java');
    paths.add(
        '/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java');

    final home = Platform.environment['HOME'];
    if (home != null) {
      paths.add(
          '$home/Library/Java/JavaVirtualMachines/jdk1.8.0_301.jdk/Contents/Home/bin/java');
      paths.add(
          '$home/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java');
    }

    paths.add('/usr/local/bin/java');
    paths.add('/usr/bin/java');
    paths.add('/opt/homebrew/bin/java');
    paths.add('java');

    return paths.where((path) => File(path).existsSync()).toList();
  }

  @override
  Future<String?> findJava() async {
    for (final path in javaPaths) {
      if (await File(path).exists()) {
        try {
          final result = await Process.run(path, ['-version']);
          if (result.exitCode == 0) {
            return path;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  @override
  Future<bool> isDirectory(String path) async {
    return Directory(path).exists();
  }

  @override
  Future<bool> isFile(String path) async {
    return File(path).exists();
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: recursive);
    } else if (entity == FileSystemEntityType.file) {
      await File(path).delete();
    }
  }

  @override
  Future<String> readFile(String path) async {
    return File(path).readAsString();
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await File(path).writeAsString(content);
  }

  @override
  Future<List<String>> listFiles(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity.path);
      }
    }
    return files;
  }

  @override
  Future<List<String>> listDirectories(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    final dirs = <String>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        dirs.add(entity.path);
      }
    }
    return dirs;
  }

  @override
  Future<Process> startProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) async {
    return Process.start(executable, arguments,
        workingDirectory: workingDirectory, environment: environment);
  }

  @override
  Future<int> runProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) async {
    final result = await Process.run(executable, arguments,
        workingDirectory: workingDirectory, environment: environment);
    return result.exitCode;
  }

  @override
  Future<bool> killProcess(int pid) async {
    try {
      Process.killPid(pid);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isProcessRunning(int pid) async {
    try {
      final result = await Process.run('ps', ['-p', '$pid']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
  
  @override
  Future<void> killProcesses(String processName) async {
    try {
      await Process.run('pkill', ['-f', processName]);
    } catch (_) {
      // 忽略错误，继续执行
    }
  }

  @override
  String getPlatformName() {
    return 'MacOS';
  }

  @override
  String getPlatformVersion() {
    return Platform.version;
  }

  @override
  Future<bool> setAutoStartup(bool enabled) async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return false;

      final plistPath = '$home/Library/LaunchAgents/com.bamclauncher.plist';
      final executablePath = Platform.resolvedExecutable;

      if (enabled) {
        final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bamclauncher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$executablePath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>''';

        await File(plistPath).writeAsString(plistContent);
      } else {
        final file = File(plistPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAutoStartupEnabled() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return false;

      final plistPath = '$home/Library/LaunchAgents/com.bamclauncher.plist';
      return File(plistPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> getUsername() async {
    return Platform.environment['USER'] ?? '';
  }

  @override
  Future<String> getHostname() async {
    return Platform.localHostname;
  }

  @override
  Future<String?> getEnvironmentVariable(String name) async {
    return Platform.environment[name];
  }

  @override
  Future<void> setEnvironmentVariable(String name, String value) async {
    await Process.run('launchctl', ['setenv', name, value]);
  }

  @override
  Future<String> getExecutablePath() async {
    return Platform.resolvedExecutable;
  }

  @override
  Future<bool> isElevated() async {
    try {
      final result = await Process.run('id', ['-u']);
      return result.stdout.toString().trim() == '0';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> minimizeWindow() async {
    await windowManager.minimize();
  }

  @override
  Future<void> maximizeWindow() async {
    await windowManager.maximize();
  }

  @override
  Future<void> unmaximizeWindow() async {
    await windowManager.unmaximize();
  }

  @override
  Future<void> restoreWindow() async {
    await windowManager.restore();
  }

  @override
  Future<void> closeWindow() async {
    await windowManager.close();
  }

  @override
  Future<bool> isWindowMaximized() async {
    return await windowManager.isMaximized();
  }

  @override
  Future<bool> isWindowMinimized() async {
    return await windowManager.isMinimized();
  }

  @override
  Future<void> setWindowTitle(String title) async {
    await windowManager.setTitle(title);
  }

  @override
  Future<void> setWindowSize(int width, int height) async {
    await windowManager.setSize(Size(width.toDouble(), height.toDouble()));
  }

  @override
  Future<void> setWindowPosition(int x, int y) async {
    await windowManager.setPosition(Offset(x.toDouble(), y.toDouble()));
  }

  @override
  Future<void> setWindowAlwaysOnTop(bool alwaysOnTop) async {
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  @override
  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  @override
  Future<void> showWindow() async {
    await windowManager.show();
  }

  @override
  Future<void> initializeTray(String iconPath, String tooltip) async {
    
  }

  @override
  Future<void> showTray() async {
    
  }

  @override
  Future<void> hideTray() async {
    
  }

  @override
  Future<void> setTrayTooltip(String tooltip) async {
    
  }

  @override
  Future<void> setTrayMenu(List<Map<String, dynamic>> menuItems) async {
    
  }

  @override
  Future<void> disposeTray() async {
    
  }
}
