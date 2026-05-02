import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/config/models/global_config.dart';

void main() {
  group('GlobalConfig', () {
    test('defaultConfig creates valid config', () {
      final config = GlobalConfig.defaultConfig();
      
      expect(config.version, '1.0.0');
      expect(config.basic, isNotNull);
      expect(config.game, isNotNull);
      expect(config.download, isNotNull);
      expect(config.account, isNotNull);
      expect(config.ui, isNotNull);
      expect(config.content, isNotNull);
    });

    test('toJson and fromJson roundtrip', () {
      final original = GlobalConfig.defaultConfig();
      final json = original.toJson();
      final restored = GlobalConfig.fromJson(json);
      
      expect(restored.version, original.version);
      expect(restored.basic.launcherVersion, original.basic.launcherVersion);
      expect(restored.basic.language, original.basic.language);
      expect(restored.game.maxMemory, original.game.maxMemory);
      expect(restored.download.downloadSource, original.download.downloadSource);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final config = GlobalConfig.fromJson(json);
      
      expect(config.version, '1.0.0');
      expect(config.basic.language, 'zh_CN');
      expect(config.game.maxMemory, 2048);
    });
  });

  group('BasicConfig', () {
    test('defaultConfig has expected values', () {
      final config = BasicConfig.defaultConfig();
      
      expect(config.launcherVersion, '1.0.0');
      expect(config.language, 'zh_CN');
      expect(config.autoUpdate, true);
      expect(config.checkUpdateOnStartup, true);
      expect(config.theme, 'default');
      expect(config.enableLogging, true);
      expect(config.logLevel, 'info');
    });

    test('toJson and fromJson roundtrip', () {
      final original = BasicConfig.defaultConfig();
      final json = original.toJson();
      final restored = BasicConfig.fromJson(json);
      
      expect(restored.launcherVersion, original.launcherVersion);
      expect(restored.language, original.language);
      expect(restored.autoUpdate, original.autoUpdate);
      expect(restored.checkUpdateOnStartup, original.checkUpdateOnStartup);
      expect(restored.theme, original.theme);
      expect(restored.enableLogging, original.enableLogging);
      expect(restored.logLevel, original.logLevel);
    });
  });

  group('GameConfig', () {
    test('defaultConfig has expected values', () {
      final config = GameConfig.defaultConfig();
      
      expect(config.javaPath, '');
      expect(config.maxMemory, 2048);
      expect(config.minMemory, 512);
      expect(config.jvmArguments.length, 5);
      expect(config.enableFullscreen, false);
      expect(config.windowWidth, 854);
      expect(config.windowHeight, 480);
    });

    test('toJson and fromJson roundtrip', () {
      final original = GameConfig.defaultConfig();
      final json = original.toJson();
      final restored = GameConfig.fromJson(json);
      
      expect(restored.javaPath, original.javaPath);
      expect(restored.maxMemory, original.maxMemory);
      expect(restored.minMemory, original.minMemory);
      expect(restored.jvmArguments, original.jvmArguments);
      expect(restored.gameArguments, original.gameArguments);
      expect(restored.enableFullscreen, original.enableFullscreen);
      expect(restored.windowWidth, original.windowWidth);
      expect(restored.windowHeight, original.windowHeight);
    });
  });

  group('DownloadConfig', () {
    test('defaultConfig has expected values', () {
      final config = DownloadConfig.defaultConfig();
      
      expect(config.downloadSource, 'bmclapi');
      expect(config.downloadThreads, 8);
      expect(config.downloadSpeedLimit, 0);
      expect(config.enableProxy, false);
      expect(config.enableBreakpointResume, true);
      expect(config.retryCount, 3);
    });

    test('toJson and fromJson roundtrip', () {
      final original = DownloadConfig.defaultConfig();
      final json = original.toJson();
      final restored = DownloadConfig.fromJson(json);
      
      expect(restored.downloadSource, original.downloadSource);
      expect(restored.downloadThreads, original.downloadThreads);
      expect(restored.downloadSpeedLimit, original.downloadSpeedLimit);
      expect(restored.enableProxy, original.enableProxy);
      expect(restored.proxyHost, original.proxyHost);
      expect(restored.proxyPort, original.proxyPort);
    });
  });

  group('AccountConfig', () {
    test('defaultConfig has expected values', () {
      final config = AccountConfig.defaultConfig();
      
      expect(config.defaultAccountId, '');
      expect(config.autoLogin, false);
      expect(config.rememberPassword, false);
      expect(config.enableAuthlibInjector, false);
      expect(config.enableSkinUpload, true);
    });

    test('toJson and fromJson roundtrip', () {
      final original = AccountConfig.defaultConfig();
      final json = original.toJson();
      final restored = AccountConfig.fromJson(json);
      
      expect(restored.defaultAccountId, original.defaultAccountId);
      expect(restored.autoLogin, original.autoLogin);
      expect(restored.rememberPassword, original.rememberPassword);
      expect(restored.enableAuthlibInjector, original.enableAuthlibInjector);
      expect(restored.authlibInjectorUrl, original.authlibInjectorUrl);
      expect(restored.enableSkinUpload, original.enableSkinUpload);
    });
  });

  group('UiConfig', () {
    test('defaultConfig has expected values', () {
      final config = UiConfig.defaultConfig();
      
      expect(config.enableCustomTitleBar, true);
      expect(config.enableTransparentWindow, false);
      expect(config.enableBlurEffect, true);
      expect(config.enableAnimation, true);
      expect(config.enableSound, true);
      expect(config.enableNotifications, true);
      expect(config.sidebarWidth, '200px');
      expect(config.autoHideSidebar, false);
      expect(config.enableDarkMode, false);
    });

    test('toJson and fromJson roundtrip', () {
      final original = UiConfig.defaultConfig();
      final json = original.toJson();
      final restored = UiConfig.fromJson(json);
      
      expect(restored.enableCustomTitleBar, original.enableCustomTitleBar);
      expect(restored.enableTransparentWindow, original.enableTransparentWindow);
      expect(restored.enableBlurEffect, original.enableBlurEffect);
      expect(restored.enableAnimation, original.enableAnimation);
      expect(restored.enableSound, original.enableSound);
      expect(restored.enableNotifications, original.enableNotifications);
      expect(restored.sidebarWidth, original.sidebarWidth);
      expect(restored.autoHideSidebar, original.autoHideSidebar);
      expect(restored.enableDarkMode, original.enableDarkMode);
    });
  });

  group('ContentConfig', () {
    test('defaultConfig has expected values', () {
      final config = ContentConfig.defaultConfig();
      
      expect(config.defaultModSource, 'modrinth');
      expect(config.defaultResourcePackSource, 'modrinth');
      expect(config.defaultShaderPackSource, 'modrinth');
      expect(config.enableAutoUpdateContent, false);
      expect(config.enableConflictDetection, true);
      expect(config.enableDependencyCheck, true);
    });

    test('toJson and fromJson roundtrip', () {
      final original = ContentConfig.defaultConfig();
      final json = original.toJson();
      final restored = ContentConfig.fromJson(json);
      
      expect(restored.defaultModSource, original.defaultModSource);
      expect(restored.defaultResourcePackSource, original.defaultResourcePackSource);
      expect(restored.defaultShaderPackSource, original.defaultShaderPackSource);
      expect(restored.enableAutoUpdateContent, original.enableAutoUpdateContent);
      expect(restored.enableConflictDetection, original.enableConflictDetection);
      expect(restored.enableDependencyCheck, original.enableDependencyCheck);
    });
  });
}
