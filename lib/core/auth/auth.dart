import '../platform/platform.dart';
import '../logger/logger.dart';
import '../config/config.dart';
import 'models/account.dart';
import 'interfaces/i_authenticator.dart';
import 'implementations/offline_authenticator.dart';
import 'implementations/microsoft_authenticator.dart';
import 'account_manager.dart';

export 'models/account.dart';
export 'interfaces/i_authenticator.dart';
export 'implementations/offline_authenticator.dart';
export 'implementations/microsoft_authenticator.dart';
export 'account_manager.dart';

final AccountManager accountManager = AccountManager(
  configManager,
  logger,
);