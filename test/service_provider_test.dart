// Riverpod ↔ ServiceLocator 桥接测试
//
// 验证目标：
// 1. serviceProvider<T>() 返回的 Provider 能从 ServiceLocator 获取实例
// 2. optionalServiceProvider<T>() 在服务未注册时返回 null
// 3. 核心 Provider（loggerProvider / eventBusProvider / configManagerProvider）能访问

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bamclaunch/src/core/logger.dart';
import 'package:bamclaunch/src/di/providers.dart';
import 'package:bamclaunch/src/di/service_locator.dart';
import 'package:bamclaunch/src/di/service_provider.dart';

void main() {
  group('serviceProvider<T> 验证', () {
    test('工厂函数返回 Provider<T>', () {
      final provider = serviceProvider<int>(name: 'test:int');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ServiceLocator 未注册 int 类型，应当抛异常
      expect(() => container.read(provider), throwsA(anything));
    });

    test('optionalServiceProvider 在未注册时返回 null', () {
      final provider = optionalServiceProvider<int>(name: 'test:int');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(provider), isNull);
    });

    test('同一 Provider 多次读取返回同一实例', () {
      // 用 ServiceLocator 注册一个测试服务
      ServiceLocator.instance.registerSingleton<String>('hello');

      final provider = serviceProvider<String>(name: 'test:string');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(provider);
      final b = container.read(provider);
      expect(a, 'hello');
      expect(identical(a, b), isTrue);
    });
  });

  group('核心 Provider 桥接验证', () {
    test('loggerProvider 通过 ProviderContainer 访问', () {
      // Logger 单例已经存在
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final logger = container.read(loggerProvider);
      expect(logger, isA<Object>());
      expect(logger.runtimeType.toString(), 'Logger');
    });

    test('configManagerProvider 通过 ProviderContainer 访问', () {
      // ConfigManager 单例已经存在
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cm = container.read(configManagerProvider);
      expect(cm, isA<Object>());
    });

    test('eventBusProvider 通过 ProviderContainer 访问', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final eb = container.read(eventBusProvider);
      expect(eb, isA<Object>());
    });

    test('loggerProvider 返回单例 Logger.instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final fromProvider = container.read(loggerProvider);
      expect(fromProvider, same(Logger.instance));
    });
  });
}
