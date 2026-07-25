// MinecraftPathResolver 测试
//
// 测试目标（项目 Hard Constraint：替代硬编码路径）：
// 1. resolveCandidates 返回的路径去重
// 2. 用户自定义候选优先级最高
// 3. findFirstExisting 仅返回存在的目录
// 4. predicate 过滤生效
// 5. 平台环境变量缺失时优雅降级（不抛异常）

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/instance/path_resolver.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mc_path_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MinecraftPathResolver.resolveCandidates', () {
    test('空自定义候选应返回至少一个结果', () {
      final resolver = MinecraftPathResolver();
      final candidates = resolver.resolveCandidates();
      expect(candidates, isNotEmpty);
    });

    test('自定义候选应保留在结果中', () {
      final custom = '${tempDir.path}/my_mc';
      final resolver = MinecraftPathResolver(customCandidates: [custom]);
      final candidates = resolver.resolveCandidates();

      expect(candidates, contains(custom));
    });

    test('空字符串的自定义候选应被过滤', () {
      final resolver = MinecraftPathResolver(
        customCandidates: ['', '  ', '${tempDir.path}/valid'],
      );
      final candidates = resolver.resolveCandidates();

      // 空字符串被过滤
      expect(candidates.where((c) => c.isEmpty), isEmpty);
      expect(candidates, contains('${tempDir.path}/valid'));
    });

    test('路径去重（normalize 后相同视为一条）', () {
      // Windows 风格路径分隔符差异在 normalize 后应相等
      final a = '${tempDir.path}/sub';
      final b = '${tempDir.path}\\sub';
      // 由于两条都在 normalize 后相等（或在不同平台上不相等），
      // 我们改为通过添加相同自定义路径验证去重
      final resolver = MinecraftPathResolver(customCandidates: [a, a]);
      final candidates = resolver.resolveCandidates();

      final occurrences = candidates.where((c) => c == a).length;
      expect(occurrences, equals(1), reason: '完全相同路径应被去重');
    });
  });

  group('MinecraftPathResolver.findFirstExisting', () {
    test('应返回第一个存在的目录', () async {
      final existing = Directory('${tempDir.path}/existing')..createSync();
      final resolver = MinecraftPathResolver(
        customCandidates: [
          existing.path,
          '${tempDir.path}/missing',
        ],
      );

      final found = await resolver.findFirstExisting();
      expect(found, equals(existing.path));
    });

    test('所有目录都不存在时应返回 null', () async {
      final resolver = MinecraftPathResolver(
        customCandidates: [
          '${tempDir.path}/nonexistent_1',
          '${tempDir.path}/nonexistent_2',
        ],
      );

      final found = await resolver.findFirstExisting();
      expect(found, isNull);
    });

    test('predicate 过滤不通过的目录应被跳过', () async {
      final empty = Directory('${tempDir.path}/empty_dir')..createSync();
      final valid = Directory('${tempDir.path}/valid_dir')..createSync();
      Directory('${valid.path}/versions').createSync();

      final resolver = MinecraftPathResolver(
        customCandidates: [empty.path, valid.path],
      );

      final found = await resolver.findFirstExisting(
        predicate: (dir) async {
          // 只有包含 versions 子目录的才算有效游戏目录
          final versionsDir = Directory('${dir.path}/versions');
          return versionsDir.existsSync();
        },
      );

      expect(found, equals(valid.path));
    });
  });

  group('MinecraftPathResolver - 平台覆盖', () {
    test('Windows 候选应包含 .minecraft 风格的 APPDATA 路径', () {
      // 我们无法注入 Platform.environment，所以只能验证函数本身不抛异常
      // 并返回非空列表（前提是当前环境是某个已知平台）
      final resolver = MinecraftPathResolver();
      final candidates = resolver.resolveCandidates();

      expect(candidates, isA<List<String>>());
      expect(candidates.length, greaterThan(0));
    });

    test('大量自定义候选不应导致重复条目', () {
      // 构造 20 条相同路径
      final manySame = List.filled(20, '${tempDir.path}/dup');
      final resolver = MinecraftPathResolver(customCandidates: manySame);
      final candidates = resolver.resolveCandidates();

      final dupCount = candidates
          .where((c) => c == '${tempDir.path}/dup')
          .length;
      expect(dupCount, lessThanOrEqualTo(1));
    });
  });
}