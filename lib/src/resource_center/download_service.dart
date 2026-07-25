import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/error_codes.dart';
import '../di/service_locator.dart';
import '../download/models.dart';
import '../download/download_engine.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart' show ResourceType;
import 'models.dart';
import 'resource_manager.dart';
import 'download_manager.dart';

/// 下载任务状态（保留旧 API 兼容）
@Deprecated('使用 DownloadManager.DownloadTaskStatus 代替')
typedef LegacyDownloadTaskStatus = DownloadTaskStatusCompat;

/// 下载任务状态（保留旧 API 兼容）
enum DownloadTaskStatusCompat {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
  installing,
}

/// 资源下载任务（保留旧 API 兼容，内部委托 DownloadManager.DownloadTask）
///
/// 新代码请直接使用 DownloadManager 和其 DownloadTask 类型。
class ResourceDownloadTask {
  final String taskId;
  final Resource resource;
  final ResourceVersion version;
  DownloadTaskStatusCompat status;
  double progress;
  String? error;
  String? savePath;
  final String? targetInstanceId;

  /// 关联的 DownloadManager 任务（内部使用）
  DownloadTask? _managerTask;

  ResourceDownloadTask({
    required this.taskId,
    required this.resource,
    required this.version,
    this.status = DownloadTaskStatusCompat.pending,
    this.progress = 0.0,
    this.error,
    this.savePath,
    this.targetInstanceId,
  });

  static DownloadTaskStatusCompat _convertStatus(DownloadTaskStatus s) {
    switch (s) {
      case DownloadTaskStatus.pending:
        return DownloadTaskStatusCompat.pending;
      case DownloadTaskStatus.downloading:
        return DownloadTaskStatusCompat.downloading;
      case DownloadTaskStatus.installing:
        return DownloadTaskStatusCompat.installing;
      case DownloadTaskStatus.completed:
        return DownloadTaskStatusCompat.completed;
      case DownloadTaskStatus.failed:
        return DownloadTaskStatusCompat.failed;
      case DownloadTaskStatus.cancelled:
        return DownloadTaskStatusCompat.cancelled;
    }
  }
}

/// 下载服务（已废弃，内部委托给 DownloadManager）
///
/// 历史原因存在两套下载实现：DownloadService 与 DownloadManager。
/// 现在 DownloadService 作为薄包装，所有真实下载逻辑委托给
/// DownloadManager，确保并发、进度、取消与依赖解析等行为统一。
///
/// 新代码请直接使用 DownloadManager。
@Deprecated('使用 DownloadManager 代替')
class DownloadService {
  static DownloadService? _instance;

  factory DownloadService() => instance;

  DownloadService._internal();

  static DownloadService get instance =>
      ServiceLocator.instance.tryGet<DownloadService>() ??
      (_instance ??= DownloadService._internal());

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('DownloadService');
  final EventBus _eventBus = EventBus.instance;
  final DownloadEngine _downloadEngine = DownloadEngine();
  final DownloadManager _manager = DownloadManager.instance;
  final ResourceManager _resourceManager = ResourceManager();
  final InstanceManager _instanceManager = InstanceManager();

  /// 旧 API 兼容：维护 taskId 到 ResourceDownloadTask 的映射
  final Map<String, ResourceDownloadTask> _activeTasks = {};
  final List<ResourceDownloadTask> _completedTasks = [];

  bool _initialized = false;
  StreamSubscription? _taskUpdateSubscription;

  List<ResourceDownloadTask> get activeTasks =>
      List.unmodifiable(_activeTasks.values);

  List<ResourceDownloadTask> get completedTasks =>
      List.unmodifiable(_completedTasks);

  /// 初始化
  ///
  /// 订阅 DownloadManager 的任务更新事件，转发为旧的事件格式。
  Future<void> initialize() async {
    if (_initialized) return;

    await _resourceManager.initialize();

    _taskUpdateSubscription = _manager.onTaskUpdate.listen(
      _onManagerTaskUpdate,
    );
    _initialized = true;
    _logger.info('DownloadService initialized (delegating to DownloadManager)');
  }

