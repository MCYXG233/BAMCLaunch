import 'dart:io';
import 'dart:math';
import 'models.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';

/// 资源管理器
/// 负责管理集中化的游戏资源（模组、资源包、存档等）
class ResourceManager {
  static ResourceManager? _instance;
  static const String _resourcesKey = 'centralized_resources';

  final Logger _logger = Logger('ResourceManager');
  final ConfigManager _config = ConfigManager.instance;

  List<ResourceItem> _resources = [];
  bool _isInitialized = false;

  ResourceManager._internal();

  factory ResourceManager() {
    _instance ??= ResourceManager._internal();
    return _instance!;
  }

  static ResourceManager get instance => ResourceManager();

  bool get isInitialized => _isInitialized;
  List<ResourceItem> get resources => List.unmodifiable(_resources);

  /// 初始化管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing ResourceManager...');
      await _loadResources();
      _isInitialized = true;
      _logger.info('ResourceManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize ResourceManager', e, stackTrace);
      rethrow;
    }
  }

  /// 加载资源列表
  Future<void> _loadResources() async {
    try {
      final raw = _config.get<List<dynamic>>(_resourcesKey);
      if (raw != null) {
        _resources = raw.map((e) => ResourceItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _resources = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load resources', e, stackTrace);
      _resources = [];
    }
  }

  /// 保存资源数据
  Future<void> save() async {
    try {
      await _config.set<List<dynamic>>(_resourcesKey, _resources.map((r) => r.toJson()).toList());
      await _config.save();
      _logger.info('Resource data saved successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to save resource data', e, stackTrace);
      rethrow;
    }
  }

  /// 获取指定类型的资源
  List<ResourceItem> getResourcesByType(ResourceType type) {
    return _resources.where((r) => r.type == type).toList();
  }

  /// 获取资源项
  ResourceItem? getResource(String id) {
    try {
      return _resources.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 添加资源
  Future<ResourceItem> addResource({
    required String name,
    required ResourceType type,
    required String path,
    String? source,
    String? version,
  }) async {
    final id = _generateId();
    final now = DateTime.now();

    final resource = ResourceItem(
      id: id,
      name: name,
      type: type,
      path: path,
      source: source,
      version: version,
      createdAt: now,
      linkedInstances: [],
    );

    _resources.add(resource);
    await save();
    _logger.info('Added resource: $name');

    return resource;
  }

  /// 更新资源
  Future<ResourceItem> updateResource({
    required String id,
    String? name,
    String? path,
    String? source,
    String? version,
    List<String>? linkedInstances,
  }) async {
    final index = _resources.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw ArgumentError('Resource not found: $id');
    }

    final resource = _resources[index].copyWith(
      name: name,
      path: path,
      source: source,
      version: version,
      linkedInstances: linkedInstances,
    );

    _resources[index] = resource;
    await save();
    _logger.info('Updated resource: ${resource.name}');

    return resource;
  }

  /// 删除资源
  Future<void> deleteResource(String id) async {
    final index = _resources.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw ArgumentError('Resource not found: $id');
    }

    final resource = _resources[index];
    _resources.removeAt(index);
    await save();
    _logger.info('Deleted resource: ${resource.name}');
  }

  /// 将资源链接到实例
  Future<void> linkResourceToInstance(String resourceId, String instanceId) async {
    final resourceIndex = _resources.indexWhere((r) => r.id == resourceId);
    if (resourceIndex == -1) {
      throw ArgumentError('Resource not found: $resourceId');
    }

    final resource = _resources[resourceIndex];
    final linkedInstances = List<String>.from(resource.linkedInstances ?? []);

    if (!linkedInstances.contains(instanceId)) {
      linkedInstances.add(instanceId);

      final updatedResource = resource.copyWith(
        linkedInstances: linkedInstances,
        lastUsed: DateTime.now(),
      );

      _resources[resourceIndex] = updatedResource;
      await save();
      _logger.info('Linked resource $resourceId to instance $instanceId');
    }
  }

  /// 取消资源与实例的链接
  Future<void> unlinkResourceFromInstance(String resourceId, String instanceId) async {
    final resourceIndex = _resources.indexWhere((r) => r.id == resourceId);
    if (resourceIndex == -1) {
      throw ArgumentError('Resource not found: $resourceId');
    }

    final resource = _resources[resourceIndex];
    final linkedInstances = List<String>.from(resource.linkedInstances ?? []);
    linkedInstances.remove(instanceId);

    final updatedResource = resource.copyWith(linkedInstances: linkedInstances);
    _resources[resourceIndex] = updatedResource;

    await save();
    _logger.info('Unlinked resource $resourceId from instance $instanceId');
  }

  /// 获取实例链接的资源
  List<ResourceItem> getInstanceResources(String instanceId, [ResourceType? type]) {
    final instanceResources = _resources.where((r) => r.linkedInstances?.contains(instanceId) == true).toList();
    if (type != null) {
      return instanceResources.where((r) => r.type == type).toList();
    }
    return instanceResources;
  }

  /// 搜索资源
  List<ResourceItem> searchResources(String query, [ResourceType? type]) {
    final results = _resources.where((r) => r.name.toLowerCase().contains(query.toLowerCase())).toList();
    if (type != null) {
      return results.where((r) => r.type == type).toList();
    }
    return results;
  }

  /// 按来源过滤资源
  List<ResourceItem> getResourcesBySource(String source, [ResourceType? type]) {
    final results = _resources.where((r) => r.source == source).toList();
    if (type != null) {
      return results.where((r) => r.type == type).toList();
    }
    return results;
  }

  /// 按最新使用排序
  List<ResourceItem> getRecentResources([int limit = 20]) {
    final sorted = List<ResourceItem>.from(_resources);
    sorted.sort((a, b) {
      if (a.lastUsed == null) return 1;
      if (b.lastUsed == null) return -1;
      return b.lastUsed!.compareTo(a.lastUsed!);
    });
    return sorted.take(limit).toList();
  }

  /// 复制资源
  Future<ResourceItem> duplicateResource(String resourceId, String newName) async {
    final resource = _resources.firstWhere(
      (r) => r.id == resourceId,
      orElse: () => throw ArgumentError('Resource not found: $resourceId'),
    );

    final id = _generateId();
    final now = DateTime.now();

    final duplicated = resource.copyWith(
      id: id,
      name: newName,
      createdAt: now,
      lastUsed: null,
      linkedInstances: [],
    );

    _resources.add(duplicated);
    await save();
    _logger.info('Duplicated resource: $newName');

    return duplicated;
  }

  /// 批量导入资源
  Future<List<ResourceItem>> importResources(List<Map<String, dynamic>> resourceData) async {
    final imported = <ResourceItem>[];

    for (final data in resourceData) {
      final resource = await addResource(
        name: data['name'] as String,
        type: ResourceType.values.firstWhere(
          (t) => t.name == (data['type'] as String?),
          orElse: () => ResourceType.mod,
        ),
        path: data['path'] as String,
        source: data['source'] as String?,
        version: data['version'] as String?,
      );
      imported.add(resource);
    }

    return imported;
  }

  /// 生成唯一 ID
  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

