import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
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
  /// [visited] 用于循环依赖检测的已访问资源集合（内部使用）
  ///
  /// 返回创建的任务
  Future<DownloadTask> download({
    required Resource resource,
    required ResourceVersion version,
    required String targetInstance,
    required String targetGameVersion,
    bool autoInstall = true,
    bool resolveDependencies = true,
    Set<String>? visited,
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
    _processTask(
      task,
      autoInstall: autoInstall,
      resolveDependencies: resolveDependencies,
      visited: visited,
    );

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

  /// 获取实例的根目录（modpack 解压到此处）
  Future<String> getInstanceRootDirectory(String instanceName) async {
    final dir = await getApplicationDocumentsDirectory();
    final rootDir = Directory(
      path.join(dir.path, 'BAMCLaunch', 'instances', instanceName),
    );
    await rootDir.create(recursive: true);
    return rootDir.path;
  }

  /// 处理下载任务
  Future<void> _processTask(
    DownloadTask task, {
    required bool autoInstall,
    required bool resolveDependencies,
    Set<String>? visited,
  }) async {
    // 等待并发槽位
    while (_activeTasks.where((t) => t.status == DownloadTaskStatus.downloading).length >=
        maxConcurrentDownloads) {
      if (task.status == DownloadTaskStatus.cancelled) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 等待前面的任务
    await _executeTask(
      task,
      autoInstall: autoInstall,
      resolveDependencies: resolveDependencies,
      visited: visited,
    );
  }

  /// 执行实际下载
  Future<void> _executeTask(
    DownloadTask task, {
    required bool autoInstall,
    required bool resolveDependencies,
    Set<String>? visited,
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
          await _resolveDependencies(task, visited: visited);
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
          // 清理可能残留的临时文件
          try {
            if (await localFile.exists()) {
              await localFile.delete();
            }
          } catch (_) {}
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

      // 检查磁盘空间（如果知道总大小）
      if (task.totalBytes > 0) {
        try {
          final stat = await destination.parent.stat();
          if (stat.type == FileSystemEntityType.directory) {
            // 无法直接获取可用空间，跳过检查
          }
        } catch (_) {
          // 磁盘空间检查失败不阻止下载
        }
      }

      // 写入文件，跟踪进度
      final sink = destination.openWrite();
      int downloaded = 0;
      int bytesSinceLastUpdate = 0;
      final watch = Stopwatch()..start();

      try {
        await for (final data in response.stream) {
          // 检查任务是否已取消
          if (task.status == DownloadTaskStatus.cancelled) {
            await sink.flush();
            await sink.close();
            // 清理未完成的临时文件
            try {
              if (await destination.exists()) {
                await destination.delete();
              }
            } catch (_) {}
            return;
          }

          sink.add(data);
          downloaded += data.length;
          bytesSinceLastUpdate += data.length;
          task.downloadedBytes = downloaded;

          // 计算速度（每200ms更新一次）
          if (watch.elapsedMilliseconds > 200) {
            final elapsedSeconds = watch.elapsedMilliseconds / 1000;
            if (elapsedSeconds > 0) {
              task.downloadSpeed = (bytesSinceLastUpdate / elapsedSeconds).round();
            }
            bytesSinceLastUpdate = 0;
            watch.reset();
            _notifyTaskUpdate(task);
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

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
    // modpack 需要解压到实例根目录
    if (task.resource.type == ResourceType.modpack) {
      final instanceRoot = await getInstanceRootDirectory(task.targetInstance);
      _logger.info('[Download] 检测到整合包 (modpack)，开始解压: ${task.resource.name}');
      try {
        final installDir = await _extractModpack(sourceFile, instanceRoot);
        _logger.info('[Download] 整合包解压完成: $installDir');
        return installDir;
      } catch (e) {
        _logger.warning('[Download] 整合包解压失败，回退到复制文件: $e');
        final modsDir = await getModsDirectory(task.targetInstance);
        final fileName = task.version.fileName ?? path.basename(sourceFile.path);
        final destFile = File(path.join(modsDir, fileName));
        await sourceFile.copy(destFile.path);
        _logger.info('[Download] 整合包复制到: ${destFile.path}');
        return destFile.path;
      }
    }

    final String targetDir;

    switch (task.resource.type) {
      case ResourceType.mod:
      case ResourceType.dataPack:
        targetDir = await getModsDirectory(task.targetInstance);
        break;
      case ResourceType.resourcePack:
        targetDir = await getResourcePacksDirectory(task.targetInstance);
        break;
      case ResourceType.shader:
        targetDir = await getShaderPacksDirectory(task.targetInstance);
        break;
      case ResourceType.modpack:
        targetDir = await getModsDirectory(task.targetInstance);
        break;
    }

    final fileName = task.version.fileName ?? path.basename(sourceFile.path);
    final destFile = File(path.join(targetDir, fileName));

    // 复制文件到目标位置
    await sourceFile.copy(destFile.path);

    _logger.info('[Download] 安装到: ${destFile.path}');

    return destFile.path;
  }

  /// 解压 modpack（zip/jar）到目标目录
  ///
  /// 如果解压失败，会抛出异常，由调用方回退到文件复制。
  Future<String> _extractModpack(File sourceFile, String targetDir) async {
    final bytes = await sourceFile.readAsBytes();
    final Archive archive;

    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('无法解析为 zip/jar 归档: $e');
    }

    for (final file in archive) {
      final String filePath;
      if (file.isFile) {
        filePath = path.join(targetDir, file.name);
        final destFile = File(filePath);
        await destFile.parent.create(recursive: true);
        await destFile.writeAsBytes(file.content as List<int>);
      } else {
        filePath = path.join(targetDir, file.name);
        await Directory(filePath).create(recursive: true);
      }
    }

    return targetDir;
  }

  /// 解析并下载依赖
  ///
  /// [visited] 用于循环依赖检测，记录当前解析链上已访问的资源ID。
  Future<void> _resolveDependencies(DownloadTask task, {Set<String>? visited}) async {
    final dependencies = task.version.dependencies
        .where((d) => d.isRequired && d.projectId != null)
        .toList();

    if (dependencies.isEmpty) return;

    // 初始化或复用访问集合
    final currentVisited = visited ?? <String>{};
    currentVisited.add(task.resource.id);

    _logger.info('[Download] 开始解析 ${dependencies.length} 个依赖 (来自 ${task.resource.name})');

    for (final dep in dependencies) {
      final depId = dep.projectId!;

      // 循环依赖检测
      if (currentVisited.contains(depId)) {
        _logger.warning('[Download] 检测到循环依赖，跳过: $depId (链: ${currentVisited.join(' -> ')})');
        continue;
      }

      try {
        final depResource = await _modrinth.getProject(depId);
        final depVersions = await _modrinth.getVersions(
          depId,
          gameVersions: [task.targetGameVersion],
        );

        if (depVersions.isNotEmpty) {
          final depVersion = depVersions.first;
          // 为每个分支创建独立副本，避免平行链互相污染
          final branchVisited = Set<String>.of(currentVisited);
          await download(
            resource: depResource,
            version: depVersion,
            targetInstance: task.targetInstance,
            targetGameVersion: task.targetGameVersion,
            autoInstall: true,
            resolveDependencies: true,
            visited: branchVisited,
          );
          _logger.info('[Download] 已排队下载依赖: ${depResource.name} ($depId)');
        }
      } catch (e) {
        _logger.warning('[Download] 依赖下载失败 ($depId): $e');
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
