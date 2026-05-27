import 'dart:io';

/// 实例状态
enum InstanceStatus {
  idle,
  launching,
  running,
  crashed,
}

/// 资源类型
enum ResourceType {
  mod,
  resourcePack,
  shaderPack,
  world,
  screenshot,
}

/// 游戏目录
class GameDirectory {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameDirectory({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
  });

  GameDirectory copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameDirectory(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GameDirectory.fromJson(Map<String, dynamic> json) {
    return GameDirectory(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// 游戏实例
class GameInstance {
  final String id;
  final String name;
  final String directoryId;
  final String version;
  final String? loader;
  final String? loaderVersion;
  final String? icon;
  final String? description;
  final InstanceStatus status;
  final InstanceConfig config;
  final InstanceResources resources;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPlayed;
  final int? playTimeSeconds;

  GameInstance({
    required this.id,
    required this.name,
    required this.directoryId,
    required this.version,
    this.loader,
    this.loaderVersion,
    this.icon,
    this.description,
    this.status = InstanceStatus.idle,
    required this.config,
    required this.resources,
    required this.createdAt,
    required this.updatedAt,
    this.lastPlayed,
    this.playTimeSeconds = 0,
  });

  GameInstance copyWith({
    String? id,
    String? name,
    String? directoryId,
    String? version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceStatus? status,
    InstanceConfig? config,
    InstanceResources? resources,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPlayed,
    int? playTimeSeconds,
  }) {
    return GameInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      directoryId: directoryId ?? this.directoryId,
      version: version ?? this.version,
      loader: loader ?? this.loader,
      loaderVersion: loaderVersion ?? this.loaderVersion,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      status: status ?? this.status,
      config: config ?? this.config,
      resources: resources ?? this.resources,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'directoryId': directoryId,
      'version': version,
      'loader': loader,
      'loaderVersion': loaderVersion,
      'icon': icon,
      'description': description,
      'status': status.name,
      'config': config.toJson(),
      'resources': resources.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'playTimeSeconds': playTimeSeconds,
    };
  }

  factory GameInstance.fromJson(Map<String, dynamic> json) {
    return GameInstance(
      id: json['id'] as String,
      name: json['name'] as String,
      directoryId: json['directoryId'] as String,
      version: json['version'] as String,
      loader: json['loader'] as String?,
      loaderVersion: json['loaderVersion'] as String?,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      status: InstanceStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => InstanceStatus.idle,
      ),
      config: InstanceConfig.fromJson(json['config'] as Map<String, dynamic>),
      resources: InstanceResources.fromJson(json['resources'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'] as String)
          : null,
      playTimeSeconds: json['playTimeSeconds'] as int?,
    );
  }
}

/// 实例配置
class InstanceConfig {
  final String? javaPath;
  final int? maxMemory;
  final int? minMemory;
  final List<String>? jvmArgs;
  final List<String>? gameArgs;
  final String? windowWidth;
  final String? windowHeight;
  final bool? fullscreen;
  final bool? demo;
  final Map<String, String>? customProperties;
  final String? modLoader;
  final String? modLoaderVersion;

  InstanceConfig({
    this.javaPath,
    this.maxMemory,
    this.minMemory,
    this.jvmArgs,
    this.gameArgs,
    this.windowWidth,
    this.windowHeight,
    this.fullscreen,
    this.demo,
    this.customProperties,
    this.modLoader,
    this.modLoaderVersion,
  });

  InstanceConfig copyWith({
    String? javaPath,
    int? maxMemory,
    int? minMemory,
    List<String>? jvmArgs,
    List<String>? gameArgs,
    String? windowWidth,
    String? windowHeight,
    bool? fullscreen,
    bool? demo,
    Map<String, String>? customProperties,
    String? modLoader,
    String? modLoaderVersion,
  }) {
    return InstanceConfig(
      javaPath: javaPath ?? this.javaPath,
      maxMemory: maxMemory ?? this.maxMemory,
      minMemory: minMemory ?? this.minMemory,
      jvmArgs: jvmArgs ?? this.jvmArgs,
      gameArgs: gameArgs ?? this.gameArgs,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      fullscreen: fullscreen ?? this.fullscreen,
      demo: demo ?? this.demo,
      customProperties: customProperties ?? this.customProperties,
      modLoader: modLoader ?? this.modLoader,
      modLoaderVersion: modLoaderVersion ?? this.modLoaderVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'javaPath': javaPath,
      'maxMemory': maxMemory,
      'minMemory': minMemory,
      'jvmArgs': jvmArgs,
      'gameArgs': gameArgs,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'fullscreen': fullscreen,
      'demo': demo,
      'customProperties': customProperties,
      'modLoader': modLoader,
      'modLoaderVersion': modLoaderVersion,
    };
  }

  factory InstanceConfig.fromJson(Map<String, dynamic> json) {
    return InstanceConfig(
      javaPath: json['javaPath'] as String?,
      maxMemory: json['maxMemory'] as int?,
      minMemory: json['minMemory'] as int?,
      jvmArgs: (json['jvmArgs'] as List<dynamic>?)
          ?.map((e) => e as String)
          ?.toList(),
      gameArgs: (json['gameArgs'] as List<dynamic>?)
          ?.map((e) => e as String)
          ?.toList(),
      windowWidth: json['windowWidth'] as String?,
      windowHeight: json['windowHeight'] as String?,
      fullscreen: json['fullscreen'] as bool?,
      demo: json['demo'] as bool?,
      customProperties: (json['customProperties'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      modLoader: json['modLoader'] as String?,
      modLoaderVersion: json['modLoaderVersion'] as String?,
    );
  }
}

/// 实例资源
class InstanceResources {
  final List<String> mods;
  final List<String> resourcePacks;
  final List<String> shaderPacks;
  final List<String> worlds;
  final List<String> screenshots;

  InstanceResources({
    required this.mods,
    required this.resourcePacks,
    required this.shaderPacks,
    required this.worlds,
    required this.screenshots,
  });

  InstanceResources copyWith({
    List<String>? mods,
    List<String>? resourcePacks,
    List<String>? shaderPacks,
    List<String>? worlds,
    List<String>? screenshots,
  }) {
    return InstanceResources(
      mods: mods ?? this.mods,
      resourcePacks: resourcePacks ?? this.resourcePacks,
      shaderPacks: shaderPacks ?? this.shaderPacks,
      worlds: worlds ?? this.worlds,
      screenshots: screenshots ?? this.screenshots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mods': mods,
      'resourcePacks': resourcePacks,
      'shaderPacks': shaderPacks,
      'worlds': worlds,
      'screenshots': screenshots,
    };
  }

  factory InstanceResources.fromJson(Map<String, dynamic> json) {
    return InstanceResources(
      mods: (json['mods'] as List<dynamic>?)
              ?.map((e) => e as String)
              ?.toList() ??
          [],
      resourcePacks: (json['resourcePacks'] as List<dynamic>?)
              ?.map((e) => e as String)
              ?.toList() ??
          [],
      shaderPacks: (json['shaderPacks'] as List<dynamic>?)
              ?.map((e) => e as String)
              ?.toList() ??
          [],
      worlds: (json['worlds'] as List<dynamic>?)
              ?.map((e) => e as String)
              ?.toList() ??
          [],
      screenshots: (json['screenshots'] as List<dynamic>?)
              ?.map((e) => e as String)
              ?.toList() ??
          [],
    );
  }
}

/// 资源项
class ResourceItem {
  final String id;
  final String name;
  final ResourceType type;
  final String path;
  final String? source;
  final String? version;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final List<String>? linkedInstances;

  ResourceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    this.source,
    this.version,
    required this.createdAt,
    this.lastUsed,
    this.linkedInstances,
  });

  ResourceItem copyWith({
    String? id,
    String? name,
    ResourceType? type,
    String? path,
    String? source,
    String? version,
    DateTime? createdAt,
    DateTime? lastUsed,
    List<String>? linkedInstances,
  }) {
    return ResourceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      path: path ?? this.path,
      source: source ?? this.source,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      linkedInstances: linkedInstances ?? this.linkedInstances,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'path': path,
      'source': source,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'linkedInstances': linkedInstances,
    };
  }

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ResourceType.mod,
      ),
      path: json['path'] as String,
      source: json['source'] as String?,
      version: json['version'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      linkedInstances: (json['linkedInstances'] as List<dynamic>?)
          ?.map((e) => e as String)
          ?.toList(),
    );
  }
}

