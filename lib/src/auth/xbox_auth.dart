import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Xbox Live认证服务
class XboxAuthService {
  /// Xbox Live用户认证端点
  static const String _userAuthenticateEndpoint = 'https://user.auth.xboxlive.com/user/authenticate';

  /// XSTS认证端点
  static const String _xstsAuthenticateEndpoint = 'https://xsts.auth.xboxlive.com/xsts/authorize';

  /// 获取Xbox Live令牌
  Future<XboxLiveToken> authenticateUser(String accessToken) async {
    final response = await http.post(
      Uri.parse(_userAuthenticateEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken',
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to authenticate user: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final Map<String, dynamic> displayClaims = data['DisplayClaims']['xui'][0] as Map<String, dynamic>;
    
    return XboxLiveToken(
      userHash: displayClaims['uhs'] as String,
      token: data['Token'] as String,
      expiresAt: DateTime.parse(data['NotAfter'] as String),
    );
  }

  /// 获取XSTS令牌
  Future<XstsToken> acquireXstsToken(String xboxLiveToken) async {
    final response = await http.post(
      Uri.parse(_xstsAuthenticateEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xboxLiveToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT',
      }),
    );

    if (response.statusCode != 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String errorCode = data['XErr']?.toString() ?? 'Unknown';
      
      if (errorCode == '2148916233') {
        throw Exception('Account does not have Xbox Live');
      } else if (errorCode == '2148916235') {
        throw Exception('Account is banned from Xbox Live');
      } else if (errorCode == '2148916236') {
        throw Exception('Account has not accepted Xbox Live Terms of Service');
      } else if (errorCode == '2148916237') {
        throw Exception('Account needs adult verification');
      } else if (errorCode == '2148916238') {
        throw Exception('Account is a child account and needs family setup');
      }
      
      throw Exception('Failed to acquire XSTS token: $errorCode ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final Map<String, dynamic> displayClaims = data['DisplayClaims']['xui'][0] as Map<String, dynamic>;
    
    return XstsToken(
      userHash: displayClaims['uhs'] as String,
      token: data['Token'] as String,
      expiresAt: DateTime.parse(data['NotAfter'] as String),
    );
  }
}
