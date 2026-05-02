import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/config/models/global_config.dart';
import 'package:bamclauncher/core/auth/models/account.dart';
import 'package:bamclauncher/core/version/version.dart';

void main() {
  group('Stress Tests', () {
    group('Config Serialization Stress', () {
      test('rapid config creation and serialization', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 1000; i++) {
          final config = GlobalConfig(
            version: '1.0.$i',
            basic: BasicConfig(
              launcherVersion: '1.0.$i',
              language: i % 2 == 0 ? 'zh_CN' : 'en_US',
              autoUpdate: i % 3 == 0,
              checkUpdateOnStartup: i % 4 == 0,
              theme: i % 5 == 0 ? 'dark' : 'default',
              enableLogging: true,
              logLevel: 'info',
            ),
            game: GameConfig.defaultConfig(),
            download: DownloadConfig.defaultConfig(),
            account: AccountConfig.defaultConfig(),
            ui: UiConfig.defaultConfig(),
            content: ContentConfig.defaultConfig(),
          );
          
          final json = config.toJson();
          final restored = GlobalConfig.fromJson(json);
          
          expect(restored.version, '1.0.$i');
        }
        
        stopwatch.stop();
        print('Config stress test: ${stopwatch.elapsedMilliseconds}ms for 1000 iterations');
        
        // Should complete in reasonable time (under 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Account Serialization Stress', () {
      test('rapid account creation and serialization', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 1000; i++) {
          final account = Account(
            id: 'account-$i',
            username: 'User$i',
            type: AccountType.values[i % AccountType.values.length],
            tokenData: TokenData(
              accessToken: 'token-$i',
              refreshToken: 'refresh-$i',
              expiresAt: DateTime(2026, 12, 31),
            ),
            profile: MinecraftProfile(
              id: 'profile-$i',
              name: 'Player$i',
              skinUrl: 'https://textures.minecraft.net/skin/$i',
            ),
            createdAt: DateTime(2024, 1, 1),
            lastLogin: DateTime(2024, 6, 1),
            isSelected: i % 10 == 0,
          );
          
          final json = account.toJson();
          final restored = Account.fromJson(json);
          
          expect(restored.id, 'account-$i');
          expect(restored.username, 'User$i');
        }
        
        stopwatch.stop();
        print('Account stress test: ${stopwatch.elapsedMilliseconds}ms for 1000 iterations');
        
        // Should complete in reasonable time (under 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Version Manifest Stress', () {
      test('large version manifest handling', () {
        final versions = <Map<String, dynamic>>[];
        
        // Generate 1000 versions
        for (var i = 0; i < 1000; i++) {
          versions.add({
            'id': '1.${i ~/ 100}.${i % 100}',
            'type': i % 10 == 0 ? 'snapshot' : 'release',
            'releaseTime': '2024-01-01T00:00:00+00:00',
            'time': '2024-01-01T00:00:00+00:00',
            'url': 'https://example.com/version/$i.json',
          });
        }
        
        final json = {
          'latest': {
            'release': '1.99.0',
            'snapshot': '24w01a',
          },
          'versions': versions,
        };
        
        final stopwatch = Stopwatch()..start();
        
        final manifest = VersionManifest.fromJson(json);
        
        expect(manifest.versions.length, 1000);
        
        // Test serialization
        final serialized = manifest.toJson();
        expect(serialized['versions'].length, 1000);
        
        // Test deserialization
        final restored = VersionManifest.fromJson(serialized);
        expect(restored.versions.length, 1000);
        
        stopwatch.stop();
        print('Version manifest stress test: ${stopwatch.elapsedMilliseconds}ms for 1000 versions');
        
        // Should complete in reasonable time (under 10 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });

    group('Memory Stress', () {
      test('multiple large objects in memory', () {
        final configs = <GlobalConfig>[];
        final accounts = <Account>[];
        final manifests = <VersionManifest>[];
        
        final stopwatch = Stopwatch()..start();
        
        // Create 100 of each
        for (var i = 0; i < 100; i++) {
          configs.add(GlobalConfig.defaultConfig());
          
          accounts.add(Account(
            id: 'account-$i',
            username: 'User$i',
            type: AccountType.offline,
          ));
          
          manifests.add(VersionManifest(
            latestRelease: '1.20.4',
            latestSnapshot: '24w03b',
            versions: List.generate(
              10,
              (j) => VersionEntry(
                id: 'version-$i-$j',
                type: VersionType.release,
                releaseTime: DateTime(2024, 1, 1),
                time: DateTime(2024, 1, 1),
                url: 'https://example.com/version-$i-$j.json',
              ),
            ),
          ));
        }
        
        // Verify all objects
        expect(configs.length, 100);
        expect(accounts.length, 100);
        expect(manifests.length, 100);
        
        // Serialize and deserialize all
        for (var i = 0; i < 100; i++) {
          final configJson = configs[i].toJson();
          GlobalConfig.fromJson(configJson);
          
          final accountJson = accounts[i].toJson();
          Account.fromJson(accountJson);
          
          final manifestJson = manifests[i].toJson();
          VersionManifest.fromJson(manifestJson);
        }
        
        stopwatch.stop();
        print('Memory stress test: ${stopwatch.elapsedMilliseconds}ms for 300 objects');
        
        // Should complete in reasonable time (under 30 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(30000));
      });
    });

    group('Edge Cases Stress', () {
      test('empty and null values handling', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 100; i++) {
          // Test with empty JSON
          final emptyConfig = GlobalConfig.fromJson({});
          expect(emptyConfig.version, '1.0.0');
          
          // Test with null values
          final nullConfig = GlobalConfig.fromJson({
            'version': null,
            'basic': null,
            'game': null,
            'download': null,
            'account': null,
            'ui': null,
            'content': null,
          });
          expect(nullConfig.version, '1.0.0');
          
          // Test with empty account
          final emptyAccount = Account.fromJson({
            'id': 'test',
            'username': 'test',
            'type': 0,
            'createdAt': '2024-01-01T00:00:00.000',
          });
          expect(emptyAccount.tokenData, isNull);
          expect(emptyAccount.profile, isNull);
        }
        
        stopwatch.stop();
        print('Edge cases stress test: ${stopwatch.elapsedMilliseconds}ms for 100 iterations');
        
        // Should complete in reasonable time (under 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('large string values handling', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 100; i++) {
          final largeString = 'A' * 10000; // 10KB string
          
          final config = GameConfig(
            javaPath: largeString,
            maxMemory: 2048,
            minMemory: 512,
            jvmArguments: [largeString, largeString],
            gameArguments: [largeString],
            enableFullscreen: false,
            windowWidth: 854,
            windowHeight: 480,
            enableVsync: true,
            enableMipmap: true,
            gameDirectory: largeString,
          );
          
          final json = config.toJson();
          final restored = GameConfig.fromJson(json);
          
          expect(restored.javaPath.length, 10000);
          expect(restored.gameDirectory.length, 10000);
        }
        
        stopwatch.stop();
        print('Large strings stress test: ${stopwatch.elapsedMilliseconds}ms for 100 iterations');
        
        // Should complete in reasonable time (under 10 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });
  });
}
