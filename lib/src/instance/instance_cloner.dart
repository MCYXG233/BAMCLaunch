import 'dart:io';
import 'package:path/path.dart' as path;
import 'models.dart';
import '../core/logger.dart';

/// 实例复制服务
///
/// 负责实例的复制（同目录 / 跨目录）和磁盘占用统计。
/// 从 InstanceManager 拆分而出，单一职责：实例复制与大小计算。
class InstanceCloner {
  final Logger _logger = Logger('InstanceCloner');

  /// 复制实例（在同一目录下创建副本）
  ///
  /// 参数：
  /// - [instanceId]：要复制的实例ID
  /// - [newName]：新实例的名称
  /// - [copyFiles]：是否复制实例文件（默认为 true）
  /// - [options]：复制选项
  /// - [instances]：实例列表（用于查找原实例，且新实例会被加入此列表）
  /// - [directories]：目录列表（用于查找所属目录）
  /// - [generateId]：ID 生成函数（由调用方注入，避免与 InstanceManager.generateId 耦合）
  ///
  /// 返回值：
  /// - 返回新创建的 [GameInstance] 对象
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  Future<GameInstance> duplicateInstance({
    required String instanceId,
    required String newName,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
    required String Function() generateId,
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    // 获取原实例
    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    // 获取所属目录
    final directory = directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () =>
          throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );

    // 生成新ID
    final id = generateId();
    final now = DateTime.now();

    // 创建副本（重置ID、名称、时间和统计数据）
    final duplicated = instance.copyWith(
      id: id,
      name: newName,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    instances.add(duplicated);

    // 复制实例文件
    if (copyFiles) {
      try {
        final sourceDir = Directory(
          path.join(directory.path, 'instances', instance.id),
        );
        final targetDir = Directory(path.join(directory.path, 'instances', id));

        if (await sourceDir.exists()) {
          await _copyDirectory(sourceDir, targetDir, options: options);
          _logger.info('Copied instance files: ${instance.id} -> $id');
        }

        // 如果指定，复制版本目录（仅当源和目标路径不同时）
        if (options?.copyVersionDir ?? false) {
          final sourceVersionDir = Directory(
            path.join(directory.path, 'versions', instance.version),
          );
          final targetVersionDir = Directory(
            path.join(directory.path, 'versions', instance.version),
          );

          if (await sourceVersionDir.exists() &&
              sourceVersionDir.path != targetVersionDir.path) {
            await _copyDirectory(
              sourceVersionDir,
              targetVersionDir,
              options: options,
            );
            _logger.info('Copied version directory: ${instance.version}');
          }
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to copy instance files', e, stackTrace);
      }
    }

    _logger.info('Duplicated instance: $newName');

    return duplicated;
  }

  /// 复制实例到指定目录
  ///
  /// 将实例复制到另一个游戏目录下。
  ///
  /// 参数：
  /// - [instanceId]：要复制的实例ID
  /// - [newName]：新实例的名称
  /// - [targetDirectoryId]：目标目录ID
  /// - [copyFiles]：是否复制实例文件（默认为 true）
  /// - [options]：复制选项
  /// - [instances]：实例列表
  /// - [directories]：目录列表
  /// - [generateId]：ID 生成函数
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或目标目录ID不存在
  Future<GameInstance> duplicateInstanceToDirectory({
    required String instanceId,
    required String newName,
    required String targetDirectoryId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
    required String Function() generateId,
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    // 获取原实例
    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    // 获取目标目录
    final targetDirectory = directories.firstWhere(
      (d) => d.id == targetDirectoryId,
      orElse: () =>
          throw ArgumentError('Directory not found: $targetDirectoryId'),
    );

    // 生成新ID
    final id = generateId();
    final now = DateTime.now();

    // 创建副本（更新目录ID）
    final duplicated = instance.copyWith(
      id: id,
      name: newName,
      directoryId: targetDirectoryId,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    instances.add(duplicated);

    // 复制实例文件到目标目录
    if (copyFiles) {
      try {
        final sourceDir = Directory(
          path.join(
            directories.firstWhere((d) => d.id == instance.directoryId).path,
            'instances',
            instance.id,
          ),
        );
        final targetDir = Directory(
          path.join(targetDirectory.path, 'instances', id),
        );

        if (await sourceDir.exists()) {
          await _copyDirectory(sourceDir, targetDir, options: options);
          _logger.info(
            'Copied instance files to new directory: ${instance.id} -> $id',
          );
        }

        // 如果指定，复制版本目录
        if (options?.copyVersionDir ?? false) {
          final sourceVersionDir = Directory(
            path.join(
              directories.firstWhere((d) => d.id == instance.directoryId).path,
              'versions',
              instance.version,
            ),
          );
          final targetVersionDir = Directory(
            path.join(targetDirectory.path, 'versions', instance.version),
          );

          if (await sourceVersionDir.exists()) {
            await _copyDirectory(
              sourceVersionDir,
              targetVersionDir,
              options: options,
            );
          }
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to copy instance files', e, stackTrace);
      }
    }

    _logger.info(
      'Duplicated instance: $newName to directory: ${targetDirectory.name}',
    );

    return duplicated;
  }

  /// 计算实例的磁盘占用大小
  ///
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [instances]：实例列表
  /// - [directories]：目录列表
  ///
  /// 返回值：
  /// - 返回实例目录的总大小（字节）
  /// - 如果实例目录不存在，返回 0
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  Future<int> getInstanceSize({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) async {
    // 获取实例和目录
    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final directory = directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () =>
          throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );

    // 检查实例目录是否存在
    final instanceDir = Directory(
      path.join(directory.path, 'instances', instance.id),
    );
    if (!await instanceDir.exists()) {
      return 0;
    }

    // 计算总大小
    int totalSize = 0;
    await for (final entity in instanceDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// 递归复制源目录到目标目录，支持排除特定的目录和文件。
  ///
  /// 参数：
  /// - [source]：源目录
  /// - [target]：目标目录
  /// - [options]：复制选项（可选）
  ///
  /// 注意：
  /// - 如果目标目录不存在，会自动创建
  Future<void> _copyDirectory(
    Directory source,
    Directory target, {
    CopyOptions? options,
  }) async {
    // 创建目标目录（如果不存在）
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    // 遍历源目录
    await for (final entity in source.list()) {
      final targetPath = path.join(target.path, path.basename(entity.path));

      // 处理目录
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        // 检查是否应该排除该目录
        if (options != null && options.excludeDirs.contains(dirName)) {
          continue;
        }
        await _copyDirectory(entity, Directory(targetPath), options: options);
      }
      // 处理文件
      else if (entity is File) {
        final fileName = path.basename(entity.path);
        // 检查是否应该排除该文件
        if (options != null && options.excludeFiles.contains(fileName)) {
          continue;
        }
        await entity.copy(targetPath);
      }
    }
  }
}
