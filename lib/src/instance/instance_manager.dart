import 'dart:io';
import 'dart:math';
import 'models.dart';
import 'path_resolver.dart';
import 'instance_path_service.dart';
import 'instance_cloner.dart';
import 'instance_exporter.dart';
import 'instance_importer.dart';
import '../config/config_keys.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';

/// 实例管理器（编排层）
///
/// 该类是一个单例类，负责管理 Minecraft 游戏的目录、实例和资源。
/// 作为编排层，将单一职责委托给以下子组件：
/// - [InstancePathService]：实例路径解析与目录布局管理
/// - [InstanceCloner]：实例复制与磁盘占用统计
/// - [InstanceExporter]：实例导出为 ZIP / Mrpack / BAMC 格式
/// - [InstanceImporter]：从 ZIP / Mrpack 导入实例
///
/// 主类自身保留：
/// - 单例与生命周期管理
/// - 状态字段（_directories / _instances / _selectedDirectoryId / _selectedInstanceId）
/// - 配置持久化（save / load）
/// - 目录与实例 CRUD
/// - 资源挂载（addResourceToInstance / removeResourceFromInstance）
/// - 自动检测（_autoDetectDirectories / _detectInstancesInDirectory）
///
/// 使用方式：
/// ```dart
/// final manager = InstanceManager.instance;
/// await manager.initialize();
/// final directory = await manager.createDirectory(
///   name: '我的游戏目录',
///   path: '/path/to/minecraft',
/// );
/// final instance = await manager.createInstance(
///   name: '我的实例',
///   directoryId: directory.id,
///   version: '1.20.1',
/// );
/// ```
class InstanceManager {
  /// 单例实例
  static InstanceManager? _instance;

  /// 配置文件中存储实例列表的键名
  static const String _instancesKey = 'instances';

  /// 配置文件中存储目录列表的键名
  static const String _directoriesKey = 'directories';

  /// 配置文件中存储选中目录ID的键名
  static const String _selectedDirectoryKey = 'selectedDirectory';

  /// 配置文件中存储选中实例ID的键名
  static const String _selectedInstanceKey = 'selectedInstance';

  /// 日志记录器
  final Logger _logger = Logger('InstanceManager');

  /// 配置管理器，用于持久化存储数据
  final ConfigManager _config = ConfigManager.instance;

  // ==================== 子组件 ====================

  /// 实例路径服务（路径解析与目录布局）
  final InstancePathService _pathService = InstancePathService();

  /// 实例复制服务（复制与大小计算）
  final InstanceCloner _cloner = InstanceCloner();

  // ==================== 状态字段 ====================

  /// 游戏目录列表
  List<InstanceDirectory> _directories = [];

  /// 游戏实例列表
  List<GameInstance> _instances = [];

  /// 当前选中的目录ID
  String? _selectedDirectoryId;

  /// 当前选中的实例ID
  String? _selectedInstanceId;

  /// 标记管理器是否已初始化
  bool _isInitialized = false;

  /// 标记管理器是否正在初始化中（防止并发初始化）
  bool _isInitializing = false;

  /// 私有构造函数（单例模式）
  InstanceManager._internal();

  /// 工厂构造函数，返回单例实例
  factory InstanceManager() {
    _instance ??= InstanceManager._internal();
    return _instance!;
  }

  /// 获取单例实例的静态方法
  ///
  /// 优先通过 [ServiceLocator] 获取，若未注册则回退到本地单例。
  static InstanceManager get instance =>
      ServiceLocator.instance.tryGet<InstanceManager>() ??
      (_instance ??= InstanceManager._internal());

  // ==================== 状态 Getter ====================

  /// 管理器是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取所有游戏目录（不可修改的列表）
  List<InstanceDirectory> get directories => List.unmodifiable(_directories);

  /// 获取所有游戏实例（不可修改的列表）
  List<GameInstance> get instances => List.unmodifiable(_instances);

  /// 获取当前选中的目录ID
  String? get selectedDirectoryId => _selectedDirectoryId;

  /// 获取当前选中的实例ID
  String? get selectedInstanceId => _selectedInstanceId;

