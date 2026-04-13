import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'i_platform_adapter.dart';

class LinuxPlatformAdapter implements IPlatformAdapter {
  SystemTray? _systemTray;
  @override
  String get appDataDirectory {
    final home = Platform.environment['HOME'];
    return '${home!}/.config/bamclauncher';
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

    // 检查系统级Java目录
    final jvmDir = Directory('/usr/lib/jvm');
    if (jvmDir.existsSync()) {
      final subDirs = jvmDir.listSync();
      for (final subDir in subDirs) {
        if (subDir is Directory) {
          final javaExe = '${subDir.path}/bin/java';
          if (File(javaExe).existsSync()) {
            paths.add(javaExe);
          }
        }
      }
    }

    // 检查用户级Java目录
    final home = Platform.environment['HOME'];
    if (home != null) {
      final userJdkDir = Directory('$home/.jdks');
      if (userJdkDir.existsSync()) {
        final subDirs = userJdkDir.listSync();
        for (final subDir in subDirs) {
          if (subDir is Directory) {
            final javaExe = '${subDir.path}/bin/java';
            if (File(javaExe).existsSync()) {
              paths.add(javaExe);
            }
          }
        }
      }
    }

    // 检查环境变量中的JAVA_HOME
    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome != null) {
      final javaExe = '$javaHome/bin/java';
      if (File(javaExe).existsSync()) {
        paths.add(javaExe);
      }
    }

    // 检查常见的Java执行路径
    final commonPaths = [
      '/usr/bin/java',
      '/usr/local/bin/java',
      '/opt/java/bin/java',
    ];
    for (final path in commonPaths) {
      if (File(path).existsSync()) {
        paths.add(path);
      }
    }

    // 添加通用的java命令
    paths.add('java');

    // 去重并返回
    return paths.toSet().toList();
  }

  @override
  Future<String?> findJava() async {
    for (final path in javaPaths) {
      if (await File(path).exists()) {
        try {
          // 使用超时处理，避免命令执行时间过长
          final result = await Process.run(
            path, 
            ['-version'],
            timeout: const Duration(seconds: 5),
          );
          if (result.exitCode == 0) {
            // 验证输出是否包含Java版本信息
            final errorOutput = result.stderr.toString();
            if (errorOutput.contains('java version') || errorOutput.contains('openjdk version')) {
              return path;
            }
          }
        } catch (e) {
          // 忽略错误，继续尝试下一个路径
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
    return 'Linux';
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

      final desktopFile = '$home/.config/autostart/bamclauncher.desktop';
      final executablePath = Platform.resolvedExecutable;
      const appName = 'BAMCLauncher';

      if (enabled) {
        final desktopContent = '''[Desktop Entry]
Type=Application
Name=$appName
Comment=Minecraft Launcher
Exec=$executablePath
Icon=bamclauncher
Terminal=false
Categories=Game;
X-GNOME-Autostart-enabled=true''';

        await File(desktopFile).writeAsString(desktopContent);
      } else {
        final file = File(desktopFile);
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

      final desktopFile = '$home/.config/autostart/bamclauncher.desktop';
      return File(desktopFile).existsSync();
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
    await Process.run('export', ['$name=$value']);
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
    try {
      _systemTray = SystemTray();
      
      // 初始化系统托盘
      await _systemTray!.initSystemTray(
        title: tooltip,
        iconPath: iconPath,
      );
      
      // 监听托盘点击事件
      _systemTray!.registerSystemTrayEventHandler((eventName) async {
        if (eventName == kSystemTrayEventClick) {
          // 点击托盘图标显示/隐藏窗口
          if (await windowManager.isVisible()) {
            await windowManager.hide();
          } else {
            await windowManager.show();
            await windowManager.focus();
          }
        }
      });
    } catch (e) {
      print('初始化托盘失败: $e');
    }
  }

  @override
  Future<void> showTray() async {
    try {
      if (_systemTray != null) {
        // 系统托盘在初始化时就会显示
      }
    } catch (e) {
      print('显示托盘失败: $e');
    }
  }

  @override
  Future<void> hideTray() async {
    try {
      if (_systemTray != null) {
        await _systemTray!.closeSystemTray();
      }
    } catch (e) {
      print('隐藏托盘失败: $e');
    }
  }

  @override
  Future<void> setTrayTooltip(String tooltip) async {
    try {
      if (_systemTray != null) {
        await _systemTray!.setSystemTrayInfo(
          title: tooltip,
        );
      }
    } catch (e) {
      print('设置托盘提示失败: $e');
    }
  }

  @override
  Future<void> setTrayMenu(List<Map<String, dynamic>> menuItems) async {
    try {
      if (_systemTray != null) {
        final menu = Menu();
        
        for (final item in menuItems) {
          final label = item['label'] as String;
          final action = item['action'] as Function?;
          
          if (action != null) {
            await menu.addMenuItem(
              MenuItem(label: label, onClicked: () => action()),
            );
          } else {
            // 分隔线
            await menu.addSeparator();
          }
        }
        
        await _systemTray!.setContextMenu(menu);
      }
    } catch (e) {
      print('设置托盘菜单失败: $e');
    }
  }

  @override
  Future<void> disposeTray() async {
    try {
      if (_systemTray != null) {
        await _systemTray!.closeSystemTray();
        _systemTray = null;
      }
    } catch (e) {
      print('释放托盘资源失败: $e');
    }
  }
}
