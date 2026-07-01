import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network_client.dart';
import 'models.dart';
import 'api_interface.dart';
import 'package:archive/archive.dart' as archive;

/// Modrinth API客户端
class ModrinthApi implements ResourceApi {
  static const String baseUrl = 'https://api.modrinth.com/v2';

  @override
  String get source => 'modrinth';

  Map<String, String> get _headers => NetworkClient.modrinthHeaders;

  @override
  Future<SearchResult> search(SearchParams params) async {
    final facetGroups = <List<String>>[];

    if (params.type != null) {
      final type = _projectTypeToString(params.type!);
      facetGroups.add(['project_type:$type']);
    }

    if (params.gameVersions != null && params.gameVersions!.isNotEmpty) {
      final versions = params.gameVersions!.map((v) => 'versions:$v').toList();
      facetGroups.add(versions);
    }

    if (params.loaders != null && params.loaders!.isNotEmpty) {
      final loaders = params.loaders!.map((l) => 'categories:$l').toList();
      facetGroups.add(loaders);
    }

    if (params.categories != null && params.categories!.isNotEmpty) {
      final cats = params.categories!.map((c) => 'categories:$c').toList();
      facetGroups.add(cats);
    }

    final queryParams = <String, String>{
      'limit': params.pageSize.toString(),
      'offset': ((params.page - 1) * params.pageSize).toString(),
      'index': _sortByToIndex(params.sortBy),
    };

    if (params.query.isNotEmpty) {
      queryParams['query'] = params.query;
    }

    if (facetGroups.isNotEmpty) {
      // 正确的 Modrinth facets 格式是: [["a", "b"], ["c"]]
      final jsonFacets = jsonEncode(facetGroups);
      queryParams['facets'] = jsonFacets;
    }

    final networkClient = NetworkClient();
    final response = await networkClient.get(
      '$baseUrl/search',
      headers: _headers,
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    // 处理可能的 gzip 压缩响应
    final data = _parseJsonResponse(response);
    final hits = data['hits'] as List<dynamic>;

    return SearchResult(
      resources: hits
          .map((hit) => _parseSearchHit(hit as Map<String, dynamic>))
          .toList(),
      totalResults: data['total_hits'] as int,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  @override
  Future<Resource> getResource(String id) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      '$baseUrl/project/$id',
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get resource: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseProject(data as Map<String, dynamic>);
  }

  @override
  Future<List<ResourceVersion>> getVersions(String id) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      '$baseUrl/project/$id/version',
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get versions: ${response.statusCode}');
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((version) => _parseVersion(version as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ResourceVersion> getVersion(String resourceId, String versionId) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      '$baseUrl/version/$versionId',
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get version: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseVersion(data as Map<String, dynamic>);
  }

  @override
  Future<List<Category>> getCategories(ResourceType type) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      '$baseUrl/tag/category',
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get categories: ${response.statusCode}');
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((cat) => Category(
              id: cat['name'] as String,
              name: cat['name'] as String,
              iconUrl: cat['icon'] as String?,
            ))
        .toList();
  }

  Resource _parseSearchHit(Map<String, dynamic> hit) {
    final categories = (hit['categories'] as List<dynamic>?)
            ?.map((c) => c as String)
            .toList() ??
        [];

    final type = _stringToProjectType(hit['project_type'] as String);

    final loaders = (hit['loaders'] as List<dynamic>?)
            ?.map((l) => l as String)
            .toList() ??
        [];

    final gameVersions = (hit['versions'] as List<dynamic>?)
            ?.map((v) => v as String)
            .toList() ??
        [];

    final author = hit['author'] as String?;
    final authors = author != null
        ? [Author(id: author, name: author)]
        : <Author>[];

    return Resource(
      id: hit['project_id'] as String,
      type: type,
      source: source,
      name: hit['title'] as String,
      description: hit['description'] as String,
      authors: authors,
      categories: categories,
      iconUrl: hit['icon_url'] as String?,
      summary: hit['description'] as String?,
      slug: hit['slug'] as String?,
      screenshotUrls: [],
      supportedGameVersions: gameVersions,
      supportedLoaders: loaders,
      downloads: hit['downloads'] as int,
      likes: hit['follows'] as int,
      pageUrl: 'https://modrinth.com/${_projectTypeToString(type)}/${hit['slug']}',
      publishedDate: DateTime.tryParse(hit['date_created'] as String? ?? ''),
      updatedDate: DateTime.tryParse(hit['date_modified'] as String? ?? ''),
      license: hit['license'] as String?,
    );
  }

  Resource _parseProject(Map<String, dynamic> project) {
    final members = project['team'] as String?;
    final authors = <Author>[];
    if (members != null) {
      authors.add(Author(id: members, name: members));
    }

    final categories = (project['categories'] as List<dynamic>?)
            ?.map((c) => c as String)
            .toList() ??
        [];

    final type = _stringToProjectType(project['project_type'] as String);

    final loaders = (project['loaders'] as List<dynamic>?)
            ?.map((l) => l as String)
            .toList() ??
        [];

    final gameVersions = (project['game_versions'] as List<dynamic>?)
            ?.map((v) => v as String)
            .toList() ??
        [];

    final gallery = (project['gallery'] as List<dynamic>?)
            ?.map((g) => g['url'] as String)
            .toList() ??
        [];

    return Resource(
      id: project['id'] as String,
      type: type,
      source: source,
      name: project['title'] as String,
      description: project['description'] as String,
      body: project['body'] as String?,
      authors: authors,
      categories: categories,
      iconUrl: project['icon_url'] as String?,
      summary: project['description'] as String?,
      slug: project['slug'] as String?,
      screenshotUrls: gallery,
      supportedGameVersions: gameVersions,
      supportedLoaders: loaders,
      downloads: project['downloads'] as int,
      likes: project['followers'] as int,
      pageUrl: 'https://modrinth.com/${_projectTypeToString(type)}/${project['slug']}',
      publishedDate: DateTime.tryParse(project['published'] as String? ?? ''),
      updatedDate: DateTime.tryParse(project['updated'] as String? ?? ''),
      license: project['license']?['name'] as String?,
    );
  }

  ResourceVersion _parseVersion(Map<String, dynamic> version) {
    final files = version['files'] as List<dynamic>? ?? [];
    if (files.isEmpty) {
      throw Exception('Version has no downloadable files');
    }

    final primaryFile = files.firstWhere(
      (f) => f is Map && (f['primary'] as bool? ?? false),
      orElse: () => files.first,
    );

    if (primaryFile is! Map) {
      throw Exception('Invalid file data in version');
    }

    final hashes = primaryFile['hashes'] as Map<String, dynamic>?;
    final fileHashes = <String, String>{};
    if (hashes != null) {
      hashes.forEach((key, value) {
        fileHashes[key] = value.toString();
      });
    }

    final loaders = (version['loaders'] as List<dynamic>?)
            ?.map((l) => l as String)
            .toList() ??
        [];

    final gameVersions = (version['game_versions'] as List<dynamic>?)
            ?.map((v) => v as String)
            .toList() ??
        [];

    final dependencies = <VersionDependency>[];
    final depsList = version['dependencies'] as List<dynamic>?;
    if (depsList != null) {
      for (final dep in depsList) {
        dependencies.add(VersionDependency(
          projectId: dep['project_id'] as String?,
          versionId: dep['version_id'] as String?,
          dependencyType: dep['dependency_type'] as String? ?? 'required',
        ));
      }
    }

    return ResourceVersion(
      id: version['id'] as String,
      projectId: version['project_id'] as String? ?? '',
      source: source,
      versionNumber: version['version_number'] as String? ?? '',
      name: version['name'] as String? ?? '',
      publishedDate: DateTime.tryParse(version['date_published'] as String? ?? ''),
      gameVersions: gameVersions,
      loaders: loaders,
      dependencies: dependencies,
      downloadUrl: primaryFile['url'] as String?,
      fileName: primaryFile['filename'] as String?,
      fileSize: primaryFile['size'] as int? ?? 0,
      fileHashes: fileHashes,
      downloads: 0,
      releaseType: version['version_type'] as String? ?? 'release',
      isFeatured: version['featured'] as bool? ?? false,
      changelog: version['changelog'] as String?,
    );
  }

  String _projectTypeToString(ResourceType type) {
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

  ResourceType _stringToProjectType(String type) {
    switch (type) {
      case 'resourcepack':
        return ResourceType.resourcePack;
      case 'modpack':
        return ResourceType.modpack;
      default:
        return ResourceType.mod;
    }
  }

  String _sortByToIndex(String sortBy) {
    switch (sortBy) {
      case 'downloads':
        return 'downloads';
      case 'likes':
        return 'follows';
      case 'updated':
        return 'updated';
      case 'newest':
        return 'newest';
      default:
        return 'relevance';
    }
  }

  /// 解析JSON响应，处理gzip压缩
  Map<String, dynamic> _parseJsonResponse(http.Response response) {
    // 优先检查gzip压缩（Modrinth API默认返回gzip压缩数据）
    try {
      final contentEncoding = response.headers['content-encoding'];
      if (contentEncoding != null && contentEncoding.contains('gzip')) {
        if (response.bodyBytes.length >= 2 &&
            response.bodyBytes[0] == 0x1f &&
            response.bodyBytes[1] == 0x8b) {
          final gzipDecoder = archive.GZipDecoder();
          final decodedBytes = gzipDecoder.decodeBytes(response.bodyBytes);
          return json.decode(utf8.decode(decodedBytes)) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      // gzip解压失败，尝试其他方式
    }

    // 尝试使用utf8解码bodyBytes
    try {
      final decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      // utf8解码失败
    }

    // 最后尝试直接解析response.body
    try {
      final body = response.body;
      if (body.isNotEmpty) {
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (e) {
      // 直接解析失败
    }

    throw Exception('Failed to parse JSON response');
  }
}