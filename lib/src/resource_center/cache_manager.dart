import 'dart:convert';
import 'models.dart';
import 'api_interface.dart';

/// 缓存条目
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// 缓存管理器
class CacheManager {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Duration defaultTtl;

  CacheManager({
    this.defaultTtl = const Duration(minutes: 30),
  });

  /// 获取缓存的搜索结果
  SearchResult? getSearchResult(String key) {
    final entry = _cache['search_$key'];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.data as SearchResult?;
  }

  /// 缓存搜索结果
  void setSearchResult(String key, SearchResult result, [Duration? ttl]) {
    _cache['search_$key'] = CacheEntry(
      data: result,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// 获取缓存的资源详情
  Resource? getResource(String source, String id) {
    final entry = _cache['resource_${source}_$id'];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.data as Resource?;
  }

  /// 缓存资源详情
  void setResource(Resource resource, [Duration? ttl]) {
    _cache['resource_${resource.source}_${resource.id}'] = CacheEntry(
      data: resource,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// 获取缓存的版本列表
  List<ResourceVersion>? getVersions(String source, String resourceId) {
    final entry = _cache['versions_${source}_$resourceId'];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.data as List<ResourceVersion>?;
  }

  /// 缓存版本列表
  void setVersions(
    String source,
    String resourceId,
    List<ResourceVersion> versions, [
    Duration? ttl,
  ]) {
    _cache['versions_${source}_$resourceId'] = CacheEntry(
      data: versions,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// 获取缓存的分类列表
  List<Category>? getCategories(String source, ResourceType type) {
    final entry = _cache['categories_${source}_${type.name}'];
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.data as List<Category>?;
  }

  /// 缓存分类列表
  void setCategories(
    String source,
    ResourceType type,
    List<Category> categories, [
    Duration? ttl,
  ]) {
    _cache['categories_${source}_${type.name}'] = CacheEntry(
      data: categories,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
  }

  /// 清除过期的缓存
  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
}

/// 带缓存的API包装器
class CachedResourceApi implements ResourceApi {
  final ResourceApi _api;
  final CacheManager _cache;

  CachedResourceApi(this._api, this._cache);

  @override
  String get source => _api.source;

  @override
  Future<SearchResult> search(SearchParams params) async {
    final cacheKey = _generateSearchKey(params);
    final cached = _cache.getSearchResult(cacheKey);
    if (cached != null) {
      return cached;
    }

    final result = await _api.search(params);
    _cache.setSearchResult(cacheKey, result);
    return result;
  }

  @override
  Future<Resource> getResource(String id) async {
    final cached = _cache.getResource(source, id);
    if (cached != null) {
      return cached;
    }

    final result = await _api.getResource(id);
    _cache.setResource(result);
    return result;
  }

  @override
  Future<List<ResourceVersion>> getVersions(String id) async {
    final cached = _cache.getVersions(source, id);
    if (cached != null) {
      return cached;
    }

    final result = await _api.getVersions(id);
    _cache.setVersions(source, id, result);
    return result;
  }

  @override
  Future<ResourceVersion> getVersion(String resourceId, String versionId) async {
    return await _api.getVersion(resourceId, versionId);
  }

  @override
  Future<List<Category>> getCategories(ResourceType type) async {
    final cached = _cache.getCategories(source, type);
    if (cached != null) {
      return cached;
    }

    final result = await _api.getCategories(type);
    _cache.setCategories(source, type, result);
    return result;
  }

  String _generateSearchKey(SearchParams params) {
    final buffer = StringBuffer();
    buffer.write('${params.query}_');
    buffer.write('${params.type?.name ?? 'all'}_');
    buffer.write('${params.gameVersions?.join(',') ?? ''}_');
    buffer.write('${params.loaders?.join(',') ?? ''}_');
    buffer.write('${params.categories?.join(',') ?? ''}_');
    buffer.write('${params.page}_');
    buffer.write('${params.pageSize}_');
    buffer.write('${params.sortBy}');
    return buffer.toString();
  }
}
