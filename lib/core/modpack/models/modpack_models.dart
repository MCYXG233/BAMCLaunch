class Modpack {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String gameVersion;
  final String modLoader;
  final String modLoaderVersion;
  final String iconPath;
  final List<ModpackMod> mods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String path;

  Modpack({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.gameVersion,
    required this.modLoader,
    required this.modLoaderVersion,
    required this.iconPath,
    required this.mods,
    required this.createdAt,
    required this.updatedAt,
    required this.path,
  });

  // 兼容页面中的字段名称
  String get minecraftVersion => gameVersion;
  String? get loaderType => modLoader.isNotEmpty ? modLoader : null;

  Modpack copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    String? gameVersion,
    String? modLoader,
    String? modLoaderVersion,
    String? iconPath,
    List<ModpackMod>? mods,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? path,
  }) {
    return Modpack(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      gameVersion: gameVersion ?? this.gameVersion,
      modLoader: modLoader ?? this.modLoader,
      modLoaderVersion: modLoaderVersion ?? this.modLoaderVersion,
      iconPath: iconPath ?? this.iconPath,
      mods: mods ?? this.mods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      path: path ?? this.path,
    );
  }
}

class ModpackInstallationResult {
  final bool success;
  final String modpackId;
  final String gameVersion;
  final List<String> installedMods;
  final List<String> failedMods;
  final String? error;

  ModpackInstallationResult({
    required this.success,
    required this.modpackId,
    required this.gameVersion,
    required this.installedMods,
    required this.failedMods,
    this.error,
  });
}

class ModpackMod {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String source;
  final String downloadUrl;
  final int size;
  final String filePath;
  final DateTime installedAt;

  ModpackMod({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.source,
    required this.downloadUrl,
    required this.size,
    required this.filePath,
    required this.installedAt,
  });

  ModpackMod copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    String? source,
    String? downloadUrl,
    int? size,
    String? filePath,
    DateTime? installedAt,
  }) {
    return ModpackMod(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      source: source ?? this.source,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      size: size ?? this.size,
      filePath: filePath ?? this.filePath,
      installedAt: installedAt ?? this.installedAt,
    );
  }
}

enum ModpackFormat {
  curseforge,
  modrinth,
}

class ModpackCreateOptions {
  final String name;
  final String author;
  final String version;
  final String description;
  final String minecraftVersion;
  final ModpackFormat format;
  final List<String> includeFiles;
  final List<String> excludeFiles;

  ModpackCreateOptions({
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.minecraftVersion,
    required this.format,
    required this.includeFiles,
    required this.excludeFiles,
  });
}

class ModpackImportResult {
  final bool success;
  final String? errorMessage;

  ModpackImportResult({
    required this.success,
    this.errorMessage,
  });
}

class ModpackProgress {
  final double progress;
  final String? message;

  ModpackProgress({
    required this.progress,
    this.message,
  });
}
