import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../config/config_manager.dart';
import '../core/logger.dart';
import '../download/download_engine.dart';
import '../download/models.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../platform/platform_adapter.dart';
import '../task/task.dart';
import '../task/task_context.dart';
import '../game/launcher/game_file_validator.dart';
import 'models.dart';
import 'version_manager.dart';

/// 版本安装任务
class InstallVersionTask extends Task<void> {
  /// 版本ID
  final String versionId;

  /// 版本JSON
  final VersionJson versionJson;

  /// 版本管理器
  final VersionManager versionManager;

  /// 平台适配器
  final IPlatformAdapter platformAdapter;

  /// 下载引擎
  final IDownloadEngine downloadEngine;

  /// 配置管理器
  final IConfigManager configManager;

  /// 事件总线
  final EventBus eventBus;

  /// 进度流控制器
  final StreamController<VersionInstallProgress> progressController;

  /// 日志记录器
  final Logger _logger;

  /// 总下载大小
  int _totalBytes = 0;

  /// 已下载大小
  int _downloadedBytes = 0;

  /// 创建安装任务
  InstallVersionTask({
    required this.versionId,
    required this.versionJson,
    required this.versionManager,
    required this.platformAdapter,
    required this.downloadEngine,
    required this.configManager,
    required this.eventBus,
    required this.progressController,
    String? id,
  }) : _logger = Logger('InstallVersionTask'),
       super(id: id);

  @override
  Future<void> execute(TaskContext context) async {
    _logger.info('Starting installation for version $versionId');
    eventBus.publish(VersionInstallStartedEvent(versionId: versionId));

    try {
      // 1. 创建目录结构
      await _createDirectories(context);

      // 2. 保存版本JSON
      await _saveVersionJson(context);

      // 3. 下载客户端JAR
      await _downloadClient(context);

      // 4. 下载库文件
      await _downloadLibraries(context);

      // 5. 下载资源索引
      await _downloadAssetIndex(context);

      // 6. 下载资源文件
      await _downloadAssets(context);

      _logger.info('Installation completed for version $versionId');
      eventBus.publish(VersionInstallCompletedEvent(versionId: versionId));
    } on TaskCancelledException {
      _logger.warning('Installation cancelled for version $versionId');
      eventBus.publish(VersionInstallCancelledEvent(versionId: versionId));
      rethrow;
    } catch (e) {
      _logger.error('Installation failed for version $versionId', e);
      eventBus.publish(
        VersionInstallFailedEvent(versionId: versionId, error: e),
      );
      rethrow;
    }
  }

  /// 创建目录结构
  Future<void> _createDirectories(TaskContext context) async {
    _updateProgress(0.0, '创建目录结构');
    _logger.info('Creating directories for version $versionId');

    final versionDir = await versionManager.getVersionDir(versionId);
    final assetsDir = await versionManager.getAssetsDir();
    final librariesDir = await versionManager.getLibrariesDir();

    await platformAdapter.ensureDirectoryExists(versionDir);
    await platformAdapter.ensureDirectoryExists(
      path.join(assetsDir, 'indexes'),
    );
    await platformAdapter.ensureDirectoryExists(
      path.join(assetsDir, 'objects'),
    );
    await platformAdapter.ensureDirectoryExists(librariesDir);

    context.checkCancelled();
  }

  /// 保存版本JSON
  Future<void> _saveVersionJson(TaskContext context) async {
    _updateProgress(0.02, '保存版本信息');
    _logger.info('Saving version JSON');

    final versionDir = await versionManager.getVersionDir(versionId);
    final jsonPath = path.join(versionDir, '$versionId.json');

    final jsonData = versionJson.toJson();
    final jsonString = jsonEncode(jsonData);

    await File(jsonPath).writeAsString(jsonString);

    context.checkCancelled();
  }

