/// 资源类型枚举
enum ResourceType {
  /// 模组
  mod,

  /// 资源包
  resourcePack,

  /// 模组包
  modpack,
}

/// 作者信息
class Author {
  /// 作者ID
  final String id;

  /// 作者名称
  final String name;

  /// 作者头像URL
  final String? avatarUrl;

  /// 创建作者信息
  Author({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  /// 从JSON创建
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }
}

/// 分类/标签
class Category {
  /// 分类ID
  final String id;

  /// 分类名称
  final String name;

  /// 分类图标URL
  final String? iconUrl;

  /// 创建分类
  Category({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  /// 从JSON创建
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
    };
  }
}

/// 版本下载信息
class VersionDownload {
  /// 下载URL
  final String url;

  /// 文件名
  final String fileName;

  /// 文件大小（字节）
  final int fileSize;

  /// SHA1哈希
  final String? sha1;

  /// SHA256哈希
  final String? sha256;

  /// 创建版本下载信息
  VersionDownload({
    required this.url,
    required this.fileName,
    required this.fileSize,
    this.sha1,
    this.sha256,
  });

  /// 从JSON创建
  factory VersionDownload.fromJson(Map<String, dynamic> json) {
    return VersionDownload(
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      sha1: json['sha1'] as String?,
      sha256: json['sha256'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
      'sha1': sha1,
      'sha256': sha256,
    };
  }
}

/// 资源版本信息
class ResourceVersion {
  /// 版本ID
  final String id;

  /// 版本号
  final String versionNumber;

  /// 版本名称
  final String name;

  /// 发布时间
  final DateTime releaseDate;

  /// 支持的游戏版本
  final List<String> gameVersions;

  /// 加载器类型
  final List<String> loaders;

  /// 下载信息
  final VersionDownload download;

  /// 版本说明
  final String? changelog;

  /// 创建资源版本
  ResourceVersion({
    required this.id,
    required this.versionNumber,
    required this.name,
    required this.releaseDate,
    required this.gameVersions,
    required this.loaders,
    required this.download,
    this.changelog,
  });

