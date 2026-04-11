import '../models/account.dart';

abstract class IAuthenticator {
  Future<Account> login(Map<String, dynamic> credentials);

  Future<Account> refresh(Account account);

  Future<MinecraftProfile> getProfile(Account account);

  Future<void> logout(Account account);

  bool canRefresh(Account account);

  AccountType get accountType;
}