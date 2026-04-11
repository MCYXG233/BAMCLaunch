enum AccountType {
  offline,
  microsoft,
}

class Account {
  final String id;
  final String username;
  final AccountType type;
  final TokenData? tokenData;
  final MinecraftProfile? profile;
  final DateTime createdAt;
  final DateTime? lastLogin;
  bool isSelected;

  Account({
    required this.id,
    required this.username,
    required this.type,
    this.tokenData,
    this.profile,
    DateTime? createdAt,
    this.lastLogin,
    this.isSelected = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'type': type.index,
      'tokenData': tokenData?.toJson(),
      'profile': profile?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isSelected': isSelected,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      username: json['username'],
      type: AccountType.values[json['type']],
      tokenData: json['tokenData'] != null
          ? TokenData.fromJson(json['tokenData'])
          : null,
      profile: json['profile'] != null
          ? MinecraftProfile.fromJson(json['profile'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      isSelected: json['isSelected'] ?? false,
    );
  }

  Account copyWith({
    String? id,
    String? username,
    AccountType? type,
    TokenData? tokenData,
    MinecraftProfile? profile,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isSelected,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      type: type ?? this.type,
      tokenData: tokenData ?? this.tokenData,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class TokenData {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  TokenData({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }
}

class MinecraftProfile {
  final String id;
  final String name;
  final String? skinUrl;
  final String? capeUrl;
  final Map<String, String>? textures;

  MinecraftProfile({
    required this.id,
    required this.name,
    this.skinUrl,
    this.capeUrl,
    this.textures,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'skinUrl': skinUrl,
      'capeUrl': capeUrl,
      'textures': textures,
    };
  }

  factory MinecraftProfile.fromJson(Map<String, dynamic> json) {
    return MinecraftProfile(
      id: json['id'],
      name: json['name'],
      skinUrl: json['skinUrl'],
      capeUrl: json['capeUrl'],
      textures: json['textures'] != null
          ? Map<String, String>.from(json['textures'])
          : null,
    );
  }
}
