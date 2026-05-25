import 'dart:async';
import '../core/logger.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import 'api_interface.dart';
import 'curseforge_api.dart';
import 'modrinth_api.dart';
import 'models.dart';
import 'cache_manager.dart';

/// 搜索来源枚举
enum SearchSource {
  /// Modrinth,
  modrinth,

  /// CurseForge,
  curseforge,

  /// 所有来源
  all,
}

/// 搜索服务
class SearchService {
  static SearchService? _instance;

  factory SearchService() {
    return _instance ??= SearchService._internal();
  }

  SearchService._internal();

  static SearchService get instance => _instance ??= SearchService._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger();
  final EventBus _eventBus = EventBus.instance;
  final CacheManager _cacheManager = CacheManager();

  final Map<SearchSource, ResourceApi> _apis = {};

  bool _initialized = false;

  /// 当前搜索来源
  SearchSource currentSource = SearchSource.all;

  /// 初始化搜索服务
  Future<void> initialize() async {
    if (_initialized) return;

    _apis[SearchSource.modrinth] = ModrinthApi();
    _apis[SearchSource.curseforge] = CurseForgeApi(apiKey: '');

    _initialized = true;
    _logger.info('SearchService initialized');
  }

  /// 获取指定来源的API
  ResourceApi? _getApi(SearchSource source) {
    return _apis[source];
  }

  /// 搜索资源
  Future<SearchResult> search(
    SearchParams params, {
    SearchSource? source,
    bool useCache = true,
  }) async {
    await initialize();

    final searchSource = source ?? currentSource;
    _eventBus.publish(SearchResourcesEvent(params: params));

    try {
      if (searchSource == SearchSource.all) {
        return await _searchAll(params);
      } else {
        return await _searchSingle(searchSource, params, useCache);
      }
    } catch (e, stackTrace) {
      _logger.error('Search failed', e, stackTrace);
      _eventBus.publish(SearchFailedEvent(error: e));
      rethrow;
    }
  }

  /// 从单个来源搜索
  Future<SearchResult> _searchSingle(
    SearchSource source,
    SearchParams params,
    bool useCache,
  ) async {
    final api = _getApi(source);
    if (api == null) {
      throw Exception('API not found for source: $source');
    }

    final cacheKey = _generateCacheKey(source, params);

    if (useCache) {
      final cached = await _cacheManager.getSearchResult(cacheKey);
      if (cached != null) {
        _logger.info('Returning cached search results');
        _eventBus.publish(SearchCompletedEvent(result: cached));
        return cached;
      }
    }

    final result = await api.search(params);

    _cacheManager.setSearchResult(cacheKey, result);

    _eventBus.publish(SearchCompletedEvent(result: result));
    return result;
  }

  /// 从所有来源搜索
  Future<SearchResult> _searchAll(SearchParams params) async {
    final futures = <Future<SearchResult>>[];

    for (final source in [SearchSource.modrinth, SearchSource.curseforge]) {
      futures.add(_searchSingle(source, params, true));
    }

    final results = await Future.wait(futures);

    final allResources = <Resource>[];
    int totalResults = 0;

    for (final result in results) {
      allResources.addAll(result.resources);
      totalResults += result.totalResults;
    }

    allResources.sort((a, b) => b.downloads.compareTo(a.downloads));

    final combined = SearchResult(
      resources: allResources,
      totalResults: totalResults,
      page: params.page,
      pageSize: params.pageSize,
    );

    _eventBus.publish(SearchCompletedEvent(result: combined));
    return combined;
  }

  /// 获取资源详情
  Future<Resource> getResource(
    String resourceId,
    SearchSource source, {
    bool useCache = true,
  }) async {
    await initialize();

    _eventBus.publish(GetResourceEvent(resourceId: resourceId, source: source.name));

    final api = _getApi(source);
    if (api == null) {
      throw Exception('API not found for source: $source');
    }

    if (useCache) {
      final cached = _cacheManager.getResource(source.name, resourceId);
      if (cached != null) {
        _logger.info('Returning cached resource details');
        _eventBus.publish(ResourceRetrievedEvent(resource: cached));
        return cached;
      }
    }

    final resource = await api.getResource(resourceId);

    _cacheManager.setResource(resource);

    _eventBus.publish(ResourceRetrievedEvent(resource: resource));
    return resource;
  }

  /// 获取资源版本列表
  Future<List<ResourceVersion>> getVersions(
    String resourceId,
    SearchSource source, {
    bool useCache = true,
  }) async {
    await initialize();

    _eventBus.publish(GetVersionsEvent(resourceId: resourceId, source: source.name));

    final api = _getApi(source);
    if (api == null) {
      throw Exception('API not found for source: $source');
    }

    if (useCache) {
      final cached = _cacheManager.getVersions(source.name, resourceId);
      if (cached != null) {
        _logger.info('Returning cached versions');
        _eventBus.publish(VersionsRetrievedEvent(versions: cached));
        return cached;
      }
    }

    final versions = await api.getVersions(resourceId);

    _cacheManager.setVersions(source.name, resourceId, versions);

    _eventBus.publish(VersionsRetrievedEvent(versions: versions));
    return versions;
  }

  /// 获取资源的单个版本
  Future<ResourceVersion> getVersion(
    String resourceId,
    String versionId,
    SearchSource source,
  ) async {
    await initialize();

    final api = _getApi(source);
    if (api == null) {
      throw Exception('API not found for source: $source');
    }

    return await api.getVersion(resourceId, versionId);
  }

  /// 获取分类列表
  Future<List<Category>> getCategories(
    ResourceType type,
    SearchSource source,
  ) async {
    await initialize();

    final api = _getApi(source);
    if (api == null) {
      throw Exception('API not found for source: $source');
    }

    return await api.getCategories(type);
  }

  /// 生成缓存键
  String _generateCacheKey(SearchSource source, SearchParams params) {
    final buffer = StringBuffer('search_${source.name}_');
    buffer.write('q${params.query}_');
    buffer.write('t${params.type?.name ?? 'all'}_');
    buffer.write('p${params.page}_');
    buffer.write('s${params.pageSize}_');
    buffer.write('o${params.sortBy}');
    return buffer.toString();
  }

  /// 清除缓存
  Future<void> clearCache() async {
    _cacheManager.clear();
    _logger.info('Search cache cleared');
  }
}
