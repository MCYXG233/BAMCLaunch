// MyApp widget 测试
//
// 注意：
// 1. MyApp 启动 splash 页面后会执行 ConfigManager/AccountManager/GameLauncher
//    真实初始化（涉及文件系统），不适合在单元测试中直接运行。
//    这里只验证 widget 树结构。
// 2. ThemeManager 是单例，跨测试共享状态。
// 3. setMinecraftTheme 触发 SharedPreferences（未 mock），所以只测试无副作用的 getter。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bamclaunch/main.dart';
import 'package:bamclaunch/src/ui/theme/theme_manager.dart';

void main() {
  setUp(() {
    // 清理 ThemeManager 单例（Riverpod container dispose 会触发 ThemeManager.dispose）
    ThemeManager.resetForTesting();
  });

  group('MyApp widget 树', () {
    testWidgets('ChangeNotifierProvider 树中 ThemeManager 可访问', (
      WidgetTester tester,
    ) async {
      final themeManager = ThemeManager();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeManager>.value(
          value: themeManager,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('Test'))),
          ),
        ),
      );

      // 验证：Provider 树中存在 ThemeManager
      final context = tester.element(find.byType(MaterialApp));
      final tm = Provider.of<ThemeManager>(context, listen: false);
      expect(tm, isNotNull);

      // 验证：ThemeManager 可产生有效的 ThemeData
      final lightTheme = tm.getTheme(Brightness.light);
      final darkTheme = tm.getTheme(Brightness.dark);
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));
    });

    testWidgets('MyApp 顶层渲染 MaterialApp', (WidgetTester tester) async {
      final themeManager = ThemeManager();
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeManager>.value(
          value: themeManager,
          child: MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('ThemeManager getter 行为（无副作用）', () {
    test('isBlueArchive/isMinecraft 默认值正确', () {
      final themeManager = ThemeManager();
      // 互斥的 isXxx 标记
      expect(themeManager.isBlueArchive, isTrue);
      expect(themeManager.isMinecraft, isFalse);
    });

    test('currentTheme 返回字符串', () {
      final themeManager = ThemeManager();
      expect(themeManager.currentTheme, isNotEmpty);
      // 蔚蓝档案键名
      expect(themeManager.currentTheme, equals('blue_archive'));
    });

    test('themeMode 返回有效 ThemeMode', () {
      final themeManager = ThemeManager();
      expect(
        themeManager.themeMode,
        anyOf(ThemeMode.system, ThemeMode.light, ThemeMode.dark),
      );
    });

    test('customColors 非空', () {
      final themeManager = ThemeManager();
      expect(themeManager.customColors, isNotNull);
    });

    test('getTheme(Brightness.light) 返回 ThemeData', () {
      final themeManager = ThemeManager();
      final theme = themeManager.getTheme(Brightness.light);
      expect(theme, isNotNull);
      expect(theme.brightness, equals(Brightness.light));
    });

    test('getTheme(Brightness.dark) 返回 ThemeData', () {
      final themeManager = ThemeManager();
      final theme = themeManager.getTheme(Brightness.dark);
      expect(theme, isNotNull);
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('light/dark 主题 brightness 必须不同', () {
      final themeManager = ThemeManager();
      final light = themeManager.getTheme(Brightness.light);
      final dark = themeManager.getTheme(Brightness.dark);
      expect(light.brightness, isNot(equals(dark.brightness)));
    });
  });
}
