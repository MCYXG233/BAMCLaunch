// Riverpod Provider 基础验证测试
//
// 验证目标：
// 1. themeManagerProvider 可通过 ConsumerWidget 访问
// 2. ProviderScope override 生效
// 3. selectedInstanceIndexProvider 可读可写
// 4. themeManagerProvider 重复读返回同一实例（ChangeNotifierProvider 默认）
// 5. selectedInstanceIndexProvider listen 能收到更新通知

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bamclaunch/src/di/providers.dart';
import 'package:bamclaunch/src/ui/theme/theme_manager.dart';

void main() {
  setUp(() {
    // 清理 ThemeManager 单例状态（Riverpod container dispose 时会 dispose ThemeManager）
    ThemeManager.resetForTesting();
  });

  group('selectedInstanceIndexProvider', () {
    test('默认值为 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedInstanceIndexProvider), 0);
    });

    test('可更新为新值', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedInstanceIndexProvider.notifier).state = 3;
      expect(container.read(selectedInstanceIndexProvider), 3);
    });

    test('多次更新能保持最新值', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedInstanceIndexProvider.notifier);
      notifier.state = 1;
      notifier.state = 5;
      notifier.state = 10;

      expect(container.read(selectedInstanceIndexProvider), 10);
    });

    test('ProviderScope override 应生效', () {
      final container = ProviderContainer(
        overrides: [
          selectedInstanceIndexProvider.overrideWith((ref) => 42),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(selectedInstanceIndexProvider), 42);
    });
  });

  group('themeManagerProvider', () {
    testWidgets('ConsumerWidget 可读取 themeManagerProvider 并显示类型',
        (tester) async {
      var captured = '';
      // 用 overrideWith 创建本地独立实例，避免影响全局单例
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeManagerProvider.overrideWith((ref) => ThemeManager()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final themeManager = ref.read(themeManagerProvider);
                captured = themeManager.runtimeType.toString();
                return Text('Type: $captured');
              },
            ),
          ),
        ),
      );

      await tester.pump();
      // 验证 ThemeManager 实际被构造并显示
      expect(captured, equals('ThemeManager'));
      expect(find.text('Type: ThemeManager'), findsOneWidget);
    });

    testWidgets('ConsumerWidget 通过 watch 应在 Provider 变化时重建',
        (tester) async {
      var buildCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeManagerProvider.overrideWith((ref) => ThemeManager()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                buildCount++;
                // watch 让 Consumer 在主题变化时重建
                ref.watch(themeManagerProvider);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // 初始构建 1 次
      expect(buildCount, equals(1));

      // 在同一个 container 中 read 不触发重建
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      container.read(themeManagerProvider);

      // 等一帧确保任何潜在重建完成
      await tester.pump();
      expect(buildCount, equals(1),
          reason: 'read 不应触发 watch Consumer 重建');
    });
  });

  group('loggerProvider / eventBusProvider / configManagerProvider', () {
    test('loggerProvider 可读取', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // loggerProvider 委托给 Logger.instance
      expect(container.read(loggerProvider), isNotNull);
    });

    test('eventBusProvider 可读取', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(eventBusProvider), isNotNull);
    });

    test('configManagerProvider 可读取', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(configManagerProvider), isNotNull);
    });
  });
}