/// 游戏版本类型枚举
enum VersionType {
  /// 正式版
  release,

  /// 快照版
  snapshot,

  /// 旧版
  oldBeta,

  /// 远古版
  oldAlpha,
}

/// 游戏版本数据模型
///
/// 表示一个Minecraft游戏版本的基本信息
class GameVersion {
  /// 版本ID，如 "1.20.1"
  final String id;

  /// 版本类型
  final VersionType type;

  /// 版本详情URL
  final String url;

  /// 版本更新时间
  final DateTime time;

  /// 版本发布时间
  final DateTime releaseTime;

  /// 创建游戏版本
  GameVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
  });

  /// 从JSON创建游戏版本
  factory GameVersion.fromJson(Map<String, dynamic> json) {
    return GameVersion(
      id: json['id'] as String,
      type: _parseVersionType(json['type'] as String),
      url: json['url'] as String,
      time: DateTime.parse(json['time'] as String),
      releaseTime: DateTime.parse(json['releaseTime'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'url': url,
      'time': time.toIso8601String(),
      'releaseTime': releaseTime.toIso8601String(),
    };
  }

  /// 解析版本类型字符串
  static VersionType _parseVersionType(String type) {
    switch (type) {
      case 'release':
        return VersionType.release;
      case 'snapshot':
        return VersionType.snapshot;
      case 'old_beta':
        return VersionType.oldBeta;
      case 'old_alpha':
        return VersionType.oldAlpha;
      default:
        return VersionType.release;
    }
  }
}

/// 版本清单数据模型
///
/// 包含所有可用版本的列表
class VersionManifest {
  /// 最新版本信息
  final LatestVersions latest;

  /// 所有游戏版本列表
  final List<GameVersion> versions;

  /// 创建版本清单
  VersionManifest({required this.latest, required this.versions});

  /// 从JSON创建版本清单
  factory VersionManifest.fromJson(Map<String, dynamic> json) {
    final latestJson = json['latest'] as Map<String, dynamic>;
    final versionsJson = json['versions'] as List<dynamic>;

    return VersionManifest(
      latest: LatestVersions.fromJson(latestJson),
      versions: versionsJson
          .map((v) => GameVersion.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'latest': latest.toJson(),
      'versions': versions.map((v) => v.toJson()).toList(),
    };
  }
}

/// 最新版本信息
class LatestVersions {
  /// 最新正式版
  final String release;

  /// 最新快照版
  final String snapshot;

  /// 创建最新版本信息
  LatestVersions({required this.release, required this.snapshot});

  /// 从JSON创建
  factory LatestVersions.fromJson(Map<String, dynamic> json) {
    return LatestVersions(
      release: json['release'] as String,
      snapshot: json['snapshot'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'release': release, 'snapshot': snapshot};
  }
}

/// 版本JSON数据模型
///
/// 包含版本的详细信息，如客户端、库文件、资源等
class VersionJson {
  /// 版本ID
  final String id;

  /// 版本类型
  final VersionType type;

  /// 版本继承自（Forge等）
  final String? inheritsFrom;

  /// 版本时间
  final DateTime time;

  /// 发布时间
  final DateTime releaseTime;

  /// 主类名
  final String mainClass;

  /// 游戏参数（旧版格式）
  final String? minecraftArguments;

  /// 游戏参数
  final Arguments? arguments;

  /// 客户端下载信息
  final DownloadInfo? downloads;

  /// 库文件列表
  final List<Library> libraries;

  /// 资源索引
  final AssetIndex assetIndex;

  /// 兼容的Java版本
  final JavaVersion? javaVersion;

  /// 创建版本JSON
  VersionJson({
    required this.id,
    required this.type,
    this.inheritsFrom,
    required this.time,
    required this.releaseTime,
    required this.mainClass,
    this.minecraftArguments,
    this.arguments,
    this.downloads,
    required this.libraries,
    required this.assetIndex,
    this.javaVersion,
  });

  /// 从JSON创建版本JSON
  factory VersionJson.fromJson(Map<String, dynamic> json) {
    return VersionJson(
      id: json['id'] as String,
      type: GameVersion._parseVersionType(json['type'] as String),
      inheritsFrom: json['inheritsFrom'] as String?,
      time: DateTime.parse(json['time'] as String),
      releaseTime: DateTime.parse(json['releaseTime'] as String),
      mainClass: json['mainClass'] as String,
      minecraftArguments: json['minecraftArguments'] as String?,
      arguments: json['arguments'] != null
          ? Arguments.fromJson(json['arguments'] as Map<String, dynamic>)
          : null,
      downloads: json['downloads'] != null
          ? DownloadInfo.fromJson(json['downloads'] as Map<String, dynamic>)
          : null,
      libraries: (json['libraries'] as List<dynamic>)
          .map((l) => Library.fromJson(l as Map<String, dynamic>))
          .toList(),
      assetIndex: AssetIndex.fromJson(
        json['assetIndex'] as Map<String, dynamic>,
      ),
      javaVersion: json['javaVersion'] != null
          ? JavaVersion.fromJson(json['javaVersion'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'inheritsFrom': inheritsFrom,
      'time': time.toIso8601String(),
      'releaseTime': releaseTime.toIso8601String(),
      'mainClass': mainClass,
      'minecraftArguments': minecraftArguments,
      'arguments': arguments?.toJson(),
      'downloads': downloads?.toJson(),
      'libraries': libraries.map((l) => l.toJson()).toList(),
      'assetIndex': assetIndex.toJson(),
      'javaVersion': javaVersion?.toJson(),
    };
  }
}

/// 参数信息
class Arguments {
  /// 游戏参数
  final List<dynamic> game;

  /// JVM参数
  final List<dynamic>? jvm;

  /// 创建参数信息
  Arguments({required this.game, this.jvm});

  /// 从JSON创建
  factory Arguments.fromJson(Map<String, dynamic> json) {
    return Arguments(
      game: json['game'] as List<dynamic>,
      jvm: json['jvm'] as List<dynamic>?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'game': game, 'jvm': jvm};
  }
}

/// 下载信息
class DownloadInfo {
  /// 客户端
  final DownloadItem? client;

  /// 服务端
  final DownloadItem? server;

  /// 客户端映射
  final DownloadItem? clientMappings;

  /// 服务端映射
  final DownloadItem? serverMappings;

  /// 创建下载信息
  DownloadInfo({
    this.client,
    this.server,
    this.clientMappings,
    this.serverMappings,
  });

  /// 从JSON创建
  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    return DownloadInfo(
      client: json['client'] != null
          ? DownloadItem.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      server: json['server'] != null
          ? DownloadItem.fromJson(json['server'] as Map<String, dynamic>)
          : null,
      clientMappings: json['client_mappings'] != null
          ? DownloadItem.fromJson(
              json['client_mappings'] as Map<String, dynamic>,
            )
          : null,
      serverMappings: json['server_mappings'] != null
          ? DownloadItem.fromJson(
              json['server_mappings'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'client': client?.toJson(),
      'server': server?.toJson(),
      'client_mappings': clientMappings?.toJson(),
      'server_mappings': serverMappings?.toJson(),
    };
  }
}

/// 下载项
class DownloadItem {
  /// SHA1哈希
  final String sha1;

  /// 文件大小
  final int size;

  /// 下载URL
  final String url;

  /// 创建下载项
  DownloadItem({required this.sha1, required this.size, required this.url});

  /// 从JSON创建
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      sha1: json['sha1'] as String,
      size: json['size'] as int,
      url: json['url'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'sha1': sha1, 'size': size, 'url': url};
  }
}

/// 库文件
class Library {
  /// 库名称
  final String name;

  /// 下载信息
  final LibraryDownloads? downloads;

  /// 规则（用于平台判断）
  final List<Rule>? rules;

  /// 原生库信息
  final Map<String, String>? natives;

  /// 创建库文件
  Library({required this.name, this.downloads, this.rules, this.natives});

  /// 从JSON创建
  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      name: json['name'] as String,
      downloads: json['downloads'] != null
          ? LibraryDownloads.fromJson(json['downloads'] as Map<String, dynamic>)
          : null,
      rules: json['rules'] != null
          ? (json['rules'] as List<dynamic>)
                .map((r) => Rule.fromJson(r as Map<String, dynamic>))
                .toList()
          : null,
      natives: json['natives'] != null
          ? Map<String, String>.from(json['natives'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'downloads': downloads?.toJson(),
      'rules': rules?.map((r) => r.toJson()).toList(),
      'natives': natives,
    };
  }
}

/// 库下载信息
class LibraryDownloads {
  /// 主构件
  final LibraryArtifact? artifact;

  /// 分类器
  final Map<String, LibraryArtifact>? classifiers;

  /// 创建库下载信息
  LibraryDownloads({this.artifact, this.classifiers});

  /// 从JSON创建
  factory LibraryDownloads.fromJson(Map<String, dynamic> json) {
    return LibraryDownloads(
      artifact: json['artifact'] != null
          ? LibraryArtifact.fromJson(json['artifact'] as Map<String, dynamic>)
          : null,
      classifiers: json['classifiers'] != null
          ? (json['classifiers'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                LibraryArtifact.fromJson(value as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'artifact': artifact?.toJson(),
      'classifiers': classifiers?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

/// 库构件
class LibraryArtifact {
  /// 路径
  final String path;

  /// SHA1哈希
  final String sha1;

  /// 大小
  final int size;

  /// URL
  final String url;

  /// 创建库构件
  LibraryArtifact({
    required this.path,
    required this.sha1,
    required this.size,
    required this.url,
  });

  /// 从JSON创建
  factory LibraryArtifact.fromJson(Map<String, dynamic> json) {
    return LibraryArtifact(
      path: json['path'] as String,
      sha1: json['sha1'] as String,
      size: json['size'] as int,
      url: json['url'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'path': path, 'sha1': sha1, 'size': size, 'url': url};
  }
}

/// 规则
class Rule {
  /// 动作（allow/disallow）
  final String action;

  /// 操作系统信息
  final OsRule? os;

  /// 创建规则
  Rule({required this.action, this.os});

  /// 从JSON创建
  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      action: json['action'] as String,
      os: json['os'] != null
          ? OsRule.fromJson(json['os'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'action': action, 'os': os?.toJson()};
  }
}

/// 操作系统规则
class OsRule {
  /// 操作系统名称
  final String? name;

  /// 架构
  final String? arch;

  /// 版本
  final String? version;

  /// 创建操作系统规则
  OsRule({this.name, this.arch, this.version});

  /// 从JSON创建
  factory OsRule.fromJson(Map<String, dynamic> json) {
    return OsRule(
      name: json['name'] as String?,
      arch: json['arch'] as String?,
      version: json['version'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'arch': arch, 'version': version};
  }
}

/// 资源索引
class AssetIndex {
  /// 资源ID
  final String id;

  /// SHA1哈希
  final String sha1;

  /// 大小
  final int size;

  /// 总大小
  final int totalSize;

  /// URL
  final String url;

  /// 创建资源索引
  AssetIndex({
    required this.id,
    required this.sha1,
    required this.size,
    required this.totalSize,
    required this.url,
  });

  /// 从JSON创建
  factory AssetIndex.fromJson(Map<String, dynamic> json) {
    return AssetIndex(
      id: json['id'] as String,
      sha1: json['sha1'] as String,
      size: json['size'] as int,
      totalSize: json['totalSize'] as int,
      url: json['url'] as String,
    );
  }

  /// 转换为JSON
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

/// Java版本
class JavaVersion {
  /// 组件
  final String component;

  /// 主要版本
  final int majorVersion;

  /// 创建Java版本
  JavaVersion({required this.component, required this.majorVersion});

  /// 从JSON创建
  factory JavaVersion.fromJson(Map<String, dynamic> json) {
    return JavaVersion(
      component: json['component'] as String,
      majorVersion: json['majorVersion'] as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'component': component, 'majorVersion': majorVersion};
  }
}

/// 版本安装进度
class VersionInstallProgress {
  /// 版本ID
  final String versionId;

  /// 当前进度（0.0 - 1.0）
  final double progress;

  /// 当前阶段
  final String stage;

  /// 当前下载的文件（可选）
  final String? currentFile;

  /// 已下载字节数
  final int downloadedBytes;

  /// 总字节数
  final int totalBytes;

  /// 创建版本安装进度
  VersionInstallProgress({
    required this.versionId,
    required this.progress,
    required this.stage,
    this.currentFile,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });
}

/// 资源文件
class Asset {
  /// 哈希值
  final String hash;

  /// 大小
  final int size;

  /// 创建资源文件
  Asset({required this.hash, required this.size});

  /// 从JSON创建
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(hash: json['hash'] as String, size: json['size'] as int);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'hash': hash, 'size': size};
  }
}

/// 资源索引文件
class AssetIndexFile {
  /// 资源映射
  final Map<String, Asset> objects;

  /// 创建资源索引文件
  AssetIndexFile({required this.objects});

  /// 从JSON创建
  factory AssetIndexFile.fromJson(Map<String, dynamic> json) {
    final objectsJson = json['objects'] as Map<String, dynamic>;
    return AssetIndexFile(
      objects: objectsJson.map(
        (key, value) =>
            MapEntry(key, Asset.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'objects': objects.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
