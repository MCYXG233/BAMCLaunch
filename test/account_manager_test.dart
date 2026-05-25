import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/account/account.dart';
import 'package:bamclaunch/src/account/account_manager.dart';
import 'package:bamclaunch/src/config/config_manager.dart';
import 'package:bamclaunch/src/config/config_keys.dart';
import 'package:bamclaunch/src/event/event_bus.dart';

/// 测试用的配置管理器
class MockConfigManager implements IConfigManager {
  final Map<String, dynamic> _config = {};
  final StreamController<String> _configChangesController =
      StreamController<String>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  T? get<T>(String key, {T? defaultValue}) {
    final value = _config[key];
    if (value == null) return defaultValue;
    if (value is T) return value;
    return defaultValue;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _config[key] = value;
    _configChangesController.add(key);
  }

  @override
  Future<void> setEncrypted(String key, String value) async {
    _config['${ConfigKeys.encryptedPrefix}$key'] = value;
  }

  @override
  Future<String?> getEncrypted(String key) async {
    return _config['${ConfigKeys.encryptedPrefix}$key'] as String?;
  }

  @override
  String? getString(String key, {String? defaultValue}) {
    return get<String>(key, defaultValue: defaultValue);
  }

  @override
  Future<void> setString(String key, String value) async {
    await set(key, value);
  }

  @override
  int? getInt(String key, {int? defaultValue}) {
    return get<int>(key, defaultValue: defaultValue);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await set(key, value);
  }

  @override
  bool? getBool(String key, {bool? defaultValue}) {
    return get<bool>(key, defaultValue: defaultValue);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await set(key, value);
  }

  @override
  Future<void> remove(String key) async {
    _config.remove(key);
    _configChangesController.add(key);
  }

  @override
  Future<void> clear() async {
    _config.clear();
  }

  @override
  Future<void> save() async {}

  @override
  Future<void> load() async {}

  @override
  Stream<String> get configChanges => _configChangesController.stream;
}

