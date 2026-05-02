import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/config/models/global_config.dart';
import 'package:bamclauncher/core/auth/models/account.dart';
import 'package:bamclauncher/core/version/version.dart';

void main() {
  group('Comprehensive Integration Tests', () {
    group('Config System Integration', () {
      test('GlobalConfig serialization preserves all nested configs', () {
        final config = GlobalConfig(
          version: '2.0.0',
          basic: BasicConfig(
            launcherVersion: '2.0.0',
            language: 'en_US',
            autoUpdate: false,
            checkUpdateOnStartup: false,
            theme: 'dark',
            enableLogging: false,
            logLevel: 'debug',
          ),
          game: GameConfig(
            javaPath: '/usr/bin/java',
            maxMemory: 4096,
            minMemory: 1024,
            jvmArguments: ['-Xmx4G', '-Xms1G'],
            gameArguments: ['--fullscreen'],
            enableFullscreen: true,
            windowWidth: 1920,
            windowHeight: 1080,
            enableVsync: false,
            enableMipmap: false,
            gameDirectory: '/home/user/.minecraft',
          ),
          download: DownloadConfig(
            downloadSource: 'official',
            downloadThreads: 16,
            downloadSpeedLimit: 1024,
            enableProxy: true,
            proxyHost: '192.168.1.1',
            proxyPort: 8080,
            proxyType: 'socks5',
            enableBreakpointResume: false,
            retryCount: 5,
            retryDelay: 2000,
          ),
          account: AccountConfig(
            defaultAccountId: 'test-account-id',
            autoLogin: true,
            rememberPassword: true,
            enableAuthlibInjector: true,
            authlibInjectorUrl: 'https://auth.example.com',
            enableSkinUpload: false,
          ),
          ui: UiConfig(
            enableCustomTitleBar: false,
            enableTransparentWindow: true,
            enableBlurEffect: false,
            enableAnimation: false,
            enableSound: false,
            enableNotifications: false,
            sidebarWidth: '250px',
            autoHideSidebar: true,
            enableDarkMode: true,
          ),
          content: ContentConfig(
            defaultModSource: 'curseforge',
            defaultResourcePackSource: 'curseforge',
            defaultShaderPackSource: 'curseforge',
            enableAutoUpdateContent: true,
            enableConflictDetection: false,
            enableDependencyCheck: false,
            modInstallDirectory: '/mods',
            resourcePackDirectory: '/resourcepacks',
            shaderPackDirectory: '/shaderpacks',
          ),
        );
        
        final json = config.toJson();
        final restored = GlobalConfig.fromJson(json);
        
        // Verify all nested configs are preserved
        expect(restored.version, '2.0.0');
        expect(restored.basic.language, 'en_US');
        expect(restored.basic.theme, 'dark');
        expect(restored.game.maxMemory, 4096);
        expect(restored.game.javaPath, '/usr/bin/java');
        expect(restored.download.downloadSource, 'official');
        expect(restored.download.downloadThreads, 16);
        expect(restored.download.enableProxy, true);
        expect(restored.account.defaultAccountId, 'test-account-id');
        expect(restored.account.enableAuthlibInjector, true);
        expect(restored.ui.enableDarkMode, true);
        expect(restored.ui.sidebarWidth, '250px');
        expect(restored.content.defaultModSource, 'curseforge');
        expect(restored.content.enableAutoUpdateContent, true);
      });
    });

    group('Account System Integration', () {
      test('full account lifecycle', () {
        // Create account
        var account = Account(
          id: 'lifecycle-test',
          username: 'LifecycleUser',
          type: AccountType.microsoft,
          tokenData: TokenData(
            accessToken: 'initial-token',
            refreshToken: 'initial-refresh',
            expiresAt: DateTime(2026, 12, 31),
          ),
          profile: MinecraftProfile(
            id: 'profile-uuid',
            name: 'LifecycleUser',
            skinUrl: 'https://textures.minecraft.net/skin',
          ),
        );
        
        // Verify initial state
        expect(account.isSelected, false);
        expect(account.tokenData!.isExpired, false);
        
        // Select account
        account = account.copyWith(isSelected: true);
        expect(account.isSelected, true);
        
        // Serialize and restore
        final json = account.toJson();
        final restored = Account.fromJson(json);
        
        expect(restored.id, account.id);
        expect(restored.username, account.username);
        expect(restored.isSelected, true);
        expect(restored.tokenData!.accessToken, 'initial-token');
        expect(restored.profile!.skinUrl, 'https://textures.minecraft.net/skin');
      });

      test('multiple account types coexist', () {
        final accounts = [
          Account(
            id: 'offline-1',
            username: 'OfflinePlayer',
            type: AccountType.offline,
          ),
          Account(
            id: 'ms-1',
            username: 'MSPlayer',
            type: AccountType.microsoft,
            tokenData: TokenData(
              accessToken: 'ms-token',
              expiresAt: DateTime(2026, 6, 1),
            ),
          ),
          Account(
            id: 'authlib-1',
            username: 'AuthlibPlayer',
            type: AccountType.authlibInjector,
            serverUrl: 'https://auth.example.com',
          ),
        ];
        
        // Serialize all
        final jsonList = accounts.map((a) => a.toJson()).toList();
        
        // Restore all
        final restored = jsonList.map((j) => Account.fromJson(j)).toList();
        
        expect(restored[0].type, AccountType.offline);
        expect(restored[1].type, AccountType.microsoft);
        expect(restored[1].tokenData, isNotNull);
        expect(restored[2].type, AccountType.authlibInjector);
        expect(restored[2].serverUrl, 'https://auth.example.com');
      });
    });

    group('Version System Integration', () {
      test('VersionManifest with multiple version types', () {
        final json = {
          'latest': {
            'release': '1.20.4',
            'snapshot': '24w03b',
          },
          'versions': [
            {
              'id': '1.20.4',
              'type': 'release',
              'releaseTime': '2023-12-07T12:00:00+00:00',
              'time': '2023-12-07T12:00:00+00:00',
              'url': 'https://example.com/1.20.4.json',
            },
            {
              'id': '24w03b',
              'type': 'snapshot',
              'releaseTime': '2024-01-18T12:00:00+00:00',
              'time': '2024-01-18T12:00:00+00:00',
              'url': 'https://example.com/24w03b.json',
            },
            {
              'id': 'a1.0.4',
              'type': 'old_alpha',
              'releaseTime': '2010-06-18T12:00:00+00:00',
              'time': '2010-06-18T12:00:00+00:00',
              'url': 'https://example.com/a1.0.4.json',
            },
            {
              'id': 'b1.7.3',
              'type': 'old_beta',
              'releaseTime': '2011-06-30T12:00:00+00:00',
              'time': '2011-06-30T12:00:00+00:00',
              'url': 'https://example.com/b1.7.3.json',
            },
          ],
        };
        
        final manifest = VersionManifest.fromJson(json);
        
        expect(manifest.versions.length, 4);
        expect(manifest.versions.where((v) => v.type == VersionType.release).length, 1);
        expect(manifest.versions.where((v) => v.type == VersionType.snapshot).length, 1);
        expect(manifest.versions.where((v) => v.type == VersionType.old_alpha).length, 1);
        expect(manifest.versions.where((v) => v.type == VersionType.old_beta).length, 1);
        
        // Verify roundtrip
        final restoredJson = manifest.toJson();
        final restored = VersionManifest.fromJson(restoredJson);
        expect(restored.versions.length, 4);
      });
    });

    group('Cross-Module Data Flow', () {
      test('config can reference account and version data', () {
        // Create config with custom settings
        final config = GlobalConfig(
          version: '1.0.0',
          basic: BasicConfig.defaultConfig(),
          game: GameConfig.defaultConfig(),
          download: DownloadConfig.defaultConfig(),
          account: AccountConfig(
            defaultAccountId: 'selected-account',
            autoLogin: true,
            rememberPassword: true,
            enableAuthlibInjector: false,
            authlibInjectorUrl: '',
            enableSkinUpload: true,
          ),
          ui: UiConfig.defaultConfig(),
          content: ContentConfig.defaultConfig(),
        );
        
        // Create account that matches config
        final account = Account(
          id: 'selected-account',
          username: 'SelectedUser',
          type: AccountType.microsoft,
          isSelected: true,
        );
        
        // Verify they work together
        expect(config.account.defaultAccountId, account.id);
        expect(account.isSelected, true);
        
        // Serialize both
        final configJson = config.toJson();
        final accountJson = account.toJson();
        
        // Restore and verify
        final restoredConfig = GlobalConfig.fromJson(configJson);
        final restoredAccount = Account.fromJson(accountJson);
        
        expect(restoredConfig.account.defaultAccountId, restoredAccount.id);
      });
    });
  });
}
