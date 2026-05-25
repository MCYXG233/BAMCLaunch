import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/platform/platform_adapter.dart';
import 'package:bamclaunch/src/platform/windows_adapter.dart';
import 'package:bamclaunch/src/platform/macos_adapter.dart';
import 'package:bamclaunch/src/platform/linux_adapter.dart';
import 'package:bamclaunch/src/platform/platform_adapter_factory.dart';

void main() {
  group('Platform Adapter Tests', () {
    test('WindowsAdapter platform flags', () {
      final adapter = WindowsAdapter();
      expect(adapter.isWindows, isTrue);
      expect(adapter.isMacOS, isFalse);
      expect(adapter.isLinux, isFalse);
    });

    test('MacOSAdapter platform flags', () {
      final adapter = MacOSAdapter();
      expect(adapter.isWindows, isFalse);
      expect(adapter.isMacOS, isTrue);
      expect(adapter.isLinux, isFalse);
    });

    test('LinuxAdapter platform flags', () {
      final adapter = LinuxAdapter();
      expect(adapter.isWindows, isFalse);
      expect(adapter.isMacOS, isFalse);
      expect(adapter.isLinux, isTrue);
    });

    test('PlatformAdapterFactory returns correct instance', () {
      PlatformAdapterFactory.reset();
      final adapter = PlatformAdapterFactory.instance;

      expect(adapter, isNotNull);
      expect(adapter is IPlatformAdapter, isTrue);
    });

    test('PlatformAdapterFactory singleton works', () {
      PlatformAdapterFactory.reset();
      final instance1 = PlatformAdapterFactory.instance;
      final instance2 = PlatformAdapterFactory.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('All adapters implement IPlatformAdapter', () {
      final windowsAdapter = WindowsAdapter();
      final macosAdapter = MacOSAdapter();
      final linuxAdapter = LinuxAdapter();

      expect(windowsAdapter is IPlatformAdapter, isTrue);
      expect(macosAdapter is IPlatformAdapter, isTrue);
      expect(linuxAdapter is IPlatformAdapter, isTrue);
    });
  });
}
