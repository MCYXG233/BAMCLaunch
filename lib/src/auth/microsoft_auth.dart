import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/network_client.dart';
import 'models.dart';

/// Microsoft OAuth2认证服务
class MicrosoftAuthService {
  /// 客户端 ID
  static const String _clientId = '0b1a81c9-6e23-41fd-8690-98a17d81bf4a';

  /// 重定向URI
  static const String _redirectUri = 'https://login.live.com/oauth20_desktop.srf';

  /// 授权范围
  static const String _scope = 'XboxLive.signin offline_access';

  /// 授权端点 (正确的端点)
  static const String _authorizationEndpoint = 'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize';

  /// 令牌端点 (正确的端点)
  static const String _tokenEndpoint = 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';

  /// 设备码流端点
  static const String _deviceCodeEndpoint = 'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode';

  /// 生成随机代码验证器
  String _generateCodeVerifier() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final Random random = Random.secure();
    return List.generate(128, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成代码挑战
  String _generateCodeChallenge(String codeVerifier) {
    final List<int> bytes = utf8.encode(codeVerifier);
    final Digest digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// 生成随机状态
  String _generateState() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成授权URL
  Map<String, String> generateAuthorizationUrl() {
    final String codeVerifier = _generateCodeVerifier();
    final String codeChallenge = _generateCodeChallenge(codeVerifier);
    final String state = _generateState();

    final Uri url = Uri.parse(_authorizationEndpoint).replace(
      queryParameters: {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'scope': _scope,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    return {
      'url': url.toString(),
      'codeVerifier': codeVerifier,
      'state': state,
    };
  }

  /// 使用授权代码获取令牌
  Future<OAuthToken> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    final networkClient = NetworkClient();
    final response = await networkClient.post(
      _tokenEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code for token: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    return OAuthToken(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String,
      expiresIn: data['expires_in'] as int,
      refreshToken: data['refresh_token'] as String?,
      scope: data['scope'] as String?,
    );
  }

  /// 刷新令牌
  Future<OAuthToken> refreshToken(String refreshToken) async {
    final networkClient = NetworkClient();
    final response = await networkClient.post(
      _tokenEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    return OAuthToken(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String,
      expiresIn: data['expires_in'] as int,
      refreshToken: data['refresh_token'] as String?,
      scope: data['scope'] as String?,
    );
  }

  /// 从重定向URI中提取授权代码
  String? extractAuthorizationCode(String redirectUrl) {
    final uri = Uri.parse(redirectUrl);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      throw Exception('Authorization error: $error');
    }

    return code;
  }

  /// 验证状态是否匹配
  bool verifyState(String redirectUrl, String expectedState) {
    final uri = Uri.parse(redirectUrl);
    final state = uri.queryParameters['state'];
    return state == expectedState;
  }

  /// 设备代码流 - 获取设备代码
  Future<DeviceCodeResponse> getDeviceCode() async {
    final networkClient = NetworkClient();
    final response = await networkClient.post(
      _deviceCodeEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'scope': _scope,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get device code: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    return DeviceCodeResponse(
      deviceCode: data['device_code'] as String,
      userCode: data['user_code'] as String,
      verificationUri: data['verification_uri'] as String,
      expiresIn: data['expires_in'] as int,
      interval: data['interval'] as int,
      message: data['message'] as String?,
    );
  }

  /// 设备代码流 - 轮询获取令牌
  Future<OAuthToken> pollForToken(String deviceCode) async {
    final networkClient = NetworkClient();
    
    while (true) {
      final response = await networkClient.post(
        _tokenEndpoint,
        headers: NetworkClient.microsoftHeaders,
        body: {
          'client_id': _clientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCode,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return OAuthToken(
          accessToken: data['access_token'] as String,
          tokenType: data['token_type'] as String,
          expiresIn: data['expires_in'] as int,
          refreshToken: data['refresh_token'] as String?,
          scope: data['scope'] as String?,
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final String error = data['error'] as String;

      if (error == 'authorization_pending') {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      } else if (error == 'slow_down') {
        await Future.delayed(const Duration(seconds: 10));
        continue;
      } else if (error == 'expired_token') {
        throw Exception('Device code expired');
      } else if (error == 'access_denied') {
        throw Exception('User denied authorization');
      } else {
        throw Exception('Token polling failed: $error');
      }
    }
  }
}

/// 设备代码响应
class DeviceCodeResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;
  final String? message;

  DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
    this.message,
  });
}
