// BAMCLauncher - 我的世界启动器
// Copyright (C) 2025 BAMCLaunch 项目
//
// 本程序是自由软件：您可以重新分发和/或修改它，遵循由自由软件基金会发布的 GNU 通用公共许可证的条款，包括许可证的第3版，或（由您选择）任何更新版本。
//
// 本程序是为了希望它有用而分发的，但不带任何担保；甚至没有对适销性或特定用途的适用性的暗示担保。更多细节请参阅 GNU 通用公共许可证。
//
// 您应该已经收到了 GNU 通用公共许可证的副本连同本程序。如果没有，请参见 <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'src/core/index.dart';
import 'src/di/index.dart';
import 'src/config/index.dart';
import 'src/platform/index.dart';
import 'src/ui/theme/index.dart';
import 'src/ui/pages/index.dart';

void main() {
  ErrorHandler.instance.initialize(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(900, 600),
      center: true,
      backgroundColor: Color(0xFF0A0E27),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(900, 600));
      await windowManager.show();
      await windowManager.focus();
    });

    await ServiceRegistry.initialize();

    await Logger.instance.initialize();
    Logger.instance.info('Application starting...');

    await ConfigManagerImpl().initialize();
    Logger.instance.info('Config manager initialized');

    PlatformAdapterFactory.instance;
    Logger.instance.info('Platform adapter initialized');

    Logger.instance.info(
      'ServiceRegistry: ${ServiceLocator.instance.totalRegisteredCount} services registered',
    );

    final themeManager = ThemeManager();
    await themeManager.initialize();

    runApp(
      ChangeNotifierProvider.value(
        value: themeManager,
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'BAMC Launcher',
          debugShowCheckedModeBanner: false,
          theme: themeManager.getTheme(Brightness.light),
          darkTheme: themeManager.getTheme(Brightness.dark),
          themeMode: themeManager.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
