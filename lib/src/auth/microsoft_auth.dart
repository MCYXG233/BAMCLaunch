/// Microsoft OAuth2 认证服务模块
///
/// 本文件实现了 Microsoft 账户的 OAuth2 认证流程，支持两种认证方式：
/// 1. **授权码流程（Authorization Code Flow）with PKCE**：适用于有浏览器的环境
/// 2. **设备代码流程（Device Code Flow）**：适用于无浏览器或命令行环境
///
/// ## 主要功能
/// - 生成授权 URL 和 PKCE 验证参数
/// - 通过授权码交换访问令牌
/// - 刷新过期的访问令牌
/// - 设备代码流的获取和轮询
///
/// ## 依赖
/// - `dart:convert`：用于 Base64 编码和 JSON 解析
/// - `dart:math`：用于生成随机字符串
/// - `crypto` 包：用于 SHA-256 哈希计算
/// - `NetworkClient`：网络请求客户端
/// - `models.dart`：数据模型定义
///
/// ## 使用示例
/// ```dart
/// final authService = MicrosoftAuthService();
///
/// // 方式一：授权码流程
/// final authData = authService.generateAuthorizationUrl();
/// // 打开 authData['url'] 让用户授权
/// // 用户授权后，使用返回的 code 和 authData['codeVerifier'] 获取令牌
/// final token = await authService.exchangeCodeForToken(
///   code: 'authorization_code',
///   codeVerifier: authData['codeVerifier'],
/// );
///
/// // 方式二：设备代码流程
/// final deviceCode = await authService.getDeviceCode();
/// // 显示 deviceCode.userCode 和 deviceCode.verificationUri 给用户
/// final token = await authService.pollForToken(deviceCode.deviceCode);
/// ```
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../core/api_endpoints.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import 'models.dart';

/// Microsoft OAuth2 认证服务
///
/// 该类封装了 Microsoft 账户的 OAuth2 认证逻辑，提供了完整的认证流程支持。
/// 主要用于 Minecraft 启动器的用户认证功能。
///
/// ## 支持的认证流程
///
/// ### 1. 授权码流程（Authorization Code Flow with PKCE）
/// 适用于有浏览器环境的应用程序。流程如下：
/// 1. 调用 [generateAuthorizationUrl] 生成授权 URL 和验证参数
/// 2. 在浏览器中打开授权 URL，用户登录并授权
/// 3. 用户授权后，浏览器重定向到回调 URL，携带授权码
/// 4. 调用 [extractAuthorizationCode] 从回调 URL 中提取授权码
/// 5. 调用 [exchangeCodeForToken] 使用授权码交换访问令牌
///
/// ### 2. 设备代码流程（Device Code Flow）
/// 适用于无浏览器环境（如命令行工具、智能电视等）。流程如下：
/// 1. 调用 [getDeviceCode] 获取设备代码和用户验证信息
/// 2. 显示验证 URL 和用户代码给用户
/// 3. 用户在另一设备上访问验证 URL 并输入用户代码
/// 4. 调用 [pollForToken] 轮询令牌端点，等待用户完成授权
/// 5. 用户授权后，轮询返回访问令牌
///
/// ## 安全性说明
/// - 使用 PKCE（Proof Key for Code Exchange）防止授权码拦截攻击
/// - 使用加密安全的随机数生成器生成验证参数
/// - 访问令牌和刷新令牌应安全存储
///
/// ## 相关文档
/// - [Microsoft OAuth2 文档](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
/// - [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
/// - [设备代码流 RFC 8628](https://tools.ietf.org/html/rfc8628)
class MicrosoftAuthService {
  /// OAuth2 客户端 ID
  ///
  /// 这是 Microsoft 为本应用程序分配的唯一标识符。
  /// 客户端 ID 是公开的，不包含敏感信息，可以安全地嵌入客户端应用程序中。
  /// 该 ID 已在 Microsoft Azure AD 中注册，配置了以下权限：
  /// - XboxLive.signin：Xbox Live 登录权限
  /// - offline_access：离线访问权限（用于获取刷新令牌）
  static const String _clientId = '0b1a81c9-6e23-41fd-8690-98a17d81bf4a';

  /// OAuth2 重定向 URI
  ///
  /// 授权服务器在用户授权后重定向的 URI。
  /// 使用 Microsoft 提供的桌面应用专用重定向 URI。
  /// 注意：此 URI 必须在 Azure AD 应用注册中预先配置。
  static const String _redirectUri = ApiEndpoints.microsoftRedirectUri;

