enum VersionType {
  release,
  snapshot,
  old_alpha,
  old_beta,
  custom,
}

enum VersionCategory {
  release,
  snapshot,
  oldAlpha,
  preRelease,
  other,
}

enum VersionStatus {
  not_installed,
  installed,
  installing,
  corrupted,
}

class VersionManifest {
  final String latestRelease;
  final String latestSnapshot;
  final List<VersionEntry> versions;

  VersionManifest({
    required this.latestRelease,
    required this.latestSnapshot,
    required this.versions,
  });

  factory VersionManifest.fromJson(Map<String, dynamic> json) {
    return VersionManifest(
      latestRelease: json['latest']['release'],
      latestSnapshot: json['latest']['snapshot'],
      versions: (json['versions'] as List)
          .map((v) => VersionEntry.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest': {
        'release': latestRelease,
        'snapshot': latestSnapshot,
      },
      'versions': versions.map((v) => v.toJson()).toList(),
    };
  }
}

class VersionEntry {
  final String id;
  final VersionType type;
  final DateTime releaseTime;
  final DateTime time;
  final String url;

  VersionEntry({
    required this.id,
    required this.type,
    required this.releaseTime,
    required this.time,
    required this.url,
  });

  factory VersionEntry.fromJson(Map<String, dynamic> json) {
    return VersionEntry(
      id: json['id'],
      type: _parseVersionType(json['type']),
      releaseTime: DateTime.parse(json['releaseTime']),
      time: DateTime.parse(json['time']),
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _versionTypeToString(type),
      'releaseTime': releaseTime.toIso8601String(),
      'time': time.toIso8601String(),
      'url': url,
    };
  }

  static VersionType _parseVersionType(String type) {
    switch (type) {
      case 'release':
        return VersionType.release;
      case 'snapshot':
        return VersionType.snapshot;
      case 'old_alpha':
        return VersionType.old_alpha;
      case 'old_beta':
        return VersionType.old_beta;
      default:
        return VersionType.custom;
    }
  }

  static String _versionTypeToString(VersionType type) {
    switch (type) {
      case VersionType.release:
        return 'release';
      case VersionType.snapshot:
        return 'snapshot';
      case VersionType.old_alpha:
        return 'old_alpha';
      case VersionType.old_beta:
        return 'old_beta';
      case VersionType.custom:
        return 'custom';
    }
  }
}

class Version {
  final String id;
  final VersionType type;
  final DateTime releaseTime;
  final DateTime time;
  final int complianceLevel;
  final Download? download;
  final AssetIndex? assetIndex;
  final List<Library> libraries;
  final List<String> arguments;
  final List<String> jvmArguments;
  final String mainClass;
  final String inheritsFrom;
  final VersionStatus status;

  Version({
    required this.id,
    required this.type,
    required this.releaseTime,
    required this.time,
    required this.complianceLevel,
    this.download,
    this.assetIndex,
    required this.libraries,
    required this.arguments,
    required this.jvmArguments,
    required this.mainClass,
    required this.inheritsFrom,
    required this.status,
  });

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      id: json['id'],
      type: VersionEntry._parseVersionType(json['type']),
      releaseTime: DateTime.parse(json['releaseTime']),
      time: DateTime.parse(json['time']),
      complianceLevel: json['complianceLevel'] ?? 0,
      download: json['downloads'] != null
          ? Download.fromJson(json['downloads']['client'])
          : null,
      assetIndex: json['assetIndex'] != null
          ? AssetIndex.fromJson(json['assetIndex'])
          : null,
      libraries:
          (json['libraries'] as List).map((v) => Library.fromJson(v)).toList(),
      arguments: (json['arguments']['game'] as List).cast<String>(),
      jvmArguments: (json['arguments']['jvm'] as List).cast<String>(),
      mainClass: json['mainClass'],
      inheritsFrom: json['inheritsFrom'] ?? '',
      status: VersionStatus.not_installed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': VersionEntry._versionTypeToString(type),
      'releaseTime': releaseTime.toIso8601String(),
      'time': time.toIso8601String(),
      'complianceLevel': complianceLevel,
      'downloads': download != null ? {'client': download!.toJson()} : null,
      'assetIndex': assetIndex?.toJson(),
      'libraries': libraries.map((v) => v.toJson()).toList(),
      'arguments': {
        'game': arguments,
        'jvm': jvmArguments,
      },
      'mainClass': mainClass,
      'inheritsFrom': inheritsFrom,
    };
  }

  Version copyWith({
    String? id,
    VersionType? type,
    DateTime? releaseTime,
    DateTime? time,
    int? complianceLevel,
    Download? download,
    AssetIndex? assetIndex,
    List<Library>? libraries,
    List<String>? arguments,
    List<String>? jvmArguments,
    String? mainClass,
    String? inheritsFrom,
    VersionStatus? status,
  }) {
    return Version(
      id: id ?? this.id,
      type: type ?? this.type,
      releaseTime: releaseTime ?? this.releaseTime,
      time: time ?? this.time,
      complianceLevel: complianceLevel ?? this.complianceLevel,
      download: download ?? this.download,
      assetIndex: assetIndex ?? this.assetIndex,
      libraries: libraries ?? this.libraries,
      arguments: arguments ?? this.arguments,
      jvmArguments: jvmArguments ?? this.jvmArguments,
      mainClass: mainClass ?? this.mainClass,
      inheritsFrom: inheritsFrom ?? this.inheritsFrom,
      status: status ?? this.status,
    );
  }
}

class Download {
  final String url;
  final String sha1;
  final int size;

  Download({
    required this.url,
    required this.sha1,
    required this.size,
  });

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      url: json['url'],
      sha1: json['sha1'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'sha1': sha1,
      'size': size,
    };
  }
}

class AssetIndex {
  final String id;
  final String sha1;
  final int size;
  final int totalSize;
  final String url;

  AssetIndex({
    required this.id,
    required this.sha1,
    required this.size,
    required this.totalSize,
    required this.url,
  });

  factory AssetIndex.fromJson(Map<String, dynamic> json) {
    return AssetIndex(
      id: json['id'],
      sha1: json['sha1'],
      size: json['size'],
      totalSize: json['totalSize'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sha1': sha1,
      'size': size,
      'totalSize': totalSize,
      'url': url,
    };
  }
}

class Library {
  final String name;
  final LibraryDownloads downloads;

  Library({
    required this.name,
    required this.downloads,
  });

  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      name: json['name'],
      downloads: LibraryDownloads.fromJson(json['downloads']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'downloads': downloads.toJson(),
    };
  }
}

class LibraryDownloads {
  final Artifact? artifact;

  LibraryDownloads({
    this.artifact,
  });

  factory LibraryDownloads.fromJson(Map<String, dynamic> json) {
    return LibraryDownloads(
      artifact:
          json['artifact'] != null ? Artifact.fromJson(json['artifact']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artifact': artifact?.toJson(),
    };
  }
}

class Artifact {
  final String path;
  final String url;
  final String sha1;
  final int size;

  Artifact({
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'url': url,
      'sha1': sha1,
      'size': size,
    };
  }
}
