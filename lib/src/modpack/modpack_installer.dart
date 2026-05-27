import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart' as archive;
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../core/logger.dart';
import '../core/retry_helper.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';
import '../loader/loader_download_service.dart';
import 'modpack_parser.dart';

/// 安装进度回调
typedef InstallProgressCallback = void Function(
  int completed,
  int total,
  String? currentTask,
);

/// 整合包安装器
class ModpackInstaller {
  static final Logger _logger = Logger('ModpackInstaller');
  static final NetworkClient _network = NetworkClient();

  /// 安装整合包到新实例
  static Future<String> installModpack({
    required String zipPath,
    required String instanceName,
    String? gameDirectory,
    InstallProgressCallback? onProgress,
    void Function(String)? onStatus,
  }) async {
    try {
      onStatus?.call('正在解析整合包...');
      _logger.info('Installing modpack from: $zipPath');

      // 1. 解析整合包
      final modpack = await ModpackParser.parseZip(zipPath);

      // 2. 创建新实例
      onStatus?.call('正在创建实例...');
      final manager = InstanceManager.instance;
      await manager.initialize();

      if (manager.directories.isEmpty) {
        throw AppException.fromCode(
          ErrorCodes.instanceCreateFailed,
          detail: '需要先创建游戏目录',
        );
      }

      final directory = manager.selectedDirectory ?? manager.directories.first;

      final instance = await manager.createInstance(
        name: instanceName,
        directoryId: directory.id,
        version: modpack.minecraftVersion,
        loader: modpack.modLoader,
        loaderVersion: modpack.modLoaderVersion,
      );

      _logger.info('Created instance: ${instance.id}');

      // 3. 提取覆盖文件
      onStatus?.call('正在提取整合包文件...');
      await _extractOverrides(zipPath, instance.id, directory, (progress) {
        onProgress?.call(progress, modpack.allResources.length, '提取整合包文件');
      });

      // 4. 下载资源
      onStatus?.call('正在下载资源...');
      int completed = 0;
      for (final resource in modpack.allResources) {
        completed++;
        onProgress?.call(
          completed,
          modpack.allResources.length,
          '下载 ${resource.name}',
        );

        try {
          await _downloadResource(
            resource: resource,
            instanceId: instance.id,
            gameDirectory: directory.path,
          );
        } catch (e) {
          _logger.warning('Failed to download resource ${resource.name}', e);
          // 继续安装下一个
        }
      }

      // 5. 更新实例配置
      onStatus?.call('正在配置实例...');
      await manager.updateInstance(
        id: instance.id,
        config: instance.config.copyWith(
          modLoader: modpack.modLoader,
          modLoaderVersion: modpack.modLoaderVersion,
        ),
      );

      _logger.info('Modpack installation completed successfully');
      onStatus?.call('安装完成！');

      return instance.id;
    } catch (e, stackTrace) {
      _logger.error('Failed to install modpack', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.loaderInstallFailed,
        detail: '安装整合包失败: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 提取整合包中的覆盖文件
  static Future<void> _extractOverrides(
    String zipPath,
    String instanceId,
    GameDirectory directory,
    void Function(int)? onProgress,
  ) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

      // 提取 overrides 文件夹
      final overrides = zipArchive.files
          .where((f) => f.name.startsWith('overrides/'))
          .toList();

      for (int i = 0; i < overrides.length; i++) {
        final file = overrides[i];

        // 移除 'overrides/' 前缀
        final subPath = file.name.substring('overrides/'.length);
        final destPath = path.join(directory.path, 'instances', instanceId, subPath);

        if (file.isFile) {
          // 创建目标目录
          final destDir = Directory(path.dirname(destPath));
          if (!await destDir.exists()) {
            await destDir.create(recursive: true);
          }

          // 写入文件
          if (file.content is List<int>) {
            await File(destPath).writeAsBytes(file.content as List<int>);
          }
        }

        onProgress?.call(i + 1);
      }

      _logger.info('Extracted ${overrides.length} override files');
    } catch (e, stackTrace) {
      _logger.warning('Failed to extract overrides', e, stackTrace);
      // 继续，不阻止安装
    }
  }

  /// 下载单个资源
  static Future<void> _downloadResource({
    required ModpackResource resource,
    required String instanceId,
    required String gameDirectory,
  }) async {
    if (resource.downloadUrl == null) {
      _logger.warning('Resource ${resource.name} has no download URL');
      return;
    }

    try {
      // 确定保存位置
      String savePath;
      final instanceDir = path.join(gameDirectory, 'instances', instanceId);

      switch (resource.type) {
        case ModpackResourceType.mod:
          savePath = path.join(instanceDir, 'mods', resource.name);
          break;
        case ModpackResourceType.resourcePack:
          savePath = path.join(instanceDir, 'resourcepacks', resource.name);
          break;
        case ModpackResourceType.shaderPack:
          savePath = path.join(instanceDir, 'shaderpacks', resource.name);
          break;
        case ModpackResourceType.dataPack:
          savePath = path.join(instanceDir, 'saves', resource.name);
          break;
        case ModpackResourceType.config:
          savePath = path.join(instanceDir, 'config', resource.name);
          break;
        default:
          savePath = path.join(instanceDir, resource.name);
          break;
      }

      // 创建目录
      final saveDir = Directory(path.dirname(savePath));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // 下载
      await RetryHelper.execute(
        config: const RetryConfig(maxRetries: 2),
        operation: () => _network.downloadFile(
          resource.downloadUrl!,
          savePath,
        ),
      );

      _logger.info('Downloaded resource: ${resource.name}');
    } catch (e, stackTrace) {
      _logger.warning('Failed to download resource ${resource.name}', e, stackTrace);
      rethrow;
    }
  }
}
