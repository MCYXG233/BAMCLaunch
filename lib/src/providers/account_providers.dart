import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../account/account_manager.dart';
import '../account/account.dart';
import 'service_locator_provider.dart';

/// AccountManager Provider
///
/// 提供账户管理服务
final accountManagerProvider = Provider<AccountManager>((ref) {
  final locator = ref.watch(serviceLocatorProvider);
  return locator.get<AccountManager>();
});

/// 当前激活账户 Provider
///
/// 监听账户管理器的当前账户变化
final currentAccountProvider = FutureProvider<Account?>((ref) async {
  final manager = ref.watch(accountManagerProvider);
  return manager.getSelectedAccount();
});

/// 账户列表 Provider
///
/// 获取所有账户列表
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final manager = ref.watch(accountManagerProvider);
  return manager.getAccounts();
});
