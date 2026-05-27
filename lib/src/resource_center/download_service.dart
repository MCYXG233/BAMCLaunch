import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../download/download_engine.dart';
import '../download/models.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../instance/models.dart' as instance_models;
import '../core/error_codes.dart';
import '../core/network_client.dart';
import '../core/retry_helper.dart';
import '../instance/instance_manager.dart';
import 'models.dart';
import 'resource_manager.dart';

/// 下载任务状态
enum DownloadTaskStatus {
  /// 等待中
  pending,

  /// 下载中
  downloading,

  /// 已完成
  completed,

  /// 已失败
  failed,

  /// 已取消
  cancelled,

  /// 安装中
  installing,
}

/// 资源下载任务
class ResourceDownloadTask {
  /// 任务ID
  final String taskId;

  /// 资源信息
  final Resource resource;

  /// 要下载的版本
  final ResourceVersion version;

  /// 下载状态
  DownloadTaskStatus status;

  /// 下载进度 (0.0 - 1.0)
  double progress;

  /// 错误信息
  String? error;

  /// 保存路径
  String? savePath;

  /// 目标实例ID（如果需要安装到特定实例）
  final String? targetInstanceId;

  /// 创建下载任务
  ResourceDownloadTask({
    required this.taskId,
    required this.resource,
    required this.version,
    this.status = DownloadTaskStatus.pending,
    this.progress = 0.0,
    this.error,
    this.savePath,
    this.targetInstanceId,
  });
}

/// 下载服务
class DownloadService {
  static DownloadService? _instance;

  factory DownloadService() {
    return _instance ??= DownloadService._internal();
  }

  DownloadService._internal();

  static DownloadService get instance => _instance ??= DownloadService._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger();
  final EventBus _eventBus = EventBus.instance;
  final DownloadEngine _downloadEngine = DownloadEngine();
  final ResourceManager _resourceManager = ResourceManager();
  final InstanceManager _instanceManager = InstanceManager();

  final Map<String, ResourceDownloadTask> _activeTasks = {};
  final List<ResourceDownloadTask> _completedTasks = [];

  bool _initialized = false;
  StreamSubscription? _progressSubscription;

  /// 下载进度回调
  final Map<String, void Function(double)> _progressCallbacks = {};

  /// 获取活跃的下载任务
  List<ResourceDownloadTask> get activeTasks => List.unmodifiable(_activeTasks.values);

  /// 获取已完成的下载任务
  List<ResourceDownloadTask> get completedTasks => List.unmodifiable(_completedTasks);

  /// 初始化下载服务
  Future<void> initialize() async {
    if (_initialized) return;

    await _resourceManager.initialize();

    _progressSubscription = _downloadEngine.progressStream.listen(_onDownloadProgress);

    _initialized = true;
    _logger.info('DownloadService initialized');
  }

  /// 处理下载进度
  void _onDownloadProgress(DownloadProgress progress) {
    if (_activeTasks.isNotEmpty) {
      final task = _activeTasks.values.first;
      task.progress = progress.progress;
      _eventBus.publish(ResourceDownloadProgressEvent(
        resourceId: task.resource.id,
        versionId: task.version.id,
        progress: progress,
      ));
    }
  }