  /// 获取当前选中的目录
  ///
  /// 返回值：
  /// - 如果有选中的目录ID，返回对应的目录对象
  /// - 如果选中的目录ID不存在但有其他目录，返回第一个目录
  /// - 如果没有任何目录，返回 null
  InstanceDirectory? get selectedDirectory {
    if (_selectedDirectoryId == null)
      return _directories.isNotEmpty ? _directories.first : null;
    try {
      return _directories.firstWhere((d) => d.id == _selectedDirectoryId);
    } catch (_) {
      return _directories.isNotEmpty ? _directories.first : null;
    }
  }

  /// 获取当前选中的实例
  ///
  /// 返回值：
  /// - 如果有选中的实例ID，返回对应的实例对象
  /// - 如果选中的实例ID不存在但有其他实例，返回第一个实例
  /// - 如果没有任何实例，返回 null
  GameInstance? get selectedInstance {
    if (_selectedInstanceId == null)
      return _instances.isNotEmpty ? _instances.first : null;
    try {
      return _instances.firstWhere((i) => i.id == _selectedInstanceId);
    } catch (_) {
      return _instances.isNotEmpty ? _instances.first : null;
    }
  }

  /// 获取指定目录下的所有实例
  List<GameInstance> getDirectoryInstances(String directoryId) {
    return _instances.where((i) => i.directoryId == directoryId).toList();
  }

  // ==================== 生命周期与初始化 ====================

  /// 初始化管理器
  ///
  /// 该方法必须在使用管理器之前调用。它会：
  /// 1. 从配置文件加载已保存的目录列表
  /// 2. 从配置文件加载已保存的实例列表
  /// 3. 加载上次选中的目录和实例ID
  /// 4. 自动检测系统中常见的 Minecraft 安装目录
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      _logger.info('Initializing InstanceManager...');

      await _loadDirectories();
      await _loadInstances();
      await _loadSelectedIds();
      await _autoDetectDirectories();

