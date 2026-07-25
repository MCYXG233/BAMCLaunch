// Riverpod 与 ServiceLocator 桥接
//
// 本文件提供 Riverpod Provider 与 ServiceLocator 的适配层，使得：
// 1. 业务逻辑仍通过 ServiceLocator 注册/获取（保留现有 56+ 调用点）
// 2. UI 层可选择用 Riverpod ref.watch(serviceProvider<T>()) 访问
//
// ## 使用场景
//
// - 旧代码（setState、Provider）：继续用 ServiceLocator.instance.get<T>()
// - 新代码（ConsumerWidget）：用 ref.watch(serviceProvider<T>())
//
// ## 迁移策略
//
// 阶段 3.2：在 ServiceLocator 之上提供桥接（不破坏旧代码）
// 阶段 4.x：逐步迁移 UI 层到 Riverpod
// 阶段 5.x：评估是否彻底废弃 ServiceLocator（暂不决定）

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_locator.dart';

/// 创建访问 ServiceLocator 注册服务的 Provider
///
/// 每个服务实例化一个 Provider，通过 [Provider] 包装 ServiceLocator 的 `get<T>()`。
/// 缺点：每次 watch 都重新调用 get()。若服务需要 ref.listen 自动响应，
/// 改用 ChangeNotifierProvider 或 NotifierProvider（后续迁移考虑）。
Provider<T> serviceProvider<T extends Object>({String? name}) {
  return Provider<T>(
    name: name ?? 'ServiceLocator:$T',
    (ref) => ServiceLocator.instance.get<T>(),
  );
}

/// 创建可选服务 Provider（服务可能未注册时返回 null）
Provider<T?> optionalServiceProvider<T extends Object>({String? name}) {
  return Provider<T?>(
    name: name ?? 'ServiceLocator?$T',
    (ref) => ServiceLocator.instance.tryGet<T>(),
  );
}
