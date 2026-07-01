import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'models.dart';

/// 资源管理器
class ResourceManager {
  static ResourceManager? _instance;

  factory ResourceManager() {
    return _instance ??= ResourceManager._internal();
  }

  ResourceManager._internal();

  static ResourceManager get instance =>
      ServiceLocator.instance.tryGet<ResourceManager>() ??
      (_instance ??= ResourceManager._internal());

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger();
  final EventBus _eventBus = EventBus.instance;
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.instance;

  List<InstalledResource> _installedResources = [];
  bool _initialized = false;
  File? _storageFile;

  /// 是否已初始化
  bool get initialized => _initialized;

  /// 已安装的资源列表
  List<InstalledResource> get installedResources => List.unmodifiable(_installedResources);

  /// 初始化资源管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      final resourcesDir = Directory(path.join(supportDir, 'resources'));
      
      if (!await resourcesDir.exists()) {
        await resourcesDir.create(recursive: true);
      }

      _storageFile = File(path.join(resourcesDir.path, 'installed.json'));
      
      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        final data = jsonDecode(content) as List<dynamic>;
        _installedResources = [];
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              _installedResources.add(InstalledResource.fromJson(item));
            }
          } catch (e) {
            _logger.warn('Skipping invalid resource entry: $e');
          }
        }
      }

      _initialized = true;
      _logger.info('ResourceManager initialized with ${_installedResources.length} resources');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize ResourceManager', e, stackTrace);
      rethrow;
    }
  }

  /// 获取资源存储目录
  Future<Directory> getResourceDirectory(ResourceType type) async {
    final supportDir = await _platformAdapter.getApplicationSupportDirectory();
    String typeDir;
    switch (type) {
      case ResourceType.mod:
        typeDir = 'mods';
        break;
      case ResourceType.resourcePack:
        typeDir = 'resourcepacks';
        break;
      case ResourceType.shader:
        typeDir = 'shaderpacks';
        break;
      case ResourceType.dataPack:
        typeDir = 'datapacks';
        break;
      case ResourceType.modpack:
        typeDir = 'modpacks';
        break;
    }
    final dir = Directory(path.join(supportDir, 'resources', typeDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存已安装资源数据
  Future<void> _save() async {
    if (_storageFile == null) return;
    try {
      final data = _installedResources.map((r) => r.toJson()).toList();
      // 原子写入：先写入临时文件，再重命名，防止写入中途崩溃导致数据损坏
      final tempFile = File('${_storageFile!.path}.tmp');
      await tempFile.writeAsString(jsonEncode(data));
      if (await _storageFile!.exists()) {
        await _storageFile!.delete();
      }
      await tempFile.rename(_storageFile!.path);
    } catch (e, stackTrace) {
      _logger.error('Failed to save installed resources', e, stackTrace);
      // 不再 rethrow，内存状态是权威来源，保存失败不影响运行时状态
    }
  }

  /// 添加已安装资源
  Future<void> addInstalledResource(InstalledResource resource) async {
    await initialize();
    _installedResources.add(resource);
    await _save();
    _eventBus.publish(ResourceInstalledEvent(resource: resource));
    _logger.info('Added installed resource: ${resource.name}');
  }

  /// 移除已安装资源
  Future<void> removeInstalledResource(String localId) async {
    await initialize();
    final index = _installedResources.indexWhere((r) => r.localId == localId);
    if (index == -1) return;

    final resource = _installedResources.removeAt(index);
    
    try {
      final file = File(resource.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _logger.warn('Failed to delete resource file: $e');
    }

    await _save();
    _eventBus.publish(ResourceUninstalledEvent(localId: localId));
    _logger.info('Removed installed resource: ${resource.name}');
  }

  /// 启用/禁用资源
  Future<void> toggleResource(String localId, bool enabled) async {
    await initialize();
    final index = _installedResources.indexWhere((r) => r.localId == localId);
    if (index == -1) return;

    _installedResources[index] = _installedResources[index].copyWith(enabled: enabled);
    await _save();
    _eventBus.publish(ResourceToggledEvent(localId: localId, enabled: enabled));
    _logger.info('${enabled ? 'Enabled' : 'Disabled'} resource: ${_installedResources[index].name}');
  }

  /// 根据localId获取已安装资源
  InstalledResource? getInstalledResource(String localId) {
    try {
      return _installedResources.firstWhere((r) => r.localId == localId);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定类型的已安装资源
  List<InstalledResource> getResourcesByType(ResourceType type) {
    return _installedResources.where((r) => r.type == type).toList();
  }

  /// 检查资源是否已安装
  bool isResourceInstalled(String source, String resourceId) {
    final localId = InstalledResource.generateLocalId(source, resourceId);
    return _installedResources.any((r) => r.localId == localId);
  }

  /// 获取已安装资源（通过source和resourceId）
  InstalledResource? getInstalledResourceBySource(String source, String resourceId) {
    final localId = InstalledResource.generateLocalId(source, resourceId);
    return getInstalledResource(localId);
  }
}
