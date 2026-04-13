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

class Modpack {
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

  Modpack({
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

class ModpackFile {
  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final int size;
  final String gameVersion;
  final String modLoader;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModpackFile({
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
