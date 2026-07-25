import '../../system/log_manager.dart';
import '../../system/system_diagnostics.dart';
import '../service_locator.dart';

/// 系统级服务注册
void registerSystemRegistry(ServiceLocator locator) {
  // LogManager - 日志管理器
  locator.registerLazySingleton<LogManager>(() => LogManager.instance);

  // SystemDiagnostics - 系统诊断
  locator.registerLazySingleton<SystemDiagnostics>(
    () => SystemDiagnostics.instance,
  );
}
