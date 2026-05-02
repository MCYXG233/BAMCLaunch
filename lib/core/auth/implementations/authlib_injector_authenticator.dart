import 'dart:convert';
import '../interfaces/i_authenticator.dart';
import '../models/account.dart';
import '../../http/i_http_client.dart';
import '../../http/implementations/http_client.dart';

/// Authlib Injector 认证器
///
/// 支持第三方认证服务器（如 LittleSkin、Blessing Skin 等）
/// 使用 Yggdrasil 协议进行认证
class AuthlibInjectorAuthenticator implements IAuthenticator {
  final IHttpClient _httpClient;

  AuthlibInjectorAuthenticator({IHttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  @override
  AccountType get accountType => AccountType.authlibInjector;

  @override
  Future<Account> login(Map<String, dynamic> credentials) async {
    final serverUrl = credentials['serverUrl'] as String;
    final username = credentials['username'] as String;
    final password = credentials['password'] as String;

    // 1. 验证服务器元数据
    await _getServerMetadata(serverUrl);

    // 2. 使用 Yggdrasil 协议认证
    final authResponse = await _authenticate(
      serverUrl,
      username,
      password,
      clientToken: _generateClientToken(),
    );

    // 3. 获取 Profile
    final profile = await _getProfile(
      serverUrl,
      authResponse['accessToken'] as String,
    );

    return Account(
      id: 'authlib_${serverUrl.hashCode}_${profile.id}',
      username: profile.name,
      type: AccountType.authlibInjector,
      tokenData: TokenData(
        accessToken: authResponse['accessToken'] as String,
        refreshToken:
            authResponse['accessToken'] as String, // Yggdrasil 使用相同的 token
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
      profile: profile,
      serverUrl: serverUrl,
    );
  }

  @override
  Future<Account> refresh(Account account) async {
    if (account.serverUrl == null) {
      throw Exception('服务器 URL 不存在');
    }

    if (account.tokenData == null) {
      throw Exception('Token 数据不存在');
    }

    try {
      // 使用 Yggdrasil 协议刷新 Token
      final refreshResponse = await _refresh(
        account.serverUrl!,
        account.tokenData!.accessToken,
        _generateClientToken(),
      );

      return account.copyWith(
        tokenData: TokenData(
          accessToken: refreshResponse['accessToken'] as String,
          refreshToken: refreshResponse['accessToken'] as String,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      );
    } catch (e) {
      // 刷新失败，尝试重新登录
      throw Exception('Token 刷新失败: $e');
    }
  }

  @override
  Future<MinecraftProfile> getProfile(Account account) async {
    if (account.serverUrl == null) {
      throw Exception('服务器 URL 不存在');
    }

    if (account.tokenData == null) {
      throw Exception('Token 数据不存在');
    }

    return await _getProfile(
      account.serverUrl!,
      account.tokenData!.accessToken,
    );
  }

  @override
  Future<void> logout(Account account) async {
    if (account.serverUrl == null || account.tokenData == null) {
      return;
    }

    try {
      await _invalidate(
        account.serverUrl!,
        account.tokenData!.accessToken,
      );
    } catch (e) {
      // 忽略登出错误
    }
  }

  @override
  bool canRefresh(Account account) {
    return account.serverUrl != null && account.tokenData != null;
  }

  /// 获取服务器元数据
  Future<Map<String, dynamic>> _getServerMetadata(String serverUrl) async {
    final response = await _httpClient.get(serverUrl);
    if (response.statusCode != 200) {
      throw Exception('无法连接到认证服务器: $serverUrl');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 使用 Yggdrasil 协议认证
  Future<Map<String, dynamic>> _authenticate(
    String serverUrl,
    String username,
    String password, {
    required String clientToken,
  }) async {
    final authUrl = '$serverUrl/authserver/authenticate';
    final response = await _httpClient.post(
      authUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'agent': {
          'name': 'Minecraft',
          'version': 1,
        },
        'username': username,
        'password': password,
        'clientToken': clientToken,
        'requestUser': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['errorMessage'] ?? '认证失败');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 刷新 Token
  Future<Map<String, dynamic>> _refresh(
    String serverUrl,
    String accessToken,
    String clientToken,
  ) async {
    final refreshUrl = '$serverUrl/authserver/refresh';
    final response = await _httpClient.post(
      refreshUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessToken': accessToken,
        'clientToken': clientToken,
        'requestUser': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['errorMessage'] ?? '刷新失败');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 获取 Profile
  Future<MinecraftProfile> _getProfile(
    String serverUrl,
    String accessToken,
  ) async {
    final profileUrl = '$serverUrl/authserver/validate';
    final response = await _httpClient.post(
      profileUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Token 无效');
    }

    // 从 Token 中解析 Profile 信息
    // 实际实现需要解析 JWT 或调用 Profile API
    // 这里简化处理
    return MinecraftProfile(
      id: 'authlib_user',
      name: 'Authlib User',
    );
  }

  /// 使 Token 失效
  Future<void> _invalidate(String serverUrl, String accessToken) async {
    final invalidateUrl = '$serverUrl/authserver/invalidate';
    await _httpClient.post(
      invalidateUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessToken': accessToken,
      }),
    );
  }

  /// 生成客户端 Token
  String _generateClientToken() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toRadixString(16);
  }
}
