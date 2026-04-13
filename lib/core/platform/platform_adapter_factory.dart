import 'dart:io';
import 'i_platform_adapter.dart';
import 'windows_platform_adapter.dart';
import 'macos_platform_adapter.dart';
import 'linux_platform_adapter.dart';

/// 平台适配器工厂类
/// 用于根据当前操作系统创建对应的平台适配器实例
class PlatformAdapterFactory {
  /// 单例实例
  static IPlatformAdapter? _instance;

  /// 获取平台适配器实例
  /// 使用单例模式，确保全局只有一个平台适配器实例
  static IPlatformAdapter getInstance() {
    _instance ??= _createAdapter();
    return _instance!;
  }

  /// 根据当前操作系统创建对应的平台适配器
  /// - Windows: 返回 WindowsPlatformAdapter 实例
  /// - macOS: 返回 MacOSPlatformAdapter 实例
  /// - Linux: 返回 LinuxPlatformAdapter 实例
  /// - 其他: 抛出不支持的平台错误
  static IPlatformAdapter _createAdapter() {
    switch (Platform.operatingSystem) {
      case 'windows':
        return WindowsPlatformAdapter();
      case 'macos':
        return MacOSPlatformAdapter();
      case 'linux':
        return LinuxPlatformAdapter();
      default:
        throw UnsupportedError(
            'Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}
