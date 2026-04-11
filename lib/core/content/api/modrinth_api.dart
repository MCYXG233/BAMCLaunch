import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/content_models.dart';

class ModrinthApi {
  static const String _baseUrl = 'https://api.modrinth.com/v2';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  final Map<String, dynamic> _config;

  ModrinthApi({Map<String, dynamic>? config}) : _config = config ?? {};

  Future<SearchResult> search(SearchQuery query) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/search');
      
      final request = await HttpClient().getUrl(url.replace(
        queryParameters: {
          'query': query.query,
          'limit': query.pageSize.toString(),
          'offset': ((query.page - 1) * query.pageSize).toString(),
          'facets': jsonEncode(_getFacets(query)),
          'index': _getIndex(query.sortType),
        },
      ));
      
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return _parseSearchResult(data, query.type);
      } else if (response.statusCode == 429) {
        throw Exception('Modrinth API请求频率过高，请稍后再试');
      } else {
        throw Exception('Modrinth API错误: ${response.statusCode} - $responseBody');
      }
    });
  }
  
  String _getIndex(SortType sortType) {
    switch (sortType) {
      case SortType.relevance:
        return 'relevance';
      case SortType.downloads:
        return 'downloads';
      case SortType.recentlyUpdated:
        return 'updated';
      case SortType.recentlyAdded:
        return 'newest';
      case SortType.featured:
        return 'featured';
      default:
        return 'relevance';
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

  Future<ContentItem> getProjectDetails(String projectId) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/project/$projectId');
      
      final request = await HttpClient().getUrl(url);
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return _parseProjectDetails(data);
      } else if (response.statusCode == 404) {
        throw Exception('项目不存在: $projectId');
      } else {
        throw Exception('获取项目详情失败: ${response.statusCode} - $responseBody');
      }
    });
  }

  Future<List<ContentItem>> getPopularProjects(ContentType type, {int limit = 10}) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/search');
      
      final request = await HttpClient().getUrl(url.replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': '0',
          'facets': jsonEncode(_getFacets(SearchQuery(query: '', type: type))),
          'index': 'downloads',
        },
      ));
      
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final result = _parseSearchResult(data, type);
        return result.items;
      } else {
        throw Exception('获取热门项目失败: ${response.statusCode} - $responseBody');
      }
    });
  }

  List<List<String>> _getFacets(SearchQuery query) {
    final facets = <List<String>>[];
    
    facets.add(['project_type:${_getProjectType(query.type)}']);
    
    if (query.gameVersion != null) {
      facets.add(['versions:${query.gameVersion}']);
    }
    
    if (query.loader != null) {
      facets.add(['categories:${query.loader}']);
    }
    
    if (query.category != null) {
      facets.add(['categories:${query.category}']);
    }
    
    if (query.author != null) {
      facets.add(['author:${query.author}']);
    }
    
    return facets;
  }

  String _getProjectType(ContentType type) {
    switch (type) {
      case ContentType.mod:
        return 'mod';
      case ContentType.resourcePack:
        return 'resourcepack';
      case ContentType.shaderPack:
        return 'shader';
      case ContentType.dataPack:
        return 'datapack';
      default:
        return 'mod';
    }
  }

  SearchResult _parseSearchResult(Map<String, dynamic> data, ContentType type) {
    final List<dynamic> projects = data['hits'] ?? [];
    final List<ContentItem> items = projects.map((project) => _parseProjectItem(project, type)).toList();
    
    return SearchResult(
      items: items,
      totalCount: data['total_hits'] ?? items.length,
      currentPage: (int.parse(data['offset'] ?? '0') / int.parse(data['limit'] ?? '20')).floor() + 1,
      totalPages: ((data['total_hits'] ?? items.length) / int.parse(data['limit'] ?? '20')).ceil(),
    );
  }

  ContentItem _parseProjectItem(Map<String, dynamic> project, ContentType type) {
    final author = project['author'] ?? project['team'] ?? '';
    return ContentItem(
      id: project['project_id'] ?? '',
      name: project['title'] ?? '',
      author: author.toString(),
      description: project['description'] ?? '',
      version: project['latest_version'] ?? '',
      downloadUrl: '',
      downloadCount: project['downloads'] ?? 0,
      iconUrl: project['icon_url'],
      releaseDate: project['date_created'] != null ? DateTime.parse(project['date_created']) : null,
      type: type,
      source: ContentSource.modrinth,
      status: ContentStatus.notInstalled,
      gameVersions: (project['versions'] as List?)?.cast<String>() ?? [],
      loaders: (project['categories'] as List?)?.cast<String>() ?? [],
      dependencies: _parseDependencies(project['dependencies']),
      conflicts: [],
    );
  }

  ContentItem _parseProjectDetails(Map<String, dynamic> project) {
    return _parseProjectItem(project, ContentType.mod);
  }

  List<ContentDependency> _parseDependencies(Map<String, dynamic>? dependencies) {
    if (dependencies == null) return [];
    
    final parsedDependencies = <ContentDependency>[];
    
    // Required dependencies
    final required = dependencies['required'] ?? [];
    for (final dep in required as List) {
      parsedDependencies.add(ContentDependency(
        id: dep.toString(),
        name: '',
        isRequired: true,
      ));
    }
    
    // Optional dependencies
    final optional = dependencies['optional'] ?? [];
    for (final dep in optional as List) {
      parsedDependencies.add(ContentDependency(
        id: dep.toString(),
        name: '',
        isRequired: false,
      ));
    }
    
    return parsedDependencies;
  }
  
  Future<List<dynamic>> getProjectVersions(String projectId) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/project/$projectId/version');
      
      final request = await HttpClient().getUrl(url);
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('获取版本列表失败: ${response.statusCode}');
      }
    });
  }
  
  Future<Map<String, dynamic>> getVersionDetails(String versionId) async {
    return _withRetry(() async {
      final url = Uri.parse('$_baseUrl/version/$versionId');
      
      final request = await HttpClient().getUrl(url);
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('获取版本详情失败: ${response.statusCode}');
      }
    });
  }
  
  Future<String> getVersionDownloadUrl(String versionId) async {
    final versionDetails = await getVersionDetails(versionId);
    final files = versionDetails['files'] as List?;
    if (files != null && files.isNotEmpty) {
      final primaryFile = files.firstWhere((file) => file['primary'] == true, orElse: () => files.first);
      return primaryFile['url'] ?? '';
    }
    return '';
  }
}