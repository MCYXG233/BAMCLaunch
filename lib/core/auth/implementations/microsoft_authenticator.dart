import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/account.dart';
import '../interfaces/i_authenticator.dart';
import '../../logger/logger.dart';

class MicrosoftAuthenticator implements IAuthenticator {
  static const String clientId = '0b1a81c9-6e23-41fd-8690-98a17d81bf4a';
  static const String redirectUri = 'https://login.live.com/oauth20_desktop.srf';
  static const String scope = 'XboxLive.signin offline_access';
  
  String? _codeVerifier;
  String? _state;
  String? _deviceCode;
  int? _expiresIn;
  int? _interval;

  @override
  AccountType get accountType => AccountType.microsoft;

  @override
  Future<Account> login(Map<String, dynamic> credentials) async {
    try {
      logger.info('开始Microsoft认证流程');
      
      Map<String, dynamic> azureTokens;
      
      // 检查是否是设备代码登录
      if (credentials.containsKey('deviceCodeFlow') && credentials['deviceCodeFlow'] == true) {
        azureTokens = credentials['azureTokens'] as Map<String, dynamic>;
      } else {
        // 普通授权码登录
        String authorizationCode = credentials['authorizationCode'] as String;
        String returnedState = credentials['state'] as String? ?? '';
        
        if (authorizationCode.isEmpty) {
          throw Exception('授权码不能为空');
        }
        
        if (_state != null && _state != returnedState) {
          throw Exception('状态验证失败，可能是CSRF攻击');
        }
        
        logger.info('1. 获取Azure令牌');
        azureTokens = await _getAzureTokens(authorizationCode);
      }
      
      logger.info('2. 获取Xbox Live令牌');
      Map<String, dynamic> xboxLiveToken = await _getXboxLiveToken(azureTokens['access_token']);
      
      logger.info('3. 获取XSTS令牌');
      Map<String, dynamic> xstsToken = await _getXstsToken(xboxLiveToken['Token']);
      
      logger.info('4. 获取Minecraft令牌');
      Map<String, dynamic> minecraftToken = await _getMinecraftToken(xstsToken);
      
      logger.info('5. 获取Minecraft个人资料');
      MinecraftProfile profile = await _getMinecraftProfile(minecraftToken['access_token']);

      TokenData tokenData = TokenData(
        accessToken: minecraftToken['access_token'],
        refreshToken: azureTokens['refresh_token'],
        expiresAt: DateTime.now().add(Duration(seconds: azureTokens['expires_in'])),
      );

      logger.info('认证成功，用户: ${profile.name}');
      
      return Account(
        id: profile.id,
        username: profile.name,
        type: AccountType.microsoft,
        tokenData: tokenData,
        profile: profile,
        lastLogin: DateTime.now(),
      );
    } catch (e) {
      logger.error('认证失败: $e');
      rethrow;
    } finally {
      // 清理状态
      _codeVerifier = null;
      _state = null;
      _deviceCode = null;
      _expiresIn = null;
      _interval = null;
    }
  }

  @override
  Future<Account> refresh(Account account) async {
    if (account.tokenData?.refreshToken == null) {
      throw Exception('没有刷新令牌');
    }

    try {
      logger.info('开始刷新令牌: ${account.username}');
      
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

      logger.info('令牌刷新成功: ${account.username}');
      
      return account.copyWith(
        tokenData: newTokenData,
        profile: profile,
        lastLogin: DateTime.now(),
      );
    } catch (e) {
      logger.error('令牌刷新失败: $e');
      rethrow;
    }
  }

