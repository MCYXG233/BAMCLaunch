import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/config/models/global_config.dart';
import 'package:bamclauncher/core/auth/models/account.dart';
import 'package:bamclauncher/core/version/version.dart';

void main() {
  group('Enhanced Cross-Platform Tests', () {
    group('Path Handling', () {
      test('config handles platform-specific paths', () {
        // Test Windows-style paths
        final windowsConfig = GameConfig(
          javaPath: r'C:\Program Files\Java\jdk-17\bin\java.exe',
          maxMemory: 2048,
          minMemory: 512,
          jvmArguments: [],
          gameArguments: [],
          enableFullscreen: false,
          windowWidth: 854,
          windowHeight: 480,
          enableVsync: true,
          enableMipmap: true,
          gameDirectory: r'C:\Users\User\AppData\Roaming\.minecraft',
        );
        
        final windowsJson = windowsConfig.toJson();
        final restoredWindows = GameConfig.fromJson(windowsJson);
        
        expect(restoredWindows.javaPath, r'C:\Program Files\Java\jdk-17\bin\java.exe');
        expect(restoredWindows.gameDirectory, r'C:\Users\User\AppData\Roaming\.minecraft');
        
        // Test Unix-style paths
        final unixConfig = GameConfig(
          javaPath: '/usr/lib/jvm/java-17/bin/java',
          maxMemory: 2048,
          minMemory: 512,
          jvmArguments: [],
          gameArguments: [],
          enableFullscreen: false,
          windowWidth: 854,
          windowHeight: 480,
          enableVsync: true,
          enableMipmap: true,
          gameDirectory: '/home/user/.minecraft',
        );
        
        final unixJson = unixConfig.toJson();
        final restoredUnix = GameConfig.fromJson(unixJson);
        
        expect(restoredUnix.javaPath, '/usr/lib/jvm/java-17/bin/java');
        expect(restoredUnix.gameDirectory, '/home/user/.minecraft');
      });

      test('config handles macOS-specific paths', () {
        final macConfig = GameConfig(
          javaPath: '/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin/java',
          maxMemory: 4096,
          minMemory: 1024,
          jvmArguments: ['-XstartOnFirstThread'],
          gameArguments: [],
          enableFullscreen: false,
          windowWidth: 854,
          windowHeight: 480,
          enableVsync: true,
          enableMipmap: true,
          gameDirectory: '/Users/user/Library/Application Support/minecraft',
        );
        
        final json = macConfig.toJson();
        final restored = GameConfig.fromJson(json);
        
        expect(restored.javaPath, contains('/Library/Java/JavaVirtualMachines'));
        expect(restored.jvmArguments, contains('-XstartOnFirstThread'));
        expect(restored.gameDirectory, contains('/Library/Application Support'));
      });
    });

    group('Locale Handling', () {
      test('config supports multiple languages', () {
        final languages = ['zh_CN', 'en_US', 'ja_JP', 'ko_KR', 'de_DE', 'fr_FR'];
        
        for (final lang in languages) {
          final config = BasicConfig(
            launcherVersion: '1.0.0',
            language: lang,
            autoUpdate: true,
            checkUpdateOnStartup: true,
            theme: 'default',
            enableLogging: true,
            logLevel: 'info',
          );
          
          final json = config.toJson();
          final restored = BasicConfig.fromJson(json);
          
          expect(restored.language, lang, reason: 'Failed for language: $lang');
        }
      });
    });

    group('Memory Configuration', () {
      test('config handles various memory sizes', () {
        final memorySizes = [256, 512, 1024, 2048, 4096, 8192, 16384];
        
        for (final size in memorySizes) {
          final config = GameConfig(
            javaPath: '',
            maxMemory: size,
            minMemory: size ~/ 2,
            jvmArguments: [],
            gameArguments: [],
            enableFullscreen: false,
            windowWidth: 854,
            windowHeight: 480,
            enableVsync: true,
            enableMipmap: true,
            gameDirectory: '',
          );
          
          final json = config.toJson();
          final restored = GameConfig.fromJson(json);
          
          expect(restored.maxMemory, size, reason: 'Failed for maxMemory: $size');
          expect(restored.minMemory, size ~/ 2, reason: 'Failed for minMemory: ${size ~/ 2}');
        }
      });
    });

    group('Resolution Handling', () {
      test('config handles various screen resolutions', () {
        final resolutions = [
          {'width': 854, 'height': 480},    // 480p
          {'width': 1280, 'height': 720},   // 720p
          {'width': 1920, 'height': 1080},  // 1080p
          {'width': 2560, 'height': 1440},  // 1440p
          {'width': 3840, 'height': 2160},  // 4K
          {'width': 2560, 'height': 1080},  // Ultrawide
          {'width': 3440, 'height': 1440},  // Ultrawide QHD
        ];
        
        for (final res in resolutions) {
          final config = GameConfig(
            javaPath: '',
            maxMemory: 2048,
            minMemory: 512,
            jvmArguments: [],
            gameArguments: [],
            enableFullscreen: false,
            windowWidth: res['width']!,
            windowHeight: res['height']!,
            enableVsync: true,
            enableMipmap: true,
            gameDirectory: '',
          );
          
          final json = config.toJson();
          final restored = GameConfig.fromJson(json);
          
          expect(restored.windowWidth, res['width']);
          expect(restored.windowHeight, res['height']);
        }
      });
    });

    group('Proxy Configuration', () {
      test('config handles various proxy types', () {
        final proxyTypes = ['http', 'https', 'socks4', 'socks5'];
        
        for (final type in proxyTypes) {
          final config = DownloadConfig(
            downloadSource: 'bmclapi',
            downloadThreads: 8,
            downloadSpeedLimit: 0,
            enableProxy: true,
            proxyHost: '127.0.0.1',
            proxyPort: 1080,
            proxyType: type,
            enableBreakpointResume: true,
            retryCount: 3,
            retryDelay: 1000,
          );
          
          final json = config.toJson();
          final restored = DownloadConfig.fromJson(json);
          
          expect(restored.proxyType, type, reason: 'Failed for proxy type: $type');
          expect(restored.enableProxy, true);
        }
      });
    });

    group('Content Source Handling', () {
      test('config handles various content sources', () {
        final sources = ['modrinth', 'curseforge', 'custom'];
        
        for (final source in sources) {
          final config = ContentConfig(
            defaultModSource: source,
            defaultResourcePackSource: source,
            defaultShaderPackSource: source,
            enableAutoUpdateContent: false,
            enableConflictDetection: true,
            enableDependencyCheck: true,
            modInstallDirectory: '',
            resourcePackDirectory: '',
            shaderPackDirectory: '',
          );
          
          final json = config.toJson();
          final restored = ContentConfig.fromJson(json);
          
          expect(restored.defaultModSource, source, reason: 'Failed for source: $source');
          expect(restored.defaultResourcePackSource, source);
          expect(restored.defaultShaderPackSource, source);
        }
      });
    });

    group('Account Type Handling', () {
      test('all account types serialize correctly', () {
        for (final type in AccountType.values) {
          final account = Account(
            id: 'test-${type.name}',
            username: 'User${type.name}',
            type: type,
            serverUrl: type == AccountType.authlibInjector ? 'https://auth.example.com' : null,
          );
          
          final json = account.toJson();
          final restored = Account.fromJson(json);
          
          expect(restored.type, type, reason: 'Failed for type: $type');
          expect(restored.id, 'test-${type.name}');
          
          if (type == AccountType.authlibInjector) {
            expect(restored.serverUrl, 'https://auth.example.com');
          }
        }
      });
    });

    group('Version Type Handling', () {
      test('all version types serialize correctly', () {
        for (final type in VersionType.values) {
          final entry = VersionEntry(
            id: 'test-${type.name}',
            type: type,
            releaseTime: DateTime(2024, 1, 1),
            time: DateTime(2024, 1, 1),
            url: 'https://example.com/${type.name}.json',
          );
          
          final json = entry.toJson();
          final restored = VersionEntry.fromJson(json);
          
          expect(restored.type, type, reason: 'Failed for type: $type');
          expect(restored.id, 'test-${type.name}');
        }
      });
    });
  });
}
