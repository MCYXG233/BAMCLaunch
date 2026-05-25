import 'dart:io';
import 'platform_adapter.dart';
import 'windows_adapter.dart';
import 'macos_adapter.dart';
import 'linux_adapter.dart';

/// 平台适配器工厂类
/// 根据当前运行平台返回对应的适配器实现
class PlatformAdapterFactory {
  /// 单例实例
  static IPlatformAdapter? _instance;

  /// 获取平台适配器实例
  static IPlatformAdapter get instance {
    _instance ??= _createAdapter();
    return _instance!;
  }

  /// 创建对应平台的适配器
  static IPlatformAdapter create() {
    return _createAdapter();
  }

  /// 创建对应平台的适配器
  static IPlatformAdapter _createAdapter() {
    if (Platform.isWindows) {
      return WindowsAdapter();
    } else if (Platform.isMacOS) {
      return MacOSAdapter();
    } else if (Platform.isLinux) {
      return LinuxAdapter();
    } else {
      throw UnsupportedError('不支持的平台: ${Platform.operatingSystem}');
    }
  }

  /// 重置实例（主要用于测试）
  static void reset() {
    _instance = null;
  }
}
