import 'models.dart';

/// 资源中心API接口
abstract class ResourceApi {
  /// API来源标识
  String get source;

  /// 搜索资源
  ///
  /// [params] 搜索参数
  Future<SearchResult> search(SearchParams params);

  /// 获取资源详情
  ///
  /// [id] 资源ID
  Future<Resource> getResource(String id);

  /// 获取资源版本列表
  ///
  /// [id] 资源ID
  Future<List<ResourceVersion>> getVersions(String id);

  /// 获取资源的单个版本
  ///
  /// [resourceId] 资源ID
  /// [versionId] 版本ID
  Future<ResourceVersion> getVersion(String resourceId, String versionId);

  /// 获取分类列表
  Future<List<Category>> getCategories(ResourceType type);
}