  /// 旧任务格式进度事件转发
  void _onManagerTaskUpdate(DownloadTask task) {
    // 查找或重建 ResourceDownloadTask
    ResourceDownloadTask? legacy = _activeTasks[task.id];
    if (legacy == null) {
      // 已完成或已移除的任务：从完成列表找
      for (final t in _completedTasks) {
        if (t.taskId == task.id) {
          legacy = t;
          break;
        }
      }
    }
    if (legacy == null) return;

    legacy._managerTask = task;
    legacy.progress = task.progress;
    legacy.status = ResourceDownloadTask._convertStatus(task.status);
    legacy.savePath = task.installedPath ?? task.filePath;
    if (task.errorMessage != null) {
      legacy.error = task.errorMessage;
    }

    // 触发旧 API 的进度事件（使用第一个 taskId 的旧格式）
    _eventBus.publish(
      ResourceDownloadProgressEvent(
        resourceId: legacy.resource.id,
        versionId: legacy.version.id,
        progress: DownloadProgress(
          downloadedBytes: task.downloadedBytes,
          totalBytes: task.totalBytes,
          progress: task.progress,
          speed: task.downloadSpeed,
        ),
      ),
    );

    if (task.status == DownloadTaskStatus.completed ||
        task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.cancelled) {
      _activeTasks.remove(legacy.taskId);
      if (!_completedTasks.contains(legacy)) {
        _completedTasks.add(legacy);
      }
      if (task.status == DownloadTaskStatus.completed) {
        _eventBus.publish(
          ResourceDownloadCompletedEvent(
            resourceId: legacy.resource.id,
            versionId: legacy.version.id,
            savePath: legacy.savePath ?? '',
          ),
        );
      } else if (task.status == DownloadTaskStatus.failed) {
        _eventBus.publish(
          ResourceDownloadFailedEvent(
            resourceId: legacy.resource.id,
            versionId: legacy.version.id,
            error: task.errorMessage ?? 'Unknown error',
          ),
        );
      }
    }
  }

  /// 下载资源（委托给 DownloadManager）
  Future<InstalledResource> downloadResource(
    Resource resource,
    ResourceVersion version,
  ) async {
    await initialize();

    final taskId = _generateTaskId(resource.id, version.id);

    if (_activeTasks.containsKey(taskId)) {
      throw AppException.fromCode(
        ErrorCodes.networkDownloadFailed,
        detail: 'Resource is already downloading',
      );
    }

    final legacyTask = ResourceDownloadTask(
      taskId: taskId,
      resource: resource,
      version: version,
      status: DownloadTaskStatusCompat.downloading,
    );
    _activeTasks[taskId] = legacyTask;

    _eventBus.publish(
      DownloadResourceEvent(resource: resource, version: version),
    );
    _eventBus.publish(
      ResourceDownloadStartedEvent(
        resourceId: resource.id,
        versionId: version.id,
        taskId: taskId,
      ),
    );

    _logger.info(
      'Starting download (legacy): ${resource.name} v${version.versionNumber}',
    );

    // DownloadManager 需要 targetInstance 和 targetGameVersion，
    // 这里使用占位值，由调用方改用 downloadAndInstallToInstance 传递真实值
    final managerTask = await _manager.download(
      resource: resource,
      version: version,
      targetInstance: '__temp__',
      targetGameVersion: '',
      autoInstall: true,
      resolveDependencies: false,
    );
    legacyTask._managerTask = managerTask;
    legacyTask.taskId; // 保持旧 taskId 用于事件回查

    // 等待任务完成
    await _waitForCompletion(managerTask);

    // 构造 InstalledResource 返回（与旧 API 兼容）
    return InstalledResource(
      localId: InstalledResource.generateLocalId(resource.source, resource.id),
      resourceId: resource.id,
      source: resource.source,
      type: resource.type,
      name: resource.name,
      installedVersion: version.versionNumber,
      versionId: version.id,
      filePath: managerTask.filePath ?? '',
      fileSize: version.fileSize,
      installedAt: DateTime.now(),
      iconUrl: resource.iconUrl,
    );
  }

