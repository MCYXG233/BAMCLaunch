import '../platform/platform.dart';
import '../logger/logger.dart';
import '../config/config.dart';
import 'models/account.dart';
import 'interfaces/i_authenticator.dart';
import 'implementations/offline_authenticator.dart';
import 'implementations/microsoft_authenticator.dart';
import 'account_manager.dart';

/// 导出认证相关的模型和接口
export 'models/account.dart';
export 'interfaces/i_authenticator.dart';
export 'implementations/offline_authenticator.dart';
export 'implementations/microsoft_authenticator.dart';
export 'account_manager.dart';

/// 全局账户管理器单例
/// 用于管理用户账户和认证相关操作
final AccountManager accountManager = AccountManager(
  configManager,  // 配置管理器，用于存储账户信息
  logger,         // 日志记录器，用于记录认证过程
);