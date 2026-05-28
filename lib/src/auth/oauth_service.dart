import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/logger.dart';

class OAuthService {
  static OAuthService? _instance;

  factory OAuthService() {
    return _instance ??= OAuthService._internal();
  }

  OAuthService._internal();

  static OAuthService get instance => _instance ??= OAuthService._internal();

  final Logger _logger = Logger('OAuthService');

  final String _clientId = '00000000482326AA';
  final String _redirectUri = 'https://login.live.com/oauth20_desktop.srf';
  final String _scope = 'XboxLive.signin offline_access';

  String? _currentCodeVerifier;
  String? _currentState;

  Future<String> generateAuthorizationUrl() async {
    _currentCodeVerifier = _generateCodeVerifier();
    _currentState = _generateState();

    final codeChallenge = await _generateCodeChallenge(_currentCodeVerifier!);

    final params = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': _scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': _currentState,
    };

    final uri = Uri.https('login.microsoftonline.com', 'consumers/oauth2/v2.0/authorize', params);
    return uri.toString();
  }

  Future<OAuthTokens> exchangeCodeForTokens(String code) async {
    _logger.info('Exchanging authorization code for tokens');

    try {
      final request = await HttpClient().postUrl(Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token'));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final body = {
        'client_id': _clientId,
        'code': code,
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': _currentCodeVerifier,
      };

      request.write(body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&'));
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Token exchange failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return OAuthTokens.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to exchange code for tokens', e, stackTrace);
      rethrow;
    }
  }

  Future<OAuthTokens> refreshTokens(String refreshToken) async {
    _logger.info('Refreshing access token');

    try {
      final request = await HttpClient().postUrl(Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token'));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final body = {
        'client_id': _clientId,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      };

      request.write(body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&'));
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Token refresh failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return OAuthTokens.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh tokens', e, stackTrace);
      rethrow;
    }
  }

  Future<XboxLiveResponse> authenticateXboxLive(String accessToken) async {
    _logger.info('Authenticating with Xbox Live');

    try {
      final request = await HttpClient().postUrl(Uri.parse('https://user.auth.xboxlive.com/user/authenticate'));
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken',
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT',
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Xbox Live authentication failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return XboxLiveResponse.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Xbox Live authentication failed', e, stackTrace);
      rethrow;
    }
  }

  Future<XboxLiveResponse> getXboxLiveToken(String xstsToken, String userHash) async {
    _logger.info('Getting Xbox Live token');

    try {
      final request = await HttpClient().postUrl(Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize'));
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xstsToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT',
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Xbox Live token request failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return XboxLiveResponse.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to get Xbox Live token', e, stackTrace);
      rethrow;
    }
  }

  Future<MinecraftProfile> getMinecraftProfile(String xboxToken) async {
    _logger.info('Getting Minecraft profile');

    try {
      final request = await HttpClient().postUrl(Uri.parse('https://api.minecraftservices.com/authentication/login_with_xbox'));
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'identityToken': 'XBL3.0 x=$xboxToken',
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Minecraft profile request failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return MinecraftProfile.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to get Minecraft profile', e, stackTrace);
      rethrow;
    }
  }

  Future<MinecraftOwnership> checkMinecraftOwnership(String accessToken) async {
    _logger.info('Checking Minecraft ownership');

    try {
      final request = await HttpClient().getUrl(Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'));
      request.headers.set('Authorization', 'Bearer $accessToken');

      final response = await request.close();

      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Ownership check failed: $errorContent');
      }

      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return MinecraftOwnership.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to check Minecraft ownership', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _generateCodeChallenge(String verifier) async {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

class OAuthTokens {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String refreshToken;
  final List<String> scope;

  OAuthTokens({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    required this.scope,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
      'scope': scope.join(' '),
    };
  }

  factory OAuthTokens.fromJson(Map<String, dynamic> json) {
    return OAuthTokens(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      refreshToken: json['refresh_token'] as String,
      scope: (json['scope'] as String).split(' '),
    );
  }
}

class XboxLiveResponse {
  final String token;
  final String displayClaims;

  XboxLiveResponse({
    required this.token,
    required this.displayClaims,
  });

  Map<String, dynamic> toJson() {
    return {
      'Token': token,
      'DisplayClaims': displayClaims,
    };
  }

  factory XboxLiveResponse.fromJson(Map<String, dynamic> json) {
    return XboxLiveResponse(
      token: json['Token'] as String,
      displayClaims: jsonEncode(json['DisplayClaims']),
    );
  }
}

class MinecraftProfile {
  final String accessToken;
  final String username;
  final String uuid;

  MinecraftProfile({
    required this.accessToken,
    required this.username,
    required this.uuid,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'username': username,
      'uuid': uuid,
    };
  }

  factory MinecraftProfile.fromJson(Map<String, dynamic> json) {
    return MinecraftProfile(
      accessToken: json['access_token'] as String,
      username: json['username'] as String,
      uuid: json['uuid'] as String,
    );
  }
}

class MinecraftOwnership {
  final List<MinecraftEntitlement> items;

  MinecraftOwnership({required this.items});

  bool get ownsMinecraft => items.any((item) => item.name == 'game_minecraft');

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory MinecraftOwnership.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>;
    return MinecraftOwnership(
      items: itemsJson.map((item) => MinecraftEntitlement.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class MinecraftEntitlement {
  final String name;
  final String id;

  MinecraftEntitlement({
    required this.name,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
  }

  factory MinecraftEntitlement.fromJson(Map<String, dynamic> json) {
    return MinecraftEntitlement(
      name: json['name'] as String,
      id: json['id'] as String,
    );
  }
}