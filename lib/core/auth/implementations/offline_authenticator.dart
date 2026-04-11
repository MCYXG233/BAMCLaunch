import 'dart:math';
import '../models/account.dart';
import '../interfaces/i_authenticator.dart';

class OfflineAuthenticator implements IAuthenticator {
  @override
  AccountType get accountType => AccountType.offline;

  @override
  Future<Account> login(Map<String, dynamic> credentials) async {
    String username = credentials['username'] as String;
    
    if (username.isEmpty) {
      throw Exception('用户名不能为空');
    }

    String offlineUuid = _generateOfflineUuid(username);
    
    TokenData tokenData = TokenData(
      accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );

    MinecraftProfile profile = MinecraftProfile(
      id: offlineUuid,
      name: username,
    );

    return Account(
      id: offlineUuid,
      username: username,
      type: AccountType.offline,
      tokenData: tokenData,
      profile: profile,
      lastLogin: DateTime.now(),
    );
  }

  @override
  Future<Account> refresh(Account account) async {
    TokenData newTokenData = TokenData(
      accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );

    return account.copyWith(
      tokenData: newTokenData,
      lastLogin: DateTime.now(),
    );
  }

  @override
  Future<MinecraftProfile> getProfile(Account account) async {
    return account.profile!;
  }

  @override
  Future<void> logout(Account account) async {
    
  }

  @override
  bool canRefresh(Account account) {
    return true;
  }

  String _generateOfflineUuid(String username) {
    String offlinePrefix = 'OfflinePlayer:';
    List<int> bytes = (offlinePrefix + username).codeUnits;
    
    Random random = Random();
    List<int> uuidBytes = List.generate(16, (index) => random.nextInt(256));
    
    for (int i = 0; i < bytes.length && i < uuidBytes.length; i++) {
      uuidBytes[i] ^= bytes[i];
    }
    
    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30;
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80;

    String uuid = '';
    for (int i = 0; i < uuidBytes.length; i++) {
      uuid += uuidBytes[i].toRadixString(16).padLeft(2, '0');
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        uuid += '-';
      }
    }
    
    return uuid;
  }
}