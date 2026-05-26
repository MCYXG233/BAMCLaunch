import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'models.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';

/// 实例管理器
/// 负责管理游戏目录、实例、资源的增删改查
class InstanceManager {
  static InstanceManager? _instance;
  static const String _instancesKey = 'instances';
  static const String _directoriesKey = 'directories';
  static const String _selectedDirectoryKey = 'selectedDirectory';
  static const String _selectedInstanceKey = 'selectedInstance';

  final Logger _logger = Logger('InstanceManager');
  final ConfigManager _config = ConfigManager.instance;

  List<GameDirectory> _directories = [];
  List<GameInstance> _instances = [];
  String? _selectedDirectoryId;
  String? _selectedInstanceId;
  bool _isInitialized = false;

  InstanceManager._internal();

  factory InstanceManager() {
    _instance ??= InstanceManager._internal();
    return _instance!;
  }

  static InstanceManager get instance => InstanceManager();

  bool get isInitialized => _isInitialized;
  List<GameDirectory> get directories => List.unmodifiable(_directories);
  List<GameInstance> get instances => List.unmodifiable(_instances);
  String? get selectedDirectoryId => _selectedDirectoryId;
  String? get selectedInstanceId => _selectedInstanceId;

  /// 获取当前选中的目录
  GameDirectory? get selectedDirectory {
    if (_selectedDirectoryId == null) return null;
    return _directories.firstWhere(
      (d) => d.id == _selectedDirectoryId,
      orElse: () => _directories.isNotEmpty ? _directories.first : throw StateError('No directories found'),
    );
  }

  /// 获取当前选中的实例
  GameInstance? get selectedInstance {
    if (_selectedInstanceId == null) return null;
    return _instances.firstWhere(
      (i) => i.id == _selectedInstanceId,
      orElse: () => _instances.isNotEmpty ? _instances.first : throw StateError('No instances found'),
    );
  }

  /// 获取指定目录的实例
  List<GameInstance> getDirectoryInstances(String directoryId) {
    return _instances.where((i) => i.directoryId == directoryId).toList();
  }

  /// 初始化管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing InstanceManager...');

      await _loadDirectories();
      await _loadInstances();
      await _loadSelectedIds();

      _isInitialized = true;
      _logger.info('InstanceManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize InstanceManager', e, stackTrace);
      rethrow;
    }
  }

  /// 加载目录列表
  Future<void> _loadDirectories() async {
    try {
      final raw = _config.get<List<dynamic>>(_directoriesKey);
      if (raw != null) {
        _directories = raw.map((e) => GameDirectory.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _directories = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load directories', e, stackTrace);
      _directories = [];
    }
  }

  /// 加载实例列表
  Future<void> _loadInstances() async {
    try {
      final raw = _config.get<List<dynamic>>(_instancesKey);
      if (raw != null) {
        _instances = raw.map((e) => GameInstance.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _instances = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load instances', e, stackTrace);
      _instances = [];
    }
  }

  /// 加载选中的 ID
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

  /// 保存数据
  Future<void> save() async {
    try {
      await _config.set<List<dynamic>>(_directoriesKey, _directories.map((d) => d.toJson()).toList());
      await _config.set<List<dynamic>>(_instancesKey, _instances.map((i) => i.toJson()).toList());

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

  /// 创建游戏目录
  Future<GameDirectory> createDirectory({
    required String name,
    required String path,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    final directory = GameDirectory(
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

  /// 更新游戏目录
  Future<GameDirectory> updateDirectory({
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
  Future<void> deleteDirectory(String id) async {
    final index = _directories.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Directory not found: $id');
    }

    final directory = _directories[index];

    _instances.removeWhere((i) => i.directoryId == id);
    _directories.removeAt(index);

    if (_selectedDirectoryId == id) {
      _selectedDirectoryId = _directories.isNotEmpty ? _directories.first.id : null;
      _selectedInstanceId = _instances.isNotEmpty ? _instances.first.id : null;
    }

    await save();
    _logger.info('Deleted directory: ${directory.name}');
  }

  /// 选择游戏目录
  Future<void> selectDirectory(String id) async {
    if (!_directories.any((d) => d.id == id)) {
      throw ArgumentError('Directory not found: $id');
    }

    _selectedDirectoryId = id;

    final dirInstances = getDirectoryInstances(id);
    if (dirInstances.isNotEmpty && !dirInstances.any((i) => i.id == _selectedInstanceId)) {
      _selectedInstanceId = dirInstances.first.id;
    }

    await save();
    _logger.info('Selected directory: $id');
  }

  /// 创建游戏实例
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

    final id = _generateId();
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
      resources: resources ?? InstanceResources(mods: [], resourcePacks: [], shaderPacks: [], worlds: [], screenshots: []),
      createdAt: now,
      updatedAt: now,
    );

    _instances.add(instance);

    if (_selectedDirectoryId == directoryId && _selectedInstanceId == null) {
      _selectedInstanceId = id;
    }

    await save();
    _logger.info('Created instance: $name');

    return instance;
  }

  /// 更新游戏实例
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
  Future<void> deleteInstance(String id) async {
    final index = _instances.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances[index];
    _instances.removeAt(index);

    if (_selectedInstanceId == id) {
      final dirInstances = getDirectoryInstances(instance.directoryId);
      _selectedInstanceId = dirInstances.isNotEmpty ? dirInstances.first.id : null;
    }

    await save();
    _logger.info('Deleted instance: ${instance.name}');
  }

  /// 选择游戏实例
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

  /// 添加资源到实例
  Future<void> addResourceToInstance(String instanceId, String resourceId, ResourceType type) async {
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
    }

    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  /// 从实例移除资源
  Future<void> removeResourceFromInstance(String instanceId, String resourceId, ResourceType type) async {
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
    }

    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  /// 复制实例
  Future<GameInstance> duplicateInstance(String instanceId, String newName) async {
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final id = _generateId();
    final now = DateTime.now();

    final duplicated = instance.copyWith(
      id: id,
      name: newName,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    _instances.add(duplicated);
    await save();
    _logger.info('Duplicated instance: $newName');

    return duplicated;
  }

  /// 生成唯一 ID
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