void main() {
  group('Account Tests', () {
    test('Account should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        uuid: 'test_uuid',
        type: AccountType.microsoft,
        skinUrl: 'http://example.com/skin.png',
        capeUrl: 'http://example.com/cape.png',
        createdAt: now,
        lastUsedAt: now,
      );

      final json = account.toJson();
      final reconstructed = Account.fromJson(json);

      expect(reconstructed.id, equals(account.id));
      expect(reconstructed.username, equals(account.username));
      expect(reconstructed.uuid, equals(account.uuid));
      expect(reconstructed.type, equals(account.type));
      expect(reconstructed.skinUrl, equals(account.skinUrl));
      expect(reconstructed.capeUrl, equals(account.capeUrl));
      expect(reconstructed.createdAt, equals(account.createdAt));
      expect(reconstructed.lastUsedAt, equals(account.lastUsedAt));
    });

    test('Account should handle null optional fields correctly', () {
      final now = DateTime.now();
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(account.uuid, isNull);
      expect(account.skinUrl, isNull);
      expect(account.capeUrl, isNull);

      final json = account.toJson();
      final reconstructed = Account.fromJson(json);

      expect(reconstructed.uuid, isNull);
      expect(reconstructed.skinUrl, isNull);
      expect(reconstructed.capeUrl, isNull);
    });

    test('Account avatarUrl should be generated correctly', () {
      final now = DateTime.now();
      final offlineAccount = Account(
        id: 'test_id',
        username: 'OfflineUser',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(offlineAccount.avatarUrl, contains('OfflineUser'));

      final microsoftAccount = Account(
        id: 'test_id_2',
        username: 'MicrosoftUser',
        uuid: 'test_uuid',
        type: AccountType.microsoft,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(microsoftAccount.avatarUrl, contains('test_uuid'));
    });

    test('copyWith should create a new instance with updated values', () {
      final now = DateTime.now();
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      final updated = account.copyWith(
        username: 'NewUsername',
        skinUrl: 'http://example.com/newskin.png',
      );

      expect(updated.username, equals('NewUsername'));
      expect(updated.skinUrl, equals('http://example.com/newskin.png'));
      expect(updated.id, equals(account.id));
      expect(updated, isNot(same(account)));
    });

    test('equality should work correctly', () {
      final now = DateTime.now();
      final account1 = Account(
        id: 'test_id',
        username: 'User1',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      final account2 = Account(
        id: 'test_id',
        username: 'User2',
        type: AccountType.microsoft,
        createdAt: now.add(const Duration(days: 1)),
        lastUsedAt: now.add(const Duration(days: 1)),
      );

      final account3 = Account(
        id: 'different_id',
        username: 'User1',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(account1, equals(account2));
      expect(account1.hashCode, equals(account2.hashCode));
      expect(account1, isNot(equals(account3)));
    });
  });

  group('AccountManager Tests', () {
    late AccountManager accountManager;
    late MockConfigManager configManager;
    late EventBus eventBus;

    setUp(() {
      AccountManager.reset();
      accountManager = AccountManager();
      configManager = MockConfigManager();
      eventBus = EventBus();
      accountManager.initialize(
        configManager: configManager,
        eventBus: eventBus,
      );
    });

    tearDown(() {
      accountManager.dispose();
      EventBus.reset();
    });

    test('addOfflineAccount should add a new account', () async {
      final account = await accountManager.addOfflineAccount('TestUser');

      expect(account.username, equals('TestUser'));
      expect(account.type, equals(AccountType.offline));

      final accounts = await accountManager.getAccounts();
      expect(accounts.length, equals(1));
      expect(accounts.first.id, equals(account.id));
    });

    test('addOfflineAccount should trim username', () async {
      final account = await accountManager.addOfflineAccount(
        '  UserWithSpace  ',
      );
      expect(account.username, equals('UserWithSpace'));
    });

    test('addOfflineAccount should throw error for empty username', () async {
      expect(
        () => accountManager.addOfflineAccount(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => accountManager.addOfflineAccount('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('selectAccount should select an existing account', () async {
      final account = await accountManager.addOfflineAccount('TestUser');
      await accountManager.selectAccount(account.id);

      final selected = await accountManager.getSelectedAccount();
      expect(selected, isNotNull);
      expect(selected?.id, equals(account.id));
    });

    test('selectAccount should throw error for non-existent account', () async {
      expect(
        () => accountManager.selectAccount('non_existent_id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateAccount should update account information', () async {
      final account = await accountManager.addOfflineAccount('TestUser');
      final updatedAccount = account.copyWith(
        username: 'UpdatedUser',
        skinUrl: 'http://example.com/skin.png',
      );

      await accountManager.updateAccount(updatedAccount);

      final accounts = await accountManager.getAccounts();
      final found = accounts.firstWhere((a) => a.id == account.id);
      expect(found.username, equals('UpdatedUser'));
      expect(found.skinUrl, equals('http://example.com/skin.png'));
    });

    test('updateAccount should throw error for non-existent account', () async {
      final now = DateTime.now();
      final fakeAccount = Account(
        id: 'fake_id',
        username: 'FakeUser',
        type: AccountType.offline,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(
        () => accountManager.updateAccount(fakeAccount),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removeAccount should remove an account', () async {
      final account = await accountManager.addOfflineAccount('TestUser');
      await accountManager.removeAccount(account.id);

      final accounts = await accountManager.getAccounts();
      expect(accounts.length, equals(0));
    });

    test('removeAccount should throw error for non-existent account', () async {
      expect(
        () => accountManager.removeAccount('non_existent_id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'removeAccount should deselect if selected account is removed',
      () async {
        final account = await accountManager.addOfflineAccount('TestUser');
        await accountManager.selectAccount(account.id);

        var selected = await accountManager.getSelectedAccount();
        expect(selected, isNotNull);

        await accountManager.removeAccount(account.id);

        selected = await accountManager.getSelectedAccount();
        expect(selected, isNull);
      },
    );

    test('accountsStream should emit updates when accounts change', () async {
      final accountsList = <List<Account>>[];
      final subscription = accountManager.accountsStream.listen(
        accountsList.add,
      );

      await accountManager.addOfflineAccount('User1');
      await accountManager.addOfflineAccount('User2');

      expect(accountsList.isNotEmpty, isTrue);
      expect(accountsList.last.length, equals(2));

      await subscription.cancel();
    });

    test('should handle multiple accounts correctly', () async {
      await accountManager.addOfflineAccount('User1');
      await accountManager.addOfflineAccount('User2');
      await accountManager.addOfflineAccount('User3');

      final accounts = await accountManager.getAccounts();
      expect(accounts.length, equals(3));
      expect(
        accounts.map((a) => a.username),
        containsAll(['User1', 'User2', 'User3']),
      );
    });

    test(
      'getSelectedAccount should return null when no account is selected',
      () async {
        final selected = await accountManager.getSelectedAccount();
        expect(selected, isNull);
      },
    );

    test('AccountType should work correctly', () {
      expect(AccountType.offline.name, equals('offline'));
      expect(AccountType.microsoft.name, equals('microsoft'));
      expect(AccountType.authlib.name, equals('authlib'));
    });
  });
}
