// ServiceLocator 与 ServiceRegistry 测试
//
// 验证 DI 容器的核心行为：
// 1. 单例/懒加载/工厂 三种注册方式的区别
// 2. tryGet 不触发懒加载（避免循环依赖）
// 3. get 触发懒加载
// 4. reset 清空所有注册
// 5. isRegistered / unregister 行为

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/di/service_locator.dart';

class _FakeService {
  final int id;
  _FakeService(this.id);
}

class _OtherService {
  final String name;
  _OtherService(this.name);
}

void main() {
  late ServiceLocator locator;

  setUp(() {
    // 每个测试用独立的 ServiceLocator 实例
    ServiceLocator.resetInstance();
    locator = ServiceLocator.instance;
    locator.reset();
  });

  tearDown(() {
    locator.reset();
  });

  group('ServiceLocator 注册语义', () {
    test('registerSingleton 多次 get 返回同一实例', () {
      final instance = _FakeService(1);
      locator.registerSingleton<_FakeService>(instance);

      expect(locator.get<_FakeService>(), same(instance));
      expect(locator.get<_FakeService>(), same(instance));
    });

    test('registerLazySingleton 首次 get 创建实例并缓存', () {
      var factoryCalls = 0;
      locator.registerLazySingleton<_FakeService>(() {
        factoryCalls++;
        return _FakeService(42);
      });

      expect(factoryCalls, equals(0), reason: '注册不应触发工厂');
      expect(locator.get<_FakeService>().id, equals(42));
      expect(factoryCalls, equals(1));
      // 第二次 get 不应再调用工厂
      expect(locator.get<_FakeService>().id, equals(42));
      expect(factoryCalls, equals(1));
    });

    test('registerFactory 每次 get 创建新实例', () {
      var factoryCalls = 0;
      locator.registerFactory<_FakeService>(() {
        factoryCalls++;
        return _FakeService(factoryCalls);
      });

      final a = locator.get<_FakeService>();
      final b = locator.get<_FakeService>();
      expect(identical(a, b), isFalse, reason: 'factory 应返回新实例');
      expect(a.id, equals(1));
      expect(b.id, equals(2));
    });

    test('未注册类型 get 抛 StateError', () {
      expect(() => locator.get<_FakeService>(), throwsA(isA<StateError>()));
    });

    test('isRegistered 区分单例/懒加载/工厂', () {
      locator.registerSingleton<_FakeService>(_FakeService(1));
      locator.registerLazySingleton<_OtherService>(() => _OtherService('a'));
      locator.registerFactory<_FakeService>(() => _FakeService(2));
      // 注意：上面 registerSingleton 已注册 _FakeService，后续 registerFactory 替换之

      expect(locator.isRegistered<_FakeService>(), isTrue);
      expect(locator.isRegistered<_OtherService>(), isTrue);
      expect(locator.isRegistered<String>(), isFalse);
    });

    test('unregister 移除注册', () {
      locator.registerSingleton<_FakeService>(_FakeService(1));
      expect(locator.isRegistered<_FakeService>(), isTrue);

      locator.unregister<_FakeService>();
      expect(locator.isRegistered<_FakeService>(), isFalse);
    });

    test('tryGet 不触发懒加载（避免循环依赖）', () {
      var factoryCalls = 0;
      locator.registerLazySingleton<_FakeService>(() {
        factoryCalls++;
        return _FakeService(42);
      });

      expect(locator.tryGet<_FakeService>(), isNull);
      expect(factoryCalls, equals(0), reason: 'tryGet 不应触发懒加载工厂');
    });

    test('tryGet 已缓存的单例返回该实例', () {
      final instance = _FakeService(7);
      locator.registerSingleton<_FakeService>(instance);

      expect(locator.tryGet<_FakeService>(), same(instance));
    });

    test('reset 清空所有注册', () {
      locator.registerSingleton<_FakeService>(_FakeService(1));
      locator.registerLazySingleton<_OtherService>(() => _OtherService('a'));

      locator.reset();

      expect(locator.isRegistered<_FakeService>(), isFalse);
      expect(locator.isRegistered<_OtherService>(), isFalse);
    });

    test('registerLazySingleton 不清除已有 singleton（实现细节）', () {
      // 当前实现：registerLazySingleton 不移除已有的 singleton 注册，
      // get 会优先返回 singleton。注册顺序决定优先级。
      locator.registerSingleton<_FakeService>(_FakeService(1));
      locator.registerLazySingleton<_FakeService>(() => _FakeService(2));

      // get 优先匹配 singleton，返回 id=1 的实例
      expect(locator.get<_FakeService>().id, equals(1));
    });

    test('activeSingletonCount 反映已缓存实例数', () {
      expect(locator.activeSingletonCount, equals(0));

      locator.registerSingleton<_FakeService>(_FakeService(1));
      expect(locator.activeSingletonCount, equals(1));

      locator.registerLazySingleton<_OtherService>(() => _OtherService('a'));
      // 懒加载注册但不调用 get，不会增加 active 计数
      expect(locator.activeSingletonCount, equals(1));

      // 调用 get 后懒加载实例才被计入
      locator.get<_OtherService>();
      expect(locator.activeSingletonCount, equals(2));
    });

    test('totalRegisteredCount 包含所有注册类型（单例+懒加载+工厂）', () {
      locator.registerSingleton<_FakeService>(_FakeService(1));
      locator.registerLazySingleton<_OtherService>(() => _OtherService('a'));
      locator.registerFactory<_FakeService>(() => _FakeService(2));

      // _FakeService 注册了两次（singleton + factory），
      // 但总类型数应只算一次
      expect(locator.totalRegisteredCount, equals(2));
    });

    test('registeredTypes 返回所有已注册类型', () {
      locator.registerSingleton<_FakeService>(_FakeService(1));
      locator.registerLazySingleton<_OtherService>(() => _OtherService('a'));

      final types = locator.registeredTypes;
      expect(types, contains(_FakeService));
      expect(types, contains(_OtherService));
    });
  });
}
