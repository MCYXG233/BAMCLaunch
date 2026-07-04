import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/network_client.dart';
import '../di/service_locator.dart';

/// Mod信息
class ModInfo {
  final String name;
  final String version;
  final String? modId;
  final String? fileName;
  final String? filePath;
  final DateTime? installedAt;

  ModInfo({
    required this.name,
    required this.version,
    this.modId,
    this.fileName,
    this.filePath,
    this.installedAt,
  });
}

/// Mod版本信息（来自API）
class ModVersionInfo {
  final String version;
  final String downloadUrl;
  final DateTime releaseDate;
  final String? changelog;
  final List<String>? gameVersions;

  ModVersionInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseDate,
    this.changelog,
    this.gameVersions,
  });
}

/// 更新状态
enum UpdateStatus {
  /// 无需更新
  upToDate,

  /// 有更新可用
  updateAvailable,

  /// 检查中
  checking,

  /// 检查失败
  error,
}

/// 更新检查结果
class UpdateCheckResult {
  final ModInfo modInfo;
  final UpdateStatus status;
  final ModVersionInfo? latestVersion;
  final String? errorMessage;

  UpdateCheckResult({
    required this.modInfo,
    required this.status,
    this.latestVersion,
    this.errorMessage,
  });
}

/// Mod更新检查器
class ModUpdateChecker {
  static ModUpdateChecker? _instance;

  final Logger _logger = Logger('ModUpdateChecker');

  /// 检查缓存（避免频繁检查）
  final Map<String, (DateTime, UpdateCheckResult)> _checkCache = {};

  /// 缓存有效期（1小时）
  static const Duration _cacheDuration = Duration(hours: 1);

  ModUpdateChecker._internal();

  /// 获取单例实例
  static ModUpdateChecker get instance {
    return ServiceLocator.instance.tryGet<ModUpdateChecker>() ??
        (_instance ??= ModUpdateChecker._internal());
  }

  /// 工厂构造函数
  factory ModUpdateChecker() => instance;

  /// 扫描实例目录，获取所有Mod信息
  Future<List<ModInfo>> scanForMods(String instancePath) async {
    final modsDir = Directory(path.join(instancePath, 'mods'));
    final modInfos = <ModInfo>[];

    if (!await modsDir.exists()) {
      return modInfos;
    }

    await for (final file in modsDir.list()) {
      if (file is File &&
          (file.path.endsWith('.jar') || file.path.endsWith('.litemod'))) {
        final modInfo = await _parseModFile(file);
        if (modInfo != null) {
          modInfos.add(modInfo);
        }
      }
    }

    return modInfos;
  }

  /// 解析Mod文件（简化实现）
  Future<ModInfo?> _parseModFile(File file) async {
    // 简单实现：从文件名获取信息
    // 实际应该读取jar包中的mod信息
    final fileName = path.basename(file.path);

    // 尝试解析文件名中的版本信息
    // 常见格式：modname-1.0.0.jar
    final nameParts = fileName.replaceAll('.jar', '').replaceAll('.litemod', '').split('-');

    String name = nameParts.first;
    String version = 'unknown';

    if (nameParts.length > 1) {
      // 假设最后一部分是版本号
      version = nameParts.last;

      // 如果有多个部分，尝试组合名称
      if (nameParts.length > 2) {
        name = nameParts.sublist(0, nameParts.length - 1).join('-');
      }
    }

    final fileStat = await file.stat();

    return ModInfo(
      name: name,
      version: version,
      fileName: fileName,
      filePath: file.path,
      installedAt: fileStat.modified,
    );
  }

