import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../download/download_engine.dart';

class ModLoaderManager {
  static ModLoaderManager? _instance;

  factory ModLoaderManager() {
    _instance ??= ModLoaderManager._internal();
    return _instance!;
  }

  ModLoaderManager._internal();

  static ModLoaderManager get instance => _instance ??= ModLoaderManager._internal();

  final Logger _logger = Logger('ModLoaderManager');
  final DownloadEngine _downloadEngine = DownloadEngine();

  final Map<String, LoaderInstallationStatus> _installationStatus = {};

  Future<void> installLoader(
    String instanceId,
    String instancePath,
    String gameVersion,
    LoaderType loaderType, {
    void Function(double progress, String message)? onProgress,
    void Function(LoaderInstallationStatus status)? onStatusChange,
  }) async {
    final statusKey = '$instanceId-${loaderType.name}';
    
    _updateStatus(statusKey, LoaderInstallationStatus.downloading);
    onStatusChange?.call(LoaderInstallationStatus.downloading);
    onProgress?.call(0.0, '正在下载${loaderType.displayName}...');

    try {
      final loaderInfo = await _getLoaderInfo(loaderType, gameVersion);
      if (loaderInfo == null) {
        throw Exception('无法获取${loaderType.displayName}信息');
      }

      _logger.info('Installing ${loaderType.displayName} ${loaderInfo.version} for game $gameVersion');

      final installerPath = path.join(instancePath, '.loader', 'installer.jar');
      await _ensureDirectory(path.dirname(installerPath));

      onProgress?.call(0.2, '下载安装器...');
      await _downloadEngine.download(loaderInfo.installerUrl, installerPath);

      _updateStatus(statusKey, LoaderInstallationStatus.installing);
      onStatusChange?.call(LoaderInstallationStatus.installing);
      onProgress?.call(0.5, '正在安装...');

      await _runInstaller(instancePath, gameVersion, installerPath, loaderType);

      _updateStatus(statusKey, LoaderInstallationStatus.installed);
      onStatusChange?.call(LoaderInstallationStatus.installed);
      onProgress?.call(1.0, '安装完成');

      _logger.info('${loaderType.displayName} installation completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to install ${loaderType.displayName}', e, stackTrace);
      _updateStatus(statusKey, LoaderInstallationStatus.downloadFailed);
      onStatusChange?.call(LoaderInstallationStatus.downloadFailed);
      rethrow;
    }
  }

  Future<void> uninstallLoader(String instanceId, String instancePath) async {
    final libsDir = Directory(path.join(instancePath, 'libraries'));
    final modsDir = Directory(path.join(instancePath, 'mods'));

    try {
      if (await libsDir.exists()) {
        await _deleteLoaderLibraries(libsDir);
      }

      if (await modsDir.exists()) {
        await _deleteLoaderMods(modsDir);
      }

      _logger.info('Loader uninstalled successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to uninstall loader', e, stackTrace);
      rethrow;
    }
  }

  Future<LoaderInstallationStatus> checkLoaderStatus(
    String instanceId,
    String instancePath,
    String gameVersion,
    LoaderType loaderType,
  ) async {
    final statusKey = '$instanceId-${loaderType.name}';
    if (_installationStatus.containsKey(statusKey)) {
      return _installationStatus[statusKey]!;
    }

    return await _detectLoaderStatus(instancePath, loaderType);
  }

  Future<bool> isLoaderInstalled(String instancePath, LoaderType loaderType) async {
    final status = await _detectLoaderStatus(instancePath, loaderType);
    return status == LoaderInstallationStatus.installed;
  }

  Future<LoaderInfo?> getLoaderInfo(String gameVersion, LoaderType loaderType) {
    return _getLoaderInfo(loaderType, gameVersion);
  }

  void cancelInstallation(String instanceId, LoaderType loaderType) {
    final statusKey = '$instanceId-${loaderType.name}';
    _installationStatus[statusKey] = LoaderInstallationStatus.notInstalled;
    _downloadEngine.cancelAll();
  }

  void _updateStatus(String key, LoaderInstallationStatus status) {
    _installationStatus[key] = status;
  }

  Future<LoaderInfo?> _getLoaderInfo(LoaderType loaderType, String gameVersion) async {
    switch (loaderType) {
      case LoaderType.fabric:
        return _fetchFabricInfo(gameVersion);
      case LoaderType.forge:
        return _fetchForgeInfo(gameVersion);
      case LoaderType.quilt:
        return _fetchQuiltInfo(gameVersion);
      case LoaderType.neoforge:
        return _fetchNeoForgeInfo(gameVersion);
    }
  }

  Future<LoaderInfo?> _fetchFabricInfo(String gameVersion) async {
    try {
      final version = await _getLatestFabricVersion(gameVersion);
      if (version == null) return null;
      
      return LoaderInfo(
        type: LoaderType.fabric,
        version: version,
        installerUrl: 'https://maven.fabricmc.net/net/fabricmc/fabric-installer/$version/fabric-installer-$version.jar',
      );
    } catch (e) {
      _logger.debug('Failed to fetch Fabric info: $e');
      return null;
    }
  }