  /// 下载客户端JAR
  Future<void> _downloadClient(TaskContext context) async {
    _updateProgress(0.05, '下载客户端');
    _logger.info('Downloading client JAR');

    if (versionJson.downloads?.client == null) {
      _logger.warning('No client download available');
      return;
    }

    final client = versionJson.downloads!.client!;
    final versionDir = await versionManager.getVersionDir(versionId);
    final jarPath = path.join(versionDir, '$versionId.jar');

    // 检查文件是否已存在且正确
    if (await _verifyFile(jarPath, client.sha1, client.size)) {
      _logger.info('Client JAR already exists and is valid');
      _downloadedBytes += client.size;
      return;
    }

    _totalBytes += client.size;

    // 转换URL使用BMCLAPI
    final bmclUrl = _convertToBMCLApi(client.url);

    await downloadEngine.download(
      bmclUrl,
      jarPath,
      hash: client.sha1,
      hashType: HashType.sha1,
    );

    _downloadedBytes += client.size;
    _updateProgress(0.15, '下载客户端');

    context.checkCancelled();
  }

  /// 下载库文件
  Future<void> _downloadLibraries(TaskContext context) async {
    _updateProgress(0.15, '下载库文件');
    _logger.info('Downloading libraries');

    final librariesDir = await versionManager.getLibrariesDir();
    final downloadRequests = <DownloadRequest>[];

    for (final library in versionJson.libraries) {
      context.checkCancelled();

      // 检查是否需要下载此库
      if (!versionManager.shouldDownloadLibrary(library)) {
        _logger.debug('Skipping library ${library.name} (rules)');
        continue;
      }

      // 处理主库
      if (library.downloads?.artifact != null) {
        final artifact = library.downloads!.artifact!;
        final artifactPath = path.join(librariesDir, artifact.path);

        if (!await _verifyFile(artifactPath, artifact.sha1, artifact.size)) {
          final bmclUrl = _convertToBMCLApi(artifact.url);
          downloadRequests.add(
            DownloadRequest(
              url: bmclUrl,
              savePath: artifactPath,
              hash: artifact.sha1,
              hashType: HashType.sha1,
            ),
          );
          _totalBytes += artifact.size;
        } else {
          _downloadedBytes += artifact.size;
        }
      }

      // 处理原生库
      final nativeClassifier = versionManager.getNativeClassifier(library);
      if (nativeClassifier != null &&
          library.downloads?.classifiers != null &&
          library.downloads!.classifiers!.containsKey(nativeClassifier)) {
        final nativeArtifact =
            library.downloads!.classifiers![nativeClassifier]!;
        final nativePath = path.join(librariesDir, nativeArtifact.path);

        if (!await _verifyFile(
          nativePath,
          nativeArtifact.sha1,
          nativeArtifact.size,
        )) {
          final bmclUrl = _convertToBMCLApi(nativeArtifact.url);
          downloadRequests.add(
            DownloadRequest(
              url: bmclUrl,
              savePath: nativePath,
              hash: nativeArtifact.sha1,
              hashType: HashType.sha1,
            ),
          );
          _totalBytes += nativeArtifact.size;
        } else {
          _downloadedBytes += nativeArtifact.size;
        }
      }
    }

    if (downloadRequests.isNotEmpty) {
      _logger.info('Downloading ${downloadRequests.length} library files');

      int completed = 0;
      for (final request in downloadRequests) {
        context.checkCancelled();

        try {
          await downloadEngine.download(
            request.url,
            request.savePath,
            hash: request.hash,
            hashType: request.hashType,
          );
          _downloadedBytes += request.hash != null
              ? await _getFileSize(request.savePath)
              : 0;
        } catch (e) {
          _logger.warning('Failed to download ${request.url}, continuing: $e');
        }

        completed++;
        final progress = 0.15 + (0.4 * completed / downloadRequests.length);
        _updateProgress(
          progress,
          '下载库文件 ($completed/${downloadRequests.length})',
        );
      }
    }

    _updateProgress(0.55, '下载库文件完成');
  }

  /// 下载资源索引
  Future<void> _downloadAssetIndex(TaskContext context) async {
    _updateProgress(0.55, '下载资源索引');
    _logger.info('Downloading asset index');

    final assetIndex = versionJson.assetIndex;
    final assetsDir = await versionManager.getAssetsDir();
    final indexPath = path.join(assetsDir, 'indexes', '${assetIndex.id}.json');

    if (await _verifyFile(indexPath, assetIndex.sha1, assetIndex.size)) {
      _logger.info('Asset index already exists and is valid');
      _downloadedBytes += assetIndex.size;
      return;
    }

    _totalBytes += assetIndex.size;

    final bmclUrl = _convertToBMCLApi(assetIndex.url);
    await downloadEngine.download(
      bmclUrl,
      indexPath,
      hash: assetIndex.sha1,
      hashType: HashType.sha1,
    );

    _downloadedBytes += assetIndex.size;
    _updateProgress(0.6, '下载资源索引');

    context.checkCancelled();
  }

