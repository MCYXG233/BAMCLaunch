import '../interfaces/i_content_manager.dart';
import '../models/content_models.dart';
import '../../http/i_http_client.dart';
import '../../logger/i_logger.dart';
import '../../download/i_download_engine.dart';
import 'dart:convert';

class ContentManager implements IContentManager {
  final IHttpClient _httpClient;
  final ILogger _logger;
  final IDownloadEngine _downloadEngine;

  ContentManager({
    required IHttpClient httpClient,
    required ILogger logger,
    required IDownloadEngine downloadEngine,
  })  : _httpClient = httpClient,
        _logger = logger,
        _downloadEngine = downloadEngine;

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
  Future<List<Modpack>> searchModpacks({
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
  Future<Modpack> getModpackDetails(String modpackId, {String? source}) async {
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
  Future<List<ModpackFile>> getModpackFiles(String modpackId, {String? source}) async {
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
  Future<List<Modpack>> _searchModpacksOnModrinth({
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
    
    final modpacks = <Modpack>[];
    for (final item in data['hits'] as List) {
      modpacks.add(Modpack(
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

  Future<Modpack> _getModpackDetailsOnModrinth(String modpackId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modpackId');
    final data = jsonDecode(response.body);
    
    return Modpack(
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

  Future<List<ModpackFile>> _getModpackFilesOnModrinth(String modpackId) async {
    final response = await _httpClient.get('https://api.modrinth.com/v2/project/$modpackId/version');
    final data = jsonDecode(response.body) as List;
    
    final files = <ModpackFile>[];
    for (final item in data) {
      for (final file in item['files'] as List) {
        files.add(ModpackFile(
          id: file['hashes']['sha1'] as String,
          name: item['name'] as String,
          fileName: file['filename'] as String,
          downloadUrl: file['url'] as String,
          size: file['size'] as int,
          gameVersion: item['game_versions'][0] as String,
          modLoader: item['loaders'][0] as String,
          createdAt: DateTime.parse(item['date_published'] as String),
          updatedAt: DateTime.parse(item['date_published'] as String),
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
  Future<List<Modpack>> _searchModpacksOnCurseForge({
    required String query,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  }) async {
    // 注意：CurseForge API 需要 API Key
    return [];
  }

  Future<Modpack> _getModpackDetailsOnCurseForge(String modpackId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }

  Future<List<ModpackFile>> _getModpackFilesOnCurseForge(String modpackId) async {
    // 注意：CurseForge API 需要 API Key
    return [];
  }

  Future<String> _getModpackFileDownloadUrlOnCurseForge(String modpackId, String fileId) async {
    // 注意：CurseForge API 需要 API Key
    throw Exception('CurseForge API not implemented');
  }
}
