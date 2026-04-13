import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../interfaces/i_version_manager.dart';
import '../models/version_models.dart';
import '../models/loader_models.dart';
import '../../download/i_download_engine.dart';
import '../../download/download_engine.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';

class VersionManager implements IVersionManager {
  final IDownloadEngine _downloadEngine;
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;

  VersionManifest? _cachedManifest;
  DateTime? _manifestLastUpdated;

  VersionManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    IDownloadEngine? downloadEngine,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _downloadEngine = downloadEngine ?? DownloadEngine();

  @override
  Future<VersionManifest> getVersionManifest(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedManifest != null &&
        _manifestLastUpdated != null) {
      final now = DateTime.now();
      const cacheDuration = Duration(hours: 1);

      if (now.difference(_manifestLastUpdated!) < cacheDuration) {
        _logger.info('Using cached version manifest');
        return _cachedManifest!;
      }
    }

    _logger.info('Fetching version manifest');

    const manifestUrl =
        'https://launchermeta.mojang.com/mc/game/version_manifest.json';
    final cacheDir = Directory(_platformAdapter.cacheDirectory);

    // 确保缓存目录存在
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final tempFile =
        File('${_platformAdapter.cacheDirectory}/version_manifest.json');

    await _downloadEngine.downloadFile(manifestUrl, tempFile.path);

    final manifestContent = await tempFile.readAsString();
    final manifest = VersionManifest.fromJson(jsonDecode(manifestContent));

    _cachedManifest = manifest;
    _manifestLastUpdated = DateTime.now();

