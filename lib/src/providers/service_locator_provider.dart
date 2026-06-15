import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/service_locator.dart';

/// ServiceLocator Provider
/// 
/// 提供 ServiceLocator 实例，用于获取其他服务依赖
final serviceLocatorProvider = Provider<ServiceLocator>((ref) {
  throw UnimplementedError(
    'ServiceLocator must be overridden in ProviderScope.overrides',
  );
});
