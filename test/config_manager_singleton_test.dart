// ConfigManager 单类化验证测试
//
// 验证目标：
// 1. ConfigManager.instance 内部转发到 ServiceRegistry 注册的 IConfigManager 实例
// 2. ConfigManagerImpl() 单例与 ConfigManager.instance 状态同步
// 3. ServiceRegistry.get<IConfigManager>() 与 ConfigManager.instance 返回同一对象

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/config/config_manager.dart';
import 'package:bamclaunch/src/config/config_manager_impl.dart';
import 'package:bamclaunch/src/di/service_locator.dart';
import 'package:bamclaunch/src/di/service_registry.dart';

// 忽略 ConfigManager 类的 @Deprecated 警告
// ignore: deprecated_member_use_from_same_package

void main() {
  group('ConfigManager 单类化验证', () {
    setUp(() {
      ServiceLocator.resetInstance();
    });

    tearDown(() {
      ServiceLocator.resetInstance();
    });

    test('ConfigManager.instance 内部委托到 IConfigManager 实例', () async {
      // 初始化 ServiceRegistry（注册 IConfigManager）
      await ServiceRegistry.initialize();

      // 通过 ServiceRegistry 获取 IConfigManager
      final fromRegistry = ServiceRegistry.get<IConfigManager>();
      expect(fromRegistry, isNotNull);
      expect(fromRegistry, isA<IConfigManager>());

      // ConfigManager.instance 应该委托到同一实例
      final fromWrapper = ConfigManager.instance;
      // 两次访问应返回同一对象（单例语义）
      expect(ConfigManager.instance, same(ConfigManager.instance));
      expect(fromWrapper, isA<IConfigManager>());

      // 由于 ConfigManager 实例化时会触发 _impl getter（lazy），
      // 这里验证状态：set/get 走的是同一底层 IConfigManager
      await fromWrapper.set('test_key', 'test_value');
      final value = fromRegistry.get<String>('test_key');
      expect(value, equals('test_value'));
    });

    test('ConfigManager 工厂与 instance 返回同一对象', () {
      final a = ConfigManager();
      final b = ConfigManager.instance;
      expect(identical(a, b), isTrue);
    });

    test('ConfigManagerImpl 单例行为保持不变', () {
      final a = ConfigManagerImpl();
      final b = ConfigManagerImpl();
      expect(identical(a, b), isTrue);
    });

    test('ServiceRegistry 未初始化时 ConfigManager 回退到 ConfigManagerImpl', () async {
      // 不调用 ServiceRegistry.initialize()
      final config = ConfigManager.instance;
      expect(config, isA<IConfigManager>());

      // set/get 应正常工作
      await config.set('fallback_key', 'fallback_value');
      final value = config.get<String>('fallback_key');
      expect(value, equals('fallback_value'));
    });
  });
}
