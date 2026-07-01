import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../event/event_bus.dart';
import '../event/event.dart';

/// Mod 加载器类型
enum LoaderType {
  forge,
  fabric,
  neoforge,
  quilt,
}

/// Mod 加载器信息
class ModLoaderInfo {
  final LoaderType type;
  final String version;
  final String mcVersion;
  final String downloadUrl;
  final String? installerUrl;
  final String? universalUrl;
  final String? launcherMetaUrl;

  ModLoaderInfo({
    required this.type,
    required this.version,
    required this.mcVersion,
    required this.downloadUrl,
    this.installerUrl,
    this.universalUrl,
    this.launcherMetaUrl,
  });
}

/// Mod 加载器下载服务
class LoaderDownloadService {
  static LoaderDownloadService? _instance;
  static LoaderDownloadService get instance =>
      ServiceLocator.instance.tryGet<LoaderDownloadService>() ??
      (_instance ??= LoaderDownloadService._());
  LoaderDownloadService._();

  final Logger _logger = Logger('LoaderDownloadService');
  final NetworkClient _networkClient = NetworkClient();
  final EventBus _eventBus = EventBus.instance;

  /// 获取 Forge 可用版本列表
  Future<List<String>> getForgeVersions(String mcVersion) async {
    try {
      final url = 'https://maven.neoforged.net/releases/net/neoforged/forge/maven-metadata.json';
      
      _logger.info('Fetching Forge versions for Minecraft $mcVersion...');
      
      final response = await _networkClient.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versions = <String>[];
        
        // 过滤出匹配 Minecraft 版本的 Forge
        final allVersions = data['versions'] as List<dynamic>? ?? [];
        for (final v in allVersions) {
          final version = v.toString();
          if (version.contains(mcVersion)) {
            versions.add(version);
          }
        }
        
        _logger.info('Found ${versions.length} Forge versions');
        return versions;
      } else {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'HTTP ${response.statusCode}',
          retryable: true,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch Forge versions', e, stackTrace);
      rethrow;
    }
  }

  /// 获取指定版本的 Forge 下载 URL
  Future<String?> getForgeDownloadUrl(String version) async {
    try {
      // Forge 版本格式: 1.20.1-47.2.20 -> mcVersion-loaderVersion
      final parts = version.split('-');
      if (parts.length < 2) return null;
      
      final mcVersion = parts[0];
      final forgeVersion = parts[1];
      
      final url = 'https://maven.neoforged.net/releases/net/neoforged/forge/$mcVersion-$forgeVersion/forge-$mcVersion-$forgeVersion-installer.jar';
      
      _logger.info('Forge download URL: $url');
      return url;
    } catch (e, stackTrace) {
      _logger.error('Failed to get Forge download URL', e, stackTrace);
      return null;
    }
  }

  /// 获取 Fabric 可用版本列表
  Future<List<String>> getFabricVersions(String mcVersion) async {
    try {
      final url = 'https://maven.fabricmc.net/net/fabricmc/fabric-loader/maven-metadata.json';
      
      _logger.info('Fetching Fabric versions for Minecraft $mcVersion...');
      
      final response = await _networkClient.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versions = <String>[];
        
        // 过滤出匹配 Minecraft 版本的 Fabric
        final allVersions = data['versions'] as List<dynamic>? ?? [];
        for (final v in allVersions) {
          final version = v.toString();
          if (version.contains(mcVersion)) {
            versions.add(version);
          }
        }
        
        _logger.info('Found ${versions.length} Fabric versions');
        return versions;
      } else {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'HTTP ${response.statusCode}',
          retryable: true,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch Fabric versions', e, stackTrace);
      rethrow;
    }
  }

  /// 获取指定版本的 Fabric 下载 URL
  Future<String?> getFabricDownloadUrl(String version) async {
    try {
      final mcVersion = version.split('-').first;
      final loaderVersion = version.split('-').last;
      
      final url = 'https://maven.fabricmc.net/net/fabricmc/fabric-loader/$loaderVersion/fabric-loader-$loaderVersion.jar';
      
      _logger.info('Fabric download URL: $url');
      return url;
    } catch (e, stackTrace) {
      _logger.error('Failed to get Fabric download URL', e, stackTrace);
      return null;
    }
  }

