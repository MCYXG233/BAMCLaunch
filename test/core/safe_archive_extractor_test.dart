// SafeArchiveExtractor 安全测试
//
// 测试目标（项目 Hard Constraint）：
// 1. 防 Zip Slip 路径穿越（.. 攻击）
// 2. 防绝对路径条目（C:\、\\server\share、/etc/...）
// 3. 防 Zip 炸弹（单文件大小 / 总条目数 / 总字节数）
// 4. nameTransformer 重写规则正确生效
// 5. onUnsafePath 回调被正确触发

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/core/safe_archive_extractor.dart';

/// 测试辅助：手动构造 ZIP 字节流
///
/// 使用 archive 包的 ZipEncoder，无需依赖系统 zip 命令。
Uint8List buildZipBytes(List<ArchiveFile> files) {
  final archive = Archive();
  for (final file in files) {
    archive.addFile(file);
  }
  return ZipEncoder().encode(archive) as Uint8List;
}

/// 测试辅助：创建文本文件条目
ArchiveFile textFile(String name, String content) {
  return ArchiveFile.string(name, content);
}

/// 测试辅助：创建二进制文件条目
ArchiveFile bytesFile(String name, List<int> content) {
  // ArchiveFile 构造器签名：(name, size, content)
  // size <= 0 时会自动从 content.length 推断
  return ArchiveFile(name, 0, Uint8List.fromList(content));
}

/// 测试辅助：创建目录条目
ArchiveFile dirEntry(String name) {
  final entry = ArchiveFile.string(name, '');
  entry.isFile = false;
  entry.size = 0;
  return entry;
}

