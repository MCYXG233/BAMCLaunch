import '../interfaces/i_content_manager.dart';
import '../models/content_models.dart';
import '../api/curseforge_api.dart';
import '../api/modrinth_api.dart';
import '../../http/i_http_client.dart';
import '../../logger/i_logger.dart';
import '../../download/i_download_engine.dart';
import '../../platform/platform.dart';
import 'dart:convert';
import 'dart:io';

/// 内容管理器实现类
/// 负责管理游戏内容的搜索、下载、安装等功能，对接CurseForge和Modrinth平台
class ContentManager implements IContentManager {
  /// HTTP客户端
  final IHttpClient _httpClient;
  /// 日志记录器
  final ILogger _logger;
  /// 下载引擎
  final IDownloadEngine _downloadEngine;
  /// CurseForge API客户端
  final CurseForgeApi _curseForgeApi;
  /// Modrinth API客户端
  final ModrinthApi _modrinthApi;
  /// 平台适配器
  final IPlatformAdapter _platformAdapter;

  /// 构造函数
  /// [httpClient]: HTTP客户端实例
  /// [logger]: 日志记录器实例
  /// [downloadEngine]: 下载引擎实例
  ContentManager({
    required IHttpClient httpClient,
    required ILogger logger,
    required IDownloadEngine downloadEngine,
  })  : _httpClient = httpClient,
        _logger = logger,
        _downloadEngine = downloadEngine,
        _curseForgeApi = CurseForgeApi(),
        _modrinthApi = ModrinthApi(),
        _platformAdapter = PlatformAdapterFactory.getInstance();

  @override
  Future<List<Mod>> searchMods({
    required String query,
    String? gameVersion,
    String? modLoader,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _logger.info('搜索模组: $query');
      
      // 先尝试Modrinth API
      final modrinthMods = await _searchModsOnModrinth(
        query: query,
        gameVersion: gameVersion,
        modLoader: modLoader,
        page: page,
        pageSize: pageSize,
      );
      
      if (modrinthMods.isNotEmpty) {
        return modrinthMods;
      }
      
      // 再尝试CurseForge API
      final curseforgeMods = await _searchModsOnCurseForge(
        query: query,
        gameVersion: gameVersion,
        modLoader: modLoader,
        page: page,
        pageSize: pageSize,
      );
      
      return curseforgeMods;
    } catch (e) {
      _logger.error('搜索模组失败: $e');
      return [];
    }
  }

