import 'dart:io';
import 'package:path/path.dart' as path;
import 'models.dart';

/// 实例路径服务
///
/// 负责计算实例的各种子目录路径，并确保目录存在。
/// 从 InstanceManager 拆分而出，单一职责：路径解析与目录布局管理。
class InstancePathService {
  /// 实例下需要管理的子目录列表
  static const List<String> subDirectories = [
    'mods',
    'config',
    'saves',
    'resourcepacks',
    'shaderpacks',
    'screenshots',
    'logs',
  ];

  /// 根据实例列表和目录列表，计算指定实例的根路径
  ///
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [instances]：实例列表（用于查找实例）
  /// - [directories]：目录列表（用于查找实例所属目录）
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  String getInstancePath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );
    final directory = directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () =>
          throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );
    return path.join(directory.path, 'instances', instance.id);
  }

  /// 计算实例的 mods 目录路径
  String getInstanceModsPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'mods',
    );
  }

  /// 计算实例的 config 目录路径
  String getInstanceConfigPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'config',
    );
  }

  /// 计算实例的 saves（存档）目录路径
  String getInstanceSavesPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'saves',
    );
  }

  /// 计算实例的 resourcepacks（资源包）目录路径
  String getInstanceResourcePacksPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'resourcepacks',
    );
  }

  /// 计算实例的 shaderpacks（光影包）目录路径
  String getInstanceShaderPacksPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'shaderpacks',
    );
  }

  /// 计算实例的 screenshots（截图）目录路径
  String getInstanceScreenshotsPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'screenshots',
    );
  }

  /// 计算实例的 logs（日志）目录路径
  String getInstanceLogsPath({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) {
    return path.join(
      getInstancePath(
        instanceId: instanceId,
        instances: instances,
        directories: directories,
      ),
      'logs',
    );
  }

  /// 确保实例的所有必要目录都存在
  ///
  /// 创建以下子目录：mods / config / saves / resourcepacks / shaderpacks / screenshots / logs
  ///
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [instances]：实例列表
  /// - [directories]：目录列表
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在（由 [getInstancePath] 抛出）
  Future<void> ensureInstanceDirectories({
    required String instanceId,
    required List<GameInstance> instances,
    required List<InstanceDirectory> directories,
  }) async {
    final basePath = getInstancePath(
      instanceId: instanceId,
      instances: instances,
      directories: directories,
    );
    for (final subDir in subDirectories) {
      final directory = Directory(path.join(basePath, subDir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }
}
