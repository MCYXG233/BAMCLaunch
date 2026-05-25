import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/config/config_manager_impl.dart';
import 'package:bamclaunch/src/config/config_keys.dart';
import 'package:bamclaunch/src/config/crypto_util.dart';

void main() {
  group('CryptoUtil Tests', () {
    test('encrypt and decrypt should work correctly', () {
      const plaintext = 'Hello, World!';
      final encrypted = CryptoUtil.encryptString(plaintext);
      final decrypted = CryptoUtil.decryptString(encrypted);

      expect(decrypted, equals(plaintext));
      expect(encrypted, isNot(equals(plaintext)));
    });

    test('decrypt invalid data should return null', () {
      final decrypted = CryptoUtil.decryptString('invalid_data');
      expect(decrypted, isNull);
    });

    test('different passwords should produce different results', () {
      const plaintext = 'Secret Message';
      final encrypted1 = CryptoUtil.encryptString(plaintext, password: 'pass1');
      final encrypted2 = CryptoUtil.encryptString(plaintext, password: 'pass2');

      expect(encrypted1, isNot(equals(encrypted2)));
    });
  });

  group('ConfigManager Tests', () {
    late ConfigManagerImpl configManager;

    setUp(() {
      configManager = ConfigManagerImpl();
      configManager.setAutoSave(false);
    });

    tearDown(() {
      configManager.clear();
    });

    test('set and get should work with different types', () async {
      await configManager.set('string_key', 'test_value');
      await configManager.set('int_key', 42);
      await configManager.set('double_key', 3.14);
      await configManager.set('bool_key', true);

      expect(configManager.get<String>('string_key'), equals('test_value'));
      expect(configManager.get<int>('int_key'), equals(42));
      expect(configManager.get<double>('double_key'), equals(3.14));
      expect(configManager.get<bool>('bool_key'), equals(true));
    });

    test(
      'get with default value should return default when key not exists',
      () {
        expect(
          configManager.get<String>('non_existent', defaultValue: 'default'),
          equals('default'),
        );
        expect(
          configManager.get<int>('non_existent', defaultValue: 100),
          equals(100),
        );
      },
    );

    test('setEncrypted and getEncrypted should work correctly', () async {
      const secret = 'my_secret_password';
      await configManager.setEncrypted('secret_key', secret);
      final decrypted = await configManager.getEncrypted('secret_key');

      expect(decrypted, equals(secret));
    });

    test('remove should delete the key', () async {
      await configManager.set('test_key', 'test_value');
      expect(configManager.get<String>('test_key'), isNotNull);

      await configManager.remove('test_key');
      expect(configManager.get<String>('test_key'), isNull);
    });

    test('clear should remove all keys', () async {
      await configManager.set('key1', 'value1');
      await configManager.set('key2', 'value2');

      expect(configManager.get<String>('key1'), isNotNull);
      expect(configManager.get<String>('key2'), isNotNull);

      await configManager.clear();

      expect(configManager.get<String>('key1'), isNull);
      expect(configManager.get<String>('key2'), isNull);
    });

    test('configChanges should emit events when config changes', () async {
      final events = <String>[];
      final subscription = configManager.configChanges.listen(events.add);

      await configManager.set('test_key', 'value');
      await configManager.set('another_key', 42);

      expect(events, containsAll(['test_key', 'another_key']));

      await subscription.cancel();
    });

    test('ConfigKeys should be accessible', () {
      expect(ConfigKeys.theme, isNotNull);
      expect(ConfigKeys.downloadPath, isNotNull);
      expect(ConfigKeys.javaPath, isNotNull);
      expect(ConfigKeys.accounts, isNotNull);
    });
  });
}
