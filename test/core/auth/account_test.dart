import 'package:flutter_test/flutter_test.dart';
import 'package:bamclauncher/core/auth/models/account.dart';

void main() {
  group('Account', () {
    test('creates offline account', () {
      final account = Account(
        id: 'test-id',
        username: 'TestPlayer',
        type: AccountType.offline,
      );
      
      expect(account.id, 'test-id');
      expect(account.username, 'TestPlayer');
      expect(account.type, AccountType.offline);
      expect(account.isSelected, false);
      expect(account.tokenData, isNull);
      expect(account.profile, isNull);
    });

    test('creates microsoft account with token', () {
      final token = TokenData(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresAt: DateTime(2026, 12, 31),
      );
      
      final account = Account(
        id: 'ms-id',
        username: 'MSPlayer',
        type: AccountType.microsoft,
        tokenData: token,
      );
      
      expect(account.type, AccountType.microsoft);
      expect(account.tokenData, isNotNull);
      expect(account.tokenData!.accessToken, 'test-access-token');
    });

    test('toJson and fromJson roundtrip', () {
      final token = TokenData(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime(2026, 6, 15),
      );
      
      final profile = MinecraftProfile(
        id: 'profile-id',
        name: 'PlayerName',
        skinUrl: 'https://example.com/skin.png',
      );
      
      final original = Account(
        id: 'account-id',
        username: 'TestUser',
        type: AccountType.microsoft,
        tokenData: token,
        profile: profile,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime(2026, 5, 1),
        isSelected: true,
      );
      
      final json = original.toJson();
      final restored = Account.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.type, original.type);
      expect(restored.tokenData!.accessToken, original.tokenData!.accessToken);
      expect(restored.tokenData!.refreshToken, original.tokenData!.refreshToken);
      expect(restored.profile!.id, original.profile!.id);
      expect(restored.profile!.name, original.profile!.name);
      expect(restored.profile!.skinUrl, original.profile!.skinUrl);
      expect(restored.isSelected, original.isSelected);
    });

    test('copyWith creates new instance with updated values', () {
      final account = Account(
        id: 'original-id',
        username: 'OriginalName',
        type: AccountType.offline,
      );
      
      final updated = account.copyWith(
        username: 'NewName',
        isSelected: true,
      );
      
      expect(updated.id, 'original-id');
      expect(updated.username, 'NewName');
      expect(updated.isSelected, true);
      expect(updated.type, AccountType.offline);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-id',
        'username': 'TestUser',
        'type': 0, // AccountType.offline
        'createdAt': '2026-01-01T00:00:00.000',
      };
      
      final account = Account.fromJson(json);
      
      expect(account.id, 'test-id');
      expect(account.tokenData, isNull);
      expect(account.profile, isNull);
      expect(account.lastLogin, isNull);
      expect(account.isSelected, false);
      expect(account.serverUrl, isNull);
    });
  });

  group('TokenData', () {
    test('creates token data', () {
      final token = TokenData(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime(2026, 12, 31),
      );
      
      expect(token.accessToken, 'access-token');
      expect(token.refreshToken, 'refresh-token');
      expect(token.isExpired, false);
    });

    test('isExpired returns true for past date', () {
      final token = TokenData(
        accessToken: 'expired-token',
        expiresAt: DateTime(2020, 1, 1),
      );
      
      expect(token.isExpired, true);
    });

    test('toJson and fromJson roundtrip', () {
      final original = TokenData(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        expiresAt: DateTime(2026, 6, 15, 12, 30),
      );
      
      final json = original.toJson();
      final restored = TokenData.fromJson(json);
      
      expect(restored.accessToken, original.accessToken);
      expect(restored.refreshToken, original.refreshToken);
      expect(restored.expiresAt, original.expiresAt);
    });
  });

  group('MinecraftProfile', () {
    test('creates profile with required fields', () {
      final profile = MinecraftProfile(
        id: 'uuid-123',
        name: 'Steve',
      );
      
      expect(profile.id, 'uuid-123');
      expect(profile.name, 'Steve');
      expect(profile.skinUrl, isNull);
      expect(profile.capeUrl, isNull);
      expect(profile.textures, isNull);
    });

    test('creates profile with all fields', () {
      final profile = MinecraftProfile(
        id: 'uuid-456',
        name: 'Alex',
        skinUrl: 'https://example.com/skin.png',
        capeUrl: 'https://example.com/cape.png',
        textures: {'skin': 'texture-data'},
      );
      
      expect(profile.skinUrl, 'https://example.com/skin.png');
      expect(profile.capeUrl, 'https://example.com/cape.png');
      expect(profile.textures, {'skin': 'texture-data'});
    });

    test('toJson and fromJson roundtrip', () {
      final original = MinecraftProfile(
        id: 'profile-uuid',
        name: 'TestPlayer',
        skinUrl: 'https://textures.minecraft.net/skin',
        capeUrl: 'https://textures.minecraft.net/cape',
        textures: {'SKIN': 'url1', 'CAPE': 'url2'},
      );
      
      final json = original.toJson();
      final restored = MinecraftProfile.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.skinUrl, original.skinUrl);
      expect(restored.capeUrl, original.capeUrl);
      expect(restored.textures, original.textures);
    });
  });
}
