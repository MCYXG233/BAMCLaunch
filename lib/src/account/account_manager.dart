import 'dart:async';
import 'dart:convert';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import 'account.dart';

/// 账户管理器接口
abstract class IAccountManager {
  /// 获取所有账户
  Future<List<Account>> getAccounts();

  /// 获取当前选中的账户
  Future<Account?> getSelectedAccount();

  /// 选中账户
  Future<void> selectAccount(String accountId);

  /// 添加离线账户
  Future<Account> addOfflineAccount(String username);

  /// 添加微软账户
  Future<Account> addMicrosoftAccount(String username, String uuid);

  /// 更新账户
  Future<void> updateAccount(Account account);

  /// 删除账户
  Future<void> removeAccount(String accountId);

  /// 账户变更流
  Stream<List<Account>> get accountsStream;
}

/// 账户管理器实现类（单例）
class AccountManager implements IAccountManager {
  static AccountManager? _instance;

  factory AccountManager() => _instance ??= AccountManager._internal();

  AccountManager._internal();

  /// 获取单例实例
  static AccountManager get instance =>
      _instance ??= AccountManager._internal();

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// 配置管理器
  IConfigManager? _configManager;

  /// 事件总线
  EventBus? _eventBus;

  /// 账户缓存
  List<Account> _cachedAccounts = [];

  /// 账户变更流控制器
  StreamController<List<Account>>? _accountsStreamController;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化账户管理器
  Future<void> initialize({
    required IConfigManager configManager,
    required EventBus eventBus,
  }) async {
    if (_isInitialized) return;

    _configManager = configManager;
    _eventBus = eventBus;

    _accountsStreamController = StreamController<List<Account>>.broadcast();

    await _loadAccounts();

    _isInitialized = true;
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _configManager = ConfigManager.instance;
    _eventBus = EventBus.instance;
    _accountsStreamController = StreamController<List<Account>>.broadcast();

    await _loadAccounts();
    _isInitialized = true;
  }

  /// 从配置加载账户
  Future<void> _loadAccounts() async {
    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    final accountsJson = _configManager!.get<List<dynamic>>(
      ConfigKeys.accounts,
      defaultValue: [],
    );

    _cachedAccounts =
        accountsJson
            ?.map(
              (json) =>
                  Account.fromJson(Map<String, dynamic>.from(json as Map)),
            )
            .toList() ??
        [];
  }

  /// 保存账户到配置
  Future<void> _saveAccounts() async {
    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    final accountsJson = _cachedAccounts
        .map((account) => account.toJson())
        .toList();
    await _configManager!.set(ConfigKeys.accounts, accountsJson);
    _accountsStreamController?.add(_cachedAccounts);
  }

  @override
  Future<List<Account>> getAccounts() async {
    await _ensureInitialized();
    return List.unmodifiable(_cachedAccounts);
  }

  @override
  Future<Account?> getSelectedAccount() async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    final selectedId = _configManager!.get<String>(ConfigKeys.selectedAccount);
    if (selectedId == null) return null;

    try {
      return _cachedAccounts.firstWhere((account) => account.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> selectAccount(String accountId) async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    final oldAccountId = _configManager!.get<String>(ConfigKeys.selectedAccount);

    // 检查账户是否存在
    final accountExists = _cachedAccounts.any(
      (account) => account.id == accountId,
    );
    if (!accountExists) {
      throw ArgumentError('账户不存在: $accountId');
    }

    await _configManager!.set(ConfigKeys.selectedAccount, accountId);

    // 更新账户的最后使用时间
    final index = _cachedAccounts.indexWhere(
      (account) => account.id == accountId,
    );
    if (index != -1) {
      _cachedAccounts[index] = _cachedAccounts[index].copyWith(
        lastUsedAt: DateTime.now(),
      );
      await _saveAccounts();
    }

    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(
      SelectedAccountChangedEvent(
        newAccountId: accountId,
        oldAccountId: oldAccountId,
      ),
    );
  }

  @override
  Future<Account> addOfflineAccount(String username) async {
    await _ensureInitialized();

    if (username.trim().isEmpty) {
      throw ArgumentError('用户名不能为空');
    }

    final now = DateTime.now();
    final account = Account(
      id: _generateId(),
      username: username.trim(),
      type: AccountType.offline,
      createdAt: now,
      lastUsedAt: now,
    );

    _cachedAccounts.add(account);
    await _saveAccounts();

    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountAddedEvent(accountId: account.id));

    return account;
  }

