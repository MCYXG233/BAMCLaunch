import 'dart:io';

abstract class IPlatformAdapter {
  String get appDataDirectory;

  String get cacheDirectory;

  String get configDirectory;

  String get logsDirectory;

  String get gameDirectory;

  List<String> get javaPaths;
  
  Future<String?> findJava();

  Future<bool> isDirectory(String path);

  Future<bool> isFile(String path);

  Future<void> createDirectory(String path);

  Future<void> delete(String path, {bool recursive = false});

  Future<String> readFile(String path);

  Future<void> writeFile(String path, String content);

  Future<List<String>> listFiles(String directory);

  Future<List<String>> listDirectories(String directory);

  Future<Process> startProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});

  Future<int> runProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});

  Future<bool> killProcess(int pid);

  Future<bool> isProcessRunning(int pid);
  
  Future<void> killProcesses(String processName);

  String getPlatformName();

  String getPlatformVersion();

  Future<bool> setAutoStartup(bool enabled);

  Future<bool> isAutoStartupEnabled();

  Future<String> getUsername();

  Future<String> getHostname();

  Future<String?> getEnvironmentVariable(String name);

  Future<void> setEnvironmentVariable(String name, String value);

  Future<String> getExecutablePath();

  Future<bool> isElevated();

  Future<void> minimizeWindow();

  Future<void> maximizeWindow();

  Future<void> unmaximizeWindow();

  Future<void> restoreWindow();

  Future<void> closeWindow();

  Future<bool> isWindowMaximized();

  Future<bool> isWindowMinimized();

  Future<void> setWindowTitle(String title);

  Future<void> setWindowSize(int width, int height);

  Future<void> setWindowPosition(int x, int y);

  Future<void> setWindowAlwaysOnTop(bool alwaysOnTop);

  Future<void> hideWindow();

  Future<void> showWindow();

  Future<void> initializeTray(String iconPath, String tooltip);

  Future<void> showTray();

  Future<void> hideTray();

  Future<void> setTrayTooltip(String tooltip);

  Future<void> setTrayMenu(List<Map<String, dynamic>> menuItems);

  Future<void> disposeTray();
}
