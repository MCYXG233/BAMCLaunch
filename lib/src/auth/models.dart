/// 登录状态枚举
enum LoginState {
  initial,
  gettingDeviceCode,
  waitingForUser,
  polling,
  authenticating,
  error,
}

/// OAuth2令牌模型
class OAuthToken {
  /// 访问令牌
  final String accessToken;

  /// 令牌类型
  final String tokenType;

  /// 过期时间（秒）
  final int expiresIn;

  /// 刷新令牌
  final String? refreshToken;

  /// 授权范围
  final String? scope;

  /// 获取时间
  final DateTime acquiredAt;

  OAuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.scope,
    DateTime? acquiredAt,
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  /// 检查令牌是否已过期
  bool get isExpired {
    final expiresAt = acquiredAt.add(Duration(seconds: expiresIn));
    return DateTime.now().isAfter(expiresAt);
  }

  /// 检查令牌是否即将过期（剩余时间小于5分钟）
  bool get isNearExpiry {
    final expiresAt = acquiredAt.add(Duration(seconds: expiresIn));
    final fiveMinutesBefore = expiresAt.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(fiveMinutesBefore);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'refreshToken': refreshToken,
      'scope': scope,
      'acquiredAt': acquiredAt.toIso8601String(),
    };
  }

  factory OAuthToken.fromJson(Map<String, dynamic> json) {
    return OAuthToken(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      refreshToken: json['refreshToken'] as String?,
      scope: json['scope'] as String?,
      acquiredAt: DateTime.parse(json['acquiredAt'] as String),
    );
  }
}

/// Xbox Live令牌模型
class XboxLiveToken {
  /// 用户哈希
  final String userHash;

  /// Xbox Live令牌
  final String token;

  /// 过期时间
  final DateTime expiresAt;

  XboxLiveToken({
    required this.userHash,
    required this.token,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'userHash': userHash,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory XboxLiveToken.fromJson(Map<String, dynamic> json) {
    return XboxLiveToken(
      userHash: json['userHash'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// XSTS令牌模型
class XstsToken {
  /// 用户哈希
  final String userHash;

  /// XSTS令牌
  final String token;

  /// 过期时间
  final DateTime expiresAt;

  XstsToken({
    required this.userHash,
    required this.token,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'userHash': userHash,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory XstsToken.fromJson(Map<String, dynamic> json) {
    return XstsToken(
      userHash: json['userHash'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Minecraft会话令牌模型
class MinecraftToken {
  /// 用户名
  final String username;

  /// Minecraft UUID
  final String uuid;

  /// Minecraft访问令牌
  final String accessToken;

  /// 过期时间
  final DateTime expiresAt;

  MinecraftToken({
    required this.username,
    required this.uuid,
    required this.accessToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uuid': uuid,
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory MinecraftToken.fromJson(Map<String, dynamic> json) {
    return MinecraftToken(
      username: json['username'] as String,
      uuid: json['uuid'] as String,
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Minecraft个人资料模型
class MinecraftProfile {
  /// UUID
  final String id;

  /// 用户名
  final String name;

  /// 皮肤信息
  final MinecraftSkin? skin;

  /// 披风信息
  final MinecraftCape? cape;

  MinecraftProfile({
    required this.id,
    required this.name,
    this.skin,
    this.cape,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'skin': skin?.toJson(),
      'cape': cape?.toJson(),
    };
  }

  factory MinecraftProfile.fromJson(Map<String, dynamic> json) {
    return MinecraftProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      skin: json['skin'] != null
          ? MinecraftSkin.fromJson(json['skin'] as Map<String, dynamic>)
          : null,
      cape: json['cape'] != null
          ? MinecraftCape.fromJson(json['cape'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Minecraft皮肤模型
class MinecraftSkin {
  /// 皮肤URL
  final String url;

  /// 皮肤变体（slim或classic）
  final String variant;

  MinecraftSkin({
    required this.url,
    this.variant = 'classic',
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'variant': variant,
    };
  }

  factory MinecraftSkin.fromJson(Map<String, dynamic> json) {
    return MinecraftSkin(
      url: json['url'] as String,
      variant: json['variant'] as String? ?? 'classic',
    );
  }
}

/// Minecraft披风模型
class MinecraftCape {
  /// 披风URL
  final String url;

  MinecraftCape({
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }

  factory MinecraftCape.fromJson(Map<String, dynamic> json) {
    return MinecraftCape(
      url: json['url'] as String,
    );
  }
}

/// 完整的认证凭据模型
class AuthCredentials {
  /// Microsoft OAuth令牌
  final OAuthToken? microsoftToken;

  /// Xbox Live令牌
  final XboxLiveToken? xboxLiveToken;

  /// XSTS令牌
  final XstsToken? xstsToken;

  /// Minecraft令牌
  final MinecraftToken? minecraftToken;

  /// Minecraft个人资料
  final MinecraftProfile? minecraftProfile;

  AuthCredentials({
    this.microsoftToken,
    this.xboxLiveToken,
    this.xstsToken,
    this.minecraftToken,
    this.minecraftProfile,
  });

  bool get isValid {
    return minecraftToken != null && !minecraftToken!.isExpired;
  }

  AuthCredentials copyWith({
    OAuthToken? microsoftToken,
    XboxLiveToken? xboxLiveToken,
    XstsToken? xstsToken,
    MinecraftToken? minecraftToken,
    MinecraftProfile? minecraftProfile,
  }) {
    return AuthCredentials(
      microsoftToken: microsoftToken ?? this.microsoftToken,
      xboxLiveToken: xboxLiveToken ?? this.xboxLiveToken,
      xstsToken: xstsToken ?? this.xstsToken,
      minecraftToken: minecraftToken ?? this.minecraftToken,
      minecraftProfile: minecraftProfile ?? this.minecraftProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'microsoftToken': microsoftToken?.toJson(),
      'xboxLiveToken': xboxLiveToken?.toJson(),
      'xstsToken': xstsToken?.toJson(),
      'minecraftToken': minecraftToken?.toJson(),
      'minecraftProfile': minecraftProfile?.toJson(),
    };
  }

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      microsoftToken: json['microsoftToken'] != null
          ? OAuthToken.fromJson(json['microsoftToken'] as Map<String, dynamic>)
          : null,
      xboxLiveToken: json['xboxLiveToken'] != null
          ? XboxLiveToken.fromJson(json['xboxLiveToken'] as Map<String, dynamic>)
          : null,
      xstsToken: json['xstsToken'] != null
          ? XstsToken.fromJson(json['xstsToken'] as Map<String, dynamic>)
          : null,
      minecraftToken: json['minecraftToken'] != null
          ? MinecraftToken.fromJson(json['minecraftToken'] as Map<String, dynamic>)
          : null,
      minecraftProfile: json['minecraftProfile'] != null
          ? MinecraftProfile.fromJson(json['minecraftProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}
