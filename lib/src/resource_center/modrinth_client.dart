import 'dart:convert';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import 'models.dart';

/// Modrinth API 客户端
///
/// 提供对 Modrinth REST API 的访问，支持：
/// - 搜索项目（Mod / 资源包 / 整合包）
/// - 获取项目详情
/// - 获取项目版本
/// - 下载文件
///
/// ## 使用方式
///
/// ```dart
/// final modrinth = ModrinthClient();
///
/// // 搜索
/// final result = await modrinth.search(
///   query: 'sodium',
///   type: ResourceType.mod,
/// );
///
/// // 获取项目
/// final project = await modrinth.getProject('AANobbMI');
///
/// // 获取版本
/// final versions = await modrinth.getVersions('AANobbMI');
/// ```
///
/// ## API 参考
///
/// Modrinth v2 API: https://docs.modrinth.com/api
class ModrinthClient {
  final String baseUrl = 'https://api.modrinth.com/v2';
  final Logger _logger = Logger();
  final NetworkClient _networkClient = NetworkClient();

  /// 创建 Modrinth 客户端
  ModrinthClient();

  /// 搜索项目
  ///
  /// [query] 搜索关键词
  /// [type] 资源类型（mod / resourcepack / modpack）
  /// [gameVersions] 支持的游戏版本列表，如 ['1.20.4', '1.20.2']
  /// [loaders] Mod 加载器列表，如 ['fabric', 'forge']
  /// [categories] 分类标签，如 ['optimization', 'library']
  /// [sortBy] 排序方式，默认 'relevance'
  ///   - relevance: 相关度
  ///   - downloads: 下载量
  ///   - follows: 收藏量
  ///   - newest: 最新发布
  ///   - updated: 最近更新
  /// [page] 页码（从1开始）
  /// [pageSize] 每页数量
  ///
  /// 返回搜索结果，包含资源列表和总数
  Future<SearchResult> search({
    String query = '',
    ResourceType? type,
    List<String>? gameVersions,
    List<String>? loaders,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'relevance',
  }) async {
    final index = (page - 1) * pageSize;

    // 构建 facets 参数
    final facets = <List<String>>[];
    if (type != null) {
      final typeValue = _typeToString(type);
      facets.add(['project_type:$typeValue']);
    }
    if (loaders != null && loaders.isNotEmpty) {
      for (final loader in loaders) {
        facets.add(['categories:$loader']);
      }
    }
    if (gameVersions != null && gameVersions.isNotEmpty) {
      for (final v in gameVersions) {
        facets.add(['versions:$v']);
      }
    }
    if (categories != null && categories.isNotEmpty) {
      for (final cat in categories) {
        facets.add(['categories:$cat']);
      }
    }

    final queryParams = <String, String>{
      'query': query,
      'limit': pageSize.toString(),
      'offset': index.toString(),
      'index': sortBy,
    };

    if (facets.isNotEmpty) {
      queryParams['facets'] = json.encode(facets);
    }

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);

    _logger.info('[Modrinth] 搜索: ${uri.toString()}');

