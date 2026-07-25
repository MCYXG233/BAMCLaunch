import '../../download/download_engine.dart';
import '../../download/download_source.dart';
import '../../download/mirror_manager.dart';
import '../../download/queue_manager.dart';
import '../service_locator.dart';

/// 下载引擎与镜像源服务注册
void registerDownloadRegistry(ServiceLocator locator) {
  // DownloadEngine - 下载引擎
  locator.registerLazySingleton<DownloadEngine>(() => DownloadEngine.instance);

  // DownloadQueueManager - 下载队列管理器
  locator.registerLazySingleton<DownloadQueueManager>(
    () => DownloadQueueManager.instance,
  );

  // MirrorSourceManager - 镜像源管理器
  locator.registerLazySingleton<MirrorSourceManager>(
    () => MirrorSourceManager.instance,
  );

  // MirrorManager - 镜像管理器
  locator.registerLazySingleton<MirrorManager>(() => MirrorManager.instance);
}