void main() {
  // 测试输出目录（每个测试前清理）
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('safe_archive_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SafeArchiveExtractor - 路径安全', () {
    test('正常条目应被解压到 targetDir 下', () async {
      final bytes = buildZipBytes([
        textFile('readme.txt', 'hello'),
        dirEntry('mods/'),
        textFile('mods/example.jar', 'fake jar'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      expect(result.filesExtracted, greaterThanOrEqualTo(2));
      expect(result.skippedUnsafePaths, isEmpty);
      expect(File('${tempDir.path}/readme.txt').existsSync(), isTrue);
      expect(File('${tempDir.path}/mods/example.jar').existsSync(), isTrue);
      expect(
        File('${tempDir.path}/readme.txt').readAsStringSync(),
        equals('hello'),
      );
    });

    test('Zip Slip 攻击（../）应被拒绝且不入磁盘', () async {
      final bytes = buildZipBytes([
        textFile('../../../etc/passwd', 'pwned'),
        textFile('normal.txt', 'ok'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      // 危险条目必须被跳过
      expect(result.skippedUnsafePaths, contains('../../../etc/passwd'));
      // 危险条目绝不能写出到磁盘
      expect(File('${tempDir.path}/../etc/passwd').existsSync(), isFalse);
      // 正常条目应被解压
      expect(File('${tempDir.path}/normal.txt').existsSync(), isTrue);
    });

    test('Windows 风格绝对路径应被拒绝（C:\\）', () async {
      final bytes = buildZipBytes([
        textFile('C:\\Windows\\System32\\evil.exe', 'pwned'),
        textFile('safe.txt', 'ok'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      // archive 包在构造条目时会把 \ 替换为 /，故断言以正斜杠形式
      expect(
        result.skippedUnsafePaths,
        contains('C:/Windows/System32/evil.exe'),
      );
      // 关键：绝对路径攻击文件绝不能写入系统目录
      expect(
        File('C:/Windows/System32/evil.exe').existsSync(),
        isFalse,
        reason: '绝对路径攻击文件不应被写入系统目录',
      );
    });

    test('Unix 绝对路径应被拒绝（/etc/passwd）', () async {
      final bytes = buildZipBytes([textFile('/etc/passwd', 'pwned')]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      expect(result.skippedUnsafePaths, contains('/etc/passwd'));
    });

    test('空条目名应被拒绝', () async {
      final bytes = buildZipBytes([
        textFile('', 'pwned'),
        textFile('safe.txt', 'ok'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      expect(result.skippedUnsafePaths, contains(''));
      expect(File('${tempDir.path}/safe.txt').existsSync(), isTrue);
    });

    test('onUnsafePath 回调应被触发并接收原始条目名', () async {
      final bytes = buildZipBytes([textFile('../../evil.txt', 'pwned')]);

      final captured = <String>[];
      await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
        onUnsafePath: (entryName, resolvedPath) {
          captured.add(entryName);
        },
      );

      expect(captured, equals(['../../evil.txt']));
    });
  });

  group('SafeArchiveExtractor - nameTransformer 重写', () {
    test('Transformer 返回 null 应跳过条目', () async {
      final bytes = buildZipBytes([
        textFile('overrides/keep.txt', 'kept'),
        textFile('overrides/skip.txt', 'skipped'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
        nameTransformer: (name) {
          // skip.txt 走 overrides 路径，但 transformer 让其跳过
          if (name == 'overrides/skip.txt') return null;
          return name.substring('overrides/'.length);
        },
      );

      expect(File('${tempDir.path}/keep.txt').existsSync(), isTrue);
      expect(File('${tempDir.path}/skip.txt').existsSync(), isFalse);
      expect(result.skippedUnsafePaths, contains('overrides/skip.txt'));
    });

    test('Transformer 重写后超 targetDir 应被拒绝', () async {
      final bytes = buildZipBytes([textFile('placeholder.txt', 'pwned')]);

      // 即使 transformer 改写，escape 路径仍需被防护
      await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
        nameTransformer: (name) => '../$name',
      );

      // 重写后的路径逃出 targetDir，必须被跳过
      expect(File('${tempDir.path}/placeholder.txt').existsSync(), isFalse);
    });
  });

  group('SafeArchiveExtractor - Zip 炸弹防护', () {
    test('超过 maxEntries 应抛出 ArchiveSecurityException', () async {
      // 构造 5 个条目，限制为 3
      final bytes = buildZipBytes([
        for (var i = 0; i < 5; i++) textFile('file_$i.txt', 'content'),
      ]);

      expect(
        () => SafeArchiveExtractor.extractZip(
          bytes: bytes,
          targetDir: tempDir.path,
          maxEntries: 3,
        ),
        throwsA(isA<ArchiveSecurityException>()),
      );
    });

    test('单文件超过 maxFileSize 应抛出 ArchiveSecurityException', () async {
      final hugeContent = List.filled(2000, 0x41); // 2000 字节
      final bytes = buildZipBytes([
        bytesFile('huge.bin', hugeContent),
        textFile('safe.txt', 'ok'),
      ]);

      expect(
        () => SafeArchiveExtractor.extractZip(
          bytes: bytes,
          targetDir: tempDir.path,
          maxFileSize: 100, // 限制为 100 字节
        ),
        throwsA(isA<ArchiveSecurityException>()),
      );
    });

    test('总解压字节数超过 maxTotalBytes 应抛出异常', () async {
      final content1 = List.filled(600, 0x41);
      final content2 = List.filled(600, 0x42);
      final bytes = buildZipBytes([
        bytesFile('a.bin', content1),
        bytesFile('b.bin', content2),
      ]);

      expect(
        () => SafeArchiveExtractor.extractZip(
          bytes: bytes,
          targetDir: tempDir.path,
          maxTotalBytes: 1000,
        ),
        throwsA(isA<ArchiveSecurityException>()),
      );
    });
  });

  group('SafeArchiveExtractor - ExtractResult 统计', () {
    test('正确统计 filesExtracted 和 directoriesCreated', () async {
      final bytes = buildZipBytes([
        dirEntry('a/'),
        dirEntry('a/b/'),
        textFile('a/b/file.txt', 'x'),
        textFile('root.txt', 'y'),
      ]);

      final result = await SafeArchiveExtractor.extractZip(
        bytes: bytes,
        targetDir: tempDir.path,
      );

      expect(result.filesExtracted, equals(2));
      expect(result.directoriesCreated, equals(2));
      expect(result.totalBytes, equals(2)); // 'x' + 'y'
    });
  });
}
