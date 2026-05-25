import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'api_interface.dart';

/// CurseForge API客户端
class CurseForgeApi implements ResourceApi {
  final String apiKey;
  final http.Client _httpClient;

  static const String baseUrl = 'https://api.curseforge.com/v1';
  static const int minecraftGameId = 432;
  static const int modCategoryId = 6;
  static const int resourcePackCategoryId = 12;
  static const int modpackCategoryId = 4471;

  CurseForgeApi({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get source => 'curseforge';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'x-api-key': apiKey,
      };

  @override
  Future<SearchResult> search(SearchParams params) async {
    final queryParams = <String, String>{
      'pageSize': params.pageSize.toString(),
      'index': ((params.page - 1) * params.pageSize).toString(),
      'sortOrder': 'desc',
    };

    if (params.query.isNotEmpty) {
      queryParams['searchFilter'] = params.query;
    }

    if (params.gameVersions != null && params.gameVersions!.isNotEmpty) {
      queryParams['gameVersion'] = params.gameVersions!.first;
    }

    final classId = _getClassId(params.type ?? ResourceType.mod);
    queryParams['classId'] = classId.toString();

    final uri = Uri.parse('$baseUrl/mods/search')
        .replace(queryParameters: queryParams);

    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final mods = data['data'] as List<dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>;

    return SearchResult(
      resources: mods
          .map((mod) => _parseMod(mod as Map<String, dynamic>))
          .toList(),
      totalResults: pagination['totalCount'] as int,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  @override
  Future<Resource> getResource(String id) async {
    final uri = Uri.parse('$baseUrl/mods/$id');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get resource: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseMod(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ResourceVersion>> getVersions(String id) async {
    final uri = Uri.parse('$baseUrl/mods/$id/files');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get versions: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final files = data['data'] as List<dynamic>;

    return Future.wait(
      files.map((file) => _parseFile(file as Map<String, dynamic>, id)),
    );
  }

  @override
  Future<ResourceVersion> getVersion(String resourceId, String versionId) async {
    final uri = Uri.parse('$baseUrl/mods/$resourceId/files/$versionId');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get version: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseFile(data['data'] as Map<String, dynamic>, resourceId);
  }

  @override
  Future<List<Category>> getCategories(ResourceType type) async {
    final classId = _getClassId(type);
    final uri = Uri.parse('$baseUrl/categories')
        .replace(queryParameters: {'classId': classId.toString()});

    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get categories: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final categories = data['data'] as List<dynamic>;

    return categories
        .map((cat) => Category(
              id: cat['id'].toString(),
              name: cat['name'] as String,
              iconUrl: cat['iconUrl'] as String?,
            ))
        .toList();
  }

  Resource _parseMod(Map<String, dynamic> mod) {
    final authors = (mod['authors'] as List<dynamic>?)
            ?.map((a) => Author(
                  id: a['id'].toString(),
                  name: a['name'] as String,
                  avatarUrl: a['url'] as String?,
                ))
            .toList() ??
        [];

    final categories = (mod['categories'] as List<dynamic>?)
            ?.map((c) => Category(
                  id: c['id'].toString(),
                  name: c['name'] as String,
                  iconUrl: c['iconUrl'] as String?,
                ))
            .toList() ??
        [];

    final classId = mod['classId'] as int?;
    final type = _parseResourceType(classId);

    final screenshots = (mod['screenshots'] as List<dynamic>?)
            ?.map((s) => s['url'] as String)
            .toList() ??
        [];

    final latestFileIndex = mod['latestFilesIndexes'] as List<dynamic>?;
    final supportedGameVersions = <String>{};
    if (latestFileIndex != null) {
      for (final index in latestFileIndex) {
        final version = index['gameVersion'] as String?;
        if (version != null) {
          supportedGameVersions.add(version);
        }
      }
    }

    final loaders = <String>[];
    final slug = mod['slug'] as String?;
    if (slug != null && slug.contains('fabric')) {
      loaders.add('fabric');
    }
    if (slug != null && slug.contains('forge')) {
      loaders.add('forge');
    }
    if (loaders.isEmpty) {
      loaders.add('forge');
    }

    return Resource(
      id: mod['id'].toString(),
      type: type,
      source: source,
      name: mod['name'] as String,
      description: mod['summary'] as String,
      body: mod['description'] as String?,
      authors: authors,
      categories: categories,
      iconUrl: mod['logo']?['url'] as String?,
      screenshotUrls: screenshots,
      supportedGameVersions: supportedGameVersions.toList(),
      supportedLoaders: loaders,
      downloads: mod['downloadCount'] as int,
      likes: mod['thumbsUpCount'] as int? ?? 0,
      pageUrl: 'https://www.curseforge.com/minecraft/mc-mods/${mod['slug']}',
      publishedDate: DateTime.parse(mod['dateCreated'] as String),
      updatedDate: DateTime.parse(mod['dateModified'] as String),
      license: mod['license']?['name'] as String?,
    );
  }

  Future<ResourceVersion> _parseFile(
    Map<String, dynamic> file,
    String resourceId,
  ) async {
    final hashes = file['hashes'] as List<dynamic>?;
    String? sha1;
    String? sha256;

    if (hashes != null) {
      for (final hash in hashes) {
        final algo = hash['algo'] as int;
        final value = hash['value'] as String;
        if (algo == 1) sha1 = value;
        if (algo == 2) sha256 = value;
      }
    }

    final download = VersionDownload(
      url: file['downloadUrl'] as String,
      fileName: file['fileName'] as String,
      fileSize: file['fileLength'] as int,
      sha1: sha1,
      sha256: sha256,
    );

    final gameVersions = (file['gameVersions'] as List<dynamic>?)
            ?.map((v) => v as String)
            .toList() ??
        [];

    final loaders = <String>[];
    for (final version in gameVersions) {
      if (version.toLowerCase().contains('fabric')) {
        loaders.add('fabric');
      }
      if (version.toLowerCase().contains('forge')) {
        loaders.add('forge');
      }
      if (version.toLowerCase().contains('quilt')) {
        loaders.add('quilt');
      }
    }
    if (loaders.isEmpty) {
      loaders.add('forge');
    }

    return ResourceVersion(
      id: file['id'].toString(),
      versionNumber: file['displayName'] as String,
      name: file['displayName'] as String,
      releaseDate: DateTime.parse(file['fileDate'] as String),
      gameVersions: gameVersions,
      loaders: loaders,
      download: download,
      changelog: null,
    );
  }

  int _getClassId(ResourceType type) {
    switch (type) {
      case ResourceType.mod:
        return modCategoryId;
      case ResourceType.resourcePack:
        return resourcePackCategoryId;
      case ResourceType.modpack:
        return modpackCategoryId;
    }
  }

  ResourceType _parseResourceType(int? classId) {
    switch (classId) {
      case resourcePackCategoryId:
        return ResourceType.resourcePack;
      case modpackCategoryId:
        return ResourceType.modpack;
      default:
        return ResourceType.mod;
    }
  }
}