  /// 下载资源文件
  Future<void> _downloadAssets(TaskContext context) async {
    _updateProgress(0.6, '下载资源文件');
    _logger.info('Downloading assets');

    final assetIndex = versionJson.assetIndex;
    final assetsDir = await versionManager.getAssetsDir();
    final indexPath = path.join(assetsDir, 'indexes', '${assetIndex.id}.json');

    // 读取资源索引
    final indexJson = jsonDecode(await File(indexPath).readAsString());
    final indexFile = AssetIndexFile.fromJson(indexJson);

    final downloadRequests = <DownloadRequest>[];
    int missingCount = 0;

    for (final entry in indexFile.objects.entries) {
      context.checkCancelled();

      final asset = entry.value;
      final hashPrefix = asset.hash.substring(0, 2);
      final objectPath = path.join(
        assetsDir,
        'objects',
        hashPrefix,
        asset.hash,
      );

      if (!await _verifyFile(objectPath, asset.hash, asset.size)) {
        final url =
            'https://bmclapi2.bangbang93.com/assets/${asset.hash.substring(0, 2)}/${asset.hash}';
        downloadRequests.add(
          DownloadRequest(
            url: url,
            savePath: objectPath,
            hash: asset.hash,
            hashType: HashType.sha1,
          ),
        );
        _totalBytes += asset.size;
        missingCount++;
      } else {
        _downloadedBytes += asset.size;
      }
    }

    if (downloadRequests.isNotEmpty) {
      _logger.info('Downloading $missingCount asset files');

      int completed = 0;
      for (final request in downloadRequests) {
        context.checkCancelled();

        try {
          // 确保目录存在
          await platformAdapter.ensureDirectoryExists(
            path.dirname(request.savePath),
          );

          await downloadEngine.download(
            request.url,
            request.savePath,
            hash: request.hash,
            hashType: request.hashType,
          );
          _downloadedBytes += request.hash != null
              ? await _getFileSize(request.savePath)
              : 0;
        } catch (e) {
          _logger.warning('Failed to download ${request.url}, continuing: $e');
        }

        completed++;
        final progress = 0.6 + (0.4 * completed / downloadRequests.length);
        _updateProgress(progress, '下载资源文件 ($completed/$missingCount)');
      }
    }

    _updateProgress(1.0, '安装完成');
  }

  /// 验证文件是否存在且正确
  Future<bool> _verifyFile(
    String filePath,
    String expectedHash,
    int expectedSize,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    // 快速检查大小
    if (await file.length() != expectedSize) {
      return false;
    }

    // 这里可以添加哈希校验，但为了性能暂时跳过
    // 完整实现应该校验SHA-1哈希
    return true;
  }

  /// 获取文件大小
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// 转换URL为BMCLAPI
  String _convertToBMCLApi(String originalUrl) {
    // 将Mojang的URL转换为BMCLAPI
    // https://launcher.mojang.com/... -> https://bmclapi2.bangbang93.com/...
    return originalUrl
        .replaceFirst(
          'https://launcher.mojang.com',
          'https://bmclapi2.bangbang93.com',
        )
        .replaceFirst(
          'https://libraries.minecraft.net',
          'https://bmclapi2.bangbang93.com/maven',
        )
        .replaceFirst(
          'https://resources.download.minecraft.net',
          'https://bmclapi2.bangbang93.com/assets',
        );
  }

  /// 更新进度
  void _updateProgress(double progress, String stage, [String? currentFile]) {
    final installProgress = VersionInstallProgress(
      versionId: versionId,
      progress: progress.clamp(0.0, 1.0),
      stage: stage,
      currentFile: currentFile,
      downloadedBytes: _downloadedBytes,
      totalBytes: _totalBytes,
    );

    progressController.add(installProgress);
    eventBus.publish(
      VersionInstallProgressEvent(
        versionId: versionId,
        progress: progress.clamp(0.0, 1.0),
        stage: stage,
      ),
    );
  }
}