  Future<LoaderInfo?> _fetchForgeInfo(String gameVersion) async {
    try {
      final version = await _getLatestForgeVersion(gameVersion);
      if (version == null) return null;
      
      return LoaderInfo(
        type: LoaderType.forge,
        version: version,
        installerUrl: 'https://maven.minecraftforge.net/net/minecraftforge/forge/$gameVersion-$version/forge-$gameVersion-$version-installer.jar',
      );
    } catch (e) {
      _logger.debug('Failed to fetch Forge info: $e');
      return null;
    }
  }

  Future<LoaderInfo?> _fetchQuiltInfo(String gameVersion) async {
    try {
      final version = await _getLatestQuiltVersion(gameVersion);
      if (version == null) return null;
      
      return LoaderInfo(
        type: LoaderType.quilt,
        version: version,
        installerUrl: 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/$version/quilt-installer-$version.jar',
      );
    } catch (e) {
      _logger.debug('Failed to fetch Quilt info: $e');
      return null;
    }
  }

  Future<LoaderInfo?> _fetchNeoForgeInfo(String gameVersion) async {
    try {
      final version = await _getLatestNeoForgeVersion(gameVersion);
      if (version == null) return null;
      
      return LoaderInfo(
        type: LoaderType.neoforge,
        version: version,
        installerUrl: 'https://maven.neoforged.net/net/neoforged/neoforge/$gameVersion-$version/neoforge-$gameVersion-$version-installer.jar',
      );
    } catch (e) {
      _logger.debug('Failed to fetch NeoForge info: $e');
      return null;
    }
  }

  Future<String?> _getLatestFabricVersion(String gameVersion) async {
    return '0.15.11';
  }

  Future<String?> _getLatestForgeVersion(String gameVersion) async {
    return '47.1.0';
  }

  Future<String?> _getLatestQuiltVersion(String gameVersion) async {
    return '1.2.0';
  }

  Future<String?> _getLatestNeoForgeVersion(String gameVersion) async {
    return '20.4.85-beta';
  }

  Future<void> _runInstaller(
    String instancePath,
    String gameVersion,
    String installerPath,
    LoaderType loaderType,
  ) async {
    final javaPath = await _findJava();
    final args = _buildInstallerArgs(instancePath, gameVersion, installerPath, loaderType);

    _logger.info('Running installer: $javaPath ${args.join(' ')}');

    final process = await Process.start(javaPath, args);
    
    await process.exitCode;
  }

  String _findJava() {
    return 'java';
  }

  List<String> _buildInstallerArgs(
    String instancePath,
    String gameVersion,
    String installerPath,
    LoaderType loaderType,
  ) {
    return [
      '-jar',
      installerPath,
      'client',
      '-dir',
      instancePath,
      '-version',
      gameVersion,
    ];
  }

  Future<void> _deleteLoaderLibraries(Directory libsDir) async {
    final loaderPrefixes = [
      'net/fabricmc',
      'net/minecraftforge',
      'org/quiltmc',
      'net/neoforged',
    ];

    final files = await libsDir.list(recursive: true).whereType<File>().toList();
    
    for (final file in files) {
      final relativePath = path.relative(file.path, from: libsDir.path);
      if (loaderPrefixes.any((prefix) => relativePath.startsWith(prefix))) {
        await file.delete();
      }
    }
  }

  Future<void> _deleteLoaderMods(Directory modsDir) async {
    final loaderMods = [
      'fabric-loader',
      'fabric-api',
      'quilt-loader',
      'quilt-standard-libraries',
      'neoforge',
    ];

    final files = await modsDir.list().whereType<File>().toList();
    
    for (final file in files) {
      final fileName = path.basename(file.path).toLowerCase();
      if (loaderMods.any((mod) => fileName.contains(mod))) {
        await file.delete();
      }
    }
  }

  Future<void> _ensureDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<LoaderInstallationStatus> _detectLoaderStatus(String instancePath, LoaderType loaderType) async {
    final libsDir = Directory(path.join(instancePath, 'libraries'));
    
    if (!await libsDir.exists()) {
      return LoaderInstallationStatus.notInstalled;
    }

    final loaderPath = _getLoaderLibraryPath(instancePath, loaderType);
    return File(loaderPath).existsSync()
        ? LoaderInstallationStatus.installed
        : LoaderInstallationStatus.notInstalled;
  }

  String _getLoaderLibraryPath(String instancePath, LoaderType loaderType) {
    switch (loaderType) {
      case LoaderType.fabric:
        return path.join(instancePath, 'libraries', 'net', 'fabricmc', 'fabric-loader');
      case LoaderType.forge:
        return path.join(instancePath, 'libraries', 'net', 'minecraftforge', 'forge');
      case LoaderType.quilt:
        return path.join(instancePath, 'libraries', 'org', 'quiltmc', 'quilt-loader');
      case LoaderType.neoforge:
        return path.join(instancePath, 'libraries', 'net', 'neoforged', 'neoforge');
    }
  }
}

enum LoaderType {
  fabric('Fabric'),
  forge('Forge'),
  quilt('Quilt'),
  neoforge('NeoForge');

  final String displayName;

  const LoaderType(this.displayName);
}

enum LoaderInstallationStatus {
  notInstalled,
  downloading,
  installing,
  installed,
  downloadFailed,
}

class LoaderInfo {
  final LoaderType type;
  final String version;
  final String installerUrl;

  LoaderInfo({
    required this.type,
    required this.version,
    required this.installerUrl,
  });
}