  @override
  Future<Account> addMicrosoftAccount(String username, String uuid) async {
    await _ensureInitialized();

    if (username.trim().isEmpty) {
      throw ArgumentError('用户名不能为空');
    }
    if (uuid.trim().isEmpty) {
      throw ArgumentError('UUID不能为空');
    }

    // 检查是否已存在相同的微软账户
    final existingAccountIndex = _cachedAccounts.indexWhere(
      (acc) => acc.uuid == uuid && acc.type == AccountType.microsoft,
    );

    if (existingAccountIndex != -1) {
      // 更新现有账户
      final existingAccount = _cachedAccounts[existingAccountIndex];
      final updatedAccount = existingAccount.copyWith(
        username: username.trim(),
        lastUsedAt: DateTime.now(),
      );
      _cachedAccounts[existingAccountIndex] = updatedAccount;
      await _saveAccounts();

      if (_eventBus == null) {
        _eventBus = EventBus.instance;
      }
      _eventBus!.publish(AccountUpdatedEvent(accountId: updatedAccount.id));
      return updatedAccount;
    }

    final now = DateTime.now();
    final account = Account(
      id: _generateId(),
      username: username.trim(),
      uuid: uuid,
      type: AccountType.microsoft,
      createdAt: now,
      lastUsedAt: now,
    );

    _cachedAccounts.add(account);
    await _saveAccounts();

    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountAddedEvent(accountId: account.id));

    return account;
  }

  @override
  Future<void> updateAccount(Account account) async {
    await _ensureInitialized();

    final index = _cachedAccounts.indexWhere((a) => a.id == account.id);
    if (index == -1) {
      throw ArgumentError('账户不存在: ${account.id}');
    }

    _cachedAccounts[index] = account;
    await _saveAccounts();

    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountUpdatedEvent(accountId: account.id));
  }

  @override
  Future<void> removeAccount(String accountId) async {
    await _ensureInitialized();

    if (_configManager == null) {
      _configManager = ConfigManager.instance;
    }

    final index = _cachedAccounts.indexWhere(
      (account) => account.id == accountId,
    );
    if (index == -1) {
      throw ArgumentError('账户不存在: $accountId');
    }

    // 如果删除的是当前选中的账户，则取消选中
    final selectedId = _configManager!.get<String>(ConfigKeys.selectedAccount);
    if (selectedId == accountId) {
      await _configManager!.remove(ConfigKeys.selectedAccount);

      if (_eventBus == null) {
        _eventBus = EventBus.instance;
      }
      _eventBus!.publish(
        SelectedAccountChangedEvent(
          newAccountId: null,
          oldAccountId: selectedId,
        ),
      );
    }

    _cachedAccounts.removeAt(index);
    await _saveAccounts();

    if (_eventBus == null) {
      _eventBus = EventBus.instance;
    }
    _eventBus!.publish(AccountDeletedEvent(accountId: accountId));
  }

  @override
  Stream<List<Account>> get accountsStream {
    if (_accountsStreamController == null) {
      _accountsStreamController = StreamController<List<Account>>.broadcast();
    }
    return _accountsStreamController!.stream;
  }

  /// 生成唯一ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_cachedAccounts.length}';
  }

  /// 清理资源
  void dispose() {
    _accountsStreamController?.close();
    _accountsStreamController = null;
    _isInitialized = false;
    _configManager = null;
    _eventBus = null;
  }
}