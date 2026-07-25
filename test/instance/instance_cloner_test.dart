// InstanceCloner 测试
//
// 验证从 InstanceManager 拆分出的实例复制组件：
// 1. duplicateInstance 创建新实例（新ID、新时间戳、重置统计数据）
// 2. 文件物理复制（mods/ 等子目录内容被复制）
// 3. duplicateInstanceToDirectory 切换 directoryId
// 4. getInstanceSize 准确统计磁盘占用
// 5. CopyOptions 排除项生效

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/instance/instance_cloner.dart';
import 'package:bamclaunch/src/instance/models.dart';

GameInstance _makeInstance({
  required String id,
  required String directoryId,
  int playTimeSeconds = 100,
}) {
  final now = DateTime.now();
  return GameInstance(
    id: id,
    name: 'Instance_$id',
    directoryId: directoryId,
    version: '1.20.4',
    config: InstanceConfig(),
    resources: InstanceResources(
      mods: ['mod1.jar'],
      resourcePacks: [],
      shaderPacks: [],
      worlds: [],
      screenshots: [],
    ),
    createdAt: now,
    updatedAt: now,
    lastPlayed: now,
    playTimeSeconds: playTimeSeconds,
  );
}

InstanceDirectory _makeDirectory({required String id, required String path}) {
  final now = DateTime.now();
  return InstanceDirectory(
    id: id,
    name: 'Dir_$id',
    path: path,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late InstanceCloner cloner;
  late Directory tempDir;
  late List<GameInstance> instances;
  late List<InstanceDirectory> directories;

  setUp(() {
    cloner = InstanceCloner();
    tempDir = Directory.systemTemp.createTempSync('instance_cloner_test_');
    directories = [
      _makeDirectory(id: 'dir_1', path: tempDir.path),
    ];
    instances = [
      _makeInstance(id: 'inst_1', directoryId: 'dir_1'),
    ];

    // 预先创建原实例的 mods 目录与文件
    final srcInstanceDir =
        Directory('${tempDir.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_1')
          ..createSync(recursive: true);
    final srcMods =
        Directory('${srcInstanceDir.path}${Platform.pathSeparator}mods')
          ..createSync();
    File('${srcMods.path}${Platform.pathSeparator}mod1.jar')
      ..writeAsStringSync('1234567890'); // 10 字节
    File('${srcMods.path}${Platform.pathSeparator}mod2.jar')
      ..writeAsStringSync('abcdefghij'); // 10 字节
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('InstanceCloner.duplicateInstance', () {
    test('应返回新实例并加入列表', () async {
      final result = await cloner.duplicateInstance(
        instanceId: 'inst_1',
        newName: 'Copy of inst_1',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_new',
      );

      expect(result.id, equals('inst_new'));
      expect(result.name, equals('Copy of inst_1'));
      expect(result.directoryId, equals('dir_1'));
      expect(instances, hasLength(2));
      expect(instances.last.id, equals('inst_new'));
    });

    test('新实例应重置 lastPlayed 与 playTimeSeconds', () async {
      final result = await cloner.duplicateInstance(
        instanceId: 'inst_1',
        newName: 'Copy',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_copy',
      );

      expect(result.lastPlayed, isNull);
      expect(result.playTimeSeconds, equals(0));
    });

    test('应物理复制实例文件（mods/ 下的文件被复制）', () async {
      await cloner.duplicateInstance(
        instanceId: 'inst_1',
        newName: 'Copy',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_copy',
      );

      final targetModsDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_copy${Platform.pathSeparator}mods',
      );
      expect(targetModsDir.existsSync(), isTrue);

      final mod1 = File('${targetModsDir.path}${Platform.pathSeparator}mod1.jar');
      expect(mod1.existsSync(), isTrue);
      expect(mod1.readAsStringSync(), equals('1234567890'));
    });

    test('不存在的实例应抛 ArgumentError', () async {
      expect(
        () => cloner.duplicateInstance(
          instanceId: 'nonexistent',
          newName: 'Copy',
          instances: instances,
          directories: directories,
          generateId: () => 'id',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyFiles=false 时不应物理复制', () async {
      await cloner.duplicateInstance(
        instanceId: 'inst_1',
        newName: 'Copy',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_nofile',
        copyFiles: false,
      );

      // 实例条目已添加但磁盘文件不存在
      expect(
        Directory('${tempDir.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_nofile')
            .existsSync(),
        isFalse,
      );
      expect(instances, hasLength(2));
    });
  });

  group('InstanceCloner.duplicateInstanceToDirectory', () {
    test('应切换到目标目录的 directoryId', () async {
      // 添加第二个目录（用嵌套子目录，避免依赖 createTempSync 的奇怪路径行为）
      final dir2 = Directory('${tempDir.path}${Platform.pathSeparator}dir2')
        ..createSync();
      directories.add(_makeDirectory(id: 'dir_2', path: dir2.path));

      final result = await cloner.duplicateInstanceToDirectory(
        instanceId: 'inst_1',
        newName: 'CrossCopy',
        targetDirectoryId: 'dir_2',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_cross',
      );

      expect(result.directoryId, equals('dir_2'));
      expect(
        Directory('${dir2.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_cross')
            .existsSync(),
        isTrue,
      );
    });

    test('目标目录不存在应抛 ArgumentError', () async {
      expect(
        () => cloner.duplicateInstanceToDirectory(
          instanceId: 'inst_1',
          newName: 'Copy',
          targetDirectoryId: 'no_such_dir',
          instances: instances,
          directories: directories,
          generateId: () => 'id',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('InstanceCloner.getInstanceSize', () {
    test('应准确统计实例磁盘占用（含子目录）', () async {
      final size = await cloner.getInstanceSize(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      // mod1.jar: 10 字节 + mod2.jar: 10 字节 = 20 字节
      expect(size, equals(20));
    });

    test('实例目录不存在时应返回 0', () async {
      final phantom = _makeInstance(
        id: 'phantom',
        directoryId: 'dir_1',
      );
      instances.add(phantom);

      final size = await cloner.getInstanceSize(
        instanceId: 'phantom',
        instances: instances,
        directories: directories,
      );

      expect(size, equals(0));
    });
  });

  group('InstanceCloner - CopyOptions 排除', () {
    test('excludeDirs 应排除对应子目录', () async {
      // 准备：除了 mods 还有 cache 目录
      final cacheDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_1${Platform.pathSeparator}cache',
      )..createSync();
      File('${cacheDir.path}${Platform.pathSeparator}temp.dat')
        ..writeAsStringSync('x' * 100);

      await cloner.duplicateInstance(
        instanceId: 'inst_1',
        newName: 'Copy',
        instances: instances,
        directories: directories,
        generateId: () => 'inst_with_options',
        options: CopyOptions(
          copyVersionDir: false,
          excludeDirs: {'cache'},
          excludeFiles: {},
        ),
      );

      final targetBase = Directory(
        '${tempDir.path}${Platform.pathSeparator}instances${Platform.pathSeparator}inst_with_options',
      );
      // mods 被复制
      expect(
        Directory('${targetBase.path}${Platform.pathSeparator}mods').existsSync(),
        isTrue,
      );
      // cache 被排除
      expect(
        Directory('${targetBase.path}${Platform.pathSeparator}cache').existsSync(),
        isFalse,
      );
    });
  });
}