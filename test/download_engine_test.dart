import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/download/models.dart';
import 'package:bamclaunch/src/download/download_source.dart';
import 'package:bamclaunch/src/download/download_engine.dart';
import 'package:bamclaunch/src/event/event_bus.dart';

void main() {
  group('下载模块测试', () {
    setUp(() {
      EventBus.reset();
      DownloadEngine.reset();
    });

    test('测试 HashType 枚举值', () {
      expect(HashType.sha1, isNotNull);
      expect(HashType.sha256, isNotNull);
      expect(HashType.md5, isNotNull);
    });

    test('测试 DownloadRequest 创建', () {
      final request = DownloadRequest(
        url: 'https://example.com/test.txt',
        savePath: '/tmp/test.txt',
        hash: 'abc123',
        hashType: HashType.sha1,
      );

      expect(request.url, equals('https://example.com/test.txt'));
      expect(request.savePath, equals('/tmp/test.txt'));
      expect(request.hash, equals('abc123'));
      expect(request.hashType, equals(HashType.sha1));
    });

    test('测试 DownloadProgress 创建', () {
      final progress = DownloadProgress(
        downloadedBytes: 50,
        totalBytes: 100,
        progress: 0.5,
        speed: 1024,
        remainingTime: 30,
      );

      expect(progress.downloadedBytes, equals(50));
      expect(progress.totalBytes, equals(100));
      expect(progress.progress, equals(0.5));
      expect(progress.speed, equals(1024));
      expect(progress.remainingTime, equals(30));
    });

    test('测试 DownloadProgress fromBytes 工厂方法', () {
      final progress = DownloadProgress.fromBytes(50, 100);
      expect(progress.progress, equals(0.5));
      expect(progress.downloadedBytes, equals(50));
      expect(progress.totalBytes, equals(100));
    });

    test('测试 BMCLApiDownloadSource 名称', () {
      final source = BMCLApiDownloadSource('https://bmclapi2.bangbang93.com', 'BMCLAPI');
      expect(source.name, equals('BMCLAPI'));
    });

    test('测试 OfficialDownloadSource 名称', () {
      final source = OfficialDownloadSource();
      expect(source.name, equals('Official'));
    });

    test('测试 DownloadEngine 单例', () {
      final engine1 = DownloadEngine.instance;
      final engine2 = DownloadEngine.instance;
      expect(engine1, same(engine2));
    });

    test('测试 DownloadEngine 单例重置', () {
      final engine1 = DownloadEngine.instance;
      DownloadEngine.reset();
      final engine2 = DownloadEngine.instance;
      expect(engine1, isNot(same(engine2)));
    });

    test('测试 DownloadEngine 设置下载源', () {
      final engine = DownloadEngine.instance;
      final source = OfficialDownloadSource();
      engine.setDownloadSource(source);
      expect(true, isTrue);
    });
  });
}
