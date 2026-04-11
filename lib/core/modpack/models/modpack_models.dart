enum ModpackFormat {
  curseforge,
  modrinth,
  mmc,
  pcl,
  hmcl,
}

enum ModpackStatus {
  not_installed,
  installed,
  installing,
  corrupted,
}

class Modpack {
  final String id;
  final String name;
  final String author;
  final String version;
  final String description;
  final String minecraftVersion;
  final String? loaderType;
  final String? loaderVersion;
  final String? iconPath;
  final int fileCount;
  final int size;
  final ModpackFormat format;
  final ModpackStatus status;
  final DateTime createdAt;
  final DateTime? installedAt;
  final String? gameVersionId;

  Modpack({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.minecraftVersion,
    this.loaderType,
    this.loaderVersion,
    this.iconPath,
    required this.fileCount,
    required this.size,
    required this.format,
    required this.status,
    required this.createdAt,
    this.installedAt,
    this.gameVersionId,
  });

  factory Modpack.fromJson(Map<String, dynamic> json) {
    return Modpack(
      id: json['id'],
      name: json['name'],
      author: json['author'],
      version: json['version'],
      description: json['description'],
      minecraftVersion: json['minecraftVersion'],
      loaderType: json['loaderType'],
      loaderVersion: json['loaderVersion'],
      iconPath: json['iconPath'],
      fileCount: json['fileCount'],
      size: json['size'],
      format: _parseModpackFormat(json['format']),
      status: _parseModpackStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      installedAt: json['installedAt'] != null
          ? DateTime.parse(json['installedAt'])
          : null,
      gameVersionId: json['gameVersionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'version': version,
      'description': description,
      'minecraftVersion': minecraftVersion,
      'loaderType': loaderType,
      'loaderVersion': loaderVersion,
      'iconPath': iconPath,
      'fileCount': fileCount,
      'size': size,
      'format': _modpackFormatToString(format),
      'status': _modpackStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'installedAt': installedAt?.toIso8601String(),
      'gameVersionId': gameVersionId,
    };
  }

  Modpack copyWith({
    String? id,
    String? name,
    String? author,
    String? version,
    String? description,
    String? minecraftVersion,
    String? loaderType,
    String? loaderVersion,
    String? iconPath,
    int? fileCount,
    int? size,
    ModpackFormat? format,
    ModpackStatus? status,
    DateTime? createdAt,
    DateTime? installedAt,
    String? gameVersionId,
  }) {
    return Modpack(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      description: description ?? this.description,
      minecraftVersion: minecraftVersion ?? this.minecraftVersion,
      loaderType: loaderType ?? this.loaderType,
      loaderVersion: loaderVersion ?? this.loaderVersion,
      iconPath: iconPath ?? this.iconPath,
      fileCount: fileCount ?? this.fileCount,
      size: size ?? this.size,
      format: format ?? this.format,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      installedAt: installedAt ?? this.installedAt,
      gameVersionId: gameVersionId ?? this.gameVersionId,
    );
  }
}

class ModpackFile {
  final String path;
  final String? url;
  final String? sha1;
  final int? size;
  final bool isRequired;

  ModpackFile({
    required this.path,
    this.url,
    this.sha1,
    this.size,
    required this.isRequired,
  });

  factory ModpackFile.fromJson(Map<String, dynamic> json) {
    return ModpackFile(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size'],
      isRequired: json['isRequired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'url': url,
      'sha1': sha1,
      'size': size,
      'isRequired': isRequired,
    };
  }
}

class ModpackManifest {
  final String name;
  final String author;
  final String version;
  final String description;
  final String minecraftVersion;
  final String? loaderType;
  final String? loaderVersion;
  final List<ModpackFile> files;
  final String? iconPath;

  ModpackManifest({
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.minecraftVersion,
    this.loaderType,
    this.loaderVersion,
    required this.files,
    this.iconPath,
  });

  factory ModpackManifest.fromJson(Map<String, dynamic> json) {
    return ModpackManifest(
      name: json['name'],
      author: json['author'],
      version: json['version'],
      description: json['description'],
      minecraftVersion: json['minecraftVersion'],
      loaderType: json['loaderType'],
      loaderVersion: json['loaderVersion'],
      files:
          (json['files'] as List).map((v) => ModpackFile.fromJson(v)).toList(),
      iconPath: json['iconPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'version': version,
      'description': description,
      'minecraftVersion': minecraftVersion,
      'loaderType': loaderType,
      'loaderVersion': loaderVersion,
      'files': files.map((v) => v.toJson()).toList(),
      'iconPath': iconPath,
    };
  }
}

class ModpackImportResult {
  final bool success;
  final String? errorMessage;
  final Modpack? modpack;

  ModpackImportResult({
    required this.success,
    this.errorMessage,
    this.modpack,
  });
}

class ModpackExportResult {
  final bool success;
  final String? errorMessage;
  final String? exportPath;

  ModpackExportResult({
    required this.success,
    this.errorMessage,
    this.exportPath,
  });
}

class ModpackInstallResult {
  final bool success;
  final String? errorMessage;
  final String? gameVersionId;

  ModpackInstallResult({
    required this.success,
    this.errorMessage,
    this.gameVersionId,
  });
}

class ModpackCreateOptions {
  final String name;
  final String author;
  final String version;
  final String description;
  final String minecraftVersion;
  final String? loaderType;
  final String? loaderVersion;
  final List<String> includeFiles;
  final List<String> excludeFiles;
  final ModpackFormat format;
  final String? iconPath;

  ModpackCreateOptions({
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.minecraftVersion,
    this.loaderType,
    this.loaderVersion,
    required this.includeFiles,
    required this.excludeFiles,
    required this.format,
    this.iconPath,
  });
}

enum ModpackImportStatus {
  parsing,
  downloading,
  installing,
  completed,
  failed,
}

class ModpackImportProgress {
  final ModpackImportStatus status;
  final double progress;
  final String? message;

  ModpackImportProgress({
    required this.status,
    required this.progress,
    this.message,
  });
}

ModpackFormat _parseModpackFormat(String format) {
  switch (format) {
    case 'curseforge':
      return ModpackFormat.curseforge;
    case 'modrinth':
      return ModpackFormat.modrinth;
    case 'mmc':
      return ModpackFormat.mmc;
    case 'pcl':
      return ModpackFormat.pcl;
    case 'hmcl':
      return ModpackFormat.hmcl;
    default:
      return ModpackFormat.curseforge;
  }
}

String _modpackFormatToString(ModpackFormat format) {
  switch (format) {
    case ModpackFormat.curseforge:
      return 'curseforge';
    case ModpackFormat.modrinth:
      return 'modrinth';
    case ModpackFormat.mmc:
      return 'mmc';
    case ModpackFormat.pcl:
      return 'pcl';
    case ModpackFormat.hmcl:
      return 'hmcl';
  }
}

ModpackStatus _parseModpackStatus(String status) {
  switch (status) {
    case 'not_installed':
      return ModpackStatus.not_installed;
    case 'installed':
      return ModpackStatus.installed;
    case 'installing':
      return ModpackStatus.installing;
    case 'corrupted':
      return ModpackStatus.corrupted;
    default:
      return ModpackStatus.not_installed;
  }
}

String _modpackStatusToString(ModpackStatus status) {
  switch (status) {
    case ModpackStatus.not_installed:
      return 'not_installed';
    case ModpackStatus.installed:
      return 'installed';
    case ModpackStatus.installing:
      return 'installing';
    case ModpackStatus.corrupted:
      return 'corrupted';
  }
}
