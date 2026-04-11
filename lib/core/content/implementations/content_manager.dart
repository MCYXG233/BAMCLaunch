import '../interfaces/i_content_manager.dart';
import '../models/content_models.dart';
import '../api/curseforge_api.dart';
import '../api/modrinth_api.dart';
import '../../platform/i_platform_adapter.dart';
import '../../download/i_download_engine.dart';
import '../../logger/logger.dart';
import 'dart:io';

class ContentManager implements IContentManager {
  final IPlatformAdapter _platformAdapter;
  final IDownloadEngine _downloadEngine;
  final CurseForgeApi _curseforgeApi;
  final ModrinthApi _modrinthApi;

  // 缓存机制
  final Map<String, SearchResult> _searchCache = {};
  final Map<String, ContentItem> _contentDetailsCache = {};
  final Map<String, List<ContentItem>> _popularCache = {};
  final Duration _cacheDuration = const Duration(minutes: 30);

  ContentManager({
    required IPlatformAdapter platformAdapter,
    required IDownloadEngine downloadEngine,
  })  : _platformAdapter = platformAdapter,
        _downloadEngine = downloadEngine,
        _curseforgeApi = CurseForgeApi(),
        _modrinthApi = ModrinthApi();

  @override
  Future<SearchResult> searchContent(SearchQuery query) async {
    try {
      // 生成缓存键
      final cacheKey = _generateSearchCacheKey(query);

      // 检查缓存
      if (_searchCache.containsKey(cacheKey)) {
        final cachedResult = _searchCache[cacheKey]!;
        // 缓存有效期检查
        if (DateTime.now().difference(cachedResult.timestamp) <
            _cacheDuration) {
          return cachedResult;
        }
      }

      final results = <SearchResult>[];

      // 尝试从CurseForge搜索
      try {
        if (_curseforgeApi.isConfigured) {
          final curseforgeResult = await _curseforgeApi.search(query);
          results.add(curseforgeResult);
        }
      } catch (e) {
        logger.warn('CurseForge搜索失败: $e');
      }

      // 尝试从Modrinth搜索
      try {
        final modrinthResult = await _modrinthApi.search(query);
        results.add(modrinthResult);
      } catch (e) {
        logger.warn('Modrinth搜索失败: $e');
      }

      // 合并结果
      final combinedItems = results.expand((result) => result.items).toList();
      final totalCount =
          results.fold(0, (sum, result) => sum + result.totalCount);

      final result = SearchResult(
        items: combinedItems,
        totalCount: totalCount,
        currentPage: query.page,
        totalPages: totalCount > 0 ? (totalCount / query.pageSize).ceil() : 0,
        timestamp: DateTime.now(),
      );

      // 更新缓存
      _searchCache[cacheKey] = result;
      return result;
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  @override
  Future<ContentInstallResult> installContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  }) async {
    try {
      final contentDir = _getContentDirectory(item.type, versionId);
      await Directory(contentDir).create(recursive: true);

      final filePath = '$contentDir/${item.name}_${item.version}.jar';

      try {
        await _downloadEngine.downloadFile(
          item.downloadUrl,
          filePath,
          onProgress: onProgress,
        );
      } catch (e) {
        return ContentInstallResult(
          success: false,
          errorMessage: '下载失败: $e',
          missingDependencies: [],
          conflicts: [],
        );
      }

      final conflicts = await checkConflicts(item);
      final dependencies = await checkDependencies(item);

      return ContentInstallResult(
        success: true,
        installedItem: item.copyWith(status: ContentStatus.installed),
        missingDependencies: dependencies.missingDependencies,
        conflicts: conflicts.map((c) => c.conflictReason).toList(),
      );
    } catch (e) {
      return ContentInstallResult(
        success: false,
        errorMessage: 'Installation failed: $e',
        missingDependencies: [],
        conflicts: [],
      );
    }
  }

