import 'dart:convert';
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import 'models.dart';

/// Xbox Live认证服务
class XboxAuthService {
  /// Xbox Live用户认证端点
  static const String _userAuthenticateEndpoint = ApiEndpoints.xboxUserAuth;

  /// XSTS认证端点
  static const String _xstsAuthenticateEndpoint = ApiEndpoints.xboxXstsAuth;

  /// 获取Xbox Live令牌
  Future<XboxLiveToken> authenticateUser(String accessToken) async {
    final networkClient = NetworkClient();
    final response = await networkClient.postJson(
      _userAuthenticateEndpoint,
      {
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken',
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT',
      },
      headers: NetworkClient.xboxLiveHeaders,
    );

    if (response.statusCode == 400) {
      throw AppException.fromCode(
        ErrorCodes.authXboxFailed,
        detail: 'Xbox Live 请求格式错误 (HTTP 400)',
        originalError: response.body,
      );
    }

    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.authXboxFailed,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
        originalError: response.body,
      );
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw AppException.fromCode(
        ErrorCodes.networkJsonParseError,
        detail: 'Xbox auth returned invalid JSON: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        originalError: e,
      );
    }
    final Map<String, dynamic> displayClaims = data['DisplayClaims']['xui'][0] as Map<String, dynamic>;

    return XboxLiveToken(
      userHash: displayClaims['uhs'] as String,
      token: data['Token'] as String,
      expiresAt: DateTime.parse(data['NotAfter'] as String),
    );
  }

  /// 获取XSTS令牌
  Future<XstsToken> acquireXstsToken(String xboxLiveToken) async {
    final networkClient = NetworkClient();
    final response = await networkClient.postJson(
      _xstsAuthenticateEndpoint,
      {
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xboxLiveToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT',
      },
      headers: NetworkClient.xboxLiveHeaders,
    );

    if (response.statusCode == 400) {
      throw AppException.fromCode(
        ErrorCodes.authXboxFailed,
        detail: 'Xbox Live 请求格式错误 (HTTP 400)',
        originalError: response.body,
      );
    }

    if (response.statusCode != 200) {
      final Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw AppException.fromCode(
          ErrorCodes.networkJsonParseError,
          detail: 'XSTS error returned invalid JSON: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
          originalError: e,
        );
      }
      final String errorCode = data['XErr']?.toString() ?? 'Unknown';
      
      if (errorCode == '2148916227') {
        throw AppException.fromCode(ErrorCodes.authXboxFailed, detail: '账户已被Xbox Live封禁 (2148916227)');
      } else if (errorCode == '2148916233') {
        throw AppException.fromCode(ErrorCodes.authXboxFailed, detail: '账户没有Xbox Live (2148916233)');
      } else if (errorCode == '2148916235') {
        throw AppException.fromCode(ErrorCodes.authXboxFailed, detail: '当前地区不可用Xbox Live (2148916235)');
      } else if (errorCode == '2148916238') {
        throw AppException.fromCode(ErrorCodes.authXboxFailed, detail: '子账户需要家庭设置 (2148916238)');
      }

      throw AppException.fromCode(
        ErrorCodes.authXstsFailed,
        detail: 'XErr=$errorCode, ${response.body}',
        originalError: response.body,
      );
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw AppException.fromCode(
        ErrorCodes.networkJsonParseError,
        detail: 'XSTS success returned invalid JSON: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        originalError: e,
      );
    }
    final Map<String, dynamic> displayClaims = data['DisplayClaims']['xui'][0] as Map<String, dynamic>;

    return XstsToken(
      userHash: displayClaims['uhs'] as String,
      token: data['Token'] as String,
      expiresAt: DateTime.parse(data['NotAfter'] as String),
    );
  }
}
