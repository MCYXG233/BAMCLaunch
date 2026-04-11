import 'dart:io';
import 'i_platform_adapter.dart';
import 'platform_adapter_factory.dart';

class PlatformService {
  static PlatformService? _instance;
  final IPlatformAdapter _adapter;

  PlatformService._internal() : _adapter = PlatformAdapterFactory.getInstance();

  static PlatformService getInstance() {
    _instance ??= PlatformService._internal();
    return _instance!;
  }

  IPlatformAdapter get adapter => _adapter;

  String get appDataDirectory => _adapter.appDataDirectory;

  String get cacheDirectory => _adapter.cacheDirectory;

  String get configDirectory => _adapter.configDirectory;

  String get logsDirectory => _adapter.logsDirectory;

  String get gameDirectory => _adapter.gameDirectory;

  List<String> get javaPaths => _adapter.javaPaths;

  Future<String?> findJava() => _adapter.findJava();

  Future<bool> isDirectory(String path) => _adapter.isDirectory(path);

  Future<bool> isFile(String path) => _adapter.isFile(path);

  Future<void> createDirectory(String path) => _adapter.createDirectory(path);

  Future<void> delete(String path, {bool recursive = false}) =>
      _adapter.delete(path, recursive: recursive);

  Future<String> readFile(String path) => _adapter.readFile(path);

  Future<void> writeFile(String path, String content) =>
      _adapter.writeFile(path, content);

  Future<List<String>> listFiles(String directory) =>
      _adapter.listFiles(directory);

  Future<List<String>> listDirectories(String directory) =>
      _adapter.listDirectories(directory);

  Future<Process> startProcess(String executable, List<String> arguments,
          {String? workingDirectory, Map<String, String>? environment}) =>
      _adapter.startProcess(executable, arguments,
          workingDirectory: workingDirectory, environment: environment);

  Future<int> runProcess(String executable, List<String> arguments,
          {String? workingDirectory, Map<String, String>? environment}) =>
      _adapter.runProcess(executable, arguments,
          workingDirectory: workingDirectory, environment: environment);

  Future<bool> killProcess(int pid) => _adapter.killProcess(pid);

  Future<bool> isProcessRunning(int pid) => _adapter.isProcessRunning(pid);

  String getPlatformName() => _adapter.getPlatformName();

  String getPlatformVersion() => _adapter.getPlatformVersion();

  Future<bool> setAutoStartup(bool enabled) => _adapter.setAutoStartup(enabled);

  Future<bool> isAutoStartupEnabled() => _adapter.isAutoStartupEnabled();

  Future<String> getUsername() => _adapter.getUsername();

  Future<String> getHostname() => _adapter.getHostname();

  Future<String?> getEnvironmentVariable(String name) =>
      _adapter.getEnvironmentVariable(name);

  Future<void> setEnvironmentVariable(String name, String value) =>
      _adapter.setEnvironmentVariable(name, value);

  Future<String> getExecutablePath() => _adapter.getExecutablePath();

  Future<bool> isElevated() => _adapter.isElevated();

  Future<void> minimizeWindow() => _adapter.minimizeWindow();

  Future<void> maximizeWindow() => _adapter.maximizeWindow();

  Future<void> unmaximizeWindow() => _adapter.unmaximizeWindow();

  Future<void> restoreWindow() => _adapter.restoreWindow();

  Future<void> closeWindow() => _adapter.closeWindow();

  Future<bool> isWindowMaximized() => _adapter.isWindowMaximized();

  Future<bool> isWindowMinimized() => _adapter.isWindowMinimized();

  Future<void> setWindowTitle(String title) => _adapter.setWindowTitle(title);

  Future<void> setWindowSize(int width, int height) =>
      _adapter.setWindowSize(width, height);

  Future<void> setWindowPosition(int x, int y) =>
      _adapter.setWindowPosition(x, y);

  Future<void> setWindowAlwaysOnTop(bool alwaysOnTop) =>
      _adapter.setWindowAlwaysOnTop(alwaysOnTop);

  Future<void> hideWindow() => _adapter.hideWindow();

  Future<void> showWindow() => _adapter.showWindow();

  Future<void> initializeTray(String iconPath, String tooltip) =>
      _adapter.initializeTray(iconPath, tooltip);

  Future<void> showTray() => _adapter.showTray();

  Future<void> hideTray() => _adapter.hideTray();

  Future<void> setTrayTooltip(String tooltip) => _adapter.setTrayTooltip(tooltip);

  Future<void> setTrayMenu(List<Map<String, dynamic>> menuItems) =>
      _adapter.setTrayMenu(menuItems);

  Future<void> disposeTray() => _adapter.disposeTray();
}