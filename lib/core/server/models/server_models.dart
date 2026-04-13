class Server {
  final String id;
  final String name;
  final String address;
  final int port;
  final String? description;
  final String? version;
  final String? modpackId;
  final bool isLocal;
  final String? localPath;
  final String? javaPath;
  final int? memoryMb;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Server({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    this.description,
    this.version,
    this.modpackId,
    required this.isLocal,
    this.localPath,
    this.javaPath,
    this.memoryMb,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Server copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    String? description,
    String? version,
    String? modpackId,
    bool? isLocal,
    String? localPath,
    String? javaPath,
    int? memoryMb,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      description: description ?? this.description,
      version: version ?? this.version,
      modpackId: modpackId ?? this.modpackId,
      isLocal: isLocal ?? this.isLocal,
      localPath: localPath ?? this.localPath,
      javaPath: javaPath ?? this.javaPath,
      memoryMb: memoryMb ?? this.memoryMb,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ServerConnectionResult {
  final bool success;
  final String serverId;
  final String? error;
  final int? ping;
  final String? motd;
  final int? onlinePlayers;
  final int? maxPlayers;

  ServerConnectionResult({
    required this.success,
    required this.serverId,
    this.error,
    this.ping,
    this.motd,
    this.onlinePlayers,
    this.maxPlayers,
  });
}

class ServerPingResult {
  final bool success;
  final String serverId;
  final int? ping;
  final String? motd;
  final String? version;
  final int? onlinePlayers;
  final int? maxPlayers;
  final String? error;

  ServerPingResult({
    required this.success,
    required this.serverId,
    this.ping,
    this.motd,
    this.version,
    this.onlinePlayers,
    this.maxPlayers,
    this.error,
  });
}

class ServerSyncResult {
  final bool success;
  final String serverId;
  final List<String> syncedMods;
  final List<String> failedMods;
  final String? error;

  ServerSyncResult({
    required this.success,
    required this.serverId,
    required this.syncedMods,
    required this.failedMods,
    this.error,
  });
}

class ServerStatus {
  final String serverId;
  final ServerState state;
  final int? ping;
  final String? motd;
  final int? onlinePlayers;
  final int? maxPlayers;
  final String? version;
  final DateTime lastUpdated;

  ServerStatus({
    required this.serverId,
    required this.state,
    this.ping,
    this.motd,
    this.onlinePlayers,
    this.maxPlayers,
    this.version,
    required this.lastUpdated,
  });
}

enum ServerState {
  offline,
  online,
  connecting,
  disconnecting,
  starting,
  stopping,
  error,
}