  /// 下载资源
  Future<InstalledResource> downloadResource(
    Resource resource,
    ResourceVersion version,
  ) async {
    await initialize();

    final taskId = _generateTaskId(resource.id, version.id);

    if (_activeTasks.containsKey(taskId)) {
      throw Exception('Resource is already downloading');
    }

    final task = ResourceDownloadTask(
      taskId: taskId,
      resource: resource,
      version: version,
      status: DownloadTaskStatus.downloading,
    );

    _activeTasks[taskId] = task;

    _eventBus.publish(DownloadResourceEvent(resource: resource, version: version));
    _eventBus.publish(ResourceDownloadStartedEvent(
      resourceId: resource.id,
      versionId: version.id,
      taskId: taskId,
    ));

    _logger.info('Starting download: ${resource.name} v${version.versionNumber}');

    try {
      final saveDir = await _resourceManager.getResourceDirectory(resource.type);
      final fileName = version.download.fileName;
      final savePath = path.join(saveDir.path, fileName);

      task.savePath = savePath;

      await _downloadEngine.download(
        version.download.url,
        savePath,
        hash: version.download.sha1,
        hashType: HashType.sha1,
      );

      task.status = DownloadTaskStatus.completed;
      task.progress = 1.0;

      _completedTasks.add(task);
      _activeTasks.remove(taskId);

      final installedResource = InstalledResource(
        localId: InstalledResource.generateLocalId(resource.source, resource.id),
        resourceId: resource.id,
        source: resource.source,
        type: resource.type,
        name: resource.name,
        installedVersion: version.versionNumber,
        versionId: version.id,
        filePath: savePath,
        fileSize: version.download.fileSize,
        installedAt: DateTime.now(),
        iconUrl: resource.iconUrl,
      );

      await _resourceManager.addInstalledResource(installedResource);

      _eventBus.publish(ResourceDownloadCompletedEvent(
        resourceId: resource.id,
        versionId: version.id,
        savePath: savePath,
      ));

      _logger.info('Download completed: ${resource.name}');

      return installedResource;
    } catch (e, stackTrace) {
      task.status = DownloadTaskStatus.failed;
      task.error = e.toString();
      _activeTasks.remove(taskId);

      _logger.error('Download failed: ${resource.name}', e, stackTrace);
      _eventBus.publish(ResourceDownloadFailedEvent(
        resourceId: resource.id,
        versionId: version.id,
        error: e,
      ));

      rethrow;
    }
  }

  /// 取消下载
  Future<void> cancelDownload(String taskId) async {
    final task = _activeTasks.remove(taskId);
    if (task != null) {
      task.status = DownloadTaskStatus.cancelled;
      await _downloadEngine.cancelAll();
      _logger.info('Download cancelled: ${task.resource.name}');
    }
  }

  /// 取消所有下载
  Future<void> cancelAllDownloads() async {
    for (final taskId in _activeTasks.keys.toList()) {
      await cancelDownload(taskId);
    }
  }

  /// 获取下载任务
  ResourceDownloadTask? getTask(String taskId) {
    return _activeTasks[taskId] ?? _completedTasks.firstWhere(
      (t) => t.taskId == taskId,
      orElse: () => null as ResourceDownloadTask,
    );
  }

  /// 检查资源是否正在下载
  bool isDownloading(String resourceId, String versionId) {
    final taskId = _generateTaskId(resourceId, versionId);
    return _activeTasks.containsKey(taskId);
  }

  /// 生成任务ID
  String _generateTaskId(String resourceId, String versionId) {
    return 'resource_${resourceId}_${versionId}';
  }

  /// 清理已完成的任务
  void clearCompletedTasks() {
    _completedTasks.clear();
  }

  /// 下载并安装资源到指定实例
  Future<InstalledResource> downloadAndInstallToInstance(
    Resource resource,
    ResourceVersion version,
    String instanceId,
  ) async {
    await initialize();
    await _instanceManager.initialize();

    final installedResource = await downloadResource(resource, version);

    await _linkResourceToInstance(resource, instanceId);

    _logger.info('Resource ${resource.name} installed to instance $instanceId');

    return installedResource;
  }

  /// 将资源链接到实例
  Future<void> _linkResourceToInstance(Resource resource, String instanceId) async {
    switch (resource.type) {
      case ResourceType.mod:
        await _instanceManager.addResourceToInstance(
          instanceId,
          resource.id,
          instance_models.ResourceType.mod,
        );
        break;
      case ResourceType.resourcePack:
        await _instanceManager.addResourceToInstance(
          instanceId,
          resource.id,
          instance_models.ResourceType.resourcePack,
        );
        break;
      case ResourceType.modpack:
        await _installModpackToInstance(resource, versionId: '', instanceId: instanceId);
        break;
    }
  }

