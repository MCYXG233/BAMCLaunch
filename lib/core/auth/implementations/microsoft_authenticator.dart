import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/account.dart';
import '../interfaces/i_authenticator.dart';

class MicrosoftAuthenticator implements IAuthenticator {
  static const String clientId = '0000000048093EE3';
  static const String redirectUri = 'https://login.live.com/oauth20_desktop.srf';
  static const String scope = 'XboxLive.signin offline_access';

  @override
  AccountType get accountType => AccountType.microsoft;

  @override
  Future<Account> login(Map<String, dynamic> credentials) async {
    String authorizationCode = credentials['authorizationCode'] as String;
    
    if (authorizationCode.isEmpty) {
      throw Exception('授权码不能为空');
    }

    Map<String, dynamic> azureTokens = await _getAzureTokens(authorizationCode);
    Map<String, dynamic> xboxLiveToken = await _getXboxLiveToken(azureTokens['access_token']);
    Map<String, dynamic> xstsToken = await _getXstsToken(xboxLiveToken['Token']);
    Map<String, dynamic> minecraftToken = await _getMinecraftToken(xstsToken);
    MinecraftProfile profile = await _getMinecraftProfile(minecraftToken['access_token']);

    TokenData tokenData = TokenData(
      accessToken: minecraftToken['access_token'],
      refreshToken: azureTokens['refresh_token'],
      expiresAt: DateTime.now().add(Duration(seconds: azureTokens['expires_in'])),
    );

    return Account(
      id: profile.id,
      username: profile.name,
      type: AccountType.microsoft,
      tokenData: tokenData,
      profile: profile,
      lastLogin: DateTime.now(),
    );
  }

  @override
  Future<Account> refresh(Account account) async {
    if (account.tokenData?.refreshToken == null) {
      throw Exception('没有刷新令牌');
    }

    Map<String, dynamic> azureTokens = await _refreshAzureTokens(account.tokenData!.refreshToken!);
    Map<String, dynamic> xboxLiveToken = await _getXboxLiveToken(azureTokens['access_token']);
    Map<String, dynamic> xstsToken = await _getXstsToken(xboxLiveToken['Token']);
    Map<String, dynamic> minecraftToken = await _getMinecraftToken(xstsToken);
    MinecraftProfile profile = await _getMinecraftProfile(minecraftToken['access_token']);

    TokenData newTokenData = TokenData(
      accessToken: minecraftToken['access_token'],
      refreshToken: azureTokens['refresh_token'],
      expiresAt: DateTime.now().add(Duration(seconds: azureTokens['expires_in'])),
    );

    return account.copyWith(
      tokenData: newTokenData,
      profile: profile,
      lastLogin: DateTime.now(),
    );
  }

  @override
  Future<MinecraftProfile> getProfile(Account account) async {
    return _getMinecraftProfile(account.tokenData!.accessToken);
  }

  @override
  Future<void> logout(Account account) async {
    
  }

  @override
  bool canRefresh(Account account) {
    return account.tokenData?.refreshToken != null;
  }

  String generateAuthorizationUrl() {
    String state = _generateRandomString(32);
    String codeVerifier = _generateRandomString(128);
    String codeChallenge = _generateCodeChallenge(codeVerifier);

    return 'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?'
        'client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=${Uri.encodeComponent(scope)}'
        '&state=$state'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=S256';
  }

  Future<Map<String, dynamic>> _getAzureTokens(String authorizationCode) async {
    Uri uri = Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token');
    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    String body = 'client_id=$clientId'
        '&grant_type=authorization_code'
        '&code=$authorizationCode'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}';

    return await _httpPost(uri, headers, body);
  }

  Future<Map<String, dynamic>> _refreshAzureTokens(String refreshToken) async {
    Uri uri = Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token');
    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    String body = 'client_id=$clientId'
        '&grant_type=refresh_token'
        '&refresh_token=$refreshToken'
        '&scope=${Uri.encodeComponent(scope)}';

    return await _httpPost(uri, headers, body);
  }

  Future<Map<String, dynamic>> _getXboxLiveToken(String azureToken) async {
    Uri uri = Uri.parse('https://user.auth.xboxlive.com/user/authenticate');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'Properties': {
        'AuthMethod': 'RPS',
        'SiteName': 'user.auth.xboxlive.com',
        'RpsTicket': 'd=$azureToken',
      },
      'RelyingParty': 'http://auth.xboxlive.com',
      'TokenType': 'JWT',
    };

    return await _httpPost(uri, headers, jsonEncode(body));
  }

  Future<Map<String, dynamic>> _getXstsToken(String xboxLiveToken) async {
    Uri uri = Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'Properties': {
        'SandboxId': 'RETAIL',
        'UserTokens': [xboxLiveToken],
      },
      'RelyingParty': 'rp://api.minecraftservices.com/',
      'TokenType': 'JWT',
    };

    return await _httpPost(uri, headers, jsonEncode(body));
  }

  Future<Map<String, dynamic>> _getMinecraftToken(Map<String, dynamic> xstsToken) async {
    Uri uri = Uri.parse('https://api.minecraftservices.com/authentication/login_with_xbox');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'identityToken': 'XBL3.0 x=${xstsToken['DisplayClaims']['xui'][0]['uhs']};${xstsToken['Token']}',
    };

    return await _httpPost(uri, headers, jsonEncode(body));
  }

  Future<MinecraftProfile> _getMinecraftProfile(String minecraftToken) async {
    Uri uri = Uri.parse('https://api.minecraftservices.com/minecraft/profile');
    Map<String, String> headers = {
      'Authorization': 'Bearer $minecraftToken',
    };

    Map<String, dynamic> response = await _httpGet(uri, headers);
    
    String skinUrl = response['skins']?.firstWhere((skin) => skin['state'] == 'ACTIVE', orElse: () => {})['url'];
    String capeUrl = response['capes']?.firstWhere((cape) => cape['state'] == 'ACTIVE', orElse: () => {})['url'];

    return MinecraftProfile(
      id: response['id'],
      name: response['name'],
      skinUrl: skinUrl,
      capeUrl: capeUrl,
    );
  }

  Future<Map<String, dynamic>> _httpPost(Uri uri, Map<String, String> headers, String body) async {
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode< 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  Future<Map<String, dynamic>> _httpGet(Uri uri, Map<String, String> headers) async {
    try {
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode< 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  String _generateCodeChallenge(String codeVerifier) {
    Uint8List bytes = utf8.encode(codeVerifier);
    Digest digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}