enum ServerType {
  vanilla,
  forge,
  fabric,
  quilt,
  neoforge,
  custom,
}

enum ServerStatus {
  offline,
  online,
  unknown,
}

class ServerInfo {
  final String name;
  final String address;
  final int port;
  final ServerType type;
  final String? description;
  final String? icon;
  final String? version;
  final int? maxPlayers;
  final int? onlinePlayers;
  final ServerStatus status;
  final DateTime? lastPingTime;
  final bool favorite;
  final bool autoConnect;
  final DateTime createdAt;
  final DateTime? lastConnected;
  final String? notes;
  final Map<String, dynamic>? customData;

  ServerInfo({
    required this.name,
    required this.address,
    required this.port,
    required this.type,
    this.description,
    this.icon,
    this.version,
    this.maxPlayers,
    this.onlinePlayers,
    this.status = ServerStatus.unknown,
    this.lastPingTime,
    this.favorite = false,
    this.autoConnect = false,
    DateTime? createdAt,
    this.lastConnected,
    this.notes,
    this.customData,
  }) : createdAt = createdAt ?? DateTime.now();

  ServerInfo copyWith({
    String? name,
    String? address,
    int? port,
    ServerType? type,
    String? description,
    String? icon,
    String? version,
    int? maxPlayers,
    int? onlinePlayers,
    ServerStatus? status,
    DateTime? lastPingTime,
    bool? favorite,
    bool? autoConnect,
    DateTime? createdAt,
    DateTime? lastConnected,
    String? notes,
    Map<String, dynamic>? customData,
  }) {
    return ServerInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      type: type ?? this.type,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      version: version ?? this.version,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      onlinePlayers: onlinePlayers ?? this.onlinePlayers,
      status: status ?? this.status,
      lastPingTime: lastPingTime ?? this.lastPingTime,
      favorite: favorite ?? this.favorite,
      autoConnect: autoConnect ?? this.autoConnect,
      createdAt: createdAt ?? this.createdAt,
      lastConnected: lastConnected ?? this.lastConnected,
      notes: notes ?? this.notes,
      customData: customData ?? this.customData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'port': port,
      'type': type.index,
      'description': description,
      'icon': icon,
      'version': version,
      'maxPlayers': maxPlayers,
      'onlinePlayers': onlinePlayers,
      'status': status.index,
      'lastPingTime': lastPingTime?.toIso8601String(),
      'favorite': favorite,
      'autoConnect': autoConnect,
      'createdAt': createdAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
      'notes': notes,
      'customData': customData,
    };
  }

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      name: json['name'],
      address: json['address'],
      port: json['port'],
      type: ServerType.values[json['type']],
      description: json['description'],
      icon: json['icon'],
      version: json['version'],
      maxPlayers: json['maxPlayers'],
      onlinePlayers: json['onlinePlayers'],
      status: ServerStatus.values[json['status']],
      lastPingTime: json['lastPingTime'] != null
          ? DateTime.parse(json['lastPingTime'])
          : null,
      favorite: json['favorite'] ?? false,
      autoConnect: json['autoConnect'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'])
          : null,
      notes: json['notes'],
      customData: json['customData'],
    );
  }
}

class LanServerInfo {
  final String name;
  final String address;
  final int port;
  final String? description;
  final DateTime discoveredAt;
  final DateTime? lastSeen;

  LanServerInfo({
    required this.name,
    required this.address,
    required this.port,
    this.description,
    DateTime? discoveredAt,
    this.lastSeen,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'port': port,
      'description': description,
      'discoveredAt': discoveredAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory LanServerInfo.fromJson(Map<String, dynamic> json) {
    return LanServerInfo(
      name: json['name'],
      address: json['address'],
      port: json['port'],
      description: json['description'],
      discoveredAt: DateTime.parse(json['discoveredAt']),
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }
}

class ServerResponse {
  final String versionName;
  final String versionProtocol;
  final int onlinePlayers;
  final int maxPlayers;
  final String description;
  final String? favicon;
  final bool secureChat;

  ServerResponse({
    required this.versionName,
    required this.versionProtocol,
    required this.onlinePlayers,
    required this.maxPlayers,
    required this.description,
    this.favicon,
    required this.secureChat,
  });

  Map<String, dynamic> toJson() {
    return {
      'versionName': versionName,
      'versionProtocol': versionProtocol,
      'onlinePlayers': onlinePlayers,
      'maxPlayers': maxPlayers,
      'description': description,
      'favicon': favicon,
      'secureChat': secureChat,
    };
  }

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      versionName: json['version']['name'],
      versionProtocol: json['version']['protocol'].toString(),
      onlinePlayers: json['players']['online'],
      maxPlayers: json['players']['max'],
      description: json['description']['text'],
      favicon: json['favicon'],
      secureChat: json['enforcesSecureChat'] ?? false,
    );
  }
}

class PortMappingResult {
  final bool success;
  final String? externalAddress;
  final int? externalPort;
  final String? errorMessage;

  PortMappingResult({
    required this.success,
    this.externalAddress,
    this.externalPort,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'externalAddress': externalAddress,
      'externalPort': externalPort,
      'errorMessage': errorMessage,
    };
  }

  factory PortMappingResult.fromJson(Map<String, dynamic> json) {
    return PortMappingResult(
      success: json['success'],
      externalAddress: json['externalAddress'],
      externalPort: json['externalPort'],
      errorMessage: json['errorMessage'],
    );
  }
}