  @override
  Future<ContentInstallResult> updateContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  }) async {
    return installContent(
      item: item,
      versionId: versionId,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> uninstallContent(String contentId, ContentType type) async {
    final versions = await getInstalledVersions();
    for (final versionId in versions) {
      final contentDir = _getContentDirectory(type, versionId);
      final files = Directory(contentDir).listSync();
      for (final file in files) {
        if (file is File && file.path.contains(contentId)) {
          await file.delete();
        }
      }
    }
  }

  @override
  Future<List<ContentItem>> getInstalledContent(ContentType type) async {
    final installedItems = <ContentItem>[];
    final versions = await getInstalledVersions();

    for (final versionId in versions) {
      final contentDir = _getContentDirectory(type, versionId);
      if (await Directory(contentDir).exists()) {
        final files = Directory(contentDir).listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.jar')) {
            final item = _parseLocalContent(file, type, versionId);
            if (item != null) {
              installedItems.add(item);
            }
          }
        }
      }
    }

    return installedItems;
  }

  @override
  Future<List<ContentItem>> checkForUpdates(ContentType type) async {
    final installedItems = await getInstalledContent(type);
    final itemsWithUpdates = <ContentItem>[];

    for (final item in installedItems) {
      try {
        ContentItem? latestVersion;
        if (item.source == ContentSource.curseforge) {
          latestVersion = await _curseforgeApi.getModDetails(item.id);
        } else if (item.source == ContentSource.modrinth) {
          latestVersion = await _modrinthApi.getProjectDetails(item.id);
        }

        if (latestVersion != null && latestVersion.version != item.version) {
          itemsWithUpdates
              .add(item.copyWith(status: ContentStatus.updateAvailable));
        }
      } catch (e) {
        continue;
      }
    }

    return itemsWithUpdates;
  }

  @override
  Future<List<ConflictInfo>> checkConflicts(ContentItem item) async {
    final conflicts = <ConflictInfo>[];
    final installedItems = await getInstalledContent(item.type);

    for (final installedItem in installedItems) {
      // 检查ID冲突（重复安装）
      if (installedItem.id == item.id) {
        conflicts.add(ConflictInfo(
          existingItem: installedItem,
          newItem: item,
          conflictReason: '该内容已安装',
        ));
        continue;
      }

      // 检查已知冲突
      for (final conflictId in installedItem.conflicts) {
        if (conflictId == item.id) {
          conflicts.add(ConflictInfo(
            existingItem: installedItem,
            newItem: item,
            conflictReason: '与已安装的 ${installedItem.name} 存在冲突',
          ));
        }
      }

      // 检查新内容的冲突列表
      for (final conflictId in item.conflicts) {
        if (conflictId == installedItem.id) {
          conflicts.add(ConflictInfo(
            existingItem: installedItem,
            newItem: item,
            conflictReason: '${item.name} 与已安装的 ${installedItem.name} 存在冲突',
          ));
        }
      }

      // 检查游戏版本兼容性冲突
      if (_checkGameVersionConflict(installedItem, item)) {
        conflicts.add(ConflictInfo(
          existingItem: installedItem,
          newItem: item,
          conflictReason: '游戏版本不兼容',
        ));
      }

      // 检查加载器冲突
      if (_checkLoaderConflict(installedItem, item)) {
        conflicts.add(ConflictInfo(
          existingItem: installedItem,
          newItem: item,
          conflictReason: '模组加载器不兼容',
        ));
      }

      // 检查文件冲突（对于模组）
      if (item.type == ContentType.mod) {
        final fileConflicts = await _checkFileConflicts(installedItem, item);
        conflicts.addAll(fileConflicts);
      }
    }

    return conflicts;
  }

  bool _checkGameVersionConflict(ContentItem existing, ContentItem newItem) {
    // 检查是否有共同的游戏版本
    final commonVersions = existing.gameVersions
        .toSet()
        .intersection(newItem.gameVersions.toSet());
    return commonVersions.isEmpty;
  }

  bool _checkLoaderConflict(ContentItem existing, ContentItem newItem) {
    // 检查是否有共同的加载器
    final commonLoaders =
        existing.loaders.toSet().intersection(newItem.loaders.toSet());
    return commonLoaders.isEmpty;
  }

  Future<List<ConflictInfo>> _checkFileConflicts(
      ContentItem existing, ContentItem newItem) async {
    final conflicts = <ConflictInfo>[];

    try {
      // 这里可以实现更复杂的文件冲突检测逻辑
      // 例如检查模组JAR文件中的类名冲突、资源文件冲突等
      // 目前返回空列表，后续可以扩展
    } catch (e) {
      logger.warn('文件冲突检测失败: $e');
    }

    return conflicts;
  }

  @override
  Future<DependencyInfo> checkDependencies(ContentItem item) async {
    final missingDependencies = <ContentDependency>[];

    for (final dep in item.dependencies) {
      try {
        // 检查依赖是否已安装
        final isInstalled = await isContentInstalled(dep.id, ContentType.mod);

        if (!isInstalled && dep.isRequired) {
          // 解析依赖详细信息
          final resolvedDep = await _resolveDependencyDetails(dep);
          if (resolvedDep != null) {
            missingDependencies.add(resolvedDep);
          }
        } else if (isInstalled) {
          // 检查版本兼容性
          final installedVersion =
              await getInstalledVersion(dep.id, ContentType.mod);
          if (installedVersion != null && dep.version != null) {
            if (!_isVersionCompatible(installedVersion, dep.version!)) {
              // 版本不兼容，添加到缺失依赖中（需要更新）
              final resolvedDep = await _resolveDependencyDetails(dep);
              if (resolvedDep != null) {
                missingDependencies.add(resolvedDep.copyWith(
                  version: dep.version,
                ));
              }
            }
          }
        }
      } catch (e) {
        logger.warn('检查依赖失败: ${dep.id}, 错误: $e');
        if (dep.isRequired) {
          missingDependencies.add(dep);
        }
      }
    }

    return DependencyInfo(
      item: item,
      missingDependencies: missingDependencies,
    );
  }

  @override
  Future<List<ContentDependency>> resolveDependencies(
      List<ContentDependency> dependencies) async {
    final resolvedDependencies = <ContentDependency>[];

    for (final dep in dependencies) {
      try {
        final resolvedDep = await _resolveDependencyDetails(dep);
        if (resolvedDep != null) {
          resolvedDependencies.add(resolvedDep);
        }
      } catch (e) {
        logger.warn('解析依赖失败: ${dep.id}, 错误: $e');
        // 如果是必需依赖，添加原始依赖信息
        if (dep.isRequired) {
          resolvedDependencies.add(dep);
        }
      }
    }

    return resolvedDependencies;
  }

  Future<ContentDependency?> _resolveDependencyDetails(
      ContentDependency dep) async {
    try {
      ContentItem? depDetails;
      if (dep.id.contains('-')) {
        // Modrinth项目ID格式
        depDetails = await _modrinthApi.getProjectDetails(dep.id);
      } else {
        // CurseForge项目ID格式
        depDetails = await _curseforgeApi.getModDetails(dep.id);
      }

      return dep.copyWith(
        name: depDetails.name,
        version: dep.version ?? depDetails.version,
      );
    } catch (e) {
      logger.warn('获取依赖详情失败: ${dep.id}, 错误: $e');
    }
    return null;
  }

  bool _isVersionCompatible(String installedVersion, String requiredVersion) {
    try {
      // 简单的版本比较逻辑
      final installedParts = installedVersion
          .split('.')
          .map(int.tryParse)
          .whereType<int>()
          .toList();
      final requiredParts = requiredVersion
          .split('.')
          .map(int.tryParse)
          .whereType<int>()
          .toList();

      // 比较主版本号
      if (installedParts.isNotEmpty && requiredParts.isNotEmpty) {
        if (installedParts[0] > requiredParts[0]) {
          return true;
        } else if (installedParts[0] == requiredParts[0]) {
          // 比较次版本号
          if (installedParts.length > 1 && requiredParts.length > 1) {
            return installedParts[1] >= requiredParts[1];
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      // 如果版本格式无法解析，假设兼容
      return true;
    }
  }

  @override
  Future<void> installDependencies(List<ContentDependency> dependencies) async {
    for (final dep in dependencies) {
      try {
        ContentItem? depItem;
        if (dep.id.contains('-')) {
          depItem = await _modrinthApi.getProjectDetails(dep.id);
        } else {
          depItem = await _curseforgeApi.getModDetails(dep.id);
        }

        await installContent(
          item: depItem,
          versionId: 'latest',
        );
      } catch (e) {
        continue;
      }
    }
  }

  @override
  Future<ContentItem> getContentDetails(
      String contentId, ContentSource source) async {
    final cacheKey = '$contentId-${source.toString()}';

    // 检查缓存
    if (_contentDetailsCache.containsKey(cacheKey)) {
      return _contentDetailsCache[cacheKey]!;
    }

    ContentItem item;
    if (source == ContentSource.curseforge) {
      item = await _curseforgeApi.getModDetails(contentId);
    } else if (source == ContentSource.modrinth) {
      item = await _modrinthApi.getProjectDetails(contentId);
    } else {
      throw Exception('Unsupported source');
    }

    // 更新缓存
    _contentDetailsCache[cacheKey] = item;
    return item;
  }

  @override
  Future<List<ContentItem>> getPopularContent(ContentType type,
      {int limit = 10}) async {
    final cacheKey = 'popular_${type.toString()}_$limit';

    // 检查缓存
    if (_popularCache.containsKey(cacheKey)) {
      return _popularCache[cacheKey]!;
    }

    final curseforgePopular =
        await _curseforgeApi.getPopularMods(type, limit: limit ~/ 2);
    final modrinthPopular =
        await _modrinthApi.getPopularProjects(type, limit: limit ~/ 2);

    final result =
        [...curseforgePopular, ...modrinthPopular].take(limit).toList();

    // 更新缓存
    _popularCache[cacheKey] = result;
    return result;
  }

  @override
  Future<List<ContentItem>> getFeaturedContent(ContentType type,
      {int limit = 10}) async {
    return getPopularContent(type, limit: limit);
  }

  @override
  Future<void> refreshContentCache() async {
    _searchCache.clear();
    _contentDetailsCache.clear();
    _popularCache.clear();
  }

  @override
  Future<bool> isContentInstalled(String contentId, ContentType type) async {
    final installedItems = await getInstalledContent(type);
    return installedItems.any((item) => item.id == contentId);
  }

  @override
  Future<String?> getInstalledVersion(
      String contentId, ContentType type) async {
    final installedItems = await getInstalledContent(type);
    final item =
        installedItems.where((item) => item.id == contentId).firstOrNull;
    return item?.version;
  }

  @override
  Future<void> validateContentIntegrity(
      String contentId, ContentType type) async {}

  String _getContentDirectory(ContentType type, String versionId) {
    final gameDir = _platformAdapter.gameDirectory;
    switch (type) {
      case ContentType.mod:
        return '$gameDir/$versionId/mods';
      case ContentType.modpack:
        return '$gameDir/modpacks';
      case ContentType.resourcePack:
        return '$gameDir/resourcepacks';
      case ContentType.shaderPack:
        return '$gameDir/shaderpacks';
      case ContentType.dataPack:
        return '$gameDir/$versionId/datapacks';
      case ContentType.map:
        return '$gameDir/saves';
    }
  }

  Future<List<String>> getInstalledVersions() async {
    final gameDir = _platformAdapter.gameDirectory;
    final versionsDir = Directory('$gameDir/versions');
    if (!await versionsDir.exists()) {
      return [];
    }

    return versionsDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => dir.path.split(Platform.pathSeparator).last)
        .toList();
  }

  ContentItem? _parseLocalContent(
      File file, ContentType type, String versionId) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final name = fileName.replaceAll(RegExp(r'_[0-9].*\.jar$'), '');

    return ContentItem(
      id: fileName,
      name: name,
      author: 'Unknown',
      description: 'Local content',
      version: 'local',
      downloadUrl: '',
      downloadCount: 0,
      type: type,
      source: ContentSource.local,
      status: ContentStatus.installed,
      gameVersions: [versionId],
      loaders: [],
      dependencies: [],
      conflicts: [],
    );
  }

  String _generateSearchCacheKey(SearchQuery query) {
    return 'search_${query.query}_${query.type}_${query.gameVersion}_${query.loader}_${query.category}_${query.author}_${query.sortType}_${query.ascending}_${query.page}_${query.pageSize}';
  }
}

extension ContentItemCopyWith on ContentItem {
  ContentItem copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    String? version,
    String? downloadUrl,
    int? downloadCount,
    String? iconUrl,
    DateTime? releaseDate,
    ContentType? type,
    ContentSource? source,
    ContentStatus? status,
    String? installedVersion,
    List<String>? gameVersions,
    List<String>? loaders,
    List<ContentDependency>? dependencies,
    List<String>? conflicts,
  }) {
    return ContentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      description: description ?? this.description,
      version: version ?? this.version,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadCount: downloadCount ?? this.downloadCount,
      iconUrl: iconUrl ?? this.iconUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      type: type ?? this.type,
      source: source ?? this.source,
      status: status ?? this.status,
      installedVersion: installedVersion ?? this.installedVersion,
      gameVersions: gameVersions ?? this.gameVersions,
      loaders: loaders ?? this.loaders,
      dependencies: dependencies ?? this.dependencies,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}