  /// 批量下载资源
  Future<List<InstalledResource>> batchDownloadResources(
    List<({Resource resource, ResourceVersion version})> resources, {
    void Function(int, int)? onProgress,
    String? targetInstanceId,
  }) async {
    await initialize();

    final results = <InstalledResource>[];
    int completed = 0;

    for (final item in resources) {
      try {
        InstalledResource installed;
        if (targetInstanceId != null) {
          installed = await downloadAndInstallToInstance(
            item.resource,
            item.version,
            targetInstanceId,
          );
        } else {
          installed = await downloadResource(item.resource, item.version);
        }
        results.add(installed);
      } catch (e) {
        _logger.error('Failed to download ${item.resource.name}', e);
      }

      completed++;
      onProgress?.call(completed, resources.length);
    }

    return results;
  }

  /// 下载并安装整合包
  Future<void> downloadAndInstallModpack(
    Resource modpack,
    ResourceVersion version,
    String targetInstanceId,
  ) async {
    await initialize();
    await _instanceManager.initialize();

    final taskId = _generateTaskId(modpack.id, version.id);

    if (_activeTasks.containsKey(taskId)) {
      throw Exception('Modpack is already downloading');
    }

    final task = ResourceDownloadTask(
      taskId: taskId,
      resource: modpack,
      version: version,
      status: DownloadTaskStatus.downloading,
      targetInstanceId: targetInstanceId,
    );

    _activeTasks[taskId] = task;

    try {
      final saveDir = await _resourceManager.getResourceDirectory(ResourceType.modpack);
      final fileName = version.download.fileName;
      final savePath = path.join(saveDir.path, fileName);

      task.savePath = savePath;

      await _downloadEngine.download(
        version.download.url,
        savePath,
        hash: version.download.sha1,
        hashType: HashType.sha1,
      );

      task.status = DownloadTaskStatus.installing;

      await _installModpackToInstance(
        modpack,
        versionId: version.id,
        instanceId: targetInstanceId,
        filePath: savePath,
      );

      task.status = DownloadTaskStatus.completed;
      task.progress = 1.0;

      _completedTasks.add(task);
      _activeTasks.remove(taskId);

      _logger.info('Modpack ${modpack.name} installed successfully');
    } catch (e, stackTrace) {
      task.status = DownloadTaskStatus.failed;
      task.error = e.toString();
      _activeTasks.remove(taskId);

      _logger.error('Failed to install modpack ${modpack.name}', e, stackTrace);
      rethrow;
    }
  }

  /// 安装整合包到实例
  Future<void> _installModpackToInstance(
    Resource modpack, {
    required String versionId,
    required String instanceId,
    String? filePath,
  }) async {
    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found'),
    );

    final modpackPath = filePath ?? path.join(
      (await _resourceManager.getResourceDirectory(ResourceType.modpack)).path,
      '${modpack.id}.zip',
    );

    final instanceDir = Directory(path.join(
      _instanceManager.selectedDirectory?.path ?? '',
      instance.name,
    ));

    if (!instanceDir.existsSync()) {
      await instanceDir.create(recursive: true);
    }

    _logger.info('Extracting modpack to ${instanceDir.path}');
  }

  /// 下载游戏版本
  Future<void> downloadGameVersion(
    String version,
    String instanceId,
  ) async {
    await initialize();
    await _instanceManager.initialize();

    _logger.info('Downloading game version $version for instance $instanceId');
  }

  /// 下载模组加载器
  Future<void> downloadLoader(
    String loaderType,
    String loaderVersion,
    String instanceId,
  ) async {
    await initialize();
    await _instanceManager.initialize();

    _logger.info('Downloading $loaderType $loaderVersion for instance $instanceId');
  }

  /// 添加下载进度回调
  void addProgressCallback(String taskId, void Function(double) callback) {
    _progressCallbacks[taskId] = callback;
  }

  /// 移除下载进度回调
  void removeProgressCallback(String taskId) {
    _progressCallbacks.remove(taskId);
  }

  /// 下载并安装资源的便捷方法
  Future<InstalledResource> downloadAndInstall(
    Resource resource,
    ResourceVersion version,
  ) async {
    return await downloadResource(resource, version);
  }

  /// 关闭服务
  Future<void> dispose() async {
    await _progressSubscription?.cancel();
    await cancelAllDownloads();
    _activeTasks.clear();
    _completedTasks.clear();
    _initialized = false;
  }
}

class ResourceDownloadService {
  static ResourceDownloadService? _instance;