  /// 等待任务完成（轮询 DownloadManager 状态）
  Future<void> _waitForCompletion(
    DownloadTask managerTask, {
    Duration timeout = const Duration(hours: 24),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final current = _manager.getTask(managerTask.id);
      if (current == null) return;
      if (current.status == DownloadTaskStatus.completed ||
          current.status == DownloadTaskStatus.failed ||
          current.status == DownloadTaskStatus.cancelled) {
        if (current.status == DownloadTaskStatus.failed) {
          throw AppException.fromCode(
            ErrorCodes.networkDownloadFailed,
            detail: current.errorMessage ?? 'Download failed',
          );
        }
        if (current.status == DownloadTaskStatus.cancelled) {
          throw AppException.fromCode(
            ErrorCodes.networkDownloadFailed,
            detail: 'Download cancelled',
          );
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    throw AppException.fromCode(
      ErrorCodes.networkDownloadFailed,
      detail: 'Download timeout',
    );
  }

  /// 取消单个下载
  Future<void> cancelDownload(String taskId) async {
    final task = _activeTasks[taskId];
    if (task != null && task._managerTask != null) {
      await _manager.cancelTask(task._managerTask!.id);
      _logger.info('Download cancelled: ${task.resource.name}');
    } else if (task != null) {
      // 找不到底层 managerTask，至少清理本地状态
      task.status = DownloadTaskStatusCompat.cancelled;
      _activeTasks.remove(taskId);
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
    final active = _activeTasks[taskId];
    if (active != null) return active;
    for (final t in _completedTasks) {
      if (t.taskId == taskId) return t;
    }
    return null;
  }

  bool isDownloading(String resourceId, String versionId) {
    final taskId = _generateTaskId(resourceId, versionId);
    return _activeTasks.containsKey(taskId);
  }

  String _generateTaskId(String resourceId, String versionId) {
    return 'resource_${resourceId}_${versionId}';
  }

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

    final taskId = _generateTaskId(resource.id, version.id);

    if (_activeTasks.containsKey(taskId)) {
      throw AppException.fromCode(
        ErrorCodes.networkDownloadFailed,
        detail: 'Resource is already downloading',
      );
    }

    final legacyTask = ResourceDownloadTask(
      taskId: taskId,
      resource: resource,
      version: version,
      status: DownloadTaskStatusCompat.downloading,
      targetInstanceId: instanceId,
    );
    _activeTasks[taskId] = legacyTask;

    _eventBus.publish(
      DownloadResourceEvent(resource: resource, version: version),
    );
    _eventBus.publish(
      ResourceDownloadStartedEvent(
        resourceId: resource.id,
        versionId: version.id,
        taskId: taskId,
      ),
    );

    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final managerTask = await _manager.download(
      resource: resource,
      version: version,
      targetInstance: instance.name,
      targetGameVersion: instance.version,
      autoInstall: true,
      resolveDependencies: false,
    );
    legacyTask._managerTask = managerTask;

    await _waitForCompletion(managerTask);

    // 链接资源到实例资源列表
    await _linkResourceToInstance(resource, instanceId);

    _logger.info('Resource ${resource.name} installed to instance $instanceId');

    return InstalledResource(
      localId: InstalledResource.generateLocalId(resource.source, resource.id),
      resourceId: resource.id,
      source: resource.source,
      type: resource.type,
      name: resource.name,
      installedVersion: version.versionNumber,
      versionId: version.id,
      filePath: managerTask.filePath ?? '',
      fileSize: version.fileSize,
      installedAt: DateTime.now(),
      iconUrl: resource.iconUrl,
    );
  }

  /// 将资源链接到实例
  Future<void> _linkResourceToInstance(
    Resource resource,
    String instanceId,
  ) async {
    switch (resource.type) {
      case ResourceType.mod:
        await _instanceManager.addResourceToInstance(
          instanceId,
          resource.id,
          ResourceType.mod,
        );
        break;
      case ResourceType.resourcePack:
        await _instanceManager.addResourceToInstance(
          instanceId,
          resource.id,
          ResourceType.resourcePack,
        );
        break;
      case ResourceType.modpack:
        await _installModpackToInstance(
          resource,
          versionId: '',
          instanceId: instanceId,
        );
        break;
      case ResourceType.shaderPack:
        await _instanceManager.addResourceToInstance(
          instanceId,
          resource.id,
          ResourceType.shaderPack,
        );
        break;
      case ResourceType.dataPack:
        break;
      case ResourceType.world:
      case ResourceType.screenshot:
        // 世界/截图不在实例资源列表中
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
      throw AppException.fromCode(
        ErrorCodes.networkDownloadFailed,
        detail: 'Modpack is already downloading',
      );
    }

    final legacyTask = ResourceDownloadTask(
      taskId: taskId,
      resource: modpack,
      version: version,
      status: DownloadTaskStatusCompat.downloading,
      targetInstanceId: targetInstanceId,
    );
    _activeTasks[taskId] = legacyTask;

    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == targetInstanceId,
      orElse: () =>
          throw ArgumentError('Instance not found: $targetInstanceId'),
    );

    final managerTask = await _manager.download(
      resource: modpack,
      version: version,
      targetInstance: instance.name,
      targetGameVersion: instance.version,
      autoInstall: true,
      resolveDependencies: false,
    );
    legacyTask._managerTask = managerTask;

    await _waitForCompletion(managerTask);

    _logger.info('Modpack ${modpack.name} installed successfully');
  }

  /// 安装整合包到实例（保持兼容）
  Future<void> _installModpackToInstance(
    Resource modpack, {
    required String versionId,
    required String instanceId,
    String? filePath,
  }) async {
    // 整合包解压由 DownloadManager._installFile 处理
    _logger.info('Modpack installation delegated to DownloadManager');
  }

  /// 下载游戏版本（保留接口，无实际实现）
  Future<void> downloadGameVersion(String version, String instanceId) async {
    await initialize();
    await _instanceManager.initialize();
    _logger.warning('downloadGameVersion is not implemented in legacy adapter');
  }

  /// 下载模组加载器（保留接口，无实际实现）
  Future<void> downloadLoader(
    String loaderType,
    String loaderVersion,
    String instanceId,
  ) async {
    await initialize();
    await _instanceManager.initialize();
    _logger.warning('downloadLoader is not implemented in legacy adapter');
  }

  void addProgressCallback(String taskId, void Function(double) callback) {
    // 已废弃，DownloadManager 提供流式更新
  }

  void removeProgressCallback(String taskId) {
    // 已废弃
  }

  Future<InstalledResource> downloadAndInstall(
    Resource resource,
    ResourceVersion version,
  ) async {
    return await downloadResource(resource, version);
  }

  /// 下载文件到指定目录（直接调底层 DownloadEngine）
  Future<String> downloadToFile({
    required String url,
    required String fileName,
    required String targetDirectory,
    void Function(double progress)? onProgress,
  }) async {
    await initialize();

    await Directory(targetDirectory).create(recursive: true);
    final sanitizedFileName = _sanitizeFileName(fileName);
    final savePath = path.join(targetDirectory, sanitizedFileName);

    _logger.info('Downloading file: $url -> $savePath');

    try {
      await _downloadEngine.download(url, savePath);
      onProgress?.call(1.0);
      _logger.info('File downloaded: $savePath');
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

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> dispose() async {
    await _taskUpdateSubscription?.cancel();
    await cancelAllDownloads();
    _activeTasks.clear();
    _completedTasks.clear();
    _initialized = false;
  }
}