  @override
  Future<Mod> getModDetails(String modId, {String? source}) async {
    try {
      _logger.info('获取模组详情: $modId');
      
      if (source == 'curseforge' || modId.startsWith('curseforge-')) {
        return await _getModDetailsOnCurseForge(modId.replaceAll('curseforge-', ''));
      } else {
        return await _getModDetailsOnModrinth(modId);
      }
    } catch (e) {
      _logger.error('获取模组详情失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ModFile>> getModFiles(String modId, {String? source}) async {
    try {
      _logger.info('获取模组文件: $modId');
      
      if (source == 'curseforge' || modId.startsWith('curseforge-')) {
        return await _getModFilesOnCurseForge(modId.replaceAll('curseforge-', ''));
      } else {
        return await _getModFilesOnModrinth(modId);
      }
    } catch (e) {
      _logger.error('获取模组文件失败: $e');
      return [];
    }
  }

  @override
  Future<List<ContentModpack>> searchModpacks({
    required String query,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _logger.info('搜索整合包: $query');
      
      // 先尝试Modrinth API
      final modrinthModpacks = await _searchModpacksOnModrinth(
        query: query,
        gameVersion: gameVersion,
        page: page,
        pageSize: pageSize,
      );
      
      if (modrinthModpacks.isNotEmpty) {
        return modrinthModpacks;
      }
      
      // 再尝试CurseForge API
      final curseforgeModpacks = await _searchModpacksOnCurseForge(
        query: query,
        gameVersion: gameVersion,
        page: page,
        pageSize: pageSize,
      );
      
      return curseforgeModpacks;
    } catch (e) {
      _logger.error('搜索整合包失败: $e');
      return [];
    }
  }

  @override
  Future<ContentModpack> getModpackDetails(String modpackId, {String? source}) async {
    try {
      _logger.info('获取整合包详情: $modpackId');
      
      if (source == 'curseforge' || modpackId.startsWith('curseforge-')) {
        return await _getModpackDetailsOnCurseForge(modpackId.replaceAll('curseforge-', ''));
      } else {
        return await _getModpackDetailsOnModrinth(modpackId);
      }
    } catch (e) {
      _logger.error('获取整合包详情失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ContentModpackFile>> getModpackFiles(String modpackId, {String? source}) async {
    try {
      _logger.info('获取整合包文件: $modpackId');
      
      if (source == 'curseforge' || modpackId.startsWith('curseforge-')) {
        return await _getModpackFilesOnCurseForge(modpackId.replaceAll('curseforge-', ''));
      } else {
        return await _getModpackFilesOnModrinth(modpackId);
      }
    } catch (e) {
      _logger.error('获取整合包文件失败: $e');
      return [];
    }
  }

  @override
  Future<String> downloadMod(String modId, String fileId, String destination, {String? source}) async {
    try {
      _logger.info('下载模组: $modId, 文件: $fileId');
      
      String downloadUrl;
      if (source == 'curseforge' || modId.startsWith('curseforge-')) {
        downloadUrl = await _getModFileDownloadUrlOnCurseForge(modId.replaceAll('curseforge-', ''), fileId);
      } else {
        downloadUrl = await _getModFileDownloadUrlOnModrinth(modId, fileId);
      }
      
      // 使用简化的下载方法下载文件
      // downloadUrl: 下载链接
      // destination: 保存路径
      await _downloadEngine.downloadFile(
        downloadUrl,
        destination,
      );
      
      return destination;
    } catch (e) {
      _logger.error('下载模组失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> downloadModpack(String modpackId, String fileId, String destination, {String? source}) async {
    try {
      _logger.info('下载整合包: $modpackId, 文件: $fileId');
      
      String downloadUrl;
      if (source == 'curseforge' || modpackId.startsWith('curseforge-')) {
        downloadUrl = await _getModpackFileDownloadUrlOnCurseForge(modpackId.replaceAll('curseforge-', ''), fileId);
      } else {
        downloadUrl = await _getModpackFileDownloadUrlOnModrinth(modpackId, fileId);
      }
      
      // 使用简化的下载方法下载文件
      // downloadUrl: 下载链接
      // destination: 保存路径
      await _downloadEngine.downloadFile(
        downloadUrl,
        destination,
      );
      
      return destination;
    } catch (e) {
      _logger.error('下载整合包失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<GameVersion>> getGameVersions() async {
    try {
      _logger.info('获取游戏版本列表');
      
      // 从Modrinth API获取游戏版本
      final response = await _httpClient.get('https://api.modrinth.com/v2/tag/game-version');
      final data = jsonDecode(response.body) as List;
      
      final versions = <GameVersion>[];
      for (final item in data) {
        versions.add(GameVersion(
          id: item['id'] as String,
          name: item['name'] as String,
          version: item['version'] as String,
          isStable: item['stable'] as bool,
          releaseDate: DateTime.parse(item['date'] as String),
        ));
      }
      
      return versions;
    } catch (e) {
      _logger.error('获取游戏版本列表失败: $e');
      return [];
    }
  }

  @override
  Future<List<ModLoader>> getModLoaders(String gameVersion) async {
    try {
      _logger.info('获取模组加载器列表: $gameVersion');
      
      // 从Modrinth API获取模组加载器
      final response = await _httpClient.get('https://api.modrinth.com/v2/tag/loader');
      final data = jsonDecode(response.body) as List;
      
      final loaders = <ModLoader>[];
      for (final item in data) {
        loaders.add(ModLoader(
          id: item['id'] as String,
          name: item['name'] as String,
          version: '',
          gameVersion: gameVersion,
          isRecommended: item['recommended'] as bool,
          isLatest: item['latest'] as bool,
        ));
      }
      
      return loaders;
    } catch (e) {
      _logger.error('获取模组加载器列表失败: $e');
      return [];
    }
  }

  @override
  Future<bool> installContent(String contentId, String version, String destination, {String? source}) async {
    try {
      _logger.info('安装内容: $contentId, 版本: $version, 目标: $destination');
      
      String? downloadUrl;
      
      if (source == 'modrinth' || (source == null && !contentId.startsWith('curseforge-'))) {
        try {
          final versions = await _modrinthApi.getProjectVersions(contentId);
          if (versions.isNotEmpty) {
            for (final v in versions) {
              if (v['version_number'] == version || version.isEmpty) {
                final files = v['files'] as List;
                if (files.isNotEmpty) {
                  final primaryFile = files.firstWhere(
                    (f) => f['primary'] == true,
                    orElse: () => files.first,
                  );
                  downloadUrl = primaryFile['url'] as String;
                  break;
                }
              }
            }
          }
        } catch (e) {
          _logger.warn('从Modrinth获取下载链接失败: $e');
        }
      }
      
      if (downloadUrl == null && (source == 'curseforge' || contentId.startsWith('curseforge-'))) {
        if (_curseForgeApi.isConfigured) {
          try {
            final cfId = contentId.replaceAll('curseforge-', '');
            final files = await _curseForgeApi.getModFiles(cfId);
            if (files.isNotEmpty) {
              final fileId = files.first['id'].toString();
              downloadUrl = await _curseForgeApi.getFileDownloadUrl(fileId);
            }
          } catch (e) {
            _logger.warn('从CurseForge获取下载链接失败: $e');
          }
        }
      }
      
      if (downloadUrl == null) {
        throw Exception('无法获取下载链接');
      }
      
      await _downloadEngine.downloadFile(downloadUrl, destination);
      
      _logger.info('内容安装成功: $contentId');
      return true;
    } catch (e) {
      _logger.error('安装内容失败: $e');
      return false;
    }
  }

  @override
  Future<List<ContentItem>> getInstalledContent(ContentType type) async {
    try {
      _logger.info('获取已安装内容: ${type.name}');
      
      final installedContent = <ContentItem>[];
      final gameDir = _platformAdapter.gameDirectory;
      
      if (type == ContentType.mod) {
        // 检查所有版本目录中的mods文件夹
        final versionsDir = Directory('$gameDir/versions');
        if (await versionsDir.exists()) {
          final versionDirs = await versionsDir.list().toList();
          
          for (final dir in versionDirs) {
            if (dir is Directory) {
              final modsDir = Directory('${dir.path}/mods');
              if (await modsDir.exists()) {
                final modFiles = await modsDir.list().where((file) => file.path.endsWith('.jar')).toList();
                
                for (final modFile in modFiles) {
                  // 这里可以解析模组信息，暂时只添加文件名
                  final modName = modFile.path.split('/').last.replaceAll('.jar', '');
                  installedContent.add(ContentItem(
                    id: modName,
                    name: modName,
                    author: '',
                    description: '',
                    version: '',
                    downloadUrl: '',
                    downloadCount: 0,
                    iconUrl: null,
                    releaseDate: null,
                    type: ContentType.mod,
                    source: ContentSource.local,
                    status: ContentStatus.notInstalled,
                    gameVersions: [],
                    loaders: [],
                    dependencies: [],
                    conflicts: [],
                  ));
                }
              }
            }
          }
        }
      }
      
      return installedContent;
    } catch (e) {
      _logger.error('获取已安装内容失败: $e');
      return [];
    }
  }

  @override
  Future<bool> uninstallContent(String contentId) async {
    try {
      _logger.info('卸载内容: $contentId');
      // 这里实现卸载逻辑
      return true;
    } catch (e) {
      _logger.error('卸载内容失败: $e');
      return false;
    }
  }

  @override
  Future<List<ContentItem>> searchContent({
    required String query,
    ContentType? type,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      _logger.info('搜索内容: $query, 类型: ${type?.name}');
      final contentType = type ?? ContentType.mod;
      
      List<ContentItem> results = [];
      
      try {
        final searchQuery = SearchQuery(
          query: query,
          type: contentType,
          gameVersion: gameVersion,
          page: page,
          pageSize: pageSize,
        );
        final modrinthResult = await _modrinthApi.search(searchQuery);
        results.addAll(modrinthResult.items);
      } catch (e) {
        _logger.warn('Modrinth搜索失败: $e');
      }
      
      if (results.isEmpty && _curseForgeApi.isConfigured) {
        try {
          final searchQuery = SearchQuery(
            query: query,
            type: contentType,
            gameVersion: gameVersion,
            page: page,
            pageSize: pageSize,
          );
          final curseforgeResult = await _curseForgeApi.search(searchQuery);
          results.addAll(curseforgeResult.items);
        } catch (e) {
          _logger.warn('CurseForge搜索失败: $e');
        }
      }
      
      return results;
    } catch (e) {
      _logger.error('搜索内容失败: $e');
      return [];
    }
  }

  /// 获取热门内容
  /// [type]: 内容类型
  /// [gameVersion]: 游戏版本
  /// [limit]: 返回数量限制
  /// 返回热门内容列表
  @override
  Future<List<ContentItem>> getPopularContent({
    ContentType? type,
    String? gameVersion,
    int limit = 20,
  }) async {
    try {
      _logger.info('获取热门内容: ${type?.name}');
      final contentType = type ?? ContentType.mod;
      
      List<ContentItem> results = [];
      
      try {
        results = await _modrinthApi.getPopularProjects(contentType, limit: limit);
      } catch (e) {
        _logger.warn('Modrinth获取热门项目失败: $e');
      }
      
      if (results.isEmpty && _curseForgeApi.isConfigured) {
        try {
          results = await _curseForgeApi.getPopularMods(contentType, limit: limit);
        } catch (e) {
          _logger.warn('CurseForge获取热门项目失败: $e');
        }
      }
      
      return results;
    } catch (e) {
      _logger.error('获取热门内容失败: $e');
      return [];
    }
  }

  // Modrinth API 实现
  Future<List<Mod>> _searchModsOnModrinth({
    required String query,
    String? gameVersion,
    String? modLoader,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse('https://api.modrinth.com/v2/search').replace(
      queryParameters: {
        'query': query,
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
        'facets': jsonEncode([
          if (gameVersion != null) ['versions:$gameVersion'],
          if (modLoader != null) ['loaders:$modLoader'],
          ['project_type:mod'],
        ]),
      },
    );
    
    final response = await _httpClient.get(url.toString());
    final data = jsonDecode(response.body);
    
    final mods = <Mod>[];
    for (final item in data['hits'] as List) {
      mods.add(Mod(
        id: item['project_id'] as String,
        name: item['title'] as String,
        summary: item['description'] as String,
        description: item['body'] as String,
        author: item['author'] as String,
        source: 'modrinth',
        slug: item['slug'] as String,
        iconUrl: item['icon_url'] as String?,
        logoUrl: null,
        categories: List<String>.from(item['categories'] as List),
        gameVersions: List<String>.from(item['versions'] as List),
        modLoaders: List<String>.from(item['loaders'] as List),
        downloadCount: item['downloads'] as int,
        followersCount: item['follows'] as int,
        score: (item['score'] as num).toDouble(),
        createdAt: DateTime.parse(item['published'] as String),
        updatedAt: DateTime.parse(item['updated'] as String),
        publishedAt: DateTime.parse(item['published'] as String),
      ));
    }
    
    return mods;
  }

  Future<Mod> _getModDetailsOnModrinth(String modId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modId');
    final data = jsonDecode(response.body);
    
    return Mod(
      id: data['id'] as String,
      name: data['title'] as String,
      summary: data['description'] as String,
      description: data['body'] as String,
      author: data['author'] as String,
      source: 'modrinth',
      slug: data['slug'] as String,
      iconUrl: data['icon_url'] as String?,
      logoUrl: null,
      categories: List<String>.from(data['categories'] as List),
      gameVersions: List<String>.from(data['versions'] as List),
      modLoaders: List<String>.from(data['loaders'] as List),
      downloadCount: data['downloads'] as int,
      followersCount: data['follows'] as int,
      score: 0.0,
      createdAt: DateTime.parse(data['published'] as String),
      updatedAt: DateTime.parse(data['updated'] as String),
      publishedAt: DateTime.parse(data['published'] as String),
    );
  }

  Future<List<ModFile>> _getModFilesOnModrinth(String modId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modId/version');
    final data = jsonDecode(response.body) as List;
    
    final files = <ModFile>[];
    for (final item in data) {
      for (final file in item['files'] as List) {
        files.add(ModFile(
          id: file['hashes']['sha1'] as String,
          name: item['name'] as String,
          fileName: file['filename'] as String,
          downloadUrl: file['url'] as String,
          size: file['size'] as int,
          fileType: file['file_type'] as String,
          gameVersions: List<String>.from(item['game_versions'] as List),
          modLoaders: List<String>.from(item['loaders'] as List),
          createdAt: DateTime.parse(item['date_published'] as String),
          updatedAt: DateTime.parse(item['date_published'] as String),
          isPrimary: file['primary'] as bool,
        ));
      }
    }
    
    return files;
  }

  Future<String> _getModFileDownloadUrlOnModrinth(String modId, String fileId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/version/$fileId');
    final data = jsonDecode(response.body);
    
    for (final file in data['files'] as List) {
      if (file['hashes']['sha1'] == fileId) {
        return file['url'] as String;
      }
    }
    
    throw Exception('File not found');
  }

  // CurseForge API 实现
  Future<List<Mod>> _searchModsOnCurseForge({
    required String query,
    String? gameVersion,
    String? modLoader,
    int page = 1,
    int pageSize = 20,
  }) async {
    // 注意：CurseForge API 需要 API Key
    // 这里使用模拟数据，实际实现需要添加 API Key
    return [];
  }

  Future<Mod> _getModDetailsOnCurseForge(String modId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }

  Future<List<ModFile>> _getModFilesOnCurseForge(String modId) async {
    // 注意：CurseForge API 需要 API Key
    return [];
  }

  Future<String> _getModFileDownloadUrlOnCurseForge(String modId, String fileId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }

  // 整合包相关方法
  Future<List<ContentModpack>> _searchModpacksOnModrinth({
    required String query,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse('https://api.modrinth.com/v2/search').replace(
      queryParameters: {
        'query': query,
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
        'facets': jsonEncode([
          if (gameVersion != null) ['versions:$gameVersion'],
          ['project_type:modpack'],
        ]),
      },
    );
    
    final response = await _httpClient.get(url.toString());
    final data = jsonDecode(response.body);
    
    final modpacks = <ContentModpack>[];
    for (final item in data['hits'] as List) {
      modpacks.add(ContentModpack(
        id: item['project_id'] as String,
        name: item['title'] as String,
        summary: item['description'] as String,
        description: item['body'] as String,
        author: item['author'] as String,
        source: 'modrinth',
        slug: item['slug'] as String,
        iconUrl: item['icon_url'] as String?,
        logoUrl: null,
        categories: List<String>.from(item['categories'] as List),
        gameVersions: List<String>.from(item['versions'] as List),
        downloadCount: item['downloads'] as int,
        followersCount: item['follows'] as int,
        score: (item['score'] as num).toDouble(),
        createdAt: DateTime.parse(item['published'] as String),
        updatedAt: DateTime.parse(item['updated'] as String),
        publishedAt: DateTime.parse(item['published'] as String),
      ));
    }
    
    return modpacks;
  }

  Future<ContentModpack> _getModpackDetailsOnModrinth(String modpackId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modpackId');
    final data = jsonDecode(response.body);
    
    return ContentModpack(
      id: data['id'] as String,
      name: data['title'] as String,
      summary: data['description'] as String,
      description: data['body'] as String,
      author: data['author'] as String,
      source: 'modrinth',
      slug: data['slug'] as String,
      iconUrl: data['icon_url'] as String?,
      logoUrl: null,
      categories: List<String>.from(data['categories'] as List),
      gameVersions: List<String>.from(data['versions'] as List),
      downloadCount: data['downloads'] as int,
      followersCount: data['follows'] as int,
      score: 0.0,
      createdAt: DateTime.parse(data['published'] as String),
      updatedAt: DateTime.parse(data['updated'] as String),
      publishedAt: DateTime.parse(data['published'] as String),
    );
  }

  Future<List<ContentModpackFile>> _getModpackFilesOnModrinth(String modpackId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modpackId/version');
    final data = jsonDecode(response.body) as List;
    
    final files = <ContentModpackFile>[];
    for (final item in data) {
      for (final file in item['files'] as List) {
        files.add(ContentModpackFile(
          id: file['hashes']['sha1'] as String,
          name: file['filename'] as String,
          fileName: file['filename'] as String,
          downloadUrl: file['url'] as String,
          size: file['size'] as int,
          gameVersion: item['game_versions'] as String,
          modLoader: item['loaders'] as String,
          createdAt: DateTime.parse(item['created'] as String),
          updatedAt: DateTime.parse(item['updated'] as String),
        ));
      }
    }
    
    return files;
  }

  Future<String> _getModpackFileDownloadUrlOnModrinth(String modpackId, String fileId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/version/$fileId');
    final data = jsonDecode(response.body);
    
    for (final file in data['files'] as List) {
      if (file['hashes']['sha1'] == fileId) {
        return file['url'] as String;
      }
    }
    
    throw Exception('File not found');
  }

  // CurseForge 整合包相关方法
  Future<List<ContentModpack>> _searchModpacksOnCurseForge({
    required String query,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  }) async {
    // 注意：CurseForge API 需要 API Key
    return [];
  }

  Future<ContentModpack> _getModpackDetailsOnCurseForge(String modpackId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }

  Future<List<ContentModpackFile>> _getModpackFilesOnCurseForge(String modpackId) async {
    // 注意：CurseForge API 需要 API Key
    return [];
  }

  Future<String> _getModpackFileDownloadUrlOnCurseForge(String modpackId, String fileId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }
}
