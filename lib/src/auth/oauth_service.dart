import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/api_endpoints.dart';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../core/json_utils.dart';
import '../di/service_locator.dart';

class OAuthService {
  static OAuthService? _instance;

  factory OAuthService() {
    return _instance ??= OAuthService._internal();
  }

  OAuthService._internal();

  static OAuthService get instance =>
      ServiceLocator.instance.tryGet<OAuthService>() ??
      (_instance ??= OAuthService._internal());

  final Logger _logger = Logger('OAuthService');
  final NetworkClient _networkClient = NetworkClient();

  final String _clientId = '00000000482326AA';
  final String _redirectUri = ApiEndpoints.microsoftRedirectUri;
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

    final uri = Uri.parse(ApiEndpoints.microsoftAuthAuthorize).replace(queryParameters: params);
    return uri.toString();
  }

  Future<OAuthTokens> exchangeCodeForTokens(String code) async {
    _logger.info('Exchanging authorization code for tokens');

    try {
      final body = {
        'client_id': _clientId,
        'code': code,
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': _currentCodeVerifier,
      };

      final response = await _networkClient.post(
        ApiEndpoints.microsoftAuthToken,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&'),
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authCodeExchangeFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return OAuthTokens.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to exchange code for tokens', e, stackTrace);
      rethrow;
    }
  }

  Future<OAuthTokens> refreshTokens(String refreshToken) async {
    _logger.info('Refreshing access token');

    try {
      final body = {
        'client_id': _clientId,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      };

      final response = await _networkClient.post(
        ApiEndpoints.microsoftAuthToken,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&'),
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authRefreshFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return OAuthTokens.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh tokens', e, stackTrace);
      rethrow;
    }
  }

  Future<XboxLiveResponse> authenticateXboxLive(String accessToken) async {
    _logger.info('Authenticating with Xbox Live');

    try {
      final body = jsonEncode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken',
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT',
      });

      final response = await _networkClient.post(
        ApiEndpoints.xboxUserAuth,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authXboxLiveFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return XboxLiveResponse.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Xbox Live authentication failed', e, stackTrace);
      rethrow;
    }
  }

  Future<XboxLiveResponse> getXboxLiveToken(String xstsToken, String userHash) async {
    _logger.info('Getting Xbox Live token');

    try {
      final body = jsonEncode({
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xstsToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT',
      });

      final response = await _networkClient.post(
        ApiEndpoints.xboxXstsAuth,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authXstsFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return XboxLiveResponse.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to get Xbox Live token', e, stackTrace);
      rethrow;
    }
  }

  Future<MinecraftProfile> getMinecraftProfile(String xboxToken) async {
    _logger.info('Getting Minecraft profile');

    try {
      final body = jsonEncode({
        'identityToken': 'XBL3.0 x=$xboxToken',
      });

      final response = await _networkClient.post(
        ApiEndpoints.minecraftAuthLogin,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authMinecraftFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return MinecraftProfile.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to get Minecraft profile', e, stackTrace);
      rethrow;
    }
  }

  Future<MinecraftOwnership> checkMinecraftOwnership(String accessToken) async {
    _logger.info('Checking Minecraft ownership');

    try {
      final response = await _networkClient.get(
        ApiEndpoints.minecraftEntitlements,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.authOwnershipCheckFailed,
          detail: response.body,
          originalError: response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

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
      accessToken: JsonUtils.getStringOrDefault(json['access_token']),
      tokenType: JsonUtils.getStringOrDefault(json['token_type']),
      expiresIn: JsonUtils.getIntOrDefault(json['expires_in']),
      refreshToken: JsonUtils.getStringOrDefault(json['refresh_token']),
      scope: JsonUtils.getStringOrDefault(json['scope']).split(' '),
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
      token: JsonUtils.getStringOrDefault(json['Token']),
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
      accessToken: JsonUtils.getStringOrDefault(json['access_token']),
      username: JsonUtils.getStringOrDefault(json['username']),
      uuid: JsonUtils.getStringOrDefault(json['uuid']),
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
      name: JsonUtils.getStringOrDefault(json['name']),
      id: JsonUtils.getStringOrDefault(json['id']),
    );
  }
}