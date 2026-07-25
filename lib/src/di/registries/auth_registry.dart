import '../../auth/auth_manager.dart';
import '../../auth/authlib_injector.dart';
import '../../auth/authlib_login.dart';
import '../../auth/local_yggdrasil_server.dart';
import '../service_locator.dart';

/// 认证服务注册
///
/// 注册 Authlib 注入、Authlib 登录、本地 Yggdrasil 服务器等认证相关服务。
void registerAuthRegistry(ServiceLocator locator) {
  // AuthManager - 认证管理器
  locator.registerLazySingleton<AuthManager>(() => AuthManager.instance);

  // AuthlibInjector - Authlib 注入器
  locator.registerLazySingleton<AuthlibInjector>(
    () => AuthlibInjector.instance,
  );

  // AuthlibLoginManager - Authlib 登录管理器
  locator.registerLazySingleton<AuthlibLoginManager>(
    () => AuthlibLoginManager.instance,
  );

  // LocalYggdrasilServer - 本地 Yggdrasil 服务器
  locator.registerLazySingleton<LocalYggdrasilServer>(
    () => LocalYggdrasilServer.instance,
  );
}
