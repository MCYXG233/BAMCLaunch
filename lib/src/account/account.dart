/// 账户类型枚举
enum AccountType {
  /// 离线账户
  offline,

  /// Microsoft账户
  microsoft,

  /// Authlib Injector账户
  authlib,
}

/// 账户数据模型
class Account {
  /// 账户唯一标识符
  final String id;

  /// 用户名
  final String username;

  /// 正版账户UUID，离线账户可为空
  final String? uuid;

  /// 账户类型
  final AccountType type;

  /// 皮肤URL，可为空
  final String? skinUrl;

  /// 披风URL，可为空
  final String? capeUrl;

  /// 账户创建时间
  final DateTime createdAt;

  /// 账户最后使用时间
  final DateTime lastUsedAt;

  /// 创建账户实例
  Account({
    required this.id,
    required this.username,
    this.uuid,
    required this.type,
    this.skinUrl,
    this.capeUrl,
    required this.createdAt,
    required this.lastUsedAt,
  });

  /// 将账户对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'uuid': uuid,
      'type': type.name,
      'skinUrl': skinUrl,
      'capeUrl': capeUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  /// 从JSON创建账户对象
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      username: json['username'] as String,
      uuid: json['uuid'] as String?,
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.offline,
      ),
      skinUrl: json['skinUrl'] as String?,
      capeUrl: json['capeUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }

  /// 获取Minecraft头像URL
  String get avatarUrl {
    // 使用Crafatar头像服务
    final baseUrl = 'https://crafatar.com/avatars';
    if (uuid != null) {
      return '$baseUrl/$uuid?size=64&default=MHF_Steve';
    }
    // 离线账户使用用户名的哈希值生成头像
    return '$baseUrl/$username?size=64&default=MHF_Steve';
  }

  /// 创建副本并更新部分字段
  Account copyWith({
    String? id,
    String? username,
    String? uuid,
    AccountType? type,
    String? skinUrl,
    String? capeUrl,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      skinUrl: skinUrl ?? this.skinUrl,
      capeUrl: capeUrl ?? this.capeUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
