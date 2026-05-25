import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../download/download_engine.dart';
import '../download/models.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
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

  /// 创建下载任务
  ResourceDownloadTask({
    required this.taskId,
    required this.resource,
    required this.version,
    this.status = DownloadTaskStatus.pending,
    this.progress = 0.0,
    this.error,
    this.savePath,
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

  final Map<String, ResourceDownloadTask> _activeTasks = {};
  final List<ResourceDownloadTask> _completedTasks = [];

  bool _initialized = false;
  StreamSubscription? _progressSubscription;

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
