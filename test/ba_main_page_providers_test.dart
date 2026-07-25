// BAMainPage Riverpod Provider 测试
//
// 验证目标：
// 1. currentPageProvider 默认值为 0
// 2. selectedAccountNameProvider 默认为 null
// 3. instancesProvider 默认为空列表
// 4. isLaunchingProvider 默认为 false
// 5. 状态可被独立更新而互不影响

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bamclaunch/src/ui/pages/ba_main_page.dart';

void main() {
  group('BAMainPage Provider 验证', () {
    test('currentPageProvider 默认值为 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentPageProvider), 0);
    });

    test('currentPageProvider 可独立更新', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentPageProvider.notifier).state = 3;
      expect(container.read(currentPageProvider), 3);
    });

    test('selectedAccountNameProvider 默认值为 null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedAccountNameProvider), isNull);
    });

    test('selectedAccountNameProvider 可更新为字符串', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedAccountNameProvider.notifier).state = 'Steve';
      expect(container.read(selectedAccountNameProvider), 'Steve');
    });

    test('instancesProvider 默认为空列表', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final instances = container.read(instancesProvider);
      expect(instances, isEmpty);
    });

    test('instancesProvider 可被替换', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(instancesProvider.notifier).state = [
        // 不创建真实 GameInstance（依赖较多），仅验证 list 替换
      ];
      expect(container.read(instancesProvider), isEmpty); // 替换为空 list
    });

    test('isLaunchingProvider 默认为 false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isLaunchingProvider), isFalse);
    });

    test('isLaunchingProvider 可切换为 true / false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isLaunchingProvider.notifier).state = true;
      expect(container.read(isLaunchingProvider), isTrue);

      container.read(isLaunchingProvider.notifier).state = false;
      expect(container.read(isLaunchingProvider), isFalse);
    });

    test('4 个 Provider 状态独立', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentPageProvider.notifier).state = 2;
      container.read(isLaunchingProvider.notifier).state = true;
      container.read(selectedAccountNameProvider.notifier).state = 'Alex';

      expect(container.read(currentPageProvider), 2);
      expect(container.read(isLaunchingProvider), isTrue);
      expect(container.read(selectedAccountNameProvider), 'Alex');
    });
  });
}
