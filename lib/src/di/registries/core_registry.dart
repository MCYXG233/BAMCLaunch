import '../../event/event_bus.dart';
import '../../core/logger.dart';
import '../../core/error_handler.dart';
import '../../core/privacy_manager.dart';
import '../service_locator.dart';

/// 核心基础设施注册
///
/// 注册无外部依赖的基础服务：EventBus / Logger / ErrorHandler / PrivacyManager。
void registerCoreRegistry(ServiceLocator locator) {
  // EventBus - 全局事件总线，几乎所有模块都依赖
  locator.registerLazySingleton<EventBus>(() => EventBus.instance);

  // Logger - 日志系统
  locator.registerLazySingleton<Logger>(() => Logger.instance);

  // ErrorHandler - 全局异常处理（依赖 Logger, EventBus）
  locator.registerLazySingleton<ErrorHandler>(() => ErrorHandler.instance);

  // PrivacyManager - 隐私管理
  locator.registerLazySingleton<PrivacyManager>(() => PrivacyManager());
}
