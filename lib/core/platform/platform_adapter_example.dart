import 'platform_service.dart';
import 'window_manager_service.dart';
import 'tray_service.dart';

class PlatformAdapterExample {
  static Future<void> demonstratePlatformFeatures() async {
    final platformService = PlatformService.getInstance();
    final windowManagerService = WindowManagerService.getInstance();
    final trayService = TrayService.getInstance();

    print('=== Platform Information ===');
    print('Platform: ${platformService.getPlatformName()}');
    print('Platform Version: ${platformService.getPlatformVersion()}');
    print('Username: ${await platformService.getUsername()}');
    print('Hostname: ${await platformService.getHostname()}');
    print('App Data Directory: ${platformService.appDataDirectory}');
    print('Game Directory: ${platformService.gameDirectory}');

    print('\n=== Java Detection ===');
    final javaPath = await platformService.findJava();
    if (javaPath != null) {
      print('Found Java at: $javaPath');
    } else {
      print('Java not found');
    }

    print('\n=== Window Management ===');
    await windowManagerService.setTitle('BAMCLauncher - Demo');
    await windowManagerService.setSize(1024, 768);
    await windowManagerService.center();

    print('\n=== Tray Management ===');
    await trayService.initialize('assets/icon.png', 'BAMCLauncher');
    await trayService.setMenu([
      TrayMenuItem(id: 'show', label: 'Show Window'),
      TrayMenuItem(id: 'hide', label: 'Hide Window'),
      TrayMenuItem(id: 'exit', label: 'Exit'),
    ], (id) {
      switch (id) {
        case 'show':
          windowManagerService.show();
          break;
        case 'hide':
          windowManagerService.hide();
          break;
        case 'exit':
          windowManagerService.close();
          break;
      }
    });
    await trayService.show();
  }
}
