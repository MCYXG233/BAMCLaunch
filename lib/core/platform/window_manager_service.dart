import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagerService {
  static WindowManagerService? _instance;

  WindowManagerService._internal();

  static WindowManagerService getInstance() {
    _instance ??= WindowManagerService._internal();
    return _instance!;
  }

  Future<void> initialize() async {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      title: 'BAMCLauncher',
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  Future<void> setSize(int width, int height) async {
    await windowManager.setSize(Size(width.toDouble(), height.toDouble()));
  }

  Future<void> setPosition(int x, int y) async {
    await windowManager.setPosition(Offset(x.toDouble(), y.toDouble()));
  }

  Future<void> setMinimumSize(int width, int height) async {
    await windowManager.setMinimumSize(Size(width.toDouble(), height.toDouble()));
  }

  Future<void> setMaximumSize(int width, int height) async {
    await windowManager.setMaximumSize(Size(width.toDouble(), height.toDouble()));
  }

  Future<void> center() async {
    await windowManager.center();
  }

  Future<void> maximize() async {
    await windowManager.maximize();
  }

  Future<void> unmaximize() async {
    await windowManager.unmaximize();
  }

  Future<void> minimize() async {
    await windowManager.minimize();
  }

  Future<void> restore() async {
    await windowManager.restore();
  }

  Future<void> hide() async {
    await windowManager.hide();
  }

  Future<void> show() async {
    await windowManager.show();
  }

  Future<void> close() async {
    await windowManager.close();
  }

  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  Future<void> setSkipTaskbar(bool skip) async {
    await windowManager.setSkipTaskbar(skip);
  }

  Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }

  Future<bool> isMinimized() async {
    return await windowManager.isMinimized();
  }

  Future<Size> getSize() async {
    return await windowManager.getSize();
  }

  Future<Offset> getPosition() async {
    return await windowManager.getPosition();
  }

  Future<void> startDragging() async {
    await windowManager.startDragging();
  }

  // stopDragging方法在window_manager库中不存在，已移除
}
