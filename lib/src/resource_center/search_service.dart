import 'models.dart';
import 'modrinth_api.dart';
import 'api_interface.dart';

/// 资源搜索服务
///
/// 聚合多个资源平台（Modrinth、CurseForge）的搜索结果。
/// 当前已接入 Modrinth 真实 API，CurseForge 待配置 API Key 后启用。
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

  /// Modrinth API 客户端（免费，无需密钥）
  final ResourceApi _modrinthApi = ModrinthApi();

  /// CurseForge API 客户端（需要 API Key，暂未启用）
  ResourceApi? _curseforgeApi;

  /// 启用 CurseForge 数据源
  ///
  /// 提供 API Key 后调用此方法即可启用 CurseForge 搜索。
  /// 获取 API Key: https://console.curseforge.com/
  void enableCurseForge(String apiKey) {
    // CurseForgeApi 将在后续版本中接入
    // _curseforgeApi = CurseForgeApi(apiKey: apiKey);
  }

  /// 搜索资源
  ///
  /// 从 Modrinth 获取真实搜索结果。
  /// 如果启用了 CurseForge，会同时搜索两个平台并合并结果。
  Future<SearchResult> search(SearchParams params) async {
    try {
      // 使用 Modrinth 真实 API 搜索
      final result = await _modrinthApi.search(params);

      // TODO: 当 CurseForge API Key 配置后，启用聚合搜索
      // if (_curseforgeApi != null) {
      //   final cfResult = await _curseforgeApi!.search(params);
      //   result = _mergeResults(result, cfResult, params);
      // }

      return result;
    } catch (e) {
      // 网络错误时提供友好提示
      throw Exception('搜索失败，请检查网络连接: $e');
    }
  }

  /// 获取资源详情
  Future<Resource> getResource(String id, {String source = 'modrinth'}) async {
    try {
      if (source == 'curseforge' && _curseforgeApi != null) {
        return await _curseforgeApi!.getResource(id);
      }
      return await _modrinthApi.getResource(id);
    } catch (e) {
      throw Exception('获取资源详情失败: $e');
    }
  }

  /// 获取资源版本列表
  Future<List<ResourceVersion>> getVersions(String id, {String source = 'modrinth'}) async {
    try {
      if (source == 'curseforge' && _curseforgeApi != null) {
        return await _curseforgeApi!.getVersions(id);
      }
      return await _modrinthApi.getVersions(id);
    } catch (e) {
      throw Exception('获取版本列表失败: $e');
    }
  }

  /// 获取单个版本信息
  Future<ResourceVersion> getVersion(String resourceId, String versionId, {String source = 'modrinth'}) async {
    try {
      if (source == 'curseforge' && _curseforgeApi != null) {
        return await _curseforgeApi!.getVersion(resourceId, versionId);
      }
      return await _modrinthApi.getVersion(resourceId, versionId);
    } catch (e) {
      throw Exception('获取版本信息失败: $e');
    }
  }
}