      _isInitialized = true;
      _logger.info('InstanceManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize InstanceManager', e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 自动检测常见的 Minecraft 目录和实例
  ///
  /// 候选路径通过 [MinecraftPathResolver] 解析，包含：
  /// - 用户自定义路径（从配置项读取）
  /// - 平台默认路径（Windows APPDATA、macOS Library、Linux ~/.minecraft）
  /// - Windows 常用盘符（C:/D: 上的 Minecraft 目录）
  Future<void> _autoDetectDirectories() async {
    try {
      final customCandidates = <String>[];
      try {
        final configManager = ConfigManager.instance;
        await configManager.initialize();
        final stored = configManager.get<List<dynamic>>(
          ConfigKeys.customGameDirectories,
        );
        if (stored != null) {
          for (final entry in stored) {
            if (entry is String && entry.isNotEmpty) {
              customCandidates.add(entry);
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to load customGameDirectories: $e');
      }

      final resolver = MinecraftPathResolver(
        customCandidates: customCandidates,
      );
      final candidatePaths = resolver.resolveCandidates();

      for (final candidatePath in candidatePaths) {
        if (candidatePath.isEmpty) continue;

        final directory = Directory(candidatePath);
        if (await directory.exists()) {
          final existingDir = _directories.firstWhere(
            (d) => d.path == candidatePath,
            orElse: () => InstanceDirectory(
              id: '',
              name: '',
              path: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          String? dirId;

          if (existingDir.id.isEmpty) {
            _logger.info('Detected new Minecraft directory: $candidatePath');
            final name = _basename(candidatePath);
            final newDir = await createDirectory(
              name: name,
              path: candidatePath,
            );
            dirId = newDir.id;
          } else {
            dirId = existingDir.id;
          }

          if (dirId != null) {
            await _detectInstancesInDirectory(dirId, candidatePath);
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to auto-detect directories', e);
    }
  }

  /// 在指定目录中检测游戏版本并创建实例
  ///
  /// 扫描 `versions` 文件夹，对于每个版本：
  /// 1. 检查是否存在对应的 JSON 文件（如 `1.20.1.json`）
  /// 2. 如果存在且该版本尚未创建实例，则自动创建实例记录
  Future<void> _detectInstancesInDirectory(
    String directoryId,
    String directoryPath,
  ) async {
    try {
      final versionsDir = Directory(_joinPath(directoryPath, 'versions'));
      if (!await versionsDir.exists()) {
        return;
      }

      final versionDirs = await versionsDir
          .list()
          .where((entity) => entity is Directory)
          .toList();

      for (final versionDir in versionDirs) {
        final versionName = _basename(versionDir.path);
        final jsonFile = File(
          _joinPath(versionDir.path, '$versionName.json'),
        );

        if (await jsonFile.exists()) {
          final exists = _instances.any(
            (i) => i.directoryId == directoryId && i.version == versionName,
          );

          if (!exists) {
            _logger.info(
              'Detected Minecraft version: $versionName in $directoryPath',
            );
            await createInstance(
              name: versionName,
              directoryId: directoryId,
              version: versionName,
              description: '自动检测到的 $versionName 版本',
            );
          }
        }
      }
    } catch (e) {
      _logger.warning(
        'Failed to detect instances in directory: $directoryPath',
        e,
      );
    }
  }

  // ==================== 配置持久化 ====================

  /// 从配置文件加载目录列表
  Future<void> _loadDirectories() async {
    try {
      final raw = _config.get<List<dynamic>>(_directoriesKey);
      if (raw != null) {
        _directories = raw
            .map((e) => InstanceDirectory.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _directories = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load directories', e, stackTrace);
      _directories = [];
    }
  }

  /// 从配置文件加载实例列表
  Future<void> _loadInstances() async {
    try {
      final raw = _config.get<List<dynamic>>(_instancesKey);
      if (raw != null) {
        _instances = raw
            .map((e) => GameInstance.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _instances = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load instances', e, stackTrace);
      _instances = [];
    }
  }

  /// 从配置文件加载选中的ID
  Future<void> _loadSelectedIds() async {
    _selectedDirectoryId = _config.getString(_selectedDirectoryKey);
    _selectedInstanceId = _config.getString(_selectedInstanceKey);

    if (_directories.isNotEmpty && _selectedDirectoryId == null) {
      _selectedDirectoryId = _directories.first.id;
    }

    if (_instances.isNotEmpty && _selectedInstanceId == null) {
      _selectedInstanceId = _instances.first.id;
    }
  }

  /// 保存所有数据到配置文件
  ///
  /// 将当前的目录列表、实例列表、选中的ID等数据保存到配置文件中，
  /// 以便下次启动时恢复状态。
  Future<void> save() async {
    try {
      await _config.set<List<dynamic>>(
        _directoriesKey,
        _directories.map((d) => d.toJson()).toList(),
      );
      await _config.set<List<dynamic>>(
        _instancesKey,
        _instances.map((i) => i.toJson()).toList(),
      );

      if (_selectedDirectoryId != null) {
        await _config.setString(_selectedDirectoryKey, _selectedDirectoryId!);
      }

      if (_selectedInstanceId != null) {
        await _config.setString(_selectedInstanceKey, _selectedInstanceId!);
      }

      await _config.save();
      _logger.info('Instance data saved successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to save instance data', e, stackTrace);
      rethrow;
    }
  }

  // ==================== 目录 CRUD ====================

  /// 创建新的游戏目录
  ///
  /// 参数：
  /// - [name]：目录名称，用于显示
  /// - [path]：目录的文件系统路径
  ///
  /// 返回值：
  /// - 返回新创建的 [InstanceDirectory] 对象
  ///
  /// 注意：
  /// - 如果这是第一个创建的目录，会自动将其设为选中状态
  /// - 创建后会自动保存到配置文件
  Future<InstanceDirectory> createDirectory({
    required String name,
    required String path,
  }) async {
    final id = generateId();
    final now = DateTime.now();

    final directory = InstanceDirectory(
      id: id,
      name: name,
      path: path,
      createdAt: now,
      updatedAt: now,
    );

    _directories.add(directory);

    if (_directories.length == 1) {
      _selectedDirectoryId = id;
    }

    await save();
    _logger.info('Created directory: $name at $path');

    return directory;
  }

  /// 更新游戏目录信息
  ///
  /// 参数：
  /// - [id]：要更新的目录ID
  /// - [name]：新的目录名称（可选）
  /// - [path]：新的目录路径（可选）
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  Future<InstanceDirectory> updateDirectory({
    required String id,
    String? name,
    String? path,
  }) async {
    final index = _directories.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Directory not found: $id');
    }

    final directory = _directories[index].copyWith(
      name: name,
      path: path,
      updatedAt: DateTime.now(),
    );

    _directories[index] = directory;
    await save();
    _logger.info('Updated directory: ${directory.name}');

    return directory;
  }

  /// 删除游戏目录
  ///
  /// 参数：
  /// - [id]：要删除的目录ID
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  ///
  /// 注意：
  /// - 删除目录会同时删除该目录下的所有实例
  /// - 如果删除的是当前选中的目录，会自动选中第一个可用目录
  Future<void> deleteDirectory(String id) async {
    final index = _directories.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Directory not found: $id');
    }

    final directory = _directories[index];

    _instances.removeWhere((i) => i.directoryId == id);
    _directories.removeAt(index);

    if (_selectedDirectoryId == id) {
      _selectedDirectoryId = _directories.isNotEmpty
          ? _directories.first.id
          : null;
      _selectedInstanceId = _instances.isNotEmpty ? _instances.first.id : null;
    }

    await save();
    _logger.info('Deleted directory: ${directory.name}');
  }

  /// 选择游戏目录
  ///
  /// 参数：
  /// - [id]：要选择的目录ID
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  ///
  /// 注意：
  /// - 选择目录时，如果当前选中的实例不在该目录下，
  ///   会自动选中该目录下的第一个实例
  Future<void> selectDirectory(String id) async {
    if (!_directories.any((d) => d.id == id)) {
      throw ArgumentError('Directory not found: $id');
    }

    _selectedDirectoryId = id;

    final dirInstances = getDirectoryInstances(id);
    if (dirInstances.isNotEmpty &&
        !dirInstances.any((i) => i.id == _selectedInstanceId)) {
      _selectedInstanceId = dirInstances.first.id;
    }

    await save();
    _logger.info('Selected directory: $id');
  }

  // ==================== 实例 CRUD ====================

  /// 创建新的游戏实例
  ///
  /// 参数：
  /// - [name]：实例名称
  /// - [directoryId]：所属目录ID
  /// - [version]：Minecraft 版本号
  /// - [loader]：模组加载器类型（如 'forge', 'fabric'，可选）
  /// - [loaderVersion]：模组加载器版本（可选）
  /// - [icon]：实例图标路径（可选）
  /// - [description]：实例描述（可选）
  /// - [config]：实例配置（可选，默认为空配置）
  /// - [resources]：实例资源（可选，默认为空资源列表）
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  ///
  /// 注意：
  /// - 创建实例时会自动创建实例所需的所有子目录
  /// - 如果实例属于当前选中的目录且没有选中的实例，会自动选中该实例
  Future<GameInstance> createInstance({
    required String name,
    required String directoryId,
    required String version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceConfig? config,
    InstanceResources? resources,
  }) async {
    if (!_directories.any((d) => d.id == directoryId)) {
      throw ArgumentError('Directory not found: $directoryId');
    }

    final id = generateId();
    final now = DateTime.now();

    final instance = GameInstance(
      id: id,
      name: name,
      directoryId: directoryId,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      config: config ?? InstanceConfig(),
      resources:
          resources ??
          InstanceResources(
            mods: [],
            resourcePacks: [],
            shaderPacks: [],
            worlds: [],
            screenshots: [],
          ),
      createdAt: now,
      updatedAt: now,
    );

    _instances.add(instance);

    if (_selectedDirectoryId == directoryId && _selectedInstanceId == null) {
      _selectedInstanceId = id;
    }

    await ensureInstanceDirectories(id);
    await save();
    _logger.info('Created instance: $name');

    return instance;
  }

  /// 更新游戏实例信息
  ///
  /// 参数：
  /// - [id]：要更新的实例ID
  /// - 其他可选参数：需要更新的字段
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  Future<GameInstance> updateInstance({
    required String id,
    String? name,
    String? version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceStatus? status,
    InstanceConfig? config,
    InstanceResources? resources,
    DateTime? lastPlayed,
    int? playTimeSeconds,
  }) async {
    final index = _instances.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances[index].copyWith(
      name: name,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      status: status,
      config: config,
      resources: resources,
      updatedAt: DateTime.now(),
      lastPlayed: lastPlayed,
      playTimeSeconds: playTimeSeconds,
    );

    _instances[index] = instance;
    await save();
    _logger.info('Updated instance: ${instance.name}');

    return instance;
  }

  /// 删除游戏实例
  ///
  /// 参数：
  /// - [id]：要删除的实例ID
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  ///
  /// 注意：
  /// - 如果删除的是当前选中的实例，会自动选中同目录下的第一个可用实例
  /// - 该方法只删除实例记录，不会删除实际的文件
  Future<void> deleteInstance(String id) async {
    final index = _instances.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances[index];
    _instances.removeAt(index);

    if (_selectedInstanceId == id) {
      final dirInstances = getDirectoryInstances(instance.directoryId);
      _selectedInstanceId = dirInstances.isNotEmpty
          ? dirInstances.first.id
          : null;
    }

    await save();
    _logger.info('Deleted instance: ${instance.name}');
  }

  /// 选择游戏实例
  ///
  /// 参数：
  /// - [id]：要选择的实例ID
  ///
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  ///
  /// 注意：
  /// - 选择实例时会自动选中实例所属的目录
  Future<void> selectInstance(String id) async {
    if (!_instances.any((i) => i.id == id)) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances.firstWhere((i) => i.id == id);
    _selectedInstanceId = id;
    _selectedDirectoryId = instance.directoryId;

    await save();
    _logger.info('Selected instance: $id');
  }

  // ==================== 路径服务（委托给 InstancePathService） ====================

  /// 获取实例的根目录路径
  ///
  /// 返回值格式：`{目录路径}/instances/{实例ID}`
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  String getInstancePath(String instanceId) {
    return _pathService.getInstancePath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 mods 目录路径
  String getInstanceModsPath(String instanceId) {
    return _pathService.getInstanceModsPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 config 目录路径
  String getInstanceConfigPath(String instanceId) {
    return _pathService.getInstanceConfigPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 saves（存档）目录路径
  String getInstanceSavesPath(String instanceId) {
    return _pathService.getInstanceSavesPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 resourcepacks（资源包）目录路径
  String getInstanceResourcePacksPath(String instanceId) {
    return _pathService.getInstanceResourcePacksPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 shaderpacks（光影包）目录路径
  String getInstanceShaderPacksPath(String instanceId) {
    return _pathService.getInstanceShaderPacksPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 screenshots（截图）目录路径
  String getInstanceScreenshotsPath(String instanceId) {
    return _pathService.getInstanceScreenshotsPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 获取实例的 logs（日志）目录路径
  String getInstanceLogsPath(String instanceId) {
    return _pathService.getInstanceLogsPath(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  /// 确保实例的所有必要目录都存在
  ///
  /// 创建以下子目录：mods / config / saves / resourcepacks / shaderpacks / screenshots / logs
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在（由 [getInstancePath] 抛出）
  Future<void> ensureInstanceDirectories(String instanceId) async {
    await _pathService.ensureInstanceDirectories(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  // ==================== 资源挂载 ====================

  /// 添加资源到实例
  ///
  /// 将资源ID添加到实例的资源列表中。根据资源类型，
  /// 资源ID会被添加到对应的列表中（mods、resourcePacks等）。
  ///
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [resourceId]：资源ID
  /// - [type]：资源类型（mod、resourcePack、shaderPack、world、screenshot）
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在
  ///
  /// 注意：
  /// - 如果资源ID已存在于列表中，不会重复添加
  Future<void> addResourceToInstance(
    String instanceId,
    String resourceId,
    ResourceType type,
  ) async {
    final instanceIndex = _instances.indexWhere((i) => i.id == instanceId);
    if (instanceIndex == -1) {
      throw ArgumentError('Instance not found: $instanceId');
    }

    final instance = _instances[instanceIndex];
    final updatedResources = instance.resources.copyWith();

    switch (type) {
      case ResourceType.mod:
        if (!updatedResources.mods.contains(resourceId)) {
          updatedResources.mods.add(resourceId);
        }
        break;
      case ResourceType.resourcePack:
        if (!updatedResources.resourcePacks.contains(resourceId)) {
          updatedResources.resourcePacks.add(resourceId);
        }
        break;
      case ResourceType.shaderPack:
        if (!updatedResources.shaderPacks.contains(resourceId)) {
          updatedResources.shaderPacks.add(resourceId);
        }
        break;
      case ResourceType.world:
        if (!updatedResources.worlds.contains(resourceId)) {
          updatedResources.worlds.add(resourceId);
        }
        break;
      case ResourceType.screenshot:
        if (!updatedResources.screenshots.contains(resourceId)) {
          updatedResources.screenshots.add(resourceId);
        }
        break;
      case ResourceType.modpack:
      case ResourceType.dataPack:
        // modpack/dataPack 不直接挂载到实例资源列表，由整合包/数据安装器处理
        break;
    }

    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  /// 从实例移除资源
  ///
  /// 从实例的资源列表中移除指定的资源ID。
  ///
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [resourceId]：要移除的资源ID
  /// - [type]：资源类型
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在
  ///
  /// 注意：
  /// - 如果资源ID不存在于列表中，操作会被忽略
  Future<void> removeResourceFromInstance(
    String instanceId,
    String resourceId,
    ResourceType type,
  ) async {
    final instanceIndex = _instances.indexWhere((i) => i.id == instanceId);
    if (instanceIndex == -1) {
      throw ArgumentError('Instance not found: $instanceId');
    }

    final instance = _instances[instanceIndex];
    final updatedResources = instance.resources.copyWith();

    switch (type) {
      case ResourceType.mod:
        updatedResources.mods.remove(resourceId);
        break;
      case ResourceType.resourcePack:
        updatedResources.resourcePacks.remove(resourceId);
        break;
      case ResourceType.shaderPack:
        updatedResources.shaderPacks.remove(resourceId);
        break;
      case ResourceType.world:
        updatedResources.worlds.remove(resourceId);
        break;
      case ResourceType.screenshot:
        updatedResources.screenshots.remove(resourceId);
        break;
      case ResourceType.modpack:
      case ResourceType.dataPack:
        // modpack/dataPack 没有挂载到实例资源列表，无需移除
        break;
    }

    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  // ==================== 实例复制（委托给 InstanceCloner） ====================

  /// 复制实例
  ///
  /// 在同一目录下创建实例的副本，可选择是否复制实例文件。
  ///
  /// 参数：
  /// - [instanceId]：要复制的实例ID
  /// - [newName]：新实例的名称
  /// - [copyFiles]：是否复制实例文件（默认为 true）
  /// - [options]：复制选项，可指定要排除的目录和文件
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  Future<GameInstance> duplicateInstance(
    String instanceId,
    String newName, {
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    final duplicated = await _cloner.duplicateInstance(
      instanceId: instanceId,
      newName: newName,
      instances: _instances,
      directories: _directories,
      generateId: generateId,
      copyFiles: copyFiles,
      options: options,
    );
    await save();
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
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或目标目录ID不存在
  Future<GameInstance> duplicateInstanceToDirectory(
    String instanceId,
    String newName,
    String targetDirectoryId, {
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    final duplicated = await _cloner.duplicateInstanceToDirectory(
      instanceId: instanceId,
      newName: newName,
      targetDirectoryId: targetDirectoryId,
      instances: _instances,
      directories: _directories,
      generateId: generateId,
      copyFiles: copyFiles,
      options: options,
    );
    await save();
    return duplicated;
  }

  /// 计算实例的磁盘占用大小
  ///
  /// 返回值：
  /// - 返回实例目录的总大小（字节）
  /// - 如果实例目录不存在，返回 0
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  Future<int> getInstanceSize(String instanceId) async {
    return _cloner.getInstanceSize(
      instanceId: instanceId,
      instances: _instances,
      directories: _directories,
    );
  }

  // ==================== 工具方法 ====================

  /// 生成唯一ID
  ///
  /// 生成一个32字符的十六进制字符串作为唯一标识符。
  /// 使用加密安全的随机数生成器确保ID的唯一性。
  String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 添加实例（用于导入）
  ///
  /// 直接将一个已构建好的实例对象添加到管理器中。
  /// 通常用于从外部导入实例数据。
  ///
  /// 参数：
  /// - [instance]：要添加的实例对象
  ///
  /// 注意：
  /// - 该方法会自动创建实例所需的目录
  /// - 实例ID应该已经设置好，不会重新生成
  Future<GameInstance> addInstance(GameInstance instance) async {
    _instances.add(instance);
    await ensureInstanceDirectories(instance.id);
    await save();
    _logger.info('Added instance: ${instance.name}');
    return instance;
  }

  // ==================== 导入导出（委托给 InstanceExporter / InstanceImporter） ====================

  /// 导出实例为ZIP文件
  ///
  /// 委托给 [InstanceExporter.exportInstance]，使用 BAMC 格式与默认选项。
  /// 保留旧签名 `(instanceId, exportPath)` 以维持向后兼容。
  ///
  /// 参数：
  /// - [instanceId]：要导出的实例ID
  /// - [exportPath]：导出文件的路径（ZIP文件路径）
  ///
  /// 返回值：
  /// - 返回创建的ZIP文件对象
  ///
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  Future<File> exportInstance(String instanceId, String exportPath) async {
    final resultPath = await InstanceExporter.exportInstance(
      instanceId: instanceId,
      outputPath: exportPath,
      format: InstanceExportFormat.bamc,
      options: const InstanceExportOptions(),
    );
    _logger.info('Exported instance: $instanceId -> $resultPath');
    return File(resultPath);
  }

  /// 从ZIP文件导入实例
  ///
  /// 委托给 [InstanceImporter.importFromZip]，使用默认冲突处理策略（rename）。
  /// 保留旧签名 `(zipPath, directoryId)` 以维持向后兼容。
  ///
  /// 参数：
  /// - [zipPath]：ZIP文件的路径
  /// - [directoryId]：目标目录ID
  ///
  /// 返回值：
  /// - 返回导入的实例对象
  ///
  /// 异常：
  /// - [ArgumentError]：如果目标目录ID不存在，或ZIP文件格式无效
  Future<GameInstance> importInstance(
    String zipPath,
    String directoryId,
  ) async {
    final result = await InstanceImporter.importFromZip(
      zipPath: zipPath,
      options: InstanceImportOptions(targetDirectoryId: directoryId),
    );
    _logger.info('Imported instance: ${result.instance.id}');
    return result.instance;
  }

  /// 从Mrpack文件导入实例
  ///
  /// 委托给 [InstanceImporter.importFromMrpack]。
  /// 保留旧签名 `(mrpackPath, directoryId, {customName})` 以维持向后兼容。
  ///
  /// 参数：
  /// - [mrpackPath]：mrpack 文件的路径
  /// - [directoryId]：目标目录ID
  /// - [customName]：自定义实例名称（可选，默认使用模组包名称）
  ///
  /// 返回值：
  /// - 返回导入的实例对象
  ///
  /// 异常：
  /// - [ArgumentError]：如果目标目录ID不存在，或mrpack文件格式无效
  Future<GameInstance> importFromMrpack(
    String mrpackPath,
    String directoryId, {
    String? customName,
  }) async {
    final result = await InstanceImporter.importFromMrpack(
      mrpackPath: mrpackPath,
      options: InstanceImportOptions(
        targetDirectoryId: directoryId,
        customName: customName,
      ),
    );
    _logger.info('Imported mrpack instance: ${result.instance.id}');
    return result.instance;
  }

  /// 从实例数据创建实例（用于导入后重建实例）
  ///
  /// 该方法是 [createInstance] 的包装方法，提供更明确的语义。
  Future<GameInstance> createInstanceFromData({
    required String name,
    required String directoryId,
    required String version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceConfig? config,
    InstanceResources? resources,
  }) async {
    return createInstance(
      name: name,
      directoryId: directoryId,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      config: config,
      resources: resources,
    );
  }

  // ==================== 路径工具（避免 import package:path） ====================

  /// 拼接路径（使用正斜杠，由调用方按需转换）
  String _joinPath(String part1, String part2) {
    if (part1.isEmpty) return part2;
    if (part1.endsWith('/') || part1.endsWith('\\')) {
      return '$part1$part2';
    }
    return '$part1/$part2';
  }

  /// 获取路径的最后一部分（文件/目录名）
  String _basename(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash == -1) return filePath;
    return normalized.substring(lastSlash + 1);
  }
}
