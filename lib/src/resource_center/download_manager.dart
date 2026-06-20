import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/logger.dart';
import 'models.dart';
import 'modrinth_client.dart';

/// 下载任务状态
enum DownloadTaskStatus {
  /// 等待中
  pending,

  /// 下载中
  downloading,

  /// 安装中
  installing,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// 下载任务
class DownloadTask {
  /// 唯一任务ID
  final String id;

  /// 资源（mod/资源包）
  final Resource resource;

  /// 要下载的版本
  final ResourceVersion version;

  /// 目标实例名称
  final String targetInstance;

  /// 下载目标
  final String targetGameVersion;

  /// 状态
  DownloadTaskStatus status;

  /// 已下载字节数
  int downloadedBytes;

  /// 总字节数
  int totalBytes;

  /// 进度（0-1）
  double get progress {
    if (totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes;
  }

  /// 速度（字节/秒）
  int downloadSpeed;

  /// 下载开始时间
  DateTime? startTime;

  /// 下载结束时间
  DateTime? endTime;

  /// 错误信息
  String? errorMessage;

  /// 本地文件路径（下载完成后）
  String? filePath;

  /// 已安装到实例目录的最终路径
  String? installedPath;

  /// 创建下载任务
  DownloadTask({
    required this.id,
    required this.resource,
    required this.version,
    required this.targetInstance,
    required this.targetGameVersion,
    this.status = DownloadTaskStatus.pending,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.downloadSpeed = 0,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.filePath,
    this.installedPath,
  });

  /// 创建任务ID
  static String generateId(String resourceId, String instance) {
    return '${resourceId}_${instance}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  String toString() => 'DownloadTask($id, $status, ${(progress * 100).toStringAsFixed(0)}%)';
}

/// 下载管理器
///
/// 负责：
/// - 管理下载任务队列
/// - 并发下载（可配置）
/// - 从 Modrinth/CurseForge 下载文件
/// - 自动安装到实例（支持版本隔离）
/// - 依赖解析（自动下载必需的依赖）
/// - 进度跟踪和通知
///
/// ## 使用方式
///
/// ```dart
/// final manager = DownloadManager();
///
/// // 创建下载任务
/// final task = await manager.download(
///   resource: resource,
///   version: version,
///   targetInstance: '我的整合包',
///   targetGameVersion: '1.20.4',
///   autoInstall: true,
///   resolveDependencies: true,
/// );
///
/// // 监听任务进度
/// manager.onTaskUpdate.listen((task) {
///   print('${task.resource.name}: ${(task.progress * 100).toStringAsFixed(0)}%');
/// });
/// ```
class DownloadManager {
  /// 单例
  static DownloadManager? _instance;

  static DownloadManager get instance {
    _instance ??= DownloadManager._();
    return _instance!;
  }

  DownloadManager._();

  /// 最大并发下载数
  int maxConcurrentDownloads = 2;

  /// 最大重试次数
  int maxRetryCount = 3;

  /// 超时时间（秒）
  int timeoutSeconds = 120;

  /// 临时目录
  Directory? _tempDir;

  /// 所有任务
  final Map<String, DownloadTask> _tasks = {};

  /// 活动中的任务（正在下载或等待）
  final List<DownloadTask> _activeTasks = [];

  /// 已完成的任务
  final List<DownloadTask> _completedTasks = [];

  /// 任务更新事件流
  final StreamController<DownloadTask> _taskUpdateStream =
      StreamController<DownloadTask>.broadcast();

  /// 监听任务更新
  Stream<DownloadTask> get onTaskUpdate => _taskUpdateStream.stream;

  /// 所有任务
  List<DownloadTask> get allTasks => List.unmodifiable(_tasks.values);

  /// 正在进行的任务
  List<DownloadTask> get activeTasks => List.unmodifiable(_activeTasks);

  /// 已完成的任务
  List<DownloadTask> get completedTasks => List.unmodifiable(_completedTasks);

  /// Modrinth 客户端
  final ModrinthClient _modrinth = ModrinthClient();

  final Logger _logger = Logger();

  /// 是否有进行中的任务
  bool get hasActiveTasks => _activeTasks.isNotEmpty;

  /// 获取任务
  DownloadTask? getTask(String id) => _tasks[id];

  /// 创建并启动下载任务
  ///
  /// [resource] 要下载的资源
  /// [version] 要下载的版本
  /// [targetInstance] 目标实例名称（用于版本隔离）
  /// [targetGameVersion] 目标游戏版本
  /// [autoInstall] 是否自动安装（下载完成后自动移动到对应目录）
  /// [resolveDependencies] 是否自动解析并下载依赖
  ///
  /// 返回创建的任务
  Future<DownloadTask> download({
    required Resource resource,
    required ResourceVersion version,
    required String targetInstance,
    required String targetGameVersion,
    bool autoInstall = true,
    bool resolveDependencies = true,
  }) async {
    final task = DownloadTask(
      id: DownloadTask.generateId(resource.id, targetInstance),
      resource: resource,
      version: version,
      targetInstance: targetInstance,
      targetGameVersion: targetGameVersion,
      status: DownloadTaskStatus.pending,
      totalBytes: version.fileSize,
    );

    _tasks[task.id] = task;
    _activeTasks.add(task);

    _logger.info('[Download] 创建任务: ${task.id} (${resource.name} v${version.versionNumber})');

    // 异步执行下载
    _processTask(task, autoInstall: autoInstall, resolveDependencies: resolveDependencies);

    return task;
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    if (task.status == DownloadTaskStatus.downloading ||
        task.status == DownloadTaskStatus.pending) {
      task.status = DownloadTaskStatus.cancelled;
      task.endTime = DateTime.now();
      _activeTasks.remove(task);
      _notifyTaskUpdate(task);
      _logger.info('[Download] 取消任务: ${task.id}');
    }
  }

  /// 清除所有已完成的任务
  void clearCompleted() {
    _completedTasks.clear();
  }

  /// 获取临时目录
  Future<Directory> _getTempDir() async {
    if (_tempDir != null) return _tempDir!;
    final dir = await getTemporaryDirectory();
    _tempDir = Directory(path.join(dir.path, 'bamclaunch_downloads'));
    await _tempDir!.create(recursive: true);
    return _tempDir!;
  }

  /// 获取实例的 mods 目录（支持版本隔离）
  Future<String> getModsDirectory(String instanceName) async {
    final dir = await getApplicationDocumentsDirectory();
    final modsDir = Directory(
      path.join(dir.path, 'BAMCLaunch', 'instances', instanceName, 'mods'),
    );
    await modsDir.create(recursive: true);
    return modsDir.path;
  }

  /// 获取实例的 resourcepacks 目录
  Future<String> getResourcePacksDirectory(String instanceName) async {
    final dir = await getApplicationDocumentsDirectory();
    final packsDir = Directory(
      path.join(dir.path, 'BAMCLaunch', 'instances', instanceName, 'resourcepacks'),
    );
    await packsDir.create(recursive: true);
    return packsDir.path;
  }

  /// 获取实例的 shaderpacks 目录
  Future<String> getShaderPacksDirectory(String instanceName) async {
    final dir = await getApplicationDocumentsDirectory();
    final packsDir = Directory(
      path.join(dir.path, 'BAMCLaunch', 'instances', instanceName, 'shaderpacks'),
    );
    await packsDir.create(recursive: true);
    return packsDir.path;
  }

  /// 处理下载任务
  Future<void> _processTask(
    DownloadTask task, {
    required bool autoInstall,
    required bool resolveDependencies,
  }) async {
    // 等待并发槽位
    while (_activeTasks.where((t) => t.status == DownloadTaskStatus.downloading).length >=
        maxConcurrentDownloads) {
      if (task.status == DownloadTaskStatus.cancelled) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 等待前面的任务
    await _executeTask(task, autoInstall: autoInstall, resolveDependencies: resolveDependencies);
  }

  /// 执行实际下载
  Future<void> _executeTask(
    DownloadTask task, {
    required bool autoInstall,
    required bool resolveDependencies,
  }) async {
    if (task.status == DownloadTaskStatus.cancelled) return;

    task.status = DownloadTaskStatus.downloading;
    task.startTime = DateTime.now();
    _notifyTaskUpdate(task);

    final tempDir = await _getTempDir();
    final fileName = task.version.fileName ?? '${task.resource.id}.jar';
    final localFile = File(path.join(tempDir.path, fileName));

    final downloadUrl = task.version.downloadUrl;

    if (downloadUrl == null || downloadUrl.isEmpty) {
      task.status = DownloadTaskStatus.failed;
      task.errorMessage = '下载链接无效';
      _notifyTaskUpdate(task);
      _removeActiveTask(task);
      return;
    }

    _logger.info('[Download] 开始下载: $downloadUrl');

    // 下载文件
    for (int attempt = 0; attempt < maxRetryCount; attempt++) {
      try {
        await _downloadFile(downloadUrl, localFile, task);

        if (task.status == DownloadTaskStatus.cancelled) return;

        // 下载成功
        task.filePath = localFile.path;

        // 安装
        if (autoInstall) {
          task.status = DownloadTaskStatus.installing;
          _notifyTaskUpdate(task);

          try {
            final installPath = await _installFile(task, localFile);
            task.installedPath = installPath;
            task.status = DownloadTaskStatus.completed;
            task.endTime = DateTime.now();
            _logger.info('[Download] 安装完成: ${task.resource.name} -> $installPath');
          } catch (e) {
            task.status = DownloadTaskStatus.failed;
            task.errorMessage = '安装失败: $e';
            _logger.error('[Download] 安装异常: $e');
          }
        } else {
          task.status = DownloadTaskStatus.completed;
          task.endTime = DateTime.now();
        }

        _notifyTaskUpdate(task);
        _removeActiveTask(task);
        _completedTasks.add(task);

        // 依赖解析
        if (resolveDependencies && task.status == DownloadTaskStatus.completed) {
          await _resolveDependencies(task);
        }
        return;
      } catch (e) {
        if (attempt < maxRetryCount - 1) {
          _logger.warning('[Download] 重试 ${attempt + 1}/$maxRetryCount: $e');
          await Future.delayed(Duration(seconds: attempt + 1));
        } else {
          task.status = DownloadTaskStatus.failed;
          task.errorMessage = '下载失败: $e';
          _notifyTaskUpdate(task);
          _removeActiveTask(task);
          _logger.error('[Download] 下载异常: $e');
          return;
        }
      }
    }
  }

  /// 下载文件
  Future<void> _downloadFile(String url, File destination, DownloadTask task) async {
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // 如果不知道总大小，从 content-length 获取
      if (task.totalBytes == 0) {
        final contentLength = response.contentLength;
        if (contentLength != null) {
          task.totalBytes = contentLength;
          _notifyTaskUpdate(task);
        }
      }

      // 写入文件，跟踪进度
      final sink = destination.openWrite();
      int downloaded = 0;
      final watch = Stopwatch()..start();

      await response.stream.listen((List<int> data) {
        sink.add(data);
        downloaded += data.length;
        task.downloadedBytes = downloaded;

        // 计算速度（每200ms更新一次）
        if (watch.elapsedMilliseconds > 200) {
          task.downloadSpeed = downloaded ~/ (watch.elapsedMilliseconds / 1000).toInt().clamp(1, 99999);
          watch.reset();
          _notifyTaskUpdate(task);
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      task.downloadedBytes = downloaded;
      if (task.totalBytes == 0) task.totalBytes = downloaded;
      _notifyTaskUpdate(task);

      _logger.info('[Download] 文件下载完成: ${destination.path} (${(task.totalBytes / 1024).toStringAsFixed(1)} KB)');
    } finally {
      client.close();
    }
  }

  /// 根据资源类型安装文件到目标实例
  Future<String> _installFile(DownloadTask task, File sourceFile) async {
    final String targetDir;

    switch (task.resource.type) {
      case ResourceType.mod:
      case ResourceType.dataPack:
      case ResourceType.modpack:
        targetDir = await getModsDirectory(task.targetInstance);
        break;
      case ResourceType.resourcePack:
        targetDir = await getResourcePacksDirectory(task.targetInstance);
        break;
      case ResourceType.shader:
        targetDir = await getShaderPacksDirectory(task.targetInstance);
        break;
    }

    final fileName = task.version.fileName ?? path.basename(sourceFile.path);
    final destFile = File(path.join(targetDir, fileName));

    // 复制文件到目标位置
    await sourceFile.copy(destFile.path);

    _logger.info('[Download] 安装到: ${destFile.path}');

    return destFile.path;
  }

  /// 解析并下载依赖
  Future<void> _resolveDependencies(DownloadTask task) async {
    final dependencies = task.version.dependencies
        .where((d) => d.isRequired && d.projectId != null)
        .toList();

    if (dependencies.isEmpty) return;

    _logger.info('[Download] 开始解析 ${dependencies.length} 个依赖');

    for (final dep in dependencies) {
      try {
        final depResource = await _modrinth.getProject(dep.projectId!);
        final depVersions = await _modrinth.getVersions(
          dep.projectId!,
          gameVersions: [task.targetGameVersion],
        );

        if (depVersions.isNotEmpty) {
          final depVersion = depVersions.first;
          await download(
            resource: depResource,
            version: depVersion,
            targetInstance: task.targetInstance,
            targetGameVersion: task.targetGameVersion,
            autoInstall: true,
            resolveDependencies: false,
          );
        }
      } catch (e) {
        _logger.warning('[Download] 依赖下载失败 (${dep.projectId}): $e');
      }
    }
  }

  /// 从活动列表移除
  void _removeActiveTask(DownloadTask task) {
    _activeTasks.remove(task);
  }

  /// 通知任务更新
  void _notifyTaskUpdate(DownloadTask task) {
    _taskUpdateStream.add(task);
  }

  /// 关闭所有流
  void dispose() {
    _taskUpdateStream.close();
  }
}
