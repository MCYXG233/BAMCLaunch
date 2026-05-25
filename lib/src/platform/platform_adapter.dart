import 'dart:io';

/// 平台适配器统一接口
/// 定义了跨平台文件系统操作和路径获取的抽象
abstract class IPlatformAdapter {
  /// 获取应用支持目录
  /// 返回应用专属的存储目录路径
  Future<String> getApplicationSupportDirectory();

  /// 获取默认游戏目录
  /// 返回游戏数据的默认存储路径
  Future<String> getDefaultGameDirectory();

  /// 获取默认Java路径
  /// 返回系统默认Java可执行文件路径
  Future<String> getDefaultJavaPath();

  /// 获取临时目录
  /// 返回系统临时文件目录路径
  Future<String> getTempDirectory();

  /// 确保目录存在
  /// 如果目录不存在则创建它
  /// [path] 要确保存在的目录路径
  Future<void> ensureDirectoryExists(String path);

  /// 检查写权限
  /// 返回指定路径是否有写权限
  /// [path] 要检查的路径
  Future<bool> hasWritePermission(String path);

  /// 查找系统中的Java安装
  /// 返回找到的Java可执行文件路径列表
  Future<List<String>> findJavaInstallations();

  /// 是否Windows平台
  bool get isWindows;

  /// 是否MacOS平台
  bool get isMacOS;

  /// 是否Linux平台
  bool get isLinux;
}
