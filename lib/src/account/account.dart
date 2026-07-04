import 'dart:math';
import 'skin_manager.dart';

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

  /// 访问令牌
  final String? accessToken;

  /// 账户创建时间
  final DateTime createdAt;

  /// 账户最后使用时间
  final DateTime lastUsedAt;

  /// 皮肤类型（Steve或Alex）
  final SkinType modelType;

  /// 本地皮肤文件路径
  final String? localSkinPath;

  /// 本地披风文件路径
  final String? localCapePath;

  /// 使用 UUID v4 生成唯一的账户标识符
  static String generateId() {
    final random = Random();
    String hexChars(int count) => List.generate(
          count,
          (_) => '0123456789abcdef'[random.nextInt(16)],
        ).join();
    return '${hexChars(8)}-${hexChars(4)}-4${hexChars(3)}-'
        '${'89ab'[random.nextInt(4)]}${hexChars(3)}-${hexChars(12)}';
  }

  /// 创建账户实例
  Account({
    required this.id,
    required this.username,
    this.uuid,
    required this.type,
    this.skinUrl,
    this.capeUrl,
    this.accessToken,
    required this.createdAt,
    required this.lastUsedAt,
    this.modelType = SkinType.steve,
    this.localSkinPath,
    this.localCapePath,
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
      'accessToken': accessToken,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'modelType': modelType.name,
      'localSkinPath': localSkinPath,
      'localCapePath': localCapePath,
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
      accessToken: json['accessToken'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      modelType: json['modelType'] != null
          ? SkinType.values.firstWhere(
              (e) => e.name == json['modelType'],
              orElse: () => SkinType.steve,
            )
          : SkinType.steve,
      localSkinPath: json['localSkinPath'] as String?,
      localCapePath: json['localCapePath'] as String?,
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

  /// 是否是Microsoft账户
  bool get isMicrosoft => type == AccountType.microsoft;

  /// 是否是离线账户
  bool get isOffline => type == AccountType.offline;

  /// 创建副本并更新部分字段
  Account copyWith({
    String? id,
    String? username,
    String? uuid,
    AccountType? type,
    String? skinUrl,
    String? capeUrl,
    String? accessToken,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    SkinType? modelType,
    String? localSkinPath,
    String? localCapePath,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      skinUrl: skinUrl ?? this.skinUrl,
      capeUrl: capeUrl ?? this.capeUrl,
      accessToken: accessToken ?? this.accessToken,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      modelType: modelType ?? this.modelType,
      localSkinPath: localSkinPath ?? this.localSkinPath,
      localCapePath: localCapePath ?? this.localCapePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