    return manifest;
  }

  @override
  Future<List<Version>> getInstalledVersions() async {
    final versionsDir = Directory('${_platformAdapter.gameDirectory}/versions');
    final installedVersions = <Version>[];

    if (!await versionsDir.exists()) {
      return installedVersions;
    }

    final versionDirs = await versionsDir.list().toList();

    for (final dir in versionDirs) {
      if (dir is Directory) {
        final versionId = path.basename(dir.path);
        final jsonFile = File('${dir.path}/$versionId.json');

        if (await jsonFile.exists()) {
          try {
            final content = await jsonFile.readAsString();
            final versionData = jsonDecode(content);
            final version = Version.fromJson(versionData);
            installedVersions
                .add(version.copyWith(status: VersionStatus.installed));
          } catch (e) {
            _logger.error('Failed to parse version $versionId: $e');
          }
        }
      }
    }

    return installedVersions;
  }

  @override
  Future<Version> getVersionInfo(String versionId) async {
    final manifest = await getVersionManifest();
    final versionEntry = manifest.versions.firstWhere(
      (v) => v.id == versionId,
      orElse: () => throw Exception('Version $versionId not found'),
    );

    final versionJsonUrl = versionEntry.url;
    final tempFile =
        File('${_platformAdapter.cacheDirectory}/versions/$versionId.json');

    await _downloadEngine.downloadFile(versionJsonUrl, tempFile.path);

    final content = await tempFile.readAsString();
    final versionData = jsonDecode(content);
    return Version.fromJson(versionData);
  }

  @override
  Future<void> installVersion(
      String versionId, Function(double) onProgress) async {
    _logger.info('Installing version: $versionId');

    final version = await getVersionInfo(versionId);
    final versionsDir = Directory('${_platformAdapter.gameDirectory}/versions');
    final versionDir = Directory('${versionsDir.path}/$versionId');

    await versionDir.create(recursive: true);

    final jsonFile = File('${versionDir.path}/$versionId.json');
    await jsonFile.writeAsString(jsonEncode(version.toJson()));

    if (version.download != null) {
      final jarFile = File('${versionDir.path}/$versionId.jar');
      // 使用多线程分块下载
      await _downloadEngine.downloadFile(
        version.download!.url,
        jarFile.path,
        checksum: version.download!.sha1,
        checksumType: 'sha1',
        onProgress: onProgress,
        maxThreads: 4, // 启用多线程下载
      );
    }

    if (version.assetIndex != null) {
      await downloadVersionAssets(versionId, onProgress);
    }

    await _installLibraries(version, onProgress);
  }

  @override
  Future<void> uninstallVersion(String versionId) async {
    _logger.info('Uninstalling version: $versionId');

    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');

    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
    }
  }

  @override
  Future<bool> checkVersionIntegrity(String versionId) async {
    try {
      final versionDir =
          Directory('${_platformAdapter.gameDirectory}/versions/$versionId');

      if (!await versionDir.exists()) {
        return false;
      }

      final jsonFile = File('${versionDir.path}/$versionId.json');
      final jarFile = File('${versionDir.path}/$versionId.jar');

      if (!await jsonFile.exists() || !await jarFile.exists()) {
        return false;
      }

      final version = await getVersionInfo(versionId);

      if (version.download != null) {
        final isValid = await _downloadEngine.verifyFile(
          jarFile.path,
          version.download!.sha1,
          'sha1',
        );

        if (!isValid) {
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.error('Failed to check version integrity: $e');
      return false;
    }
  }

  @override
  Future<void> repairVersion(String versionId) async {
    _logger.info('Repairing version: $versionId');

    await uninstallVersion(versionId);
    await installVersion(versionId, (progress) {});
  }

  @override
  Future<Version> createCustomVersion({
    required String id,
    required String name,
    required String inheritsFrom,
    Map<String, dynamic>? customData,
  }) async {
    final baseVersion = await getVersionInfo(inheritsFrom);

    final customVersion = Version(
      id: id,
      type: VersionType.custom,
      releaseTime: DateTime.now(),
      time: DateTime.now(),
      complianceLevel: baseVersion.complianceLevel,
      download: baseVersion.download,
      assetIndex: baseVersion.assetIndex,
      libraries: baseVersion.libraries,
      arguments: baseVersion.arguments,
      jvmArguments: baseVersion.jvmArguments,
      mainClass: baseVersion.mainClass,
      inheritsFrom: inheritsFrom,
      status: VersionStatus.not_installed,
    );

    final versionsDir = Directory('${_platformAdapter.gameDirectory}/versions');
    final versionDir = Directory('${versionsDir.path}/$id');

    await versionDir.create(recursive: true);

    final jsonFile = File('${versionDir.path}/$id.json');
    await jsonFile.writeAsString(jsonEncode(customVersion.toJson()));

    return customVersion;
  }

  Future<Version> resolveVersionInheritance(String versionId) async {
    _logger.info('Resolving version inheritance for: $versionId');

    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    final jsonFile = File('${versionDir.path}/$versionId.json');

    if (!await jsonFile.exists()) {
      throw Exception('Version $versionId not found');
    }

    final content = await jsonFile.readAsString();
    final versionData = jsonDecode(content);
    var version = Version.fromJson(versionData);

    // 递归解析继承关系，直到找到基础版本
    while (version.inheritsFrom != null) {
      final parentVersion = await getVersionInfo(version.inheritsFrom);
      // 合并版本信息，子版本覆盖父版本的相同字段
      version = version.copyWith(
        download: version.download ?? parentVersion.download,
        assetIndex: version.assetIndex ?? parentVersion.assetIndex,
        libraries: version.libraries ?? parentVersion.libraries,
        arguments: version.arguments ?? parentVersion.arguments,
        jvmArguments: version.jvmArguments ?? parentVersion.jvmArguments,
        mainClass: version.mainClass ?? parentVersion.mainClass,
        complianceLevel:
            version.complianceLevel ?? parentVersion.complianceLevel,
        inheritsFrom: parentVersion.inheritsFrom,
      );
    }

    return version;
  }

  @override
  Future<void> updateVersionStatus(
      String versionId, VersionStatus status) async {
    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    final jsonFile = File('${versionDir.path}/$versionId.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final versionData = jsonDecode(content);
      versionData['status'] = status.toString().split('.').last;
      await jsonFile.writeAsString(jsonEncode(versionData));
    }
  }

  @override
  Future<List<VersionEntry>> searchVersions(String query) async {
    final manifest = await getVersionManifest();

    return manifest.versions.where((version) {
      return version.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<void> downloadVersionAssets(
      String versionId, Function(double) onProgress) async {
    final version = await getVersionInfo(versionId);

    if (version.assetIndex != null) {
      final assetIndexUrl = version.assetIndex!.url;
      final tempFile = File(
          '${_platformAdapter.cacheDirectory}/assets/indexes/${version.assetIndex!.id}.json');

      await _downloadEngine.downloadFile(
        assetIndexUrl,
        tempFile.path,
        checksum: version.assetIndex!.sha1,
        checksumType: 'sha1',
      );

      final assetIndexContent = await tempFile.readAsString();
      final assetIndex = jsonDecode(assetIndexContent);

      final assets = assetIndex['objects'] as Map<String, dynamic>;
      final totalAssets = assets.length;
      var downloadedAssets = 0;

      for (final entry in assets.entries) {
        final assetPath = entry.key;
        final assetInfo = entry.value as Map<String, dynamic>;
        final hash = assetInfo['hash'] as String;
        final size = assetInfo['size'] as int;

        final assetDir = Directory(
            '${_platformAdapter.gameDirectory}/assets/objects/${hash.substring(0, 2)}');
        await assetDir.create(recursive: true);

        final assetFile = File('${assetDir.path}/$hash');

        if (!await assetFile.exists()) {
          final assetUrl =
              'https://resources.download.minecraft.net/${hash.substring(0, 2)}/$hash';

          await _downloadEngine.downloadFile(
            assetUrl,
            assetFile.path,
            checksum: hash,
            checksumType: 'sha1',
          );
        }

        downloadedAssets++;
        onProgress(downloadedAssets / totalAssets);
      }
    }
  }

  Future<void> _installLibraries(
      Version version, Function(double) onProgress) async {
    final librariesDir =
        Directory('${_platformAdapter.gameDirectory}/libraries');
    await librariesDir.create(recursive: true);

    final totalLibraries = version.libraries.length;
    var installedLibraries = 0;

    for (final library in version.libraries) {
      if (library.downloads.artifact != null) {
        final artifact = library.downloads.artifact!;
        final libraryFile = File('${librariesDir.path}/${artifact.path}');

        if (!await libraryFile.exists()) {
          await libraryFile.parent.create(recursive: true);

          await _downloadEngine.downloadFile(
            artifact.url,
            libraryFile.path,
            checksum: artifact.sha1,
            checksumType: 'sha1',
          );
        }
      }

      installedLibraries++;
      onProgress(installedLibraries / totalLibraries);
    }
  }

  @override
  Future<List<LoaderVersion>> getLoaderVersions(
    LoaderType loaderType,
    String mcVersion,
  ) async {
    _logger
        .info('Fetching ${loaderType.name} versions for Minecraft $mcVersion');

    final versions = <LoaderVersion>[];

    switch (loaderType) {
      case LoaderType.forge:
        versions.addAll(await _fetchForgeVersions(mcVersion));
        break;
      case LoaderType.fabric:
        versions.addAll(await _fetchFabricVersions(mcVersion));
        break;
      case LoaderType.quilt:
        versions.addAll(await _fetchQuiltVersions(mcVersion));
        break;
      case LoaderType.neoForge:
        versions.addAll(await _fetchNeoForgeVersions(mcVersion));
        break;
    }

    return versions;
  }

  @override
  Future<LoaderInstallResult> installLoader({
    required LoaderType loaderType,
    required String mcVersion,
    required String loaderVersion,
    Function(double)? onProgress,
    Function(LoaderInstallStatus)? onStatusChanged,
  }) async {
    onStatusChanged?.call(LoaderInstallStatus.pending);

    String versionId;
    switch (loaderType) {
      case LoaderType.forge:
        versionId = '$mcVersion-forge-$loaderVersion';
        break;
      case LoaderType.fabric:
        versionId = '$mcVersion-fabric-$loaderVersion';
        break;
      case LoaderType.quilt:
        versionId = '$mcVersion-quilt-$loaderVersion';
        break;
      case LoaderType.neoForge:
        versionId = '$mcVersion-neoforge-$loaderVersion';
        break;
    }

    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    final jsonFile = File('${versionDir.path}/$versionId.json');

    List<String> backupFiles = [];

    try {
      onStatusChanged?.call(LoaderInstallStatus.downloading);

      switch (loaderType) {
        case LoaderType.forge:
          await _installForge(mcVersion, loaderVersion, versionId, onProgress);
          break;
        case LoaderType.fabric:
          await _installFabric(mcVersion, loaderVersion, versionId, onProgress);
          break;
        case LoaderType.quilt:
          await _installQuilt(mcVersion, loaderVersion, versionId, onProgress);
          break;
        case LoaderType.neoForge:
          await _installNeoForge(
              mcVersion, loaderVersion, versionId, onProgress);
          break;
      }

      onStatusChanged?.call(LoaderInstallStatus.installing);

      await _verifyLoaderInstallation(versionId);

      onStatusChanged?.call(LoaderInstallStatus.completed);
      return LoaderInstallResult(
        success: true,
        versionId: versionId,
        status: LoaderInstallStatus.completed,
      );
    } catch (e) {
      _logger.error(
          'Failed to install ${loaderType.name} $loaderVersion for $mcVersion: $e');

      onStatusChanged?.call(LoaderInstallStatus.failed);

      try {
        await _rollbackLoaderInstallation(versionId, backupFiles);
        onStatusChanged?.call(LoaderInstallStatus.rolledBack);
      } catch (rollbackError) {
        _logger.error('Failed to rollback installation: $rollbackError');
      }

      return LoaderInstallResult(
        success: false,
        versionId: versionId,
        errorMessage: e.toString(),
        status: LoaderInstallStatus.failed,
      );
    }
  }

  @override
  Future<LoaderCompatibilityInfo> checkLoaderCompatibility(
    LoaderType loaderType,
    String mcVersion,
    String loaderVersion,
  ) async {
    try {
      final versions = await getLoaderVersions(loaderType, mcVersion);
      final compatibleVersions = versions.map((v) => v.version).toList();

      if (compatibleVersions.contains(loaderVersion)) {
        return LoaderCompatibilityInfo(
          isCompatible: true,
          compatibleLoaderVersions: compatibleVersions,
        );
      } else {
        return LoaderCompatibilityInfo(
          isCompatible: false,
          reason:
              'Loader version $loaderVersion is not compatible with Minecraft $mcVersion',
          compatibleLoaderVersions: compatibleVersions,
        );
      }
    } catch (e) {
      _logger.error('Failed to check loader compatibility: $e');
      return LoaderCompatibilityInfo(
        isCompatible: false,
        reason: 'Failed to check compatibility: $e',
        compatibleLoaderVersions: [],
      );
    }
  }

  @override
  Future<void> uninstallLoader(String versionId) async {
    _logger.info('Uninstalling loader version: $versionId');
    await uninstallVersion(versionId);
  }

  @override
  Future<List<Version>> getInstalledLoaders() async {
    final allVersions = await getInstalledVersions();
    return allVersions.where((v) {
      return v.id.contains('-forge-') ||
          v.id.contains('-fabric-') ||
          v.id.contains('-quilt-') ||
          v.id.contains('-neoforge-');
    }).toList();
  }

  Future<List<LoaderVersion>> _fetchForgeVersions(String mcVersion) async {
    final url =
        'https://files.minecraftforge.net/net/minecraftforge/forge/index_$mcVersion.json';
    final tempFile =
        File('${_platformAdapter.cacheDirectory}/forge_$mcVersion.json');

    try {
      await _downloadEngine.downloadFile(url, tempFile.path);
      final content = await tempFile.readAsString();
      final data = jsonDecode(content);

      final versions = <LoaderVersion>[];
      for (final entry in (data['promos'] as Map<String, dynamic>).entries) {
        if (entry.key.startsWith('$mcVersion-')) {
          final version = entry.key.replaceFirst('$mcVersion-', '');
          versions.add(LoaderVersion(
            version: version,
            mcVersion: mcVersion,
            url:
                'https://maven.minecraftforge.net/net/minecraftforge/forge/$mcVersion-$version/forge-$mcVersion-$version-installer.jar',
            releaseTime: DateTime.now(),
          ));
        }
      }
      return versions;
    } catch (e) {
      _logger.error('Failed to fetch Forge versions: $e');
      return [];
    }
  }

  Future<List<LoaderVersion>> _fetchFabricVersions(String mcVersion) async {
    final url = 'https://meta.fabricmc.net/v2/versions/loader/$mcVersion';
    final tempFile =
        File('${_platformAdapter.cacheDirectory}/fabric_$mcVersion.json');

    try {
      await _downloadEngine.downloadFile(url, tempFile.path);
      final content = await tempFile.readAsString();
      final data = jsonDecode(content) as List;

      return data
          .map((v) => LoaderVersion(
                version: v['loader']['version'],
                mcVersion: mcVersion,
                url: v['loader']['url'],
                sha1: v['loader']['sha1'],
                size: v['loader']['size'],
                releaseTime: DateTime.parse(
                    v['loader']['maven']['version'].split('-').last),
              ))
          .toList();
    } catch (e) {
      _logger.error('Failed to fetch Fabric versions: $e');
      return [];
    }
  }

  Future<List<LoaderVersion>> _fetchQuiltVersions(String mcVersion) async {
    final url = 'https://meta.quiltmc.org/v3/versions/loader/$mcVersion';
    final tempFile =
        File('${_platformAdapter.cacheDirectory}/quilt_$mcVersion.json');

    try {
      await _downloadEngine.downloadFile(url, tempFile.path);
      final content = await tempFile.readAsString();
      final data = jsonDecode(content) as List;

      return data
          .map((v) => LoaderVersion(
                version: v['version'],
                mcVersion: mcVersion,
                url: v['downloads']['loader']['url'],
                sha1: v['downloads']['loader']['sha1'],
                size: v['downloads']['loader']['size'],
                releaseTime: DateTime.parse(v['releaseTime']),
              ))
          .toList();
    } catch (e) {
      _logger.error('Failed to fetch Quilt versions: $e');
      return [];
    }
  }

  Future<List<LoaderVersion>> _fetchNeoForgeVersions(String mcVersion) async {
    final url =
        'https://maven.neoforged.net/releases/net/neoforged/forge/index_$mcVersion.json';
    final tempFile =
        File('${_platformAdapter.cacheDirectory}/neoforge_$mcVersion.json');

    try {
      await _downloadEngine.downloadFile(url, tempFile.path);
      final content = await tempFile.readAsString();
      final data = jsonDecode(content);

      final versions = <LoaderVersion>[];
      for (final entry in (data['promos'] as Map<String, dynamic>).entries) {
        if (entry.key.startsWith('$mcVersion-')) {
          final version = entry.key.replaceFirst('$mcVersion-', '');
          versions.add(LoaderVersion(
            version: version,
            mcVersion: mcVersion,
            url:
                'https://maven.neoforged.net/releases/net/neoforged/forge/$mcVersion-$version/forge-$mcVersion-$version-installer.jar',
            releaseTime: DateTime.now(),
          ));
        }
      }
      return versions;
    } catch (e) {
      _logger.error('Failed to fetch NeoForge versions: $e');
      return [];
    }
  }

  Future<void> _installForge(String mcVersion, String loaderVersion,
      String versionId, Function(double)? onProgress) async {
    final installerUrl =
        'https://maven.minecraftforge.net/net/minecraftforge/forge/$mcVersion-$loaderVersion/forge-$mcVersion-$loaderVersion-installer.jar';
    final installerFile = File(
        '${_platformAdapter.cacheDirectory}/forge_installer_$mcVersion-$loaderVersion.jar');

    await _downloadEngine.downloadFile(
      installerUrl,
      installerFile.path,
      onProgress: onProgress,
    );

    final versionsDir = Directory('${_platformAdapter.gameDirectory}/versions');
    await versionsDir.create(recursive: true);

    final process = await Process.start(
      'java',
      [
        '-jar',
        installerFile.path,
        '--installServer',
        versionsDir.path,
      ],
    );

    await process.stderr.forEach((line) {
      _logger.info(String.fromCharCodes(line));
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Forge installer failed with exit code $exitCode');
    }
  }

  Future<void> _installFabric(String mcVersion, String loaderVersion,
      String versionId, Function(double)? onProgress) async {
    final baseVersion = await getVersionInfo(mcVersion);

    final fabricVersionUrl =
        'https://meta.fabricmc.net/v2/versions/loader/$mcVersion/$loaderVersion/profile/json';
    final tempFile = File(
        '${_platformAdapter.cacheDirectory}/fabric_profile_$mcVersion-$loaderVersion.json');

    await _downloadEngine.downloadFile(fabricVersionUrl, tempFile.path);

    final content = await tempFile.readAsString();
    final fabricProfile = jsonDecode(content);

    final versionJson = {
      'id': versionId,
      'inheritsFrom': mcVersion,
      'jar': mcVersion,
      'type': 'release',
      'time': DateTime.now().toIso8601String(),
      'releaseTime': DateTime.now().toIso8601String(),
      'libraries': fabricProfile['libraries'],
      'mainClass': fabricProfile['mainClass'],
    };

    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    await versionDir.create(recursive: true);

    final jsonFile = File('${versionDir.path}/$versionId.json');
    await jsonFile.writeAsString(jsonEncode(versionJson));

    await _installLibraries(Version.fromJson(versionJson), (progress) {
      onProgress?.call(progress);
    });
  }

  Future<void> _installQuilt(String mcVersion, String loaderVersion,
      String versionId, Function(double)? onProgress) async {
    final quiltVersionUrl =
        'https://meta.quiltmc.org/v3/versions/loader/$mcVersion/$loaderVersion/profile/json';
    final tempFile = File(
        '${_platformAdapter.cacheDirectory}/quilt_profile_$mcVersion-$loaderVersion.json');

    await _downloadEngine.downloadFile(quiltVersionUrl, tempFile.path);

    final content = await tempFile.readAsString();
    final quiltProfile = jsonDecode(content);

    final versionJson = {
      'id': versionId,
      'inheritsFrom': mcVersion,
      'jar': mcVersion,
      'type': 'release',
      'time': DateTime.now().toIso8601String(),
      'releaseTime': DateTime.now().toIso8601String(),
      'libraries': quiltProfile['libraries'],
      'mainClass': quiltProfile['mainClass'],
    };

    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    await versionDir.create(recursive: true);

    final jsonFile = File('${versionDir.path}/$versionId.json');
    await jsonFile.writeAsString(jsonEncode(versionJson));

    await _installLibraries(Version.fromJson(versionJson), (progress) {
      onProgress?.call(progress);
    });
  }

  Future<void> _installNeoForge(String mcVersion, String loaderVersion,
      String versionId, Function(double)? onProgress) async {
    final installerUrl =
        'https://maven.neoforged.net/releases/net/neoforged/forge/$mcVersion-$loaderVersion/forge-$mcVersion-$loaderVersion-installer.jar';
    final installerFile = File(
        '${_platformAdapter.cacheDirectory}/neoforge_installer_$mcVersion-$loaderVersion.jar');

    await _downloadEngine.downloadFile(
      installerUrl,
      installerFile.path,
      onProgress: onProgress,
    );

    final versionsDir = Directory('${_platformAdapter.gameDirectory}/versions');
    await versionsDir.create(recursive: true);

    final process = await Process.start(
      'java',
      [
        '-jar',
        installerFile.path,
        '--installServer',
        versionsDir.path,
      ],
    );

    await process.stderr.forEach((line) {
      _logger.info(String.fromCharCodes(line));
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('NeoForge installer failed with exit code $exitCode');
    }
  }

  Future<void> _verifyLoaderInstallation(String versionId) async {
    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');
    final jsonFile = File('${versionDir.path}/$versionId.json');

    if (!await versionDir.exists() || !await jsonFile.exists()) {
      throw Exception(
          'Loader installation verification failed: version directory or json file missing');
    }

    final content = await jsonFile.readAsString();
    final versionData = jsonDecode(content);

    if (versionData['id'] != versionId) {
      throw Exception(
          'Loader installation verification failed: version ID mismatch');
    }
  }

  Future<void> _rollbackLoaderInstallation(
      String versionId, List<String> backupFiles) async {
    final versionDir =
        Directory('${_platformAdapter.gameDirectory}/versions/$versionId');

    if (await versionDir.exists()) {
      await versionDir.delete(recursive: true);
      _logger.info('Rolled back loader installation: $versionId');
    }
  }
}
