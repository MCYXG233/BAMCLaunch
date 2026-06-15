import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../download/download_engine.dart';
import '../shared/models/download_task.dart';
import 'service_locator_provider.dart';

/// DownloadEngine Provider
/// 
/// 提供下载引擎服务
final downloadEngineProvider = Provider<DownloadEngine>((ref) {
  final locator = ref.watch(serviceLocatorProvider);
  return locator.get<DownloadEngine>();
});

/// 下载队列 Provider
/// 
/// 管理当前的下载任务队列
final downloadQueueProvider = StateProvider<List<DownloadTask>>((ref) => []);

/// 下载进度 Provider
/// 
/// 管理特定任务的下载进度
final downloadProgressProvider = StateProvider.family<double, String>((ref, taskId) {
  return 0.0;
});

/// 下载速度 Provider
/// 
/// 管理下载速度（字节/秒）
final downloadSpeedProvider = StateProvider<int>((ref) => 0);

/// 是否有正在进行的下载 Provider
final isDownloadingProvider = Provider<bool>((ref) {
  final queue = ref.watch(downloadQueueProvider);
  return queue.any((task) => task.status == DownloadStatus.downloading);
});
