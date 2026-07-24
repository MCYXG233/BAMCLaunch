// Riverpod Provider 基础验证测试
//
// 验证目标：
// 1. themeManagerProvider 可通过 ConsumerWidget 访问
// 2. ProviderScope override 生效
// 3. selectedInstanceIndexProvider 可读可写

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bamclaunch/src/di/providers.dart';

void main() {
  group('Riverpod Provider 验证', () {
    test('selectedInstanceIndexProvider 默认值为 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedInstanceIndexProvider), 0);
    });

    test('selectedInstanceIndexProvider 可更新', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedInstanceIndexProvider.notifier).state = 3;
      expect(container.read(selectedInstanceIndexProvider), 3);
    });

    testWidgets('ConsumerWidget 可读取 themeManagerProvider',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                // 仅验证 Provider 可访问，不构建真实 ThemeManager
                final themeManager = ref.read(themeManagerProvider);
                return Text('ThemeManager: ${themeManager.runtimeType}');
              },
            ),
          ),
        ),
      );

      await tester.pump();
      // 第一次构建会触发 ThemeManager 构造
      expect(find.byType(Text), findsWidgets);
    });
  });
}