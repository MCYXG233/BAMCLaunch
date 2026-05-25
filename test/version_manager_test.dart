import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/version/models.dart';
import 'package:bamclaunch/src/version/version_manager.dart';

void main() {
  group('Version Model Tests', () {
    test('GameVersion fromJson creates valid object', () {
      final json = {
        'id': '1.20.1',
        'type': 'release',
        'url': 'https://example.com/version.json',
        'time': '2023-08-10T12:00:00Z',
        'releaseTime': '2023-08-10T14:00:00Z',
      };

      final version = GameVersion.fromJson(json);

      expect(version.id, equals('1.20.1'));
      expect(version.type, equals(VersionType.release));
      expect(version.url, equals('https://example.com/version.json'));
    });

    test('GameVersion toJson produces valid JSON', () {
      final version = GameVersion(
        id: '1.20.1',
        type: VersionType.release,
        url: 'https://example.com/version.json',
        time: DateTime.utc(2023, 8, 10, 12, 0, 0),
        releaseTime: DateTime.utc(2023, 8, 10, 14, 0, 0),
      );

      final json = version.toJson();

      expect(json['id'], equals('1.20.1'));
      expect(json['type'], equals('release'));
    });

    test('VersionType parsing works correctly', () {
      expect(
        GameVersion._parseVersionType('release'),
        equals(VersionType.release),
      );
      expect(
        GameVersion._parseVersionType('snapshot'),
        equals(VersionType.snapshot),
      );
      expect(
        GameVersion._parseVersionType('old_beta'),
        equals(VersionType.oldBeta),
      );
      expect(
        GameVersion._parseVersionType('old_alpha'),
        equals(VersionType.oldAlpha),
      );
      expect(
        GameVersion._parseVersionType('unknown'),
        equals(VersionType.release),
      );
    });
  });

  group('Version Install Progress Tests', () {
    test('VersionInstallProgress initializes correctly', () {
      final progress = VersionInstallProgress(
        versionId: '1.20.1',
        progress: 0.5,
        stage: '下载库文件',
        downloadedBytes: 1024,
        totalBytes: 2048,
      );

      expect(progress.versionId, equals('1.20.1'));
      expect(progress.progress, equals(0.5));
      expect(progress.stage, equals('下载库文件'));
      expect(progress.downloadedBytes, equals(1024));
      expect(progress.totalBytes, equals(2048));
    });
  });

  group('Asset Tests', () {
    test('Asset fromJson creates valid object', () {
      final json = {'hash': 'abc123', 'size': 1024};

      final asset = Asset.fromJson(json);

      expect(asset.hash, equals('abc123'));
      expect(asset.size, equals(1024));
    });

    test('Asset toJson produces valid JSON', () {
      final asset = Asset(hash: 'abc123', size: 1024);

      final json = asset.toJson();

      expect(json['hash'], equals('abc123'));
      expect(json['size'], equals(1024));
    });
  });

  group('Version Manager Singleton Tests', () {
    test('VersionManager singleton returns same instance', () {
      final instance1 = VersionManager();
      final instance2 = VersionManager();

      expect(identical(instance1, instance2), isTrue);
    });

    test('VersionManager reset works for testing', () {
      VersionManager.reset();
      final instance1 = VersionManager();
      VersionManager.reset();
      final instance2 = VersionManager();

      expect(identical(instance1, instance2), isFalse);
    });
  });
}