  /// 检查单个Mod的更新
  Future<UpdateCheckResult> checkModUpdate(
    ModInfo modInfo, {
    bool forceCheck = false,
  }) async {
    final cacheKey = modInfo.fileName ?? modInfo.name;

    // 检查缓存
    if (!forceCheck && _checkCache.containsKey(cacheKey)) {
      final (cachedTime, cachedResult) = _checkCache[cacheKey]!;
      if (DateTime.now().difference(cachedTime) < _cacheDuration) {
        return cachedResult;
      }
    }

    try {
      // 尝试通过 Modrinth API 检查更新
      UpdateCheckResult result;

      try {
        final networkClient = NetworkClient();
        // 搜索匹配的项目
        final searchUrl = Uri.parse('https://api.modrinth.com/v2/search')
            .replace(queryParameters: {
          'query': modInfo.name,
          'limit': '5',
          'index': 'relevance',
        });
        final searchResponse = await networkClient.get(
          searchUrl.toString(),
          headers: {'Content-Type': 'application/json'},
          timeoutSeconds: 10,
        );

        if (searchResponse.statusCode == 200) {
          final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
          final hits = searchData['hits'] as List<dynamic>? ?? [];

          if (hits.isNotEmpty) {
            final projectId = (hits.first as Map<String, dynamic>)['project_id'] as String?;

            if (projectId != null) {
              // 获取项目最新版本
              final versionsUrl = Uri.parse(
                'https://api.modrinth.com/v2/project/$projectId/version',
              ).replace(queryParameters: {'limit': '1'});
              final versionsResponse = await networkClient.get(
                versionsUrl.toString(),
                headers: {'Content-Type': 'application/json'},
                timeoutSeconds: 10,
              );

              if (versionsResponse.statusCode == 200) {
                final versions = jsonDecode(versionsResponse.body) as List<dynamic>;
                if (versions.isNotEmpty) {
                  final latestVersion = versions.first as Map<String, dynamic>;
                  final versionNumber = latestVersion['version_number'] as String? ?? '';
                  final files = latestVersion['files'] as List<dynamic>? ?? [];
                  final primaryFile = files.isNotEmpty ? files.first as Map<String, dynamic> : null;

                  if (versionNumber.isNotEmpty && versionNumber != modInfo.version) {
                    result = UpdateCheckResult(
                      modInfo: modInfo,
                      status: UpdateStatus.updateAvailable,
                      latestVersion: ModVersionInfo(
                        version: versionNumber,
                        downloadUrl: primaryFile?['url'] as String? ?? '',
                        releaseDate: DateTime.tryParse(latestVersion['date_published'] as String? ?? '') ?? DateTime.now(),
                        changelog: latestVersion['changelog'] as String?,
                        gameVersions: (latestVersion['game_versions'] as List<dynamic>?)?.cast<String>(),
                      ),
                    );
                    _checkCache[cacheKey] = (DateTime.now(), result);
                    _logger.info('Checked update for ${modInfo.name}: ${result.status}');
                    return result;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.warn('API update check failed for ${modInfo.name}: $e');
      }

      result = UpdateCheckResult(
        modInfo: modInfo,
        status: UpdateStatus.upToDate,
      );

      // 更新缓存
      _checkCache[cacheKey] = (DateTime.now(), result);
      _logger.info('Checked update for ${modInfo.name}: ${result.status}');

      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to check update for ${modInfo.name}', e, stackTrace);

      final result = UpdateCheckResult(
        modInfo: modInfo,
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );

      _checkCache[cacheKey] = (DateTime.now(), result);
      return result;
    }
  }

  /// 批量检查所有Mod更新
  Future<List<UpdateCheckResult>> checkAllUpdates(
    List<ModInfo> mods, {
    bool forceCheck = false,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <UpdateCheckResult>[];

    for (var i = 0; i < mods.length; i++) {
      final result = await checkModUpdate(mods[i], forceCheck: forceCheck);
      results.add(result);

      if (onProgress != null) {
        onProgress(i + 1, mods.length);
      }
    }

    return results;
  }

  /// 获取有更新的Mod
  Future<List<UpdateCheckResult>> getAvailableUpdates(
    List<ModInfo> mods, {
    bool forceCheck = false,
  }) async {
    final results = await checkAllUpdates(mods, forceCheck: forceCheck);
    return results
        .where((r) => r.status == UpdateStatus.updateAvailable)
        .toList();
  }

  /// 清除缓存
  void clearCache() {
    _checkCache.clear();
  }

  /// 清除特定Mod的缓存
  void clearModCache(String modKey) {
    _checkCache.remove(modKey);
  }
}
