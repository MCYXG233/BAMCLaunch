import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'api_interface.dart';

/// Modrinth API客户端
class ModrinthApi implements ResourceApi {
  final http.Client _httpClient;

  static const String baseUrl = 'https://api.modrinth.com/v2';
  static const String userAgent = 'BAMCLauncher/1.0';

  ModrinthApi({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get source => 'modrinth';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'User-Agent': userAgent,
      };

  @override
  Future<SearchResult> search(SearchParams params) async {
    final facets = <String>[];

    if (params.type != null) {
      final type = _projectTypeToString(params.type!);
      facets.add('project_type:$type');
    }

    if (params.gameVersions != null && params.gameVersions!.isNotEmpty) {
      final versions = params.gameVersions!.map((v) => 'versions:$v').join(',');
      facets.add('[$versions]');
    }

    if (params.loaders != null && params.loaders!.isNotEmpty) {
      final loaders = params.loaders!.map((l) => 'categories:$l').join(',');
      facets.add('[$loaders]');
    }

    if (params.categories != null && params.categories!.isNotEmpty) {
      final cats = params.categories!.map((c) => 'categories:$c').join(',');
      facets.add('[$cats]');
    }

    final queryParams = <String, String>{
      'limit': params.pageSize.toString(),
      'offset': ((params.page - 1) * params.pageSize).toString(),
      'index': _sortByToIndex(params.sortBy),
    };

    if (params.query.isNotEmpty) {
      queryParams['query'] = params.query;
    }

    if (facets.isNotEmpty) {
      queryParams['facets'] = '[${facets.join(',')}]';
    }

    final uri = Uri.parse('$baseUrl/search')
        .replace(queryParameters: queryParams);

    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final data = json.decode(response.body);
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
    final uri = Uri.parse('$baseUrl/project/$id');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get resource: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseProject(data as Map<String, dynamic>);
  }

  @override
  Future<List<ResourceVersion>> getVersions(String id) async {
    final uri = Uri.parse('$baseUrl/project/$id/version');
    final response = await _httpClient.get(uri, headers: _headers);

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
    final uri = Uri.parse('$baseUrl/version/$versionId');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get version: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseVersion(data as Map<String, dynamic>);
  }

  @override
  Future<List<Category>> getCategories(ResourceType type) async {
    final uri = Uri.parse('$baseUrl/tag/category');
    final response = await _httpClient.get(uri, headers: _headers);

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
            ?.map((c) => Category(id: c as String, name: c as String))
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
      screenshotUrls: [],
      supportedGameVersions: gameVersions,
      supportedLoaders: loaders,
      downloads: hit['downloads'] as int,
      likes: hit['follows'] as int,
      pageUrl: 'https://modrinth.com/${_projectTypeToString(type)}/${hit['slug']}',
      publishedDate: DateTime.parse(hit['date_created'] as String),
      updatedDate: DateTime.parse(hit['date_modified'] as String),
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
            ?.map((c) => Category(id: c as String, name: c as String))
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
      screenshotUrls: gallery,
      supportedGameVersions: gameVersions,
      supportedLoaders: loaders,
      downloads: project['downloads'] as int,
      likes: project['followers'] as int,
      pageUrl: 'https://modrinth.com/${_projectTypeToString(type)}/${project['slug']}',
      publishedDate: DateTime.parse(project['published'] as String),
      updatedDate: DateTime.parse(project['updated'] as String),
      license: project['license']?['name'] as String?,
    );
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

  String _projectTypeToString(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return 'mod';
      case ResourceType.resourcePack:
        return 'resourcepack';
      case ResourceType.modpack:
        return 'modpack';
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
}
