enum ContentType {
  mod,
  modpack,
  resourcePack,
  shaderPack,
  dataPack,
  map,
}

enum ContentSource {
  curseforge,
  modrinth,
  local,
}

enum ContentStatus {
  installed,
  updateAvailable,
  notInstalled,
  installing,
  updating,
  failed,
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
  final String? installedVersion;
  final List<String> gameVersions;
  final List<String> loaders;
  final List<ContentDependency> dependencies;
  final List<String> conflicts;

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
    this.installedVersion,
    required this.gameVersions,
    required this.loaders,
    required this.dependencies,
    required this.conflicts,
  });
}

class ContentDependency {
  final String id;
  final String name;
  final String? version;
  final bool isRequired;

  ContentDependency({
    required this.id,
    required this.name,
    this.version,
    required this.isRequired,
  });

  ContentDependency copyWith({
    String? id,
    String? name,
    String? version,
    bool? isRequired,
  }) {
    return ContentDependency(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

enum SortType {
  relevance,
  downloads,
  recentlyUpdated,
  recentlyAdded,
  featured,
}

class SearchQuery {
  final String query;
  final ContentType type;
  final String? gameVersion;
  final String? loader;
  final String? category;
  final String? author;
  final SortType sortType;
  final bool ascending;
  final int page;
  final int pageSize;

  SearchQuery({
    required this.query,
    required this.type,
    this.gameVersion,
    this.loader,
    this.category,
    this.author,
    this.sortType = SortType.relevance,
    this.ascending = false,
    this.page = 1,
    this.pageSize = 20,
  });

  SearchQuery copyWith({
    String? query,
    ContentType? type,
    String? gameVersion,
    String? loader,
    String? category,
    String? author,
    SortType? sortType,
    bool? ascending,
    int? page,
    int? pageSize,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      type: type ?? this.type,
      gameVersion: gameVersion ?? this.gameVersion,
      loader: loader ?? this.loader,
      category: category ?? this.category,
      author: author ?? this.author,
      sortType: sortType ?? this.sortType,
      ascending: ascending ?? this.ascending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class SearchResult {
  final List<ContentItem> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final DateTime timestamp;

  SearchResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ContentInstallResult {
  final bool success;
  final String? errorMessage;
  final ContentItem? installedItem;
  final List<ContentDependency> missingDependencies;
  final List<String> conflicts;

  ContentInstallResult({
    required this.success,
    this.errorMessage,
    this.installedItem,
    required this.missingDependencies,
    required this.conflicts,
  });
}

class ConflictInfo {
  final ContentItem existingItem;
  final ContentItem newItem;
  final String conflictReason;

  ConflictInfo({
    required this.existingItem,
    required this.newItem,
    required this.conflictReason,
  });
}

class DependencyInfo {
  final ContentItem item;
  final List<ContentDependency> missingDependencies;

  DependencyInfo({
    required this.item,
    required this.missingDependencies,
  });
}