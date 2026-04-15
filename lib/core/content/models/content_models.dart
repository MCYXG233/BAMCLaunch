class Mod {
  final String id;
  final String name;
  final String summary;
  final String description;
  final String author;
  final String source;
  final String slug;
  final String? iconUrl;
  final String? logoUrl;
  final List<String> categories;
  final List<String> gameVersions;
  final List<String> modLoaders;
  final int downloadCount;
  final int followersCount;
  final double score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  Mod({
    required this.id,
    required this.name,
    required this.summary,
    required this.description,
    required this.author,
    required this.source,
    required this.slug,
    this.iconUrl,
    this.logoUrl,
    required this.categories,
    required this.gameVersions,
    required this.modLoaders,
    required this.downloadCount,
    required this.followersCount,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });
}

class ModFile {
  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final int size;
  final String fileType;
  final List<String> gameVersions;
  final List<String> modLoaders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrimary;

  ModFile({
    required this.id,
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.size,
    required this.fileType,
    required this.gameVersions,
    required this.modLoaders,
    required this.createdAt,
    required this.updatedAt,
    required this.isPrimary,
  });
}

class ContentModpack {
  final String id;
  final String name;
  final String summary;
  final String description;
  final String author;
  final String source;
  final String slug;
  final String? iconUrl;
  final String? logoUrl;
  final List<String> categories;
  final List<String> gameVersions;
  final int downloadCount;
  final int followersCount;
  final double score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  ContentModpack({
    required this.id,
    required this.name,
    required this.summary,
    required this.description,
    required this.author,
    required this.source,
    required this.slug,
    this.iconUrl,
    this.logoUrl,
    required this.categories,
    required this.gameVersions,
    required this.downloadCount,
    required this.followersCount,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });
}

class ContentModpackFile {
  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final int size;
  final String gameVersion;
  final String modLoader;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentModpackFile({
    required this.id,
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.size,
    required this.gameVersion,
    required this.modLoader,
    required this.createdAt,
    required this.updatedAt,
  });
}

class GameVersion {
  final String id;
  final String name;
  final String version;
  final bool isStable;
  final DateTime releaseDate;

  GameVersion({
    required this.id,
    required this.name,
    required this.version,
    required this.isStable,
    required this.releaseDate,
  });
}

class ModLoader {
  final String id;
  final String name;
  final String version;
  final String gameVersion;
  final bool isRecommended;
  final bool isLatest;

  ModLoader({
    required this.id,
    required this.name,
    required this.version,
    required this.gameVersion,
    required this.isRecommended,
    required this.isLatest,
  });
}

enum ContentType {
  mod,
  resourcePack,
  shaderPack,
  dataPack,
  modpack,
}

enum ContentSource {
  curseforge,
  modrinth,
  local,
}

enum ContentStatus {
  notInstalled,
  installed,
  updating,
  outdated,
  error,
}

enum SortType {
  relevance,
  downloads,
  recentlyUpdated,
  recentlyAdded,
  featured,
}

class SearchQuery {
  final String? query;
  final ContentType type;
  final String? gameVersion;
  final int page;
  final int pageSize;
  final SortType sortType;
  final bool ascending;
  final String? category;
  final String? author;
  final String? loader;

  SearchQuery({
    this.query,
    required this.type,
    this.gameVersion,
    this.page = 1,
    this.pageSize = 20,
    this.sortType = SortType.relevance,
    this.ascending = false,
    this.category,
    this.author,
    this.loader,
  });
}

class SearchResult {
  final List<ContentItem> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  SearchResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class ContentItem {
  final String id;
  final String name;
  final String author;
  final String description;
  final String version;
  final String downloadUrl;
  final int downloadCount;
  final String? iconUrl;
  final DateTime? releaseDate;
  final ContentType type;
  final ContentSource source;
  final ContentStatus status;
  final List<String> gameVersions;
  final List<String> loaders;
  final List<ContentDependency> dependencies;
  final List<ContentDependency> conflicts;

  ContentItem({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.version,
    required this.downloadUrl,
    required this.downloadCount,
    this.iconUrl,
    this.releaseDate,
    required this.type,
    required this.source,
    required this.status,
    required this.gameVersions,
    required this.loaders,
    required this.dependencies,
    required this.conflicts,
  });
}

class ContentDependency {
  final String id;
  final String name;
  final bool isRequired;

  ContentDependency({
    required this.id,
    required this.name,
    required this.isRequired,
  });
}
