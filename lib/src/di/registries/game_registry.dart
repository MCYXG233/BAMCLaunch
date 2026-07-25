import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/game_file_validator.dart';
import '../../game/launcher/native_library_manager.dart';
import '../../game/launcher/process_monitor.dart';
import '../../game/java/java_manager.dart';
import '../../game/java/java_downloader.dart';
import '../../game/game_statistics.dart';
import '../../statistics/play_time_tracker.dart';
import '../service_locator.dart';

/// 游戏启动与运行时服务注册
///
/// 注册游戏启动器、文件校验、原生库管理、Java 管理、游戏统计等服务。
void registerGameRegistry(ServiceLocator locator) {
  // GameLauncher - 游戏启动器
  locator.registerLazySingleton<GameLauncher>(() => GameLauncher.instance);

  // GameFileValidator - 游戏文件校验器
  locator.registerLazySingleton<GameFileValidator>(
    () => GameFileValidator.instance,
  );

  // NativeLibraryManager - 原生库管理器
  locator.registerLazySingleton<NativeLibraryManager>(
    () => NativeLibraryManager.instance,
  );

  // ProcessMonitorManager - 进程监控管理器
  locator.registerLazySingleton<ProcessMonitorManager>(
    () => ProcessMonitorManager.instance,
  );

  // JavaManager - Java 管理器
  locator.registerLazySingleton<JavaManager>(() => JavaManager.instance);

  // JavaDownloader - Java 下载器
  locator.registerLazySingleton<JavaDownloader>(() => JavaDownloader.instance);

  // GameStatisticsManager - 游戏统计管理器
  locator.registerLazySingleton<GameStatisticsManager>(
    () => GameStatisticsManager.instance,
  );

  // PlayTimeTracker - 游戏时间追踪
  locator.registerLazySingleton<PlayTimeTracker>(
    () => PlayTimeTracker.instance,
  );
}
