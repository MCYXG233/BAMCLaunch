// BAMCLaunch 核心 Provider 定义
//
// 本文件集中定义全局 Provider，配合 ServiceLocator 形成完整的 DI 体系：
// - ServiceLocator：服务（单例、副作用、长生命周期对象）
// - Riverpod Provider：状态（UI 状态、可观察数据）
//
// ## 引入规则
//
// 新功能模块应通过本文件定义 Provider，并在 UI 中使用 ConsumerWidget。
// 旧代码（setState + Provider）可保持现状，仅在新功能开发时迁移。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_manager.dart';
import '../core/logger.dart';
import '../event/event_bus.dart';
import '../ui/theme/theme_manager.dart';

/// ThemeManager 单例 Provider
///
/// ThemeManager 是 ChangeNotifier，使用 ChangeNotifierProvider 包装。
/// 已订阅 ThemeManager 的旧代码继续通过 Provider.of<ThemeManager>(context) 工作，
/// 新代码应改用 ref.watch(themeManagerProvider)。
final themeManagerProvider = ChangeNotifierProvider<ThemeManager>((ref) {
  return ThemeManager();
});

/// 当前选中的实例索引 Provider
///
/// 用于首页 / 库页面之间的选中状态共享。
/// TODO: 后续迁移 BAMainPage._selectedInstanceIndex 时启用
final selectedInstanceIndexProvider = StateProvider<int>((ref) => 0);

/// Logger Provider（直接委托给 Logger.instance，避免依赖 ServiceLocator）
///
/// Logger 是项目启动最早初始化的单例，无需经过 ServiceLocator 注册。
/// 新代码（ConsumerWidget）用 ref.watch(loggerProvider) 获取。
final loggerProvider = Provider<Logger>((ref) => Logger.instance);

/// EventBus Provider（直接委托给 EventBus.instance）
final eventBusProvider = Provider<EventBus>((ref) => EventBus.instance);

/// ConfigManager Provider（直接委托给 ConfigManager.instance）
final configManagerProvider = Provider<ConfigManager>(
  (ref) => ConfigManager.instance,
);
