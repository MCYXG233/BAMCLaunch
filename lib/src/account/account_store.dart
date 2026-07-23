import 'dart:async';
import 'dart:convert';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../config/crypto_util.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';
import 'account.dart';

/// 账户持久化存储
///
/// 统一管理账户数据的序列化与持久化，解决 AuthManager 和 AccountManager
/// 各自维护独立存储路径的问题。
///
/// 存储策略：
/// - 非敏感字段（id, username, uuid, type 等）存储在 ConfigManager
/// - 敏感字段（accessToken, refreshToken）使用 CryptoUtil 加密后存储
///
/// 使用示例：
/// ```dart
/// final store = AccountStore.instance;
/// await store.saveAccounts(accounts);
/// final accounts = await store.loadAccounts();
/// ```
class AccountStore {
  static AccountStore? _instance;

  factory AccountStore() => instance;

  AccountStore._internal();

  /// 获取单例实例
  static AccountStore get instance =>
      ServiceLocator.instance.tryGet<AccountStore>() ??
      (_instance ??= AccountStore._internal());

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('AccountStore');
  final ConfigManager _config = ConfigManager.instance;

  /// 账户列表存储键
  static const String _accountsKey = ConfigKeys.accounts;

  /// 选中账户 ID 存储键
  static const String _selectedAccountKey = ConfigKeys.selectedAccount;

  /// 敏感凭据存储键（加密存储）
  static const String _credentialsKey = 'auth_credentials_encrypted';

  /// 保存账户列表
  ///
  /// 将账户列表序列化为 JSON 并存储到配置中。
  /// 敏感字段（accessToken, refreshToken）会单独加密存储。
  Future<void> saveAccounts(List<Account> accounts) async {
    try {
      // 分离敏感字段与非敏感字段
      final accountsJson = <Map<String, dynamic>>[];
      final credentialsMap = <String, Map<String, String?>>{};

      for (final account in accounts) {
        final accountJson = account.toJson();

        // 提取敏感字段
        credentialsMap[account.id] = {
          'accessToken': account.accessToken,
          'refreshToken': account.refreshToken,
        };

        // 移除敏感字段后存储
        accountJson.remove('accessToken');
        accountJson.remove('refreshToken');
        accountsJson.add(accountJson);
      }

      // 保存非敏感字段
      await _config.set(_accountsKey, accountsJson);

      // 加密保存敏感字段
      await _saveCredentials(credentialsMap);

      _logger.info('保存了 ${accounts.length} 个账户');
    } catch (e, stackTrace) {
      _logger.error('保存账户失败', e, stackTrace);
      rethrow;
    }
  }

  /// 加载账户列表
  ///
  /// 从配置中读取账户 JSON，并合并加密存储的敏感字段。
  Future<List<Account>> loadAccounts() async {
    try {
      final accountsJson = _config.get<List<dynamic>>(
        _accountsKey,
        defaultValue: [],
      );

      if (accountsJson == null || accountsJson.isEmpty) {
        return [];
      }

      // 加载敏感凭据
      final credentialsMap = await _loadCredentials();

      // 合并敏感字段到账户对象
      final accounts = accountsJson.map((json) {
        final accountJson = Map<String, dynamic>.from(json as Map);
        final accountId = accountJson['id'] as String;

        // 合并敏感字段
        final credentials = credentialsMap[accountId];
        if (credentials != null) {
          accountJson['accessToken'] = credentials['accessToken'];
          accountJson['refreshToken'] = credentials['refreshToken'];
        }

        return Account.fromJson(accountJson);
      }).toList();

      _logger.info('加载了 ${accounts.length} 个账户');
      return accounts;
    } catch (e, stackTrace) {
      _logger.error('加载账户失败', e, stackTrace);
      return [];
    }
  }

  /// 保存选中的账户 ID
  Future<void> saveSelectedAccountId(String? accountId) async {
    try {
      if (accountId != null) {
        await _config.setString(_selectedAccountKey, accountId);
      } else {
        await _config.remove(_selectedAccountKey);
      }
    } catch (e) {
      _logger.warn('保存选中账户 ID 失败: $e');
    }
  }

  /// 加载选中的账户 ID
  String? loadSelectedAccountId() {
    return _config.getString(_selectedAccountKey);
  }

  /// 清除所有账户数据
  Future<void> clearAll() async {
    try {
      await _config.set(_accountsKey, []);
      await _config.remove(_selectedAccountKey);
      await _config.remove(_credentialsKey);
      _logger.info('已清除所有账户数据');
    } catch (e) {
      _logger.warn('清除账户数据失败: $e');
    }
  }

  /// 加密保存敏感凭据
  Future<void> _saveCredentials(Map<String, Map<String, String?>> credentialsMap) async {
    try {
      final jsonStr = jsonEncode(credentialsMap);
      final encrypted = CryptoUtil.encryptString(jsonStr);
      await _config.setString(_credentialsKey, encrypted);
    } catch (e) {
      _logger.warn('加密保存凭据失败: $e');
    }
  }

  /// 加载并解密敏感凭据
  Future<Map<String, Map<String, String?>>> _loadCredentials() async {
    try {
      final encrypted = _config.getString(_credentialsKey);
      if (encrypted == null || encrypted.isEmpty) {
        return {};
      }

      final jsonStr = CryptoUtil.decryptString(encrypted);
      if (jsonStr == null) {
        _logger.warn('凭据解密失败，可能密钥已变更');
        return {};
      }

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) {
        final Map<String, dynamic> map = value as Map<String, dynamic>;
        return MapEntry(key, {
          'accessToken': map['accessToken'] as String?,
          'refreshToken': map['refreshToken'] as String?,
        });
      });
    } catch (e) {
      _logger.warn('加载凭据失败: $e');
      return {};
    }
  }
}