  factory ResourceDownloadService() {
    return _instance ??= ResourceDownloadService._internal();
  }

  ResourceDownloadService._internal();

  static ResourceDownloadService get instance =>
      _instance ??= ResourceDownloadService._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('ResourceDownloadService');
  final EventBus _eventBus = EventBus.instance;
  final NetworkClient _networkClient = NetworkClient();
  final ResourceManager _resourceManager = ResourceManager();
  final InstanceManager _instanceManager = InstanceManager();

  Future<void> downloadAndInstall({
    required ResourceVersion version,
    required String instanceId,
    Function(double progress)? onProgress,
  }) async {
    await _resourceManager.initialize();
    await _instanceManager.initialize();

    final url = version.download.url;
    final fileName = _sanitizeFileName(version.download.fileName);
    final resourceType = _inferResourceType(fileName);
    final targetDir = _getResourceDirectory(instanceId, resourceType);

    await Directory(targetDir).create(recursive: true);

    final savePath = path.join(targetDir, fileName);

    _eventBus.publish(ResourceDownloadStartedEvent(
      resourceId: version.id,
      versionId: version.id,
      taskId: 'resource_download_${version.id}',
    ));

    try {
      await RetryHelper.execute(
        config: RetryConfig.network,
        operation: () async {
          await _networkClient.downloadFile(
            url,
            savePath,
            onProgress: (downloaded, total) {
              if (total > 0) {
                onProgress?.call(downloaded / total);
              }
            },
          );
        },
      );

      final installedResource = InstalledResource(
        localId: InstalledResource.generateLocalId('manual', version.id),
        resourceId: version.id,
        source: 'manual',
        type: resourceType,
        name: version.name,
        installedVersion: version.versionNumber,
        versionId: version.id,
        filePath: savePath,
        fileSize: version.download.fileSize,
        installedAt: DateTime.now(),
      );

      await _resourceManager.addInstalledResource(installedResource);

      _eventBus.publish(ResourceDownloadCompletedEvent(
        resourceId: version.id,
        versionId: version.id,
        savePath: savePath,
      ));

      onProgress?.call(1.0);
    } catch (e, stackTrace) {
      _logger.error('Failed to download and install resource', e, stackTrace);
      _eventBus.publish(ResourceDownloadFailedEvent(
        resourceId: version.id,
        versionId: version.id,
        error: e,
      ));
      rethrow;
    }
  }

  Future<String> downloadToFile({
    required String url,
    required String fileName,
    required String targetDirectory,
    Function(double progress)? onProgress,
  }) async {
    await Directory(targetDirectory).create(recursive: true);

    final sanitizedFileName = _sanitizeFileName(fileName);
    final savePath = path.join(targetDirectory, sanitizedFileName);

    try {
      await RetryHelper.execute(
        config: RetryConfig.network,
        operation: () async {
          await _networkClient.downloadFile(
            url,
            savePath,
            onProgress: (downloaded, total) {
              if (total > 0) {
                onProgress?.call(downloaded / total);
              }
            },
          );
        },
      );

      onProgress?.call(1.0);
      return savePath;
    } catch (e, stackTrace) {
      _logger.error('Failed to download file: $url', e, stackTrace);
      throw AppException.fromCode(
        ErrorCodes.networkDownloadFailed,
        detail: 'Failed to download $fileName from $url',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _getResourceDirectory(String instanceId, ResourceType type) {
    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw AppException.fromCode(
        ErrorCodes.instanceNotFound,
        detail: instanceId,
      ),
    );

    final directory = _instanceManager.directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw AppException.fromCode(
        ErrorCodes.instanceNotFound,
        detail: 'Directory not found for instance $instanceId',
      ),
    );

    String subDir;
    switch (type) {
      case ResourceType.mod:
        subDir = 'mods';
        break;
      case ResourceType.resourcePack:
        subDir = 'resourcepacks';
        break;
      case ResourceType.modpack:
        subDir = 'mods';
        break;
    }
    return path.join(directory.path, 'instances', instanceId, subDir);
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  ResourceType _inferResourceType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jar')) {
      return ResourceType.mod;
    }
    return ResourceType.resourcePack;
  }
}