  /// 从JSON创建
  factory ResourceVersion.fromJson(Map<String, dynamic> json) {
    return ResourceVersion(
      id: json['id'] as String,
      versionNumber: json['versionNumber'] as String,
      name: json['name'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      gameVersions: (json['gameVersions'] as List<dynamic>)
          .map((v) => v as String)
          .toList(),
      loaders: (json['loaders'] as List<dynamic>)
          .map((l) => l as String)
          .toList(),
      download: VersionDownload.fromJson(
        json['download'] as Map<String, dynamic>,
      ),
      changelog: json['changelog'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versionNumber': versionNumber,
      'name': name,
      'releaseDate': releaseDate.toIso8601String(),
      'gameVersions': gameVersions,
      'loaders': loaders,
      'download': download.toJson(),
      'changelog': changelog,
    };
  }
}

/// 资源/模组基本信息
class Resource {
  /// 资源ID
  final String id;

  /// 资源类型
  final ResourceType type;

  /// 资源来源（curseforge/modrinth）
  final String source;

  /// 资源名称
  final String name;

  /// 资源描述
  final String description;

  /// 详细描述
  final String? body;

  /// 作者列表
  final List<Author> authors;

  /// 分类/标签列表
  final List<Category> categories;

  /// 图标URL
  final String? iconUrl;

  /// 截图URL列表
  final List<String> screenshotUrls;

  /// 支持的游戏版本
  final List<String> supportedGameVersions;

  /// 支持的加载器
  final List<String> supportedLoaders;

  /// 下载次数
  final int downloads;

  /// 点赞数
  final int likes;

  /// 页面URL
  final String pageUrl;

  /// 发布时间
  final DateTime publishedDate;

  /// 更新时间
  final DateTime updatedDate;

  /// 许可证
  final String? license;

  /// 最新版本（如果已获取）
  final ResourceVersion? latestVersion;

  /// 创建资源信息
  Resource({
    required this.id,
    required this.type,
    required this.source,
    required this.name,
    required this.description,
    this.body,
    required this.authors,
    required this.categories,
    this.iconUrl,
    this.screenshotUrls = const [],
    required this.supportedGameVersions,
    required this.supportedLoaders,
    required this.downloads,
    required this.likes,
    required this.pageUrl,
    required this.publishedDate,
    required this.updatedDate,
    this.license,
    this.latestVersion,
  });

  /// 从JSON创建
  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      type: _parseResourceType(json['type'] as String),
      source: json['source'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      body: json['body'] as String?,
      authors: (json['authors'] as List<dynamic>)
          .map((a) => Author.fromJson(a as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList(),
      iconUrl: json['iconUrl'] as String?,
      screenshotUrls: (json['screenshotUrls'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      supportedGameVersions: (json['supportedGameVersions'] as List<dynamic>)
          .map((v) => v as String)
          .toList(),
      supportedLoaders: (json['supportedLoaders'] as List<dynamic>)
          .map((l) => l as String)
          .toList(),
      downloads: json['downloads'] as int,
      likes: json['likes'] as int,
      pageUrl: json['pageUrl'] as String,
      publishedDate: DateTime.parse(json['publishedDate'] as String),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
      license: json['license'] as String?,
      latestVersion: json['latestVersion'] != null
          ? ResourceVersion.fromJson(
              json['latestVersion'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'source': source,
      'name': name,
      'description': description,
      'body': body,
      'authors': authors.map((a) => a.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'iconUrl': iconUrl,
      'screenshotUrls': screenshotUrls,
      'supportedGameVersions': supportedGameVersions,
      'supportedLoaders': supportedLoaders,
      'downloads': downloads,
      'likes': likes,
      'pageUrl': pageUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'license': license,
      'latestVersion': latestVersion?.toJson(),
    };
  }

  /// 解析资源类型
  static ResourceType _parseResourceType(String type) {
    switch (type) {
      case 'mod':
        return ResourceType.mod;
      case 'resourcePack':
        return ResourceType.resourcePack;
      case 'modpack':
        return ResourceType.modpack;
      default:
        return ResourceType.mod;
    }
  }
}

/// 搜索结果
class SearchResult {
  /// 搜索到的资源列表
  final List<Resource> resources;

  /// 总结果数
  final int totalResults;

  /// 当前页码
  final int page;

  /// 每页数量
  final int pageSize;

  /// 创建搜索结果
  SearchResult({
    required this.resources,
    required this.totalResults,
    required this.page,
    required this.pageSize,
  });

  /// 从JSON创建
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      resources: (json['resources'] as List<dynamic>)
          .map((r) => Resource.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalResults: json['totalResults'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'resources': resources.map((r) => r.toJson()).toList(),
      'totalResults': totalResults,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

/// 搜索参数
class SearchParams {
  /// 搜索关键词
  final String query;

  /// 资源类型
  final ResourceType? type;

  /// 游戏版本
  final List<String>? gameVersions;

  /// 加载器
  final List<String>? loaders;

  /// 分类
  final List<String>? categories;

  /// 页码（从1开始）
  final int page;

  /// 每页数量
  final int pageSize;

  /// 排序方式
  final String sortBy;

  /// 创建搜索参数
  SearchParams({
    this.query = '',
    this.type,
    this.gameVersions,
    this.loaders,
    this.categories,
    this.page = 1,
    this.pageSize = 20,
    this.sortBy = 'relevance',
  });

  /// 复制并更新参数
  SearchParams copyWith({
    String? query,
    ResourceType? type,
    List<String>? gameVersions,
    List<String>? loaders,
    List<String>? categories,
    int? page,
    int? pageSize,
    String? sortBy,
  }) {
    return SearchParams(
      query: query ?? this.query,
      type: type ?? this.type,
      gameVersions: gameVersions ?? this.gameVersions,
      loaders: loaders ?? this.loaders,
      categories: categories ?? this.categories,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// 已安装资源信息
class InstalledResource {
  /// 唯一标识（由 source + '_' + id 组成）
  final String localId;

  /// 资源ID（来自原平台）
  final String resourceId;

  /// 资源来源
  final String source;

  /// 资源类型
  final ResourceType type;

  /// 资源名称
  final String name;

  /// 安装的版本
  final String installedVersion;

  /// 安装的版本ID
  final String versionId;

  /// 文件路径
  final String filePath;

  /// 文件大小（字节）
  final int fileSize;

  /// 安装时间
  final DateTime installedAt;

  /// 是否启用
  final bool enabled;

  /// 图标URL（可选）
  final String? iconUrl;

  /// 创建已安装资源信息
  InstalledResource({
    required this.localId,
    required this.resourceId,
    required this.source,
    required this.type,
    required this.name,
    required this.installedVersion,
    required this.versionId,
    required this.filePath,
    required this.fileSize,
    required this.installedAt,
    this.enabled = true,
    this.iconUrl,
  });

  /// 生成唯一标识
  static String generateLocalId(String source, String resourceId) {
    return '${source}_$resourceId';
  }

  /// 解析资源类型字符串
  static ResourceType _parseResourceType(String type) {
    switch (type) {
      case 'mod':
        return ResourceType.mod;
      case 'resourcePack':
        return ResourceType.resourcePack;
      case 'modpack':
        return ResourceType.modpack;
      default:
        return ResourceType.mod;
    }
  }

  /// 从JSON创建
  factory InstalledResource.fromJson(Map<String, dynamic> json) {
    return InstalledResource(
      localId: json['localId'] as String,
      resourceId: json['resourceId'] as String,
      source: json['source'] as String,
      type: _parseResourceType(json['type'] as String),
      name: json['name'] as String,
      installedVersion: json['installedVersion'] as String,
      versionId: json['versionId'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      installedAt: DateTime.parse(json['installedAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'resourceId': resourceId,
      'source': source,
      'type': type.name,
      'name': name,
      'installedVersion': installedVersion,
      'versionId': versionId,
      'filePath': filePath,
      'fileSize': fileSize,
      'installedAt': installedAt.toIso8601String(),
      'enabled': enabled,
      'iconUrl': iconUrl,
    };
  }

  /// 复制并更新
  InstalledResource copyWith({
    String? localId,
    String? resourceId,
    String? source,
    ResourceType? type,
    String? name,
    String? installedVersion,
    String? versionId,
    String? filePath,
    int? fileSize,
    DateTime? installedAt,
    bool? enabled,
    String? iconUrl,
  }) {
    return InstalledResource(
      localId: localId ?? this.localId,
      resourceId: resourceId ?? this.resourceId,
      source: source ?? this.source,
      type: type ?? this.type,
      name: name ?? this.name,
      installedVersion: installedVersion ?? this.installedVersion,
      versionId: versionId ?? this.versionId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      installedAt: installedAt ?? this.installedAt,
      enabled: enabled ?? this.enabled,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}