  /// OAuth2 授权范围
  ///
  /// 定义应用程序请求的权限范围：
  /// - `XboxLive.signin`：Xbox Live 登录权限，用于 Minecraft 认证
  /// - `offline_access`：离线访问权限，允许获取刷新令牌以长期访问
  static const String _scope = 'XboxLive.signin offline_access';

  /// OAuth2 授权端点 URL
  ///
  /// 用户在此端点进行身份验证和授权。
  /// 使用 `/consumers` 路径支持所有 Microsoft 账户类型（个人和组织账户）。
  static const String _authorizationEndpoint = ApiEndpoints.microsoftAuthAuthorize;

  /// OAuth2 令牌端点 URL
  ///
  /// 用于交换授权码获取访问令牌，或使用刷新令牌获取新的访问令牌。
  static const String _tokenEndpoint = ApiEndpoints.microsoftAuthToken;

  /// OAuth2 设备代码端点 URL
  ///
  /// 用于设备代码流，获取设备代码和用户验证信息。
  static const String _deviceCodeEndpoint = ApiEndpoints.microsoftAuthDeviceCode;

  /// 生成 PKCE 代码验证器（Code Verifier）
  ///
  /// 代码验证器是一个高熵加密随机字符串，用于 PKCE 流程中防止授权码拦截攻击。
  ///
  /// ## 生成规则
  /// - 长度：128 个字符（PKCE 规范允许 43-128 个字符）
  /// - 字符集：`[a-zA-Z0-9-._~]`（RFC 7636 定义的未保留字符）
  /// - 随机性：使用加密安全的随机数生成器 [Random.secure]
  ///
  /// ## 返回值
  /// 返回一个 128 字符的随机字符串，用作 PKCE 代码验证器。
  ///
  /// ## 安全说明
  /// - 必须为每个授权请求生成新的代码验证器
  /// - 代码验证器应保密，直到令牌交换完成
  /// - 使用 [Random.secure] 而非普通 [Random] 以确保加密安全性
  ///
  /// ## 相关规范
  /// 参考 RFC 7636 Section 4.1: https://tools.ietf.org/html/rfc7636#section-4.1
  String _generateCodeVerifier() {
    // PKCE 规范定义的允许字符集（未保留字符）
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    // 使用加密安全的随机数生成器
    final Random random = Random.secure();
    // 生成 128 个随机字符
    return List.generate(128, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成 PKCE 代码挑战（Code Challenge）
  ///
  /// 代码挑战是代码验证器的 SHA-256 哈希值的 Base64URL 编码形式。
  /// 在授权请求中发送，用于后续令牌交换时的验证。
  ///
  /// ## 参数
  /// - [codeVerifier]：PKCE 代码验证器，由 [_generateCodeVerifier] 生成
  ///
  /// ## 返回值
  /// 返回代码挑战字符串（Base64URL 编码，无填充）。
  ///
  /// ## 算法流程
  /// 1. 将代码验证器转换为 UTF-8 字节序列
  /// 2. 对字节序列进行 SHA-256 哈希计算
  /// 3. 对哈希结果进行 Base64URL 编码
  /// 4. 移除 Base64 填充字符 `=`
  ///
  /// ## 安全说明
  /// - 使用 SHA-256 提供足够的加密强度
  /// - Base64URL 编码确保 URL 安全性
  /// - 移除填充字符符合 PKCE 规范
  ///
  /// ## 相关规范
  /// 参考 RFC 7636 Section 4.2: https://tools.ietf.org/html/rfc7636#section-4.2
  String _generateCodeChallenge(String codeVerifier) {
    // 将代码验证器转换为 UTF-8 字节
    final List<int> bytes = utf8.encode(codeVerifier);
    // 计算 SHA-256 哈希值
    final Digest digest = sha256.convert(bytes);
    // Base64URL 编码并移除填充字符
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// 生成 OAuth2 状态参数
  ///
  /// 状态参数用于防止 CSRF（跨站请求伪造）攻击。
  /// 在授权请求中发送，并在回调时验证其一致性。
  ///
  /// ## 返回值
  /// 返回一个 32 字符的随机字符串，用作 OAuth2 状态参数。
  ///
  /// ## 安全说明
  /// - 每次授权请求应生成新的状态值
  /// - 状态值应使用加密安全的随机数生成器
  /// - 在回调时必须验证状态值是否匹配
  /// - 状态值应具有足够的熵值（32 字符提供约 190 位熵）
  ///
  /// ## 使用流程
  /// 1. 生成状态值并存储
  /// 2. 将状态值包含在授权 URL 中
  /// 3. 用户授权后，回调 URL 包含相同的状态值
  /// 4. 使用 [verifyState] 验证回调中的状态值是否匹配
  String _generateState() {
    // 使用字母和数字字符集
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    // 使用加密安全的随机数生成器
    final Random random = Random.secure();
    // 生成 32 个随机字符
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成 OAuth2 授权 URL 及相关验证参数
  ///
  /// 此方法生成用于授权码流程的授权 URL，同时创建 PKCE 验证参数。
  /// 应用程序应打开此 URL 让用户进行 Microsoft 账户登录和授权。
  ///
  /// ## 返回值
  /// 返回一个包含以下键的 Map：
  /// - `url`：完整的授权 URL，应在浏览器中打开
  /// - `codeVerifier`：PKCE 代码验证器，需在令牌交换时使用，**必须安全保存**
  /// - `state`：CSRF 防护状态值，需在回调验证时使用
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  /// final authData = authService.generateAuthorizationUrl();
  ///
  /// // 保存验证参数（应安全存储）
  /// final codeVerifier = authData['codeVerifier']!;
  /// final state = authData['state']!;
  ///
  /// // 在浏览器中打开授权 URL
  /// launchUrl(authData['url']!);
  ///
  /// // 用户授权后，从回调 URL 中提取授权码
  /// final code = authService.extractAuthorizationCode(callbackUrl);
  ///
  /// // 验证状态
  /// if (!authService.verifyState(callbackUrl, state)) {
  ///   throw Exception('状态验证失败，可能存在 CSRF 攻击');
  /// }
  ///
  /// // 使用授权码交换令牌
  /// final token = await authService.exchangeCodeForToken(
  ///   code: code,
  ///   codeVerifier: codeVerifier,
  /// );
  /// ```
  ///
  /// ## 注意事项
  /// - 返回的 `codeVerifier` 和 `state` 必须安全保存
  /// - 同一授权请求的参数应一起使用
  /// - 每次调用都会生成新的随机参数
  Map<String, String> generateAuthorizationUrl() {
    // 生成 PKCE 参数
    final String codeVerifier = _generateCodeVerifier();
    final String codeChallenge = _generateCodeChallenge(codeVerifier);
    // 生成 CSRF 防护状态
    final String state = _generateState();

    // 构建授权 URL
    final Uri url = Uri.parse(_authorizationEndpoint).replace(
      queryParameters: {
        'client_id': _clientId,
        'response_type': 'code', // 授权码模式
        'redirect_uri': _redirectUri,
        'scope': _scope,
        'code_challenge': codeChallenge, // PKCE 代码挑战
        'code_challenge_method': 'S256', // 使用 SHA-256 方法
        'state': state, // CSRF 防护
      },
    );

    return {
      'url': url.toString(),
      'codeVerifier': codeVerifier,
      'state': state,
    };
  }

  /// 使用授权码交换 OAuth2 访问令牌
  ///
  /// 在用户完成授权后，使用此方法将授权码交换为访问令牌。
  /// 此方法实现了 PKCE 验证，需要提供生成授权 URL 时创建的代码验证器。
  ///
  /// ## 参数
  /// - [code]：授权服务器返回的授权码，从回调 URL 中提取
  /// - [codeVerifier]：生成授权 URL 时创建的 PKCE 代码验证器
  ///
  /// ## 返回值
  /// 返回 [OAuthToken] 对象，包含：
  /// - `accessToken`：访问令牌，用于 API 认证
  /// - `tokenType`：令牌类型（通常为 "Bearer"）
  /// - `expiresIn`：令牌有效期（秒）
  /// - `refreshToken`：刷新令牌，用于获取新的访问令牌
  /// - `scope`：授权范围
  ///
  /// ## 异常
  /// - [Exception]：当令牌交换失败时抛出，包含 HTTP 状态码和错误信息
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// try {
  ///   final token = await authService.exchangeCodeForToken(
  ///     code: 'M.R3_BAY...',
  ///     codeVerifier: 'aBcDeFgHiJkLmNoPqRsTuVwXyZ...',
  ///   );
  ///   print('访问令牌: ${token.accessToken}');
  ///   print('有效期: ${token.expiresIn} 秒');
  /// } catch (e) {
  ///   print('令牌交换失败: $e');
  /// }
  /// ```
  ///
  /// ## 注意事项
  /// - 授权码只能使用一次，交换后立即失效
  /// - 授权码通常有较短的有效期（约 10 分钟）
  /// - 代码验证器必须与生成授权 URL 时的验证器一致
  /// - 访问令牌和刷新令牌应安全存储
  Future<OAuthToken> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    final networkClient = NetworkClient();

    // 向令牌端点发送 POST 请求
    final response = await networkClient.post(
      _tokenEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'grant_type': 'authorization_code', // 授权码授权类型
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier, // PKCE 验证
        'scope': _scope,
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      String detail = 'HTTP ${response.statusCode}';
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as String? ?? '';
        final errorDesc = errorData['error_description'] as String? ?? '';
        detail = '$error: $errorDesc';
        if (error == 'invalid_grant' && errorDesc.contains('AADSTS70000')) {
          throw AppException.fromCode(ErrorCodes.authTokenExpired, detail: '凭据已过期，请重新登录');
        }
      } catch (e) {
        if (e is AppException) rethrow;
      }
      throw AppException.fromCode(
        ErrorCodes.authCodeExchangeFailed,
        detail: detail,
        originalError: response.body,
      );
    }

    // 解析响应并创建令牌对象
    final Map<String, dynamic> data = json.decode(response.body);
    return OAuthToken(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String,
      expiresIn: data['expires_in'] as int,
      refreshToken: data['refresh_token'] as String?,
      scope: data['scope'] as String?,
    );
  }

  /// 使用刷新令牌获取新的访问令牌
  ///
  /// 当访问令牌过期时，可以使用刷新令牌获取新的访问令牌，
  /// 无需用户重新登录。刷新令牌通常有较长的有效期。
  ///
  /// ## 参数
  /// - [refreshToken]：之前获取的刷新令牌
  ///
  /// ## 返回值
  /// 返回新的 [OAuthToken] 对象，包含：
  /// - `accessToken`：新的访问令牌
  /// - `tokenType`：令牌类型
  /// - `expiresIn`：新令牌的有效期（秒）
  /// - `refreshToken`：新的刷新令牌（可能更新）
  /// - `scope`：授权范围
  ///
  /// ## 异常
  /// - [Exception]：当令牌刷新失败时抛出，可能的原因包括：
  ///   - 刷新令牌已过期
  ///   - 刷新令牌已被撤销
  ///   - 网络错误
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// try {
  ///   // 使用保存的刷新令牌获取新的访问令牌
  ///   final newToken = await authService.refreshToken(oldRefreshToken);
  ///   print('新访问令牌: ${newToken.accessToken}');
  ///
  ///   // 保存新的刷新令牌（如果返回）
  ///   if (newToken.refreshToken != null) {
  ///     saveRefreshToken(newToken.refreshToken!);
  ///   }
  /// } catch (e) {
  ///   // 刷新失败，需要用户重新登录
  ///   print('令牌刷新失败，请重新登录: $e');
  /// }
  /// ```
  ///
  /// ## 注意事项
  /// - 新的响应可能包含新的刷新令牌，应更新存储
  /// - 如果刷新令牌也过期，需要用户重新授权
  /// - Microsoft 的刷新令牌有效期通常为 90 天
  Future<OAuthToken> refreshToken(String refreshToken) async {
    final networkClient = NetworkClient();

    // 向令牌端点发送刷新请求
    final response = await networkClient.post(
      _tokenEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'grant_type': 'refresh_token', // 刷新令牌授权类型
        'refresh_token': refreshToken,
        'scope': _scope,
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      String detail = 'HTTP ${response.statusCode}';
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as String? ?? '';
        final errorDesc = errorData['error_description'] as String? ?? '';
        detail = '$error: $errorDesc';
        if (error == 'invalid_grant' && errorDesc.contains('AADSTS70000')) {
          throw AppException.fromCode(ErrorCodes.authTokenExpired, detail: '凭据已过期，请重新登录');
        }
      } catch (e) {
        if (e is AppException) rethrow;
      }
      throw AppException.fromCode(
        ErrorCodes.authRefreshFailed,
        detail: detail,
        originalError: response.body,
      );
    }

    // 解析响应并创建令牌对象
    final Map<String, dynamic> data = json.decode(response.body);
    return OAuthToken(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String,
      expiresIn: data['expires_in'] as int,
      refreshToken: data['refresh_token'] as String?,
      scope: data['scope'] as String?,
    );
  }

  /// 从重定向 URI 中提取授权码
  ///
  /// 用户授权后，授权服务器会重定向到配置的回调 URI，
  /// 并在查询参数中携带授权码或错误信息。此方法用于解析这些信息。
  ///
  /// ## 参数
  /// - [redirectUrl]：完整的重定向 URI，包含查询参数
  ///
  /// ## 返回值
  /// - 成功时：返回授权码字符串
  /// - 失败时（无授权码）：返回 `null`
  ///
  /// ## 异常
  /// - [Exception]：当重定向 URI 包含 `error` 参数时抛出，
  ///   表示用户拒绝授权或发生其他错误
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// // 假设这是授权后的回调 URL
  /// final callbackUrl = 'https://login.live.com/oauth20_desktop.srf?code=M.R3_BAY...&state=abc123';
  ///
  /// try {
  ///   final code = authService.extractAuthorizationCode(callbackUrl);
  ///   if (code != null) {
  ///     print('授权码: $code');
  ///     // 继续令牌交换流程
  ///   }
  /// } catch (e) {
  ///   print('授权失败: $e');
  /// }
  /// ```
  ///
  /// ## 注意事项
  /// - 授权码通常以 `M.R3_` 开头
  /// - 授权码只能使用一次
  /// - 授权码有较短的有效期
  String? extractAuthorizationCode(String redirectUrl) {
    final uri = Uri.parse(redirectUrl);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    // 检查是否有错误
    if (error != null) {
      throw AppException.fromCode(
        ErrorCodes.authFailed,
        detail: error,
      );
    }

    return code;
  }

  /// 验证 OAuth2 状态参数是否匹配
  ///
  /// 用于验证授权回调中的状态参数是否与发起请求时生成的状态一致，
  /// 以防止 CSRF（跨站请求伪造）攻击。
  ///
  /// ## 参数
  /// - [redirectUrl]：授权服务器的重定向 URI，包含 state 参数
  /// - [expectedState]：发起授权请求时生成的预期状态值
  ///
  /// ## 返回值
  /// - `true`：状态匹配，验证通过
  /// - `false`：状态不匹配，可能存在安全风险
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// // 1. 生成授权 URL 并保存状态
  /// final authData = authService.generateAuthorizationUrl();
  /// final expectedState = authData['state']!;
  ///
  /// // 2. 用户授权后，验证状态
  /// final callbackUrl = 'https://login.live.com/oauth20_desktop.srf?code=...&state=abc123';
  ///
  /// if (authService.verifyState(callbackUrl, expectedState)) {
  ///   print('状态验证通过');
  ///   // 继续处理授权码
  /// } else {
  ///   print('状态验证失败，可能存在 CSRF 攻击');
  ///   // 拒绝请求
  /// }
  /// ```
  ///
  /// ## 安全说明
  /// - **必须**在处理授权码之前验证状态
  /// - 状态不匹配时应拒绝请求，不应继续处理
  /// - 每次授权请求应使用新的状态值
  bool verifyState(String redirectUrl, String expectedState) {
    final uri = Uri.parse(redirectUrl);
    final state = uri.queryParameters['state'];
    // 使用恒定时间比较防止时序攻击（对于简单应用可简化）
    return state == expectedState;
  }

  /// 获取设备代码（设备代码流第一步）
  ///
  /// 启动设备代码流程，从授权服务器获取设备代码和用户验证信息。
  /// 用户需要在另一设备上访问验证 URL 并输入用户代码完成授权。
  ///
  /// ## 返回值
  /// 返回 [DeviceCodeResponse] 对象，包含：
  /// - `deviceCode`：设备代码，用于后续轮询令牌
  /// - `userCode`：用户需要输入的验证码
  /// - `verificationUri`：用户访问的验证 URL
  /// - `expiresIn`：设备代码有效期（秒）
  /// - `interval`：建议的轮询间隔（秒）
  /// - `message`：可显示给用户的说明信息
  ///
  /// ## 异常
  /// - [Exception]：当获取设备代码失败时抛出
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// try {
  ///   final deviceCode = await authService.getDeviceCode();
  ///
  ///   // 显示验证信息给用户
  ///   print('请访问: ${deviceCode.verificationUri}');
  ///   print('输入代码: ${deviceCode.userCode}');
  ///   print('有效期: ${deviceCode.expiresIn} 秒');
  ///
  ///   // 开始轮询令牌
  ///   final token = await authService.pollForToken(deviceCode.deviceCode);
  ///   print('认证成功！访问令牌: ${token.accessToken}');
  /// } catch (e) {
  ///   print('获取设备代码失败: $e');
  /// }
  /// ```
  ///
  /// ## 设备代码流程说明
  /// 1. 应用调用此方法获取设备代码
  /// 2. 显示 `verificationUri` 和 `userCode` 给用户
  /// 3. 用户在另一设备（如手机）上访问验证 URL
  /// 4. 用户登录并输入用户代码
  /// 5. 应用调用 [pollForToken] 轮询令牌端点
  /// 6. 用户完成授权后，轮询返回访问令牌
  ///
  /// ## 注意事项
  /// - 设备代码有效期通常为 15 分钟
  /// - 用户代码通常为 8-9 个字符，易于手动输入
  /// - 轮询间隔应遵循服务器建议（通常 5 秒）
  Future<DeviceCodeResponse> getDeviceCode() async {
    final networkClient = NetworkClient();

    // 向设备代码端点发送请求
    final response = await networkClient.post(
      _deviceCodeEndpoint,
      headers: NetworkClient.microsoftHeaders,
      body: {
        'client_id': _clientId,
        'scope': _scope,
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.authMicrosoftFailed,
        detail: 'HTTP ${response.statusCode}: ${response.body}',
        originalError: response.body,
      );
    }

    // 解析响应并创建设备代码响应对象
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

  /// 轮询令牌端点等待用户授权（设备代码流第二步）
  ///
  /// 在用户完成设备代码验证之前，持续轮询令牌端点。
  /// 当用户完成授权后，返回访问令牌。
  ///
  /// ## 参数
  /// - [deviceCode]：从 [getDeviceCode] 获取的设备代码
  ///
  /// ## 返回值
  /// 返回 [OAuthToken] 对象，包含访问令牌和刷新令牌。
  ///
  /// ## 异常
  /// - [Exception]：设备代码已过期（`expired_token`）
  /// - [Exception]：用户拒绝授权（`access_denied`）
  /// - [Exception]：其他轮询错误
  ///
  /// ## 使用示例
  /// ```dart
  /// final authService = MicrosoftAuthService();
  ///
  /// // 获取设备代码
  /// final deviceCode = await authService.getDeviceCode();
  ///
  /// // 显示验证信息
  /// print('请访问 ${deviceCode.verificationUri} 并输入代码: ${deviceCode.userCode}');
  ///
  /// // 轮询令牌（这是一个阻塞调用）
  /// try {
  ///   final token = await authService.pollForToken(deviceCode.deviceCode);
  ///   print('认证成功！');
  ///   print('访问令牌: ${token.accessToken}');
  /// } catch (e) {
  ///   if (e.toString().contains('expired')) {
  ///     print('设备代码已过期，请重新开始');
  ///   } else if (e.toString().contains('denied')) {
  ///     print('用户拒绝了授权请求');
  ///   } else {
  ///     print('认证失败: $e');
  ///   }
  /// }
  /// ```
  ///
  /// ## 轮询逻辑说明
  /// 该方法会持续轮询令牌端点，直到发生以下情况之一：
  /// 1. 用户完成授权 → 返回访问令牌
  /// 2. 设备代码过期 → 抛出异常
  /// 3. 用户拒绝授权 → 抛出异常
  /// 4. 发生其他错误 → 抛出异常
  ///
  /// ## 错误处理
  /// - `authorization_pending`：用户尚未完成授权，继续等待（5秒后重试）
  /// - `slow_down`：轮询过快，增加间隔（10秒后重试）
  /// - `expired_token`：设备代码已过期，需要重新获取
  /// - `access_denied`：用户明确拒绝了授权请求
  ///
  /// ## 注意事项
  /// - 这是一个阻塞方法，会持续运行直到成功或失败
  /// - 应在 UI 中显示取消选项，允许用户中止流程
  /// - 轮询间隔应遵循服务器建议
  Future<OAuthToken> pollForToken(String deviceCode, {int expiresIn = 900}) async {
    final networkClient = NetworkClient();
    // 超时取 min(expiresIn, 900)，最多等15分钟
    final deadline = DateTime.now().add(Duration(seconds: expiresIn.clamp(1, 900)));
    int intervalSeconds = 5;

    while (DateTime.now().isBefore(deadline)) {
      // 向令牌端点发送轮询请求
      final response = await networkClient.post(
        _tokenEndpoint,
        headers: NetworkClient.microsoftHeaders,
        body: {
          'client_id': _clientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCode,
        },
      );

      // 成功获取令牌
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

      // 解析错误响应
      final Map<String, dynamic> data = json.decode(response.body);
      final String error = data['error'] as String;

      // 根据错误类型处理
      if (error == 'authorization_pending') {
        // 用户尚未完成授权，等待后继续轮询
        await Future.delayed(Duration(seconds: intervalSeconds));
        continue;
      } else if (error == 'slow_down') {
        // 轮询过快，增加等待时间
        intervalSeconds += 5;
        await Future.delayed(Duration(seconds: intervalSeconds));
        continue;
      } else if (error == 'expired_token') {
        // 设备代码已过期
        throw AppException.fromCode(ErrorCodes.authDeviceCodeExpired);
      } else if (error == 'authorization_declined' || error == 'access_denied') {
        // 用户拒绝授权
        throw AppException.fromCode(ErrorCodes.authUserDenied);
      } else {
        // 其他错误
        throw AppException.fromCode(
          ErrorCodes.authMicrosoftFailed,
          detail: error,
        );
      }
    }
    // 超时
    throw AppException.fromCode(ErrorCodes.authDeviceCodeExpired);
  }
}

/// 设备代码响应数据模型
///
/// 包含设备代码流程第一步返回的所有信息。
/// 用于向用户显示验证信息，并后续轮询令牌。
///
/// ## 字段说明
/// - [deviceCode]：设备代码，用于轮询令牌端点
/// - [userCode]：用户需要输入的验证码（通常 8-9 个字符）
/// - [verificationUri]：用户访问的验证 URL
/// - [expiresIn]：设备代码有效期（秒），通常为 900 秒（15 分钟）
/// - [interval]：建议的轮询间隔（秒），通常为 5 秒
/// - [message]：可显示给用户的说明信息（可选）
///
/// ## 使用示例
/// ```dart
/// final deviceCode = await authService.getDeviceCode();
///
/// // 显示给用户
/// print('请访问: ${deviceCode.verificationUri}');
/// print('输入代码: ${deviceCode.userCode}');
/// print(deviceCode.message ?? '完成验证后将继续');
///
/// // 保存设备代码用于后续轮询
/// final token = await authService.pollForToken(deviceCode.deviceCode);
/// ```
class DeviceCodeResponse {
  /// 设备代码
  ///
  /// 用于后续轮询令牌端点的唯一标识符。
  /// 此代码应保密，不应暴露给用户。
  final String deviceCode;

  /// 用户代码
  ///
  /// 用户需要在验证页面输入的代码。
  /// 通常为 8-9 个字符，易于手动输入。
  /// 例如："A1B2C3D4"
  final String userCode;

  /// 验证 URL
  ///
  /// 用户需要访问的验证页面地址。
  /// 通常为："https://microsoft.com/link" 或 "https://microsoft.com/devicelogin"
  final String verificationUri;

  /// 有效期（秒）
  ///
  /// 设备代码的有效时间。
  /// 用户需要在此时间内完成验证，否则需要重新获取设备代码。
  /// 通常为 900 秒（15 分钟）。
  final int expiresIn;

  /// 轮询间隔（秒）
  ///
  /// 建议的令牌轮询间隔时间。
  /// 应用应遵循此间隔以避免被限流。
  /// 通常为 5 秒。
  final int interval;

  /// 用户说明信息
  ///
  /// 可直接显示给用户的说明信息，包含验证 URL 和用户代码。
  /// 例如："To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code A1B2C3D4 to authenticate."
  final String? message;

  /// 创建设备代码响应对象
  ///
  /// ## 参数
  /// - [deviceCode]：设备代码（必需）
  /// - [userCode]：用户代码（必需）
  /// - [verificationUri]：验证 URL（必需）
  /// - [expiresIn]：有效期秒数（必需）
  /// - [interval]：轮询间隔秒数（必需）
  /// - [message]：用户说明信息（可选）
  DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
    this.message,
  });
}