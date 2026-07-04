import 'dart:convert';
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import 'models.dart';
import 'api_interface.dart';

/// CurseForge API客户端
class CurseForgeApi implements ResourceApi {
  final String apiKey;
  final NetworkClient _networkClient = NetworkClient();

  static const String baseUrl = ApiEndpoints.curseforgeApi;
  static const int minecraftGameId = 432;
  static const int modCategoryId = 6;
  static const int resourcePackCategoryId = 12;
  static const int modpackCategoryId = 4471;

  CurseForgeApi({
    required this.apiKey,
  });

  @override
  String get source => 'curseforge';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'x-api-key': apiKey,
      };

  @override
  Future<SearchResult> search(SearchParams params) async {
    final queryParams = <String, String>{
      'gameId': '432', // Minecraft Java Edition
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

    final response = await _networkClient.get(
      uri.toString(),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw NetworkException.fromStatusCode(response.statusCode);
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
    final response = await _networkClient.get(uri.toString(), headers: _headers);

    if (response.statusCode != 200) {
      throw NetworkException.fromStatusCode(response.statusCode);
    }

    final data = json.decode(response.body);
    return _parseMod(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ResourceVersion>> getVersions(String id) async {
    final uri = Uri.parse('$baseUrl/mods/$id/files');
    final response = await _networkClient.get(uri.toString(), headers: _headers);

    if (response.statusCode != 200) {
      throw NetworkException.fromStatusCode(response.statusCode);
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
    final response = await _networkClient.get(uri.toString(), headers: _headers);

    if (response.statusCode != 200) {
      throw NetworkException.fromStatusCode(response.statusCode);
    }

    final data = json.decode(response.body);
    return _parseFile(data['data'] as Map<String, dynamic>, resourceId);
  }

  @override
  Future<List<Category>> getCategories(ResourceType type) async {
    final classId = _getClassId(type);
    final uri = Uri.parse('$baseUrl/categories')
        .replace(queryParameters: {'classId': classId.toString()});

    final response = await _networkClient.get(uri.toString(), headers: _headers);

    if (response.statusCode != 200) {
      throw NetworkException.fromStatusCode(response.statusCode);
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
            ?.map((c) => c['name'] as String)
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
      summary: mod['summary'] as String?,
      slug: slug,
      screenshotUrls: screenshots,
      supportedGameVersions: supportedGameVersions.toList(),
      supportedLoaders: loaders,
      downloads: mod['downloadCount'] as int,
      likes: mod['thumbsUpCount'] as int? ?? 0,
      pageUrl: '${ApiEndpoints.curseforgeWebsite}/minecraft/mc-mods/${mod['slug']}',
      publishedDate: DateTime.tryParse(mod['dateCreated'] as String? ?? ''),
      updatedDate: DateTime.tryParse(mod['dateModified'] as String? ?? ''),
      license: mod['license']?['name'] as String?,
    );
  }

  Future<ResourceVersion> _parseFile(
    Map<String, dynamic> file,
    String resourceId,
  ) async {
    final hashes = file['hashes'] as List<dynamic>?;
    final fileHashes = <String, String>{};

    if (hashes != null) {
      for (final hash in hashes) {
        final algo = hash['algo'] as int;
        final value = hash['value'] as String;
        if (algo == 1) {
          fileHashes['sha1'] = value;
        }
        if (algo == 2) {
          fileHashes['sha256'] = value;
        }
      }
    }

    String? downloadUrl = file['downloadUrl'] as String?;
    final fileName = file['fileName'] as String?;

    // CurseForge 备用 CDN：当 downloadUrl 为 null 时根据 fileId 构造
    if (downloadUrl == null || downloadUrl.isEmpty) {
      final fileId = file['id'] as int?;
      if (fileId != null && fileName != null) {
        final idStr = fileId.toString();
        final prefix = idStr.length > 4 ? idStr.substring(0, idStr.length - 4) : idStr;
        final suffix = idStr.length > 4 ? idStr.substring(idStr.length - 4) : '0';
        downloadUrl = 'https://edge.forgecdn.net/files/$prefix/$suffix/$fileName';
      }
    }
    final fileSize = file['fileLength'] as int? ?? 0;

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
      projectId: resourceId,
      source: source,
      versionNumber: file['displayName'] as String? ?? file['id'].toString(),
      name: file['displayName'] as String? ?? file['id'].toString(),
      publishedDate: DateTime.tryParse(file['fileDate'] as String? ?? ''),
      gameVersions: gameVersions,
      loaders: loaders,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileHashes: fileHashes,
      downloads: 0,
      releaseType: 'release',
      isFeatured: false,
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
      case ResourceType.shader:
        return modCategoryId;
      case ResourceType.dataPack:
        return modCategoryId;
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
