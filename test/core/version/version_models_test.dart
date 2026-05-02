import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/version/version.dart';

void main() {
  group('VersionManifest', () {
    test('fromJson parses manifest correctly', () {
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
        ],
      };
      
      final manifest = VersionManifest.fromJson(json);
      
      expect(manifest.latestRelease, '1.20.4');
      expect(manifest.latestSnapshot, '24w03b');
      expect(manifest.versions.length, 2);
      expect(manifest.versions[0].id, '1.20.4');
      expect(manifest.versions[0].type, VersionType.release);
      expect(manifest.versions[1].id, '24w03b');
      expect(manifest.versions[1].type, VersionType.snapshot);
    });

    test('toJson and fromJson roundtrip', () {
      final original = VersionManifest(
        latestRelease: '1.20.1',
        latestSnapshot: '23w31a',
        versions: [
          VersionEntry(
            id: '1.20.1',
            type: VersionType.release,
            releaseTime: DateTime(2023, 6, 12),
            time: DateTime(2023, 6, 12),
            url: 'https://example.com/1.20.1.json',
          ),
        ],
      );
      
      final json = original.toJson();
      final restored = VersionManifest.fromJson(json);
      
      expect(restored.latestRelease, original.latestRelease);
      expect(restored.latestSnapshot, original.latestSnapshot);
      expect(restored.versions.length, original.versions.length);
      expect(restored.versions[0].id, original.versions[0].id);
    });
  });

  group('VersionEntry', () {
    test('fromJson parses release version', () {
      final json = {
        'id': '1.20.4',
        'type': 'release',
        'releaseTime': '2023-12-07T12:00:00+00:00',
        'time': '2023-12-07T12:00:00+00:00',
        'url': 'https://example.com/1.20.4.json',
      };
      
      final entry = VersionEntry.fromJson(json);
      
      expect(entry.id, '1.20.4');
      expect(entry.type, VersionType.release);
      expect(entry.releaseTime.year, 2023);
      expect(entry.releaseTime.month, 12);
    });

    test('fromJson parses snapshot version', () {
      final json = {
        'id': '24w03b',
        'type': 'snapshot',
        'releaseTime': '2024-01-18T12:00:00+00:00',
        'time': '2024-01-18T12:00:00+00:00',
        'url': 'https://example.com/24w03b.json',
      };
      
      final entry = VersionEntry.fromJson(json);
      
      expect(entry.type, VersionType.snapshot);
    });

    test('fromJson parses old_alpha version', () {
      final json = {
        'id': 'a1.0.4',
        'type': 'old_alpha',
        'releaseTime': '2010-06-18T12:00:00+00:00',
        'time': '2010-06-18T12:00:00+00:00',
        'url': 'https://example.com/a1.0.4.json',
      };
      
      final entry = VersionEntry.fromJson(json);
      
      expect(entry.type, VersionType.old_alpha);
    });

    test('fromJson parses old_beta version', () {
      final json = {
        'id': 'b1.7.3',
        'type': 'old_beta',
        'releaseTime': '2011-06-30T12:00:00+00:00',
        'time': '2011-06-30T12:00:00+00:00',
        'url': 'https://example.com/b1.7.3.json',
      };
      
      final entry = VersionEntry.fromJson(json);
      
      expect(entry.type, VersionType.old_beta);
    });

    test('toJson and fromJson roundtrip', () {
      final original = VersionEntry(
        id: '1.19.4',
        type: VersionType.release,
        releaseTime: DateTime(2023, 3, 14),
        time: DateTime(2023, 3, 14),
        url: 'https://example.com/1.19.4.json',
      );
      
      final json = original.toJson();
      final restored = VersionEntry.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.url, original.url);
    });
  });

  group('Download', () {
    test('fromJson parses download', () {
      final json = {
        'url': 'https://example.com/client.jar',
        'sha1': 'abc123def456',
        'size': 12345678,
      };
      
      final download = Download.fromJson(json);
      
      expect(download.url, 'https://example.com/client.jar');
      expect(download.sha1, 'abc123def456');
      expect(download.size, 12345678);
    });

    test('toJson and fromJson roundtrip', () {
      final original = Download(
        url: 'https://example.com/test.jar',
        sha1: 'testsha1',
        size: 999999,
      );
      
      final json = original.toJson();
      final restored = Download.fromJson(json);
      
      expect(restored.url, original.url);
      expect(restored.sha1, original.sha1);
      expect(restored.size, original.size);
    });
  });

  group('AssetIndex', () {
    test('fromJson parses asset index', () {
      final json = {
        'id': '5',
        'sha1': 'indexsha1',
        'size': 1234,
        'totalSize': 567890,
        'url': 'https://example.com/index.json',
      };
      
      final index = AssetIndex.fromJson(json);
      
      expect(index.id, '5');
      expect(index.sha1, 'indexsha1');
      expect(index.size, 1234);
      expect(index.totalSize, 567890);
    });

    test('toJson and fromJson roundtrip', () {
      final original = AssetIndex(
        id: '12',
        sha1: 'testsha',
        size: 500,
        totalSize: 100000,
        url: 'https://example.com/assets.json',
      );
      
      final json = original.toJson();
      final restored = AssetIndex.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.sha1, original.sha1);
      expect(restored.size, original.size);
      expect(restored.totalSize, original.totalSize);
      expect(restored.url, original.url);
    });
  });

  group('Library', () {
    test('fromJson parses library', () {
      final json = {
        'name': 'com.example:library:1.0',
        'downloads': {
          'artifact': {
            'path': 'com/example/library/1.0/library-1.0.jar',
            'url': 'https://example.com/library-1.0.jar',
            'sha1': 'libsha1',
            'size': 50000,
          },
        },
      };
      
      final library = Library.fromJson(json);
      
      expect(library.name, 'com.example:library:1.0');
      expect(library.downloads.artifact, isNotNull);
      expect(library.downloads.artifact!.path, 'com/example/library/1.0/library-1.0.jar');
    });

    test('toJson and fromJson roundtrip', () {
      final original = Library(
        name: 'org.test:testlib:2.0',
        downloads: LibraryDownloads(
          artifact: Artifact(
            path: 'org/test/testlib/2.0/testlib-2.0.jar',
            url: 'https://example.com/testlib.jar',
            sha1: 'testlibsha',
            size: 75000,
          ),
        ),
      );
      
      final json = original.toJson();
      final restored = Library.fromJson(json);
      
      expect(restored.name, original.name);
      expect(restored.downloads.artifact!.path, original.downloads.artifact!.path);
      expect(restored.downloads.artifact!.url, original.downloads.artifact!.url);
    });
  });

  group('Artifact', () {
    test('fromJson parses artifact', () {
      final json = {
        'path': 'com/example/artifact/1.0/artifact-1.0.jar',
        'url': 'https://example.com/artifact.jar',
        'sha1': 'artifactsha1',
        'size': 100000,
      };
      
      final artifact = Artifact.fromJson(json);
      
      expect(artifact.path, 'com/example/artifact/1.0/artifact-1.0.jar');
      expect(artifact.url, 'https://example.com/artifact.jar');
      expect(artifact.sha1, 'artifactsha1');
      expect(artifact.size, 100000);
    });

    test('toJson and fromJson roundtrip', () {
      final original = Artifact(
        path: 'test/path/file.jar',
        url: 'https://example.com/file.jar',
        sha1: 'filesha1',
        size: 250000,
      );
      
      final json = original.toJson();
      final restored = Artifact.fromJson(json);
      
      expect(restored.path, original.path);
      expect(restored.url, original.url);
      expect(restored.sha1, original.sha1);
      expect(restored.size, original.size);
    });
  });
}