    try {
      final response = await _networkClient.get(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        timeoutSeconds: 15,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final hits = data['hits'] as List<dynamic>;
        final total = data['total_hits'] as int? ?? hits.length;

        final resources = hits.map((hit) {
          final hitMap = hit as Map<String, dynamic>;
          return Resource(
            id: hitMap['project_id'] as String? ?? hitMap['id'] as String,
            type: _parseResourceType(hitMap['project_type'] as String?),
            source: 'modrinth',
            name: hitMap['title'] as String? ?? hitMap['name'] as String? ?? 'Unknown',
            description: hitMap['description'] as String? ?? '',
            summary: hitMap['summary'] as String?,
            authors: (hitMap['author'] as String?) != null
                ? [Author(id: 'author', name: hitMap['author'] as String)]
                : [],
            categories: (hitMap['categories'] as List<dynamic>?)?.cast<String>() ?? [],
            downloads: hitMap['downloads'] as int? ?? 0,
            likes: hitMap['follows'] as int? ?? 0,
            pageUrl: 'https://modrinth.com/${_typeToString(_parseResourceType(hitMap['project_type'] as String?))}/${hitMap['slug'] as String? ?? hitMap['id'] as String}',
            iconUrl: hitMap['icon_url'] as String?,
            publishedDate: hitMap['published'] != null
                ? DateTime.tryParse(hitMap['published'] as String)
                : null,
            updatedDate: hitMap['date_modified'] != null
                ? DateTime.tryParse(hitMap['date_modified'] as String)
                : null,
            supportedGameVersions: (hitMap['versions'] as List<dynamic>?)?.cast<String>() ?? [],
            supportedLoaders: (hitMap['loaders'] as List<dynamic>?)?.cast<String>() ?? [],
            slug: hitMap['slug'] as String?,
          );
        }).toList();

        return SearchResult(
          resources: resources,
          totalResults: total,
          page: page,
          pageSize: pageSize,
        );
      } else {
        throw NetworkException.fromStatusCode(response.statusCode);
      }
    } catch (e) {
      _logger.error('[Modrinth] 搜索异常: $e');
      rethrow;
    }
  }

  /// 获取项目详情
  Future<Resource> getProject(String projectId) async {
    final uri = Uri.parse('$baseUrl/project/$projectId');

    _logger.info('[Modrinth] 获取项目: $projectId');

    try {
      final response = await _networkClient.get(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        timeoutSeconds: 15,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Resource(
          id: data['id'] as String,
          type: _parseResourceType(data['project_type'] as String?),
          source: 'modrinth',
          name: data['title'] as String? ?? data['name'] as String? ?? 'Unknown',
          slug: data['slug'] as String?,
          description: data['body'] as String? ?? data['description'] as String? ?? '',
          summary: data['summary'] as String?,
          authors: [
            Author(id: 'author', name: data['author'] as String? ?? 'Unknown'),
          ],
          categories: (data['categories'] as List<dynamic>?)?.cast<String>() ?? [],
          downloads: data['downloads'] as int? ?? 0,
          likes: data['follows'] as int? ?? 0,
          pageUrl: data['url'] as String? ?? 'https://modrinth.com/project/$projectId',
          iconUrl: data['icon_url'] as String?,
          publishedDate: data['published'] != null
              ? DateTime.tryParse(data['published'] as String)
              : null,
          updatedDate: data['updated'] != null
              ? DateTime.tryParse(data['updated'] as String)
              : null,
          supportedGameVersions: (data['game_versions'] as List<dynamic>?)?.cast<String>() ?? [],
          supportedLoaders: (data['loaders'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      } else {
        throw NetworkException.fromStatusCode(response.statusCode);
      }
    } catch (e) {
      _logger.error('[Modrinth] 获取项目异常: $e');
      rethrow;
    }
  }

  /// 获取项目的所有版本
  ///
  /// [projectId] 项目ID或slug
  /// [gameVersions] 筛选游戏版本
  /// [loaders] 筛选加载器
  Future<List<ResourceVersion>> getVersions(
    String projectId, {
    List<String>? gameVersions,
    List<String>? loaders,
  }) async {
    final params = <String, String>{};
    if (gameVersions != null && gameVersions.isNotEmpty) {
      params['game_versions'] = json.encode(gameVersions);
    }
    if (loaders != null && loaders.isNotEmpty) {
      params['loaders'] = json.encode(loaders);
    }

    final uri = Uri.parse('$baseUrl/project/$projectId/version')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    _logger.info('[Modrinth] 获取版本: $projectId');

    try {
      final response = await _networkClient.get(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        timeoutSeconds: 15,
      );

      if (response.statusCode == 200) {
        final List<dynamic> versions = json.decode(response.body) as List<dynamic>;
        return versions.map((v) {
          final vMap = v as Map<String, dynamic>;
          final files = vMap['files'] as List<dynamic>? ?? [];
          final primaryFile = files.firstWhere(
            (f) => (f as Map<String, dynamic>)['primary'] as bool? ?? false,
            orElse: () => files.first,
          ) as Map<String, dynamic>;

          return ResourceVersion(
            id: vMap['id'] as String,
            versionNumber: vMap['version_number'] as String,
            name: vMap['name'] as String,
            changelog: vMap['changelog'] as String?,
            gameVersions: (vMap['game_versions'] as List<dynamic>?)?.cast<String>() ?? [],
            loaders: (vMap['loaders'] as List<dynamic>?)?.cast<String>() ?? [],
            dependencies: (vMap['dependencies'] as List<dynamic>?)
                    ?.map((d) {
                  final dMap = d as Map<String, dynamic>;
                  return VersionDependency(
                    projectId: dMap['project_id'] as String?,
                    versionId: dMap['version_id'] as String?,
                    dependencyType: dMap['dependency_type'] as String? ?? 'required',
                  );
                }).toList() ??
                [],
            downloads: vMap['downloads'] as int? ?? 0,
            downloadUrl: primaryFile['url'] as String?,
            fileName: primaryFile['filename'] as String?,
            fileSize: primaryFile['size'] as int? ?? 0,
            fileHashes: (primaryFile['hashes'] as Map<String, dynamic>?)
                    ?.map((key, value) => MapEntry(key, value as String)) ??
                {},
            releaseType: vMap['version_type'] as String? ?? 'release',
            isFeatured: vMap['featured'] as bool? ?? false,
            publishedDate: vMap['date_published'] != null
                ? DateTime.tryParse(vMap['date_published'] as String)
                : null,
            source: 'modrinth',
            projectId: vMap['project_id'] as String,
          );
        }).toList();
      } else {
        throw NetworkException.fromStatusCode(response.statusCode);
      }
    } catch (e) {
      _logger.error('[Modrinth] 获取版本异常: $e');
      rethrow;
    }
  }

  /// 解析资源类型
  ResourceType _parseResourceType(String? type) {
    switch (type) {
      case 'mod':
        return ResourceType.mod;
      case 'resourcepack':
        return ResourceType.resourcePack;
      case 'modpack':
        return ResourceType.modpack;
      case 'shader':
        return ResourceType.shader;
      case 'datapack':
        return ResourceType.dataPack;
      default:
        return ResourceType.mod;
    }
  }

  String _typeToString(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return 'mod';
      case ResourceType.resourcePack:
        return 'resourcepack';
      case ResourceType.modpack:
        return 'modpack';
      case ResourceType.shader:
        return 'shader';
      case ResourceType.dataPack:
        return 'datapack';
    }
  }

  /// 关闭 HTTP 客户端
  void close() {
    _networkClient.close();
  }
}
