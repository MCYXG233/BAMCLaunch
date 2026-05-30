// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bamclaunch/main.dart';
import 'package:bamclaunch/src/ui/theme/theme_manager.dart';

void main() {
  testWidgets('App initializes with ThemeManager', (WidgetTester tester) async {
    // Create a mock ThemeManager for testing
    final themeManager = ThemeManager();
    
    // Build our app with proper Provider context
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeManager,
        child: const MyApp(),
      ),
    );

    // Verify the app starts correctly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
