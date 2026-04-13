import 'dart:io';

/// 平台适配器接口
/// 定义了跨平台操作的统一接口，包括文件系统、进程管理、窗口管理等功能
abstract class IPlatformAdapter {
  /// 获取应用数据目录
  String get appDataDirectory;

  /// 获取缓存目录
  String get cacheDirectory;

  /// 获取配置目录
  String get configDirectory;

  /// 获取日志目录
  String get logsDirectory;

  /// 获取游戏目录
  String get gameDirectory;

  /// 获取Java路径列表
  List<String> get javaPaths;
  
  /// 查找Java可执行文件路径
  /// 返回找到的Java路径，未找到则返回null
  Future<String?> findJava();

  /// 检查路径是否为目录
  Future<bool> isDirectory(String path);

  /// 检查路径是否为文件
  Future<bool> isFile(String path);

  /// 创建目录
  Future<void> createDirectory(String path);

  /// 删除文件或目录
  /// [recursive]: 是否递归删除目录
  Future<void> delete(String path, {bool recursive = false});

  /// 读取文件内容
  Future<String> readFile(String path);

  /// 写入文件内容
  Future<void> writeFile(String path, String content);

  /// 列出目录中的文件
  Future<List<String>> listFiles(String directory);

  /// 列出目录中的子目录
  Future<List<String>> listDirectories(String directory);

  /// 启动进程
  /// [executable]: 可执行文件路径
  /// [arguments]: 命令行参数
  /// [workingDirectory]: 工作目录
  /// [environment]: 环境变量
  Future<Process> startProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});

  /// 运行进程并等待完成
  /// [executable]: 可执行文件路径
  /// [arguments]: 命令行参数
  /// [workingDirectory]: 工作目录
  /// [environment]: 环境变量
  /// 返回进程退出码
  Future<int> runProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});

  /// 终止进程
  /// [pid]: 进程ID
  /// 返回是否成功终止
  Future<bool> killProcess(int pid);

  /// 检查进程是否正在运行
  /// [pid]: 进程ID
  Future<bool> isProcessRunning(int pid);
  
  /// 终止指定名称的所有进程
  /// [processName]: 进程名称
  Future<void> killProcesses(String processName);

  /// 获取平台名称
  String getPlatformName();

  /// 获取平台版本
  String getPlatformVersion();

  /// 设置应用开机自启
  /// [enabled]: 是否启用自启
  /// 返回是否设置成功
  Future<bool> setAutoStartup(bool enabled);

  /// 检查应用是否设置了开机自启
  Future<bool> isAutoStartupEnabled();

  /// 获取当前用户名
  Future<String> getUsername();

  /// 获取主机名
  Future<String> getHostname();

  /// 获取环境变量
  /// [name]: 环境变量名称
  /// 返回环境变量值，不存在则返回null
  Future<String?> getEnvironmentVariable(String name);

  /// 设置环境变量
  /// [name]: 环境变量名称
  /// [value]: 环境变量值
  Future<void> setEnvironmentVariable(String name, String value);

  /// 获取可执行文件路径
  Future<String> getExecutablePath();

  /// 检查应用是否以管理员/root权限运行
  Future<bool> isElevated();

  /// 最小化窗口
  Future<void> minimizeWindow();

  /// 最大化窗口
  Future<void> maximizeWindow();

  /// 取消最大化窗口
  Future<void> unmaximizeWindow();

  /// 恢复窗口
  Future<void> restoreWindow();

  /// 关闭窗口
  Future<void> closeWindow();

  /// 检查窗口是否最大化
  Future<bool> isWindowMaximized();

  /// 检查窗口是否最小化
  Future<bool> isWindowMinimized();

  /// 设置窗口标题
  /// [title]: 窗口标题
  Future<void> setWindowTitle(String title);

  /// 设置窗口大小
  /// [width]: 窗口宽度
  /// [height]: 窗口高度
  Future<void> setWindowSize(int width, int height);

  /// 设置窗口位置
  /// [x]: 窗口X坐标
  /// [y]: 窗口Y坐标
  Future<void> setWindowPosition(int x, int y);

  /// 设置窗口是否总是在最前面
  /// [alwaysOnTop]: 是否总是在最前面
  Future<void> setWindowAlwaysOnTop(bool alwaysOnTop);

  /// 隐藏窗口
  Future<void> hideWindow();

  /// 显示窗口
  Future<void> showWindow();

  /// 初始化系统托盘
  /// [iconPath]: 托盘图标路径
  /// [tooltip]: 托盘提示文本
  Future<void> initializeTray(String iconPath, String tooltip);

  /// 显示系统托盘
  Future<void> showTray();

  /// 隐藏系统托盘
  Future<void> hideTray();

  /// 设置系统托盘提示文本
  /// [tooltip]: 提示文本
  Future<void> setTrayTooltip(String tooltip);

  /// 设置系统托盘菜单
  /// [menuItems]: 菜单项列表
  Future<void> setTrayMenu(List<Map<String, dynamic>> menuItems);

  /// 销毁系统托盘
  Future<void> disposeTray();
}
