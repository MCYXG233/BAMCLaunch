import '../config/i_config_manager.dart';
import '../logger/i_logger.dart';
import 'package:collection/collection.dart';
import 'models/account.dart';
import 'interfaces/i_authenticator.dart';
import 'implementations/offline_authenticator.dart';
import 'implementations/microsoft_authenticator.dart';

class AccountManager {
  final IConfigManager _configManager;
  final ILogger _logger;
  final List<Account> _accounts = [];
  Account? _selectedAccount;

  AccountManager(this._configManager, this._logger);

  Future<void> initialize() async {
    await _loadAccounts();
    _logger.info('账户管理器初始化完成，已加载 ${_accounts.length} 个账户');
  }

  Future<void> _loadAccounts() async {
    final accountsJson =
        await _configManager.loadConfig('accounts', decrypt: true);

    if (accountsJson != null) {
      try {
        List<dynamic> accountsList = accountsJson as List<dynamic>;
        _accounts.clear();

        for (var accountJson in accountsList) {
          Account account = Account.fromJson(accountJson);
          _accounts.add(account);

          if (account.isSelected) {
            _selectedAccount = account;
          }
        }
      } catch (e) {
        _logger.error('加载账户失败: $e');
      }
    }
  }

  Future<void> _saveAccounts() async {
    List<Map<String, dynamic>> accountsJson =
        _accounts.map((account) => account.toJson()).toList();
    await _configManager.saveConfig('accounts', accountsJson, encrypt: true);
    _logger.info('账户已保存，共 ${_accounts.length} 个账户');
  }

  Future<Account> addAccount(Account account) async {
    _accounts.removeWhere((a) => a.id == account.id);
    _accounts.add(account);
    await _saveAccounts();
    _logger.info('添加账户: ${account.username} (${account.type})');
    return account;
  }

  Future<void> removeAccount(String accountId) async {
    Account? removedAccount =
        _accounts.firstWhereOrNull((a) => a.id == accountId);

    _accounts.removeWhere((a) => a.id == accountId);

    if (_selectedAccount?.id == accountId) {
      _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
      if (_selectedAccount != null) {
        _selectedAccount = _selectedAccount!.copyWith(isSelected: true);
      }
    }

    await _saveAccounts();
    if (removedAccount != null) {
      _logger.info('删除账户: ${removedAccount.username} (${removedAccount.type})');
    }
  }

  Future<void> selectAccount(String accountId) async {
    Account? account =
        _accounts.firstWhereOrNull((a) => a.id == accountId);

    if (account == null) {
      _logger.error('账户不存在: $accountId');
      return;
    }

    for (var a in _accounts) {
      a.isSelected = a.id == accountId;
    }

    _selectedAccount = account.copyWith(isSelected: true);
    await _saveAccounts();
    _logger.info('选择账户: ${account.username} (${account.type})');
  }

  Account? get selectedAccount => _selectedAccount;

  List<Account> get accounts => List.unmodifiable(_accounts);

  IAuthenticator getAuthenticator(AccountType accountType) {
    switch (accountType) {
      case AccountType.offline:
        return OfflineAuthenticator();
      case AccountType.microsoft:
        return MicrosoftAuthenticator();
    }
  }

  Future<Account> login(
      Map<String, dynamic> credentials, AccountType accountType) async {
    IAuthenticator authenticator = getAuthenticator(accountType);
    Account account = await authenticator.login(credentials);
    return await addAccount(account);
  }

  Future<void> logout(String accountId) async {
    Account? account =
        _accounts.firstWhereOrNull((a) => a.id == accountId);
    if (account == null) {
      _logger.error('账户不存在: $accountId');
      return;
    }
    IAuthenticator authenticator = getAuthenticator(account.type);
    await authenticator.logout(account);
    _logger.info('登出账户: ${account.username} (${account.type})');
  }

  Future<Account?> refreshAccount(String accountId) async {
    Account? account =
        _accounts.firstWhereOrNull((a) => a.id == accountId);
    if (account == null) {
      _logger.error('账户不存在: $accountId');
      return null;
    }
    IAuthenticator authenticator = getAuthenticator(account.type);

    if (!authenticator.canRefresh(account)) {
      _logger.warn('账户 ${account.username} 无法刷新');
      return null;
    }

    try {
      Account refreshedAccount = await authenticator.refresh(account);
      return await addAccount(refreshedAccount);
    } catch (e) {
      _logger.error('刷新账户 ${account.username} 失败: $e');
      return null;
    }
  }

  Future<void> refreshAllAccounts() async {
    for (Account account in _accounts) {
      await refreshAccount(account.id);
    }
  }

  Account? getAccountById(String accountId) {
    return _accounts.firstWhereOrNull((a) => a.id == accountId);
  }

  bool hasAccounts() {
    return _accounts.isNotEmpty;
  }
}
