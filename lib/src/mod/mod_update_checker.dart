import 'dart:convert';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../resource_center/models.dart';
import 'mod_info.dart';

class ModUpdateChecker {
  static final Logger _logger = Logger('ModUpdateChecker');
  static const String _baseUrl = 'https://api.modrinth.com/v2';

  final NetworkClient _networkClient = NetworkClient();

  Future<List<ModUpdateInfo>> checkUpdates(
    List<ModInfo> mods, {
    String? gameVersion,
    String? loader,
  }) async {
    final updates = <ModUpdateInfo>[];

    for (final mod in mods) {
      try {
        final update = await checkModUpdate(mod, gameVersion: gameVersion, loader: loader);
        if (update != null && update.hasUpdate) {
          updates.add(update);
        }
      } catch (e, stackTrace) {
        _logger.debug('Failed to check update for ${mod.name}: $e', e, stackTrace);
      }
    }

    return updates;
  }

  Future<ModUpdateInfo?> checkModUpdate(
    ModInfo mod, {
    String? gameVersion,
    String? loader,
  }) async {
    if (mod.modId == null || mod.modId!.isEmpty) {
      return null;
    }

    try {
      final projectId = await _findProjectId(mod.modId!);
      if (projectId == null) {
        return null;
      }

      final latestVersion = await _getLatestVersion(projectId, gameVersion: gameVersion, loader: loader);
      if (latestVersion == null) {
        return null;
      }

      final currentVersion = mod.version ?? '0.0.0';
      final hasUpdate = _compareVersions(currentVersion, latestVersion.versionNumber) < 0;

      return ModUpdateInfo(
        mod: mod,
        currentVersion: currentVersion,
        latestVersion: latestVersion.versionNumber,
        latestVersionId: latestVersion.id,
        downloadUrl: latestVersion.download.url,
        hasUpdate: hasUpdate,
        changelog: latestVersion.changelog,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to check update for ${mod.modId}', e, stackTrace);
      return null;
    }
  }

  Future<String?> _findProjectId(String modIdOrSlug) async {
    final response = await _networkClient.get(
      '$_baseUrl/project/$modIdOrSlug',
      headers: NetworkClient.modrinthHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['id'] as String?;
    }

    return null;
  }

  Future<ResourceVersion?> _getLatestVersion(
    String projectId, {
    String? gameVersion,
    String? loader,
  }) async {
    final queryParams = <String, String>{
      'algorithm': 'desc',
      'game_versions': gameVersion ?? '["*"]',
      'loaders': loader ?? '["fabric", "forge", "quilt"]',
    };

    final response = await _networkClient.get(
      '$_baseUrl/project/$projectId/version',
      headers: NetworkClient.modrinthHeaders,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        return _getLatestVersionSimple(projectId);
      }
      return _parseVersion(data.first as Map<String, dynamic>);
    }

    return _getLatestVersionSimple(projectId);
  }

  Future<ResourceVersion?> _getLatestVersionSimple(String projectId) async {
    final response = await _networkClient.get(
      '$_baseUrl/project/$projectId/version',
      headers: NetworkClient.modrinthHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        return _parseVersion(data.first as Map<String, dynamic>);
      }
    }

    return null;
  }

  ResourceVersion _parseVersion(Map<String, dynamic> version) {
    final files = version['files'] as List<dynamic>;
    final primaryFile = files.firstWhere(
      (f) => f['primary'] as bool? ?? false,
      orElse: () => files.first,
    );

    final hashes = primaryFile['hashes'] as Map<String, dynamic>?;

    final download = VersionDownload(
      url: primaryFile['url'] as String,
      fileName: primaryFile['filename'] as String,
      fileSize: primaryFile['size'] as int,
      sha1: hashes?['sha1'] as String?,
      sha256: hashes?['sha512'] as String?,
    );

    final loaders = (version['loaders'] as List<dynamic>?)
            ?.map((l) => l as String)
            .toList() ??
        [];

    final gameVersions = (version['game_versions'] as List<dynamic>?)
            ?.map((v) => v as String)
            .toList() ??
        [];

    return ResourceVersion(
      id: version['id'] as String,
      versionNumber: version['version_number'] as String,
      name: version['name'] as String,
      releaseDate: DateTime.parse(version['date_published'] as String),
      gameVersions: gameVersions,
      loaders: loaders,
      download: download,
      changelog: version['changelog'] as String?,
    );
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = _parseVersionParts(v1);
    final parts2 = _parseVersionParts(v2);

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  List<int> _parseVersionParts(String version) {
    final cleanVersion = version.replaceAll(RegExp(r'^[vV]'), '').split('-').first;
    return cleanVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  Future<String?> downloadUpdate(ModUpdateInfo update, String destinationPath) async {
    try {
      await _networkClient.downloadFile(
        update.downloadUrl,
        destinationPath,
        headers: NetworkClient.modrinthHeaders,
      );
      return destinationPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to download update for ${update.mod.name}', e, stackTrace);
      return null;
    }
  }
}

class ModUpdateInfo {
  final ModInfo mod;
  final String currentVersion;
  final String latestVersion;
  final String latestVersionId;
  final String downloadUrl;
  final bool hasUpdate;
  final String? changelog;

  ModUpdateInfo({
    required this.mod,
    required this.currentVersion,
    required this.latestVersion,
    required this.latestVersionId,
    required this.downloadUrl,
    required this.hasUpdate,
    this.changelog,
  });

  String get modName => mod.name;
  String get modId => mod.modId ?? mod.id;
}
