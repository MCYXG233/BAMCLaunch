import 'dart:convert';
import '../config/config_manager.dart';
import '../core/error_codes.dart';
import '../di/service_locator.dart';
import 'models.dart';
import 'microsoft_auth.dart';
import 'xbox_auth.dart';
import 'minecraft_auth.dart';
export 'microsoft_auth.dart' show DeviceCodeResponse;

/// 认证进度回调
typedef AuthProgressCallback = void Function(String step);

/// 统一认证管理器
class AuthManager {
  static AuthManager? _instance;

  final ConfigManager _configManager = ConfigManager.instance;
  final MicrosoftAuthService _microsoftAuth = MicrosoftAuthService();
  final XboxAuthService _xboxAuth = XboxAuthService();
  final MinecraftAuthService _minecraftAuth = MinecraftAuthService();

  AuthManager._internal();

  factory AuthManager() {
    _instance ??= AuthManager._internal();
    return _instance!;
  }

  /// 获取单例实例
  ///
  /// 优先通过 [ServiceLocator] 获取，若未注册则回退到本地单例。
  static AuthManager get instance =>
      ServiceLocator.instance.tryGet<AuthManager>() ??
      (_instance ??= AuthManager._internal());

  /// 完整的认证流程
  Future<AuthCredentials> authenticate({
    String? authorizationCode,
    String? codeVerifier,
    String? accessToken,
    String? refreshToken,
    AuthProgressCallback? onProgress,
  }) async {
    AuthCredentials credentials = AuthCredentials();

    try {
      OAuthToken microsoftToken;
      
      if (accessToken != null && refreshToken != null) {
        // 直接使用令牌
        microsoftToken = OAuthToken(
          accessToken: accessToken,
          tokenType: 'Bearer',
          expiresIn: 3600,
          refreshToken: refreshToken,
        );
      } else if (authorizationCode != null && codeVerifier != null) {
        // 使用授权码交换令牌
        onProgress?.call('Authenticating with Microsoft...');
        microsoftToken = await _microsoftAuth.exchangeCodeForToken(
          code: authorizationCode,
          codeVerifier: codeVerifier,
        );
      } else {
        throw AppException.fromCode(
          ErrorCodes.authMissingParameter,
          detail: '必须提供授权码或访问令牌',
        );
      }
      
      credentials = credentials.copyWith(microsoftToken: microsoftToken);

      onProgress?.call('Authenticating with Xbox Live...');
      final xboxToken = await _xboxAuth.authenticateUser(microsoftToken.accessToken);
      credentials = credentials.copyWith(xboxLiveToken: xboxToken);

      onProgress?.call('Acquiring XSTS token...');
      final xstsToken = await _xboxAuth.acquireXstsToken(xboxToken.token);
      credentials = credentials.copyWith(xstsToken: xstsToken);

      onProgress?.call('Logging into Minecraft...');
      final minecraftToken = await _minecraftAuth.loginWithXbox(
        userHash: xstsToken.userHash,
        xstsToken: xstsToken.token,
      );
      credentials = credentials.copyWith(minecraftToken: minecraftToken);

      onProgress?.call('Fetching Minecraft profile...');
      final profile = await _minecraftAuth.getProfile(minecraftToken.accessToken);
      credentials = credentials.copyWith(minecraftProfile: profile);

      // 保存凭据
      await _saveCredentials(credentials);

      return credentials;
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新令牌
  Future<AuthCredentials> refreshCredentials(
    AuthCredentials credentials, {
    AuthProgressCallback? onProgress,
  }) async {
    try {
      if (credentials.microsoftToken?.refreshToken == null) {
        throw AppException.fromCode(ErrorCodes.authRefreshFailed, detail: 'No refresh token available');
      }

      onProgress?.call('Refreshing Microsoft token...');
      final microsoftToken = await _microsoftAuth.refreshToken(
        credentials.microsoftToken!.refreshToken!,
      );
      credentials = credentials.copyWith(microsoftToken: microsoftToken);

      onProgress?.call('Authenticating with Xbox Live...');
      final xboxToken = await _xboxAuth.authenticateUser(microsoftToken.accessToken);
      credentials = credentials.copyWith(xboxLiveToken: xboxToken);

      onProgress?.call('Acquiring XSTS token...');
      final xstsToken = await _xboxAuth.acquireXstsToken(xboxToken.token);
      credentials = credentials.copyWith(xstsToken: xstsToken);

      onProgress?.call('Logging into Minecraft...');
      final minecraftToken = await _minecraftAuth.loginWithXbox(
        userHash: xstsToken.userHash,
        xstsToken: xstsToken.token,
      );
      credentials = credentials.copyWith(minecraftToken: minecraftToken);

      onProgress?.call('Fetching Minecraft profile...');
      final profile = await _minecraftAuth.getProfile(minecraftToken.accessToken);
      credentials = credentials.copyWith(minecraftProfile: profile);

      // 保存凭据
      await _saveCredentials(credentials);

      return credentials;
    } catch (e) {
      rethrow;
    }
  }

  /// 生成授权URL
  Map<String, String> generateAuthorizationUrl() {
    return _microsoftAuth.generateAuthorizationUrl();
  }

  /// 从重定向URI提取授权代码
  String? extractAuthorizationCode(String redirectUrl) {
    return _microsoftAuth.extractAuthorizationCode(redirectUrl);
  }

  /// 验证状态
  bool verifyState(String redirectUrl, String expectedState) {
    return _microsoftAuth.verifyState(redirectUrl, expectedState);
  }

  /// 保存凭据
  Future<void> _saveCredentials(AuthCredentials credentials) async {
    final json = jsonEncode(credentials.toJson());
    await _configManager.setEncrypted('auth_credentials', json);
  }

  /// 加载凭据
  Future<AuthCredentials?> loadCredentials() async {
    final json = await _configManager.getEncrypted('auth_credentials');
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return AuthCredentials.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// 清除凭据
  Future<void> clearCredentials() async {
    await _configManager.remove('auth_credentials');
  }

  /// 检查凭据是否有效
  Future<bool> hasValidCredentials() async {
    final credentials = await loadCredentials();
    if (credentials == null) return false;
    return credentials.isValid;
  }

  /// 检查是否需要刷新令牌
  Future<bool> needsRefresh() async {
    final credentials = await loadCredentials();
    if (credentials == null) return true;
    if (credentials.microsoftToken == null) return true;
    return credentials.microsoftToken!.isNearExpiry || credentials.microsoftToken!.isExpired;
  }

  /// 设备代码流 - 获取设备代码
  Future<DeviceCodeResponse> getDeviceCode() async {
    return await _microsoftAuth.getDeviceCode();
  }

  /// 设备代码流 - 使用设备代码进行完整认证
  Future<AuthCredentials> authenticateWithDeviceCode(
    String deviceCode, {
    AuthProgressCallback? onProgress,
  }) async {
    AuthCredentials credentials = AuthCredentials();

    try {
      onProgress?.call('获取Microsoft令牌...');
      final microsoftToken = await _microsoftAuth.pollForToken(deviceCode);
      credentials = credentials.copyWith(microsoftToken: microsoftToken);

      onProgress?.call('Xbox Live认证...');
      final xboxToken = await _xboxAuth.authenticateUser(microsoftToken.accessToken);
      credentials = credentials.copyWith(xboxLiveToken: xboxToken);

      onProgress?.call('获取XSTS令牌...');
      final xstsToken = await _xboxAuth.acquireXstsToken(xboxToken.token);
      credentials = credentials.copyWith(xstsToken: xstsToken);

      onProgress?.call('登录Minecraft...');
      final minecraftToken = await _minecraftAuth.loginWithXbox(
        userHash: xstsToken.userHash,
        xstsToken: xstsToken.token,
      );
      credentials = credentials.copyWith(minecraftToken: minecraftToken);

      onProgress?.call('获取Minecraft档案...');
      final profile = await _minecraftAuth.getProfile(minecraftToken.accessToken);
      credentials = credentials.copyWith(minecraftProfile: profile);

      // 保存凭据
      await _saveCredentials(credentials);

      return credentials;
    } catch (e) {
      rethrow;
    }
  }
}