  /// 下载并安装 Mod 加载器
  Future<void> installLoader({
    required String instanceId,
    required LoaderType loaderType,
    required String version,
    required String mcVersion,
    required String gameDirectory,
    void Function(int received, int total)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    String? oldStatus;
    try {
      onStatus?.call('正在获取下载链接...');
      
      _eventBus.publish(LoaderInstallStartedEvent(
        instanceId: instanceId,
        loaderType: loaderType.name,
        loaderVersion: version,
      ));
      
      _updateLoaderStatus(instanceId, 'downloading', oldStatus);
      oldStatus = 'downloading';

      String? downloadUrl;
      String fileName;

      switch (loaderType) {
        case LoaderType.forge:
          downloadUrl = await getForgeDownloadUrl('$mcVersion-$version');
          fileName = 'forge-${mcVersion}-$version-installer.jar';
          break;
        case LoaderType.fabric:
          downloadUrl = await getFabricDownloadUrl(version);
          fileName = 'fabric-loader-${version.split('-').last}.jar';
          break;
        case LoaderType.neoforge:
          downloadUrl = await getForgeDownloadUrl('$mcVersion-$version');
          fileName = 'neoforge-${mcVersion}-$version-installer.jar';
          break;
        case LoaderType.quilt:
          // Quilt 使用类似 Fabric 的结构
          final quiltVersion = version.split('-').last;
          downloadUrl = 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-loader/$quiltVersion/quilt-loader-$quiltVersion.jar';
          fileName = 'quilt-loader-${quiltVersion}.jar';
          break;
      }

      if (downloadUrl == null) {
        throw AppException.fromCode(
          ErrorCodes.loaderInstallFailed,
          detail: '无法获取下载链接',
        );
      }

      _logger.info('Downloading $loaderType from: $downloadUrl');

      onStatus?.call('正在下载 $loaderType...');

      // 创建下载目录
      final downloadDir = Directory(gameDirectory);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 下载文件
      final filePath = path.join(gameDirectory, 'libraries', 'mods', fileName);

      await _networkClient.downloadFile(
        downloadUrl,
        filePath,
        onProgress: onProgress,
      );

      _logger.info('Loader downloaded to: $filePath');
      onStatus?.call('$loaderType 下载完成!');

      _updateLoaderStatus(instanceId, 'installing', oldStatus);
      oldStatus = 'installing';

      // 安装加载器
      await _installLoaderFiles(
        loaderType: loaderType,
        version: version,
        mcVersion: mcVersion,
        gameDirectory: gameDirectory,
        installerPath: filePath,
        onStatus: onStatus,
      );

      _logger.info('$loaderType installation completed');
      onStatus?.call('$loaderType 安装完成!');
      
      _updateLoaderStatus(instanceId, 'installed', oldStatus);
      _eventBus.publish(LoaderInstallCompletedEvent(
        instanceId: instanceId,
        loaderType: loaderType.name,
        loaderVersion: version,
      ));
    } catch (e, stackTrace) {
      _logger.error('Failed to install loader', e, stackTrace);
      _updateLoaderStatus(instanceId, 'downloadFailed', oldStatus);
      _eventBus.publish(LoaderInstallFailedEvent(
        instanceId: instanceId,
        error: e,
      ));
      rethrow;
    }
  }
  
  /// 更新加载器状态
  void _updateLoaderStatus(String instanceId, String newStatus, String? oldStatus) {
    _eventBus.publish(LoaderStatusChangedEvent(
      instanceId: instanceId,
      newStatus: newStatus,
      oldStatus: oldStatus,
    ));
    _logger.info('Loader status changed for instance $instanceId: $oldStatus -> $newStatus');
  }

  /// 安装加载器文件到游戏目录
  Future<void> _installLoaderFiles({
    required LoaderType loaderType,
    required String version,
    required String mcVersion,
    required String gameDirectory,
    required String installerPath,
    void Function(String status)? onStatus,
  }) async {
    try {
      onStatus?.call('正在安装加载器...');

      // 创建必要的目录
      final versionsDir = Directory(path.join(gameDirectory, 'versions', '$mcVersion-$version'));
      if (!await versionsDir.exists()) {
        await versionsDir.create(recursive: true);
      }

      final libsDir = Directory(path.join(gameDirectory, 'libraries'));
      if (!await libsDir.exists()) {
        await libsDir.create(recursive: true);
      }

      // 根据加载器类型执行不同的安装步骤
      switch (loaderType) {
        case LoaderType.forge:
        case LoaderType.neoforge:
          // Forge 需要运行安装器
          await _runForgeInstaller(installerPath, gameDirectory, mcVersion, version);
          break;
        case LoaderType.fabric:
        case LoaderType.quilt:
          // Fabric/Quilt 直接复制 jar 文件
          await _installFabricLikeLoader(installerPath, gameDirectory, mcVersion, version, loaderType);
          break;
      }

      // 创建版本 json 文件
      await _createVersionJson(
        loaderType: loaderType,
        mcVersion: mcVersion,
        loaderVersion: version,
        gameDirectory: gameDirectory,
      );

      _logger.info('Loader files installed successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to install loader files', e, stackTrace);
      rethrow;
    }
  }

  /// 运行 Forge 安装器
  Future<void> _runForgeInstaller(
    String installerPath,
    String gameDirectory,
    String mcVersion,
    String loaderVersion,
  ) async {
    try {
      _logger.info('Running Forge installer...');

      // 使用 Java 运行 Forge 安装器
      // 注意: 这里简化了，实际可能需要更复杂的参数
      final result = await Process.run(
        'java',
        [
          '-jar',
          installerPath,
          '--installClient',
          '--gameDir',
          gameDirectory,
        ],
        workingDirectory: gameDirectory,
      );

      if (result.exitCode != 0) {
        _logger.warning('Forge installer output: ${result.stdout}');
        _logger.warning('Forge installer errors: ${result.stderr}');
      }

      // 清理安装器文件
      final installerFile = File(installerPath);
      if (await installerFile.exists()) {
        await installerFile.delete();
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to run Forge installer', e, stackTrace);
      rethrow;
    }
  }

  /// 安装 Fabric 或 Quilt 加载器
  Future<void> _installFabricLikeLoader(
    String jarPath,
    String gameDirectory,
    String mcVersion,
    String version,
    LoaderType loaderType,
  ) async {
    try {
      final loaderName = loaderType == LoaderType.fabric ? 'fabric' : 'quilt';
      final loaderVersion = version.split('-').last;

      // 复制 jar 文件到正确位置
      final targetPath = path.join(
        gameDirectory,
        'libraries',
        loaderName,
        'loader',
        '$mcVersion-$loaderVersion',
        '$loaderName-loader-$loaderVersion.jar',
      );

      final targetFile = File(targetPath);
      final targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      await File(jarPath).copy(targetPath);
      _logger.info('Copied $loaderName loader to: $targetPath');
    } catch (e, stackTrace) {
      _logger.error('Failed to install Fabric/Quilt loader', e, stackTrace);
      rethrow;
    }
  }

  /// 创建版本 JSON 文件
  Future<void> _createVersionJson({
    required LoaderType loaderType,
    required String mcVersion,
    required String loaderVersion,
    required String gameDirectory,
  }) async {
    try {
      String id;
      String mainClass;
      String librariesPath;

      switch (loaderType) {
        case LoaderType.forge:
          id = '$mcVersion-forge-$loaderVersion';
          mainClass = 'cpw.mods.modlauncher.Launcher';
          librariesPath = 'libraries/net/minecraftforge/forge/$mcVersion-$loaderVersion';
          break;
        case LoaderType.neoforge:
          id = '$mcVersion-neoforge-$loaderVersion';
          mainClass = 'cpw.mods.modlauncher.Launcher';
          librariesPath = 'libraries/net/neoforged/forge/$mcVersion-$loaderVersion';
          break;
        case LoaderType.fabric:
          id = '$mcVersion-fabric-$loaderVersion';
          mainClass = 'net.fabricmc.loader.impl.launch.knot.KnotClient';
          librariesPath = 'libraries/net/fabricmc/fabric-loader/${loaderVersion.split('-').last}';
          break;
        case LoaderType.quilt:
          id = '$mcVersion-quilt-$loaderVersion';
          mainClass = 'org.quiltmc.loader.impl.launch.knot.KnotClient';
          librariesPath = 'libraries/org/quiltmc/quilt-loader/${loaderVersion.split('-').last}';
          break;
      }

      final versionJson = {
        'id': id,
        'inheritsFrom': mcVersion,
        'releaseTime': DateTime.now().toIso8601String(),
        'time': DateTime.now().toIso8601String(),
        'type': 'release',
        'mainClass': mainClass,
        'arguments': {
          'game': [
            '--fml.forgeVersion',
            loaderVersion,
            '--fml.mcVersion',
            mcVersion,
          ],
        },
      };

      final jsonPath = path.join(
        gameDirectory,
        'versions',
        id,
        '$id.json',
      );

      final jsonFile = File(jsonPath);
      final jsonDir = jsonFile.parent;
      if (!await jsonDir.exists()) {
        await jsonDir.create(recursive: true);
      }

      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(versionJson),
      );

      _logger.info('Version JSON created at: $jsonPath');
    } catch (e, stackTrace) {
      _logger.error('Failed to create version JSON', e, stackTrace);
      rethrow;
    }
  }
}
