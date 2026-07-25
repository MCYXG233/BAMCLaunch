// InstancePathService 测试
//
// 验证从 InstanceManager 拆分出的路径服务组件：
// 1. 路径解析的准确性（mods / config / saves / 等子目录）
// 2. 不存在的实例/目录抛出 ArgumentError
// 3. ensureInstanceDirectories 仅创建缺失的目录

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/instance/instance_path_service.dart';
import 'package:bamclaunch/src/instance/models.dart';

GameInstance _makeInstance({required String id, required String directoryId}) {
  final now = DateTime.now();
  return GameInstance(
    id: id,
    name: 'TestInstance_$id',
    directoryId: directoryId,
    version: '1.20.4',
    config: InstanceConfig(),
    resources: InstanceResources(
      mods: [],
      resourcePacks: [],
      shaderPacks: [],
      worlds: [],
      screenshots: [],
    ),
    createdAt: now,
    updatedAt: now,
  );
}

InstanceDirectory _makeDirectory({required String id, required String path}) {
  final now = DateTime.now();
  return InstanceDirectory(
    id: id,
    name: 'TestDir_$id',
    path: path,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late InstancePathService service;
  late Directory tempDir;
  late List<GameInstance> instances;
  late List<InstanceDirectory> directories;

  setUp(() {
    service = InstancePathService();
    tempDir = Directory.systemTemp.createTempSync('instance_path_test_');
    directories = [_makeDirectory(id: 'dir_1', path: tempDir.path)];
    instances = [_makeInstance(id: 'inst_1', directoryId: 'dir_1')];
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('InstancePathService.getInstancePath', () {
    test('应正确拼接目录 + instances + ID', () {
      final result = service.getInstancePath(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      // 期望: tempDir/instances/inst_1
      expect(
        result.endsWith('instances${Platform.pathSeparator}inst_1'),
        isTrue,
      );
    });

    test('不存在的实例应抛 ArgumentError', () {
      expect(
        () => service.getInstancePath(
          instanceId: 'nonexistent',
          instances: instances,
          directories: directories,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('实例引用不存在的 directoryId 应抛 ArgumentError', () {
      final orphan = _makeInstance(id: 'orphan', directoryId: 'no_dir');
      expect(
        () => service.getInstancePath(
          instanceId: 'orphan',
          instances: [orphan],
          directories: directories,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('InstancePathService 子目录路径', () {
    test('各 getXxxPath 应正确返回对应的子目录', () {
      final baseResult = service.getInstancePath(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      expect(
        service.getInstanceModsPath(
          instanceId: 'inst_1',
          instances: instances,
          directories: directories,
        ),
        equals('$baseResult${Platform.pathSeparator}mods'),
      );

      expect(
        service.getInstanceSavesPath(
          instanceId: 'inst_1',
          instances: instances,
          directories: directories,
        ),
        equals('$baseResult${Platform.pathSeparator}saves'),
      );
    });

    test('getInstanceConfigPath 应包含 config 子目录', () {
      final path = service.getInstanceConfigPath(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );
      expect(path.endsWith('${Platform.pathSeparator}config'), isTrue);
    });
  });

  group('InstancePathService.ensureInstanceDirectories', () {
    test('应创建所有 subDirectories 列表中的目录', () async {
      await service.ensureInstanceDirectories(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      final basePath = service.getInstancePath(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      for (final sub in InstancePathService.subDirectories) {
        expect(
          Directory('$basePath${Platform.pathSeparator}$sub').existsSync(),
          isTrue,
          reason: '应创建子目录 $sub',
        );
      }
    });

    test('目录已存在时不应抛异常（幂等性）', () async {
      await service.ensureInstanceDirectories(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );
      // 第二次调用
      await service.ensureInstanceDirectories(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );

      final basePath = service.getInstancePath(
        instanceId: 'inst_1',
        instances: instances,
        directories: directories,
      );
      expect(
        Directory('$basePath${Platform.pathSeparator}mods').existsSync(),
        isTrue,
      );
    });
  });
}
