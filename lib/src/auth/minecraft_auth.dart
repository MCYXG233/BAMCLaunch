import 'dart:convert';
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import 'models.dart';

/// Minecraft认证服务
class MinecraftAuthService {
  /// Minecraft登录端点
  static const String _loginWithXboxEndpoint = ApiEndpoints.minecraftAuthLogin;

  /// Minecraft个人资料端点
  static const String _profileEndpoint = ApiEndpoints.minecraftProfile;

  /// Minecraft游戏所有权检查端点
  static const String _entitlementsEndpoint = ApiEndpoints.minecraftEntitlements;

  /// 使用XSTS令牌登录Minecraft
  Future<MinecraftToken> loginWithXbox({
    required String userHash,
    required String xstsToken,
  }) async {
    final networkClient = NetworkClient();
    final response = await networkClient.postJson(
      _loginWithXboxEndpoint,
      {
        'identityToken': 'XBL3.0 x=$userHash;$xstsToken',
      },
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.authMinecraftFailed,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
        originalError: response.body,
      );
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final String accessToken = data['access_token'] as String;
    final int expiresIn = data['expires_in'] as int;

    // 获取个人资料以获取用户名和UUID
    final profile = await getProfile(accessToken);

    return MinecraftToken(
      username: profile.name,
      uuid: profile.id,
      accessToken: accessToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  /// 获取Minecraft个人资料
  Future<MinecraftProfile> getProfile(String accessToken) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      _profileEndpoint,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      throw AppException.fromCode(ErrorCodes.authOwnershipCheckFailed);
    }

    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.authMinecraftFailed,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
        originalError: response.body,
      );
    }

    final Map<String, dynamic> data = json.decode(response.body);
    
    MinecraftSkin? skin;
    MinecraftCape? cape;

    final List<dynamic> skins = data['skins'] as List<dynamic>? ?? [];
    if (skins.isNotEmpty) {
      final Map<String, dynamic> skinData = skins.first as Map<String, dynamic>;
      skin = MinecraftSkin(
        url: skinData['url'] as String,
        variant: (skinData['variant'] as String?) ?? 'classic',
      );
    }

    final List<dynamic> capes = data['capes'] as List<dynamic>? ?? [];
    if (capes.isNotEmpty) {
      final Map<String, dynamic> capeData = capes.first as Map<String, dynamic>;
      cape = MinecraftCape(
        url: capeData['url'] as String,
      );
    }

    return MinecraftProfile(
      id: data['id'] as String,
      name: data['name'] as String,
      skin: skin,
      cape: cape,
    );
  }

  /// 检查账户是否拥有Minecraft游戏
  Future<bool> checkGameOwnership(String accessToken) async {
    final networkClient = NetworkClient();
    final response = await networkClient.get(
      _entitlementsEndpoint,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.authOwnershipCheckFailed,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
        originalError: response.body,
      );
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];

    // 检查是否有游戏所有权
    return items.any((item) {
      final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
      final String name = itemMap['name'] as String? ?? '';
      return name == 'product_minecraft' || name == 'game_minecraft';
    });
  }
}
