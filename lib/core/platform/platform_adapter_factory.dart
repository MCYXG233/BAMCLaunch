import 'dart:io';
import 'i_platform_adapter.dart';
import 'windows_platform_adapter.dart';
import 'macos_platform_adapter.dart';
import 'linux_platform_adapter.dart';

class PlatformAdapterFactory {
  static IPlatformAdapter? _instance;

  static IPlatformAdapter getInstance() {
    _instance ??= _createAdapter();
    return _instance!;
  }

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
