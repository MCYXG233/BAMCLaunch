import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/content_models.dart';

class CurseForgeApi {
  static const String _baseUrl = 'https://api.curseforge.com/v1';
  static const String _apiKey = ''; // 需要配置有效的API密钥
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  final Map<String, dynamic> _config;

  CurseForgeApi({Map<String, dynamic>? config}) : _config = config ?? {};
  
  String get apiKey => _config['apiKey'] ?? _apiKey;
  bool get isConfigured => apiKey.isNotEmpty;

  Future<SearchResult> search(SearchQuery query) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/mods/search');
      
      final request = await HttpClient().getUrl(url.replace(
        queryParameters: {
          'gameId': '432',
          'classId': _getClassId(query.type),
          'gameVersion': query.gameVersion,
          'searchFilter': query.query,
          'pageSize': query.pageSize.toString(),
          'pageIndex': (query.page - 1).toString(),
          'sortField': _getSortField(query.sortType),
          'sortOrder': query.ascending ? 'asc' : 'desc',
          'categoryId': query.category,
          'authorId': query.author,
        }..removeWhere((key, value) => value == null),
      ));
      
      request.headers.add('x-api-key', apiKey);
      request.headers.add('Content-Type', 'application/json');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return _parseSearchResult(data, query.type);
      } else if (response.statusCode == 403) {
        throw Exception('CurseForge API密钥无效或权限不足');
      } else if (response.statusCode == 429) {
        throw Exception('CurseForge API请求频率过高，请稍后再试');
      } else {
        throw Exception('CurseForge API错误: ${response.statusCode} - $responseBody');
      }
    });
  }
  
  String _getSortField(SortType sortType) {
    switch (sortType) {
      case SortType.relevance:
        return '0';
      case SortType.downloads:
        return '6';
      case SortType.recentlyUpdated:
        return '3';
      case SortType.recentlyAdded:
        return '2';
      case SortType.featured:
        return '5';
      default:
        return '0';
    }
  }
  
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e as Exception;
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }
    
    throw lastException!;
  }

  Future<ContentItem> getModDetails(String modId) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/mods/$modId');
      
      final request = await HttpClient().getUrl(url);
      request.headers.add('x-api-key', apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return _parseModDetails(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('模组不存在: $modId');
      } else {
        throw Exception('获取模组详情失败: ${response.statusCode} - $responseBody');
      }
    });
  }

  Future<List<ContentItem>> getPopularMods(ContentType type, {int limit = 10}) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/mods/search');
      
      final request = await HttpClient().getUrl(url.replace(
        queryParameters: {
          'gameId': '432',
          'classId': _getClassId(type),
          'sortField': '6', // 按下载量排序
          'sortOrder': 'desc',
          'pageSize': limit.toString(),
          'pageIndex': '0',
        },
      ));
      
      request.headers.add('x-api-key', apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final result = _parseSearchResult(data, type);
        return result.items;
      } else {
        throw Exception('获取热门模组失败: ${response.statusCode} - $responseBody');
      }
    });
  }

  int _getClassId(ContentType type) {
    switch (type) {
      case ContentType.mod:
        return 6;
      case ContentType.resourcePack:
        return 12;
      case ContentType.shaderPack:
        return 4471;
      case ContentType.dataPack:
        return 17;
      default:
        return 6;
    }
  }

  SearchResult _parseSearchResult(Map<String, dynamic> data, ContentType type) {
    final List<dynamic> mods = data['data'] ?? [];
    final List<ContentItem> items = mods.map((mod) => _parseModItem(mod, type)).toList();
    
    return SearchResult(
      items: items,
      totalCount: data['pagination']['totalCount'] ?? items.length,
      currentPage: (data['pagination']['index'] ?? 0) + 1,
      totalPages: ((data['pagination']['totalCount'] ?? items.length) / 
          (data['pagination']['pageSize'] ?? 20)).ceil(),
    );
  }

  ContentItem _parseModItem(Map<String, dynamic> mod, ContentType type) {
    final latestFile = mod['latestFiles']?.firstOrNull;
    final gameVersions = (latestFile?['gameVersions'] as List?)?.cast<String>() ?? [];
    
    return ContentItem(
      id: mod['id'].toString(),
      name: mod['name'] ?? '',
      author: mod['authors']?.first?['name'] ?? '',
      description: mod['summary'] ?? '',
      version: latestFile?['displayName'] ?? '',
      downloadUrl: latestFile?['downloadUrl'] ?? '',
      downloadCount: mod['downloadCount'] ?? 0,
      iconUrl: mod['logo']?['thumbnailUrl'],
      releaseDate: latestFile != null ? DateTime.parse(latestFile['fileDate']) : null,
      type: type,
      source: ContentSource.curseforge,
      status: ContentStatus.notInstalled,
      gameVersions: gameVersions,
      loaders: _extractLoaders(gameVersions),
      dependencies: _parseDependencies(mod['dependencies']),
      conflicts: [],
    );
  }

  ContentItem _parseModDetails(Map<String, dynamic> mod) {
    return _parseModItem(mod, ContentType.mod);
  }

  List<String> _extractLoaders(List<String> gameVersions) {
    final loaders = <String>[];
    for (final version in gameVersions) {
      if (version.toLowerCase().contains('forge')) {
        loaders.add('forge');
      } else if (version.toLowerCase().contains('fabric')) {
        loaders.add('fabric');
      } else if (version.toLowerCase().contains('quilt')) {
        loaders.add('quilt');
      }
    }
    return loaders.toSet().toList();
  }

  List<ContentDependency> _parseDependencies(List<dynamic>? dependencies) {
    if (dependencies == null) return [];
    
    final parsedDependencies = <ContentDependency>[];
    
    for (final dep in dependencies) {
      final relationType = dep['relationType'];
      if (relationType == 3) { // Required dependency
        parsedDependencies.add(ContentDependency(
          id: dep['modId'].toString(),
          name: dep['modName'] ?? '',
          isRequired: true,
        ));
      } else if (relationType == 4) { // Optional dependency
        parsedDependencies.add(ContentDependency(
          id: dep['modId'].toString(),
          name: dep['modName'] ?? '',
          isRequired: false,
        ));
      }
    }
    
    return parsedDependencies;
  }
  
  Future<String> getFileDownloadUrl(String fileId) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/mods/files/$fileId/download-url');
      
      final request = await HttpClient().getUrl(url);
      request.headers.add('x-api-key', apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['data'] ?? '';
      } else {
        throw Exception('获取下载链接失败: ${response.statusCode}');
      }
    });
  }
  
  Future<List<dynamic>> getModFiles(String modId, {String? gameVersion}) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/mods/$modId/files');
      
      final request = await HttpClient().getUrl(url.replace(
        queryParameters: {
          'gameVersion': gameVersion,
          'pageSize': '50',
          'pageIndex': '0',
        }..removeWhere((key, value) => value == null),
      ));
      
      request.headers.add('x-api-key', apiKey);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['data'] ?? [];
      } else {
        throw Exception('获取模组文件列表失败: ${response.statusCode}');
      }
    });
  }
}