  @override
  Future<MinecraftProfile> getProfile(Account account) async {
    try {
      logger.info('获取个人资料: ${account.username}');
      return await _getMinecraftProfile(account.tokenData!.accessToken);
    } catch (e) {
      logger.error('获取个人资料失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout(Account account) async {
    try {
      // 这里可以添加Microsoft logout API调用
      logger.info('注销账户: ${account.username}');
    } catch (e) {
      logger.error('注销失败: $e');
      // 即使失败也继续执行，因为本地注销是主要目标
    }
  }

  @override
  bool canRefresh(Account account) {
    return account.tokenData?.refreshToken != null;
  }

  Map<String, String> generateAuthorizationUrl() {
    _state = _generateRandomString(32);
    _codeVerifier = _generateRandomString(128);
    String codeChallenge = _generateCodeChallenge(_codeVerifier!);

    String url = 'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?'
        'client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=${Uri.encodeComponent(scope)}'
        '&state=$_state'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=S256';

    return {
      'url': url,
      'state': _state!,
      'codeVerifier': _codeVerifier!,
    };
  }

  Future<Map<String, dynamic>> getDeviceCode() async {
    try {
      logger.info('获取设备代码');
      
      Uri uri = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/devicecode');
      Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
      String body = 'client_id=$clientId'
          '&scope=${Uri.encodeComponent(scope)}';

      Map<String, dynamic> response = await _httpPost(uri, headers, body, '设备代码');
      
      _deviceCode = response['device_code'];
      _expiresIn = response['expires_in'];
      _interval = response['interval'];
      
      return response;
    } catch (e) {
      logger.error('获取设备代码失败: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> pollForToken() async {
    if (_deviceCode == null) {
      throw Exception('未获取设备代码');
    }

    int maxAttempts = (_expiresIn ?? 300) ~/ (_interval ?? 5);
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        logger.info('轮询令牌，尝试 $attempts/$maxAttempts');
        
        Uri uri = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token');
        Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
        String body = 'client_id=$clientId'
            '&grant_type=urn:ietf:params:oauth:grant-type:device_code'
            '&device_code=$_deviceCode';

        Map<String, dynamic> response = await _httpPost(uri, headers, body, '轮询令牌');
        return response;
      } catch (e) {
        String errorMessage = e.toString();
        if (errorMessage.contains('authorization_pending')) {
          // 等待用户完成登录
          await Future.delayed(Duration(seconds: _interval ?? 5));
          attempts++;
        } else if (errorMessage.contains('slow_down')) {
          // 需要减慢轮询速度
          await Future.delayed(Duration(seconds: (_interval ?? 5) + 5));
          attempts++;
        } else {
          // 其他错误
          logger.error('轮询令牌失败: $e');
          rethrow;
        }
      }
    }

    throw Exception('设备代码登录超时');
  }

  Future<Account> loginWithDeviceCode() async {
    try {
      logger.info('开始设备代码流登录');
      
      logger.info('1. 获取设备代码');
      Map<String, dynamic> deviceCodeData = await getDeviceCode();
      
      logger.info('2. 等待用户登录');
      Map<String, dynamic> azureTokens = await pollForToken();
      
      logger.info('3. 获取Xbox Live令牌');
      Map<String, dynamic> xboxLiveToken = await _getXboxLiveToken(azureTokens['access_token']);
      
      logger.info('4. 获取XSTS令牌');
      Map<String, dynamic> xstsToken = await _getXstsToken(xboxLiveToken['Token']);
      
      logger.info('5. 获取Minecraft令牌');
      Map<String, dynamic> minecraftToken = await _getMinecraftToken(xstsToken);
      
      logger.info('6. 获取Minecraft个人资料');
      MinecraftProfile profile = await _getMinecraftProfile(minecraftToken['access_token']);

      TokenData tokenData = TokenData(
        accessToken: minecraftToken['access_token'],
        refreshToken: azureTokens['refresh_token'],
        expiresAt: DateTime.now().add(Duration(seconds: azureTokens['expires_in'])),
      );

      logger.info('认证成功，用户: ${profile.name}');
      
      return Account(
        id: profile.id,
        username: profile.name,
        type: AccountType.microsoft,
        tokenData: tokenData,
        profile: profile,
        lastLogin: DateTime.now(),
      );
    } catch (e) {
      logger.error('设备代码登录失败: $e');
      rethrow;
    } finally {
      // 清理状态
      _deviceCode = null;
      _expiresIn = null;
      _interval = null;
    }
  }

  Future<Map<String, dynamic>> _getAzureTokens(String authorizationCode) async {
    Uri uri = Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token');
    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    String body = 'client_id=$clientId'
        '&grant_type=authorization_code'
        '&code=$authorizationCode'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&code_verifier=$_codeVerifier';

    return await _httpPost(uri, headers, body, 'Azure令牌');
  }

  Future<Map<String, dynamic>> _refreshAzureTokens(String refreshToken) async {
    Uri uri = Uri.parse('https://login.microsoftonline.com/consumers/oauth2/v2.0/token');
    Map<String, String> headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    String body = 'client_id=$clientId'
        '&grant_type=refresh_token'
        '&refresh_token=$refreshToken'
        '&scope=${Uri.encodeComponent(scope)}';

    return await _httpPost(uri, headers, body, '刷新Azure令牌');
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

    return await _httpPost(uri, headers, jsonEncode(body), 'Xbox Live令牌');
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

    return await _httpPost(uri, headers, jsonEncode(body), 'XSTS令牌');
  }

  Future<Map<String, dynamic>> _getMinecraftToken(Map<String, dynamic> xstsToken) async {
    Uri uri = Uri.parse('https://api.minecraftservices.com/authentication/login_with_xbox');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> body = {
      'identityToken': 'XBL3.0 x=${xstsToken['DisplayClaims']['xui'][0]['uhs']};${xstsToken['Token']}',
    };

    return await _httpPost(uri, headers, jsonEncode(body), 'Minecraft令牌');
  }

  Future<MinecraftProfile> _getMinecraftProfile(String minecraftToken) async {
    Uri uri = Uri.parse('https://api.minecraftservices.com/minecraft/profile');
    Map<String, String> headers = {
      'Authorization': 'Bearer $minecraftToken',
    };

    Map<String, dynamic> response = await _httpGet(uri, headers, 'Minecraft个人资料');
    
    String skinUrl = response['skins']?.firstWhere((skin) => skin['state'] == 'ACTIVE', orElse: () => {})?['url'] ?? '';
    String capeUrl = response['capes']?.firstWhere((cape) => cape['state'] == 'ACTIVE', orElse: () => {})?['url'] ?? '';

    return MinecraftProfile(
      id: response['id'],
      name: response['name'],
      skinUrl: skinUrl,
      capeUrl: capeUrl,
    );
  }

  Future<Map<String, dynamic>> _httpPost(Uri uri, Map<String, String> headers, String body, String operation) async {
    int retries = 3;
    int delay = 1000;
    
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          logger.error('$operation失败: ${response.statusCode} - ${response.body}');
          if (i == retries - 1) {
            throw Exception('$operation失败: ${response.statusCode} - ${response.body}');
          }
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2;
        }
      } catch (e) {
        logger.error('$operation网络请求失败: $e');
        if (i == retries - 1) {
          throw Exception('$operation网络请求失败: $e');
        }
        await Future.delayed(Duration(milliseconds: delay));
        delay *= 2;
      }
    }
    throw Exception('$operation失败：达到最大重试次数');
  }

  Future<Map<String, dynamic>> _httpGet(Uri uri, Map<String, String> headers, String operation) async {
    int retries = 3;
    int delay = 1000;
    
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(
          uri,
          headers: headers,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          logger.error('$operation失败: ${response.statusCode} - ${response.body}');
          if (i == retries - 1) {
            throw Exception('$operation失败: ${response.statusCode} - ${response.body}');
          }
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2;
        }
      } catch (e) {
        logger.error('$operation网络请求失败: $e');
        if (i == retries - 1) {
          throw Exception('$operation网络请求失败: $e');
        }
        await Future.delayed(Duration(milliseconds: delay));
        delay *= 2;
      }
    }
    throw Exception('$operation失败：达到最大重试次数');
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