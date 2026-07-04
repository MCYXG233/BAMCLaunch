import 'dart:async';
import '../event/event_bus.dart';
import '../event/event.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';
import 'download_source.dart';
import 'multi_source_downloader.dart' as msd;
import 'models.dart';

/// 下载引擎接口
///
/// 定义了下载引擎的核心功能接口，包括单文件下载、批量下载、
/// 取消下载、进度监听以及镜像源管理等功能。
///
/// 实现类应确保线程安全，并支持多镜像源自动切换。
///
/// 示例用法：
/// ```dart
/// final engine = DownloadEngine();
/// engine.setDownloadSource(mySource);
/// final filePath = await engine.download(url, savePath);
/// ```
abstract class IDownloadEngine {
  /// 下载单个文件
  ///
  /// 从指定URL下载文件并保存到本地路径。
  /// 支持多镜像源自动切换和文件完整性校验。
  ///
  /// 参数：
  /// - [url] 要下载的文件URL地址
  /// - [savePath] 文件保存的本地绝对路径
  /// - [hash] 可选，预期的文件哈希值，用于完整性校验
  /// - [hashType] 可选，哈希算法类型（如MD5、SHA256等）
  ///
  /// 返回值：
  /// - 成功时返回保存的文件路径
  ///
  /// 异常：
  /// - [DownloadException] 当所有镜像源均不可用时抛出
  /// - 其他IO相关的异常
  ///
  /// 示例：
  /// ```dart
  /// final path = await engine.download(
  ///   'https://example.com/file.zip',
  ///   '/path/to/save/file.zip',
  ///   hash: 'abc123...',
  ///   hashType: HashType.sha256,
  /// );
  /// ```
  Future<String> download(
    String url,
    String savePath, {
    String? hash,
    HashType? hashType,
  });

  /// 批量下载文件
  ///
  /// 并发下载多个文件，使用 Future.wait 实现并发控制。
  ///
  /// 参数：
  /// - [requests] 下载请求列表
  /// - [parallelCount] 可选，最大并发数
  ///
  /// 返回值：
  /// - 所有成功下载的文件路径列表
  Future<List<String>> downloadBatch(
    List<DownloadRequest> requests, {
    int? parallelCount,
  });

  /// 取消所有下载任务
  ///
  /// 取消当前正在进行的所有下载任务。
  /// 已取消的任务将触发 [DownloadCancelledEvent] 事件。
  ///
  /// 返回值：
  /// - [Future<void>] 异步操作，无返回值
  Future<void> cancelAll();

  /// 下载进度流
  ///
  /// 提供下载进度的实时更新流，可用于监听下载进度变化。
  /// 流是广播模式，支持多个监听者。
  ///
  /// 返回值：
  /// - [Stream<DownloadProgress>] 下载进度事件流
  Stream<DownloadProgress> get progressStream;

  /// 设置下载源
  ///
  /// 手动指定要使用的下载源，覆盖当前默认源。
  ///
  /// 参数：
  /// - [source] 要使用的下载源实例
  void setDownloadSource(IDownloadSource source);

  /// 获取当前镜像源管理器
  ///
  /// 返回值：
  /// - [MirrorSourceManager] 镜像源管理器实例
  MirrorSourceManager get mirrorManager;

  /// 设置是否启用自动切换镜像源
  ///
  /// 当启用时，如果当前镜像源下载失败，会自动尝试下一个镜像源。
  /// 当禁用时，下载失败将直接抛出异常。
  ///
  /// 参数：
  /// - [enabled] true 启用自动切换，false 禁用
  void setAutoSwitchMirror(bool enabled);
}

/// 下载引擎实现类（单例模式）
///
/// 提供下载功能的核心实现，支持：
/// - 多镜像源自动切换
/// - 文件完整性校验（支持多种哈希算法）
/// - 下载进度实时通知
/// - 任务取消功能
/// - 事件总线集成
///
/// 使用单例模式确保全局只有一个下载引擎实例，
/// 便于统一管理下载任务和资源。
///
/// 示例用法：
/// ```dart
/// // 获取单例实例
/// final engine = DownloadEngine.instance;
///
/// // 或使用工厂构造函数
/// final engine = DownloadEngine();
///
/// // 下载文件
/// final path = await engine.download(url, savePath);
/// ```
class DownloadEngine implements IDownloadEngine {
  /// 单例实例
  static DownloadEngine? _instance;

  /// 工厂构造函数，返回单例实例
  ///
  /// 如果实例不存在则创建，否则返回已存在的实例。
  factory DownloadEngine() {
    return _instance ??= DownloadEngine._internal();
  }

  /// 私有内部构造函数
  DownloadEngine._internal();

  /// 获取单例实例的静态方法
  ///
  /// 提供更明确的单例访问方式。
  static DownloadEngine get instance =>
      ServiceLocator.instance.tryGet<DownloadEngine>() ??
      (_instance ??= DownloadEngine._internal());

  /// 重置单例（仅用于测试）
  ///
  /// 将单例实例置空，用于单元测试中重置状态。
  /// 生产代码中不应调用此方法。
  static void reset() {
    _instance = null;
  }

  /// 镜像源管理器
  ///
  /// 管理所有可用的镜像源，提供镜像源切换功能。
  final MirrorSourceManager _mirrorManager = MirrorSourceManager();

  /// 当前使用的下载源
  ///
  /// 默认使用镜像源管理器的当前镜像源。
  IDownloadSource _downloadSource = MirrorSourceManager().currentMirrorSource;

  /// 是否启用自动切换镜像源标志
  ///
  /// 为 true 时，下载失败会自动尝试下一个镜像源；
  /// 为 false 时，下载失败直接抛出异常。
  bool _autoSwitchMirror = true;

  /// 活跃的下载任务取消令牌列表
  ///
  /// 用于跟踪和取消所有正在进行的下载任务。
  /// 每个下载任务开始时添加令牌，结束时移除。
  final List<msd.CancellationToken> _activeCancellationTokens = [];

  /// 进度流控制器
  ///
  /// 使用广播模式，支持多个监听者同时监听下载进度。
  final _progressController = StreamController<DownloadProgress>.broadcast();

  /// 事件总线实例
  ///
  /// 用于发布下载相关的事件（开始、完成、取消等）。
  final EventBus _eventBus = EventBus.instance;

  /// 日志记录器
  ///
  /// 用于记录下载过程中的日志信息。
  final Logger _logger = Logger();

  /// 获取下载进度流
  ///
  /// 返回广播模式的进度流，支持多个监听者。
  @override
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// 设置下载源
  ///
  /// 手动指定要使用的下载源。
  ///
  /// 参数：
  /// - [source] 要设置的下载源实例
  @override
  void setDownloadSource(IDownloadSource source) {
    _downloadSource = source;
  }

  /// 获取镜像源管理器
  ///
  /// 返回值：
  /// - 当前使用的镜像源管理器实例
  @override
  MirrorSourceManager get mirrorManager => _mirrorManager;

  /// 设置是否启用自动切换镜像源
  ///
  /// 参数：
  /// - [enabled] 是否启用自动切换
  @override
  void setAutoSwitchMirror(bool enabled) {
    _autoSwitchMirror = enabled;
  }

  /// 下载单个文件
  ///
  /// 实现多镜像源下载逻辑：
  /// 1. 构建所有可用的下载源
  /// 2. 创建多源下载器
  /// 3. 执行下载并监听进度
  /// 4. 如果失败且启用自动切换，尝试下一个镜像源
  /// 5. 所有镜像源都失败时抛出异常
  ///
  /// 参数：
  /// - [url] 要下载的文件URL
  /// - [savePath] 本地保存路径
  /// - [hash] 可选，预期哈希值
  /// - [hashType] 可选，哈希类型
  ///
  /// 返回值：
  /// - 成功下载的文件路径
  ///
  /// 异常：
  /// - [DownloadException] 所有镜像源均不可用时抛出
  @override
  Future<String> download(
    String url,
    String savePath, {
    String? hash,
    HashType? hashType,
  }) async {
    _logger.info('开始下载: $url -> $savePath');

    // 尝试次数计数器
    int attemptCount = 0;
    // 最大尝试次数为镜像源数量
    int maxAttempts = _mirrorManager.allMirrorSources.length;
    // 记录最后一次错误，用于最终异常信息
    Exception? lastError;

    // 循环尝试所有镜像源
    while (attemptCount < maxAttempts) {
      try {
        // 构建所有可用的下载源列表
        final sources = _buildDownloadSources();
        // 创建多源下载器
        final downloader = msd.MultiSourceDownloader(sources: sources);
        // 创建取消令牌，用于支持任务取消
        final cancellationToken = msd.CancellationToken();
        // 将取消令牌添加到活跃列表，便于统一取消
        _activeCancellationTokens.add(cancellationToken);

        // 生成唯一的任务ID，用于事件追踪
        final taskId = DateTime.now().millisecondsSinceEpoch.toString();

        // 发布下载开始事件
        _eventBus.publish(
          DownloadStartedEvent(taskId: taskId, url: url, savePath: savePath),
        );

        try {
          // 执行下载操作
          final result = await downloader.download(
            url: url,
            savePath: savePath,
            expectedHash: hash,
            // 转换哈希类型枚举，从本地枚举映射到多源下载器的枚举
            hashType: hashType != null ? msd.HashType.values[hashType.index] : null,
            // 进度回调：将进度信息发送到进度流
            onProgress: (progress, downloaded, total) {
              _progressController.add(
                DownloadProgress(
                  downloadedBytes: downloaded,
                  totalBytes: total,
                  progress: progress,
                ),
              );
            },
            // 镜像源切换回调：发布切换通知事件
            onSourceSwitch: (sourceName) {
              _eventBus.publish(
                DownloadInfoEvent(message: '切换到下载源: $sourceName'),
              );
            },
            cancellationToken: cancellationToken,
          );

          // 下载成功，发布完成事件
          _eventBus.publish(
            DownloadCompletedEvent(
              taskId: taskId,
              url: url,
              savePath: savePath,
            ),
          );
          _logger.info('下载完成: $savePath');
          return result;
        } finally {
          // 无论成功或失败，都从活跃列表中移除取消令牌
          _activeCancellationTokens.remove(cancellationToken);
        }
      } catch (e) {
        // 捕获并记录错误
        lastError = e is Exception ? e : Exception(e.toString());
        _logger.warn('下载尝试失败: ${lastError.toString()}');
        attemptCount++;

        // 如果启用自动切换且还有未尝试的镜像源，切换到下一个
        if (_autoSwitchMirror && attemptCount < maxAttempts) {
          _downloadSource = _mirrorManager.switchToNextMirror();
          _eventBus.publish(
            DownloadInfoEvent(message: '镜像源不可用，正在切换到 ${_downloadSource.name}...'),
          );
        }
      }
    }

    // 所有镜像源都失败，抛出下载异常
    throw DownloadException(
      '下载失败，所有镜像源均不可用。最后一个错误: ${lastError?.toString() ?? '未知错误'}',
      lastError,
    );
  }

  /// 构建下载源列表
  ///
  /// 将所有镜像源转换为多源下载器所需的下载源格式。
  /// 每个镜像源包含名称、URL解析器和可用性检查器。
  ///
  /// 返回值：
  /// - [List<msd.DownloadSource>] 多源下载器可用的下载源列表
  List<msd.DownloadSource> _buildDownloadSources() {
    final sources = <msd.DownloadSource>[];
    // 遍历所有镜像源，转换为下载源格式
    for (final mirror in _mirrorManager.allMirrorSources) {
      sources.add(
        msd.DownloadSource(
          name: mirror.name,
          // URL解析器：将路径解析为完整URL
          urlResolver: (path) async => await mirror.getUrl(path),
          // 可用性检查器：检查镜像源是否可用
          availabilityChecker: () async => await mirror.isAvailable(),
        ),
      );
    }
    return sources;
  }

  /// 批量下载文件
  ///
  /// 并发下载多个文件。每个文件独立下载，整体进度报告。
  ///
  /// 参数：
  /// - [requests] 下载请求列表
  /// - [parallelCount] 最大并发下载数，默认与请求数量相同
  ///
  /// 返回值：
  /// - 所有成功下载的文件路径列表
  @override
  Future<List<String>> downloadBatch(
    List<DownloadRequest> requests, {
    int? parallelCount,
  }) async {
    final semaphore = parallelCount != null ? _Semaphore(parallelCount) : null;
    final futures = <Future<String>>[];

    for (final request in requests) {
      futures.add(() async {
        if (semaphore != null) await semaphore.acquire();
        try {
          return await download(
            request.url,
            request.savePath,
            hash: request.hash,
            hashType: request.hashType,
          );
        } finally {
          semaphore?.release();
        }
      }());
    }

    return Future.wait(futures);
  }

  /// 取消所有下载任务
  ///
  /// 遍历所有活跃的取消令牌并触发取消，
  /// 然后清空活跃令牌列表并发布取消事件。
  ///
  /// 返回值：
  /// - [Future<void>] 异步操作，无返回值
  @override
  Future<void> cancelAll() async {
    _logger.info('取消所有下载任务');
    // 取消所有活跃的下载任务
    for (final token in _activeCancellationTokens) {
      token.cancel();
    }
    // 清空活跃令牌列表
    _activeCancellationTokens.clear();
    // 发布取消事件
    _eventBus.publish(DownloadCancelledEvent(taskId: 'all'));
  }
}

/// 下载异常类
///
/// 封装下载过程中发生的错误信息，包括错误消息和内部异常。
/// 提供友好的错误信息格式化输出。
///
/// 示例：
/// ```dart
/// throw DownloadException('下载失败', innerException);
/// ```
class DownloadException implements Exception {
  /// 错误消息
  final String message;

  /// 内部异常（可选）
  ///
  /// 存储导致此异常的原始异常，便于调试和错误追踪。
  final Exception? innerException;

  /// 构造函数
  ///
  /// 参数：
  /// - [message] 错误消息
  /// - [innerException] 可选的内部异常
  DownloadException(this.message, [this.innerException]);

  /// 转换为字符串表示
  ///
  /// 如果存在内部异常，会包含内部异常的详细信息。
  ///
  /// 返回值：
  /// - 格式化的错误消息字符串
  @override
  String toString() {
    if (innerException != null) {
      return '$message\n原因: ${innerException.toString()}';
    }
    return message;
  }
}

/// 下载信息事件
///
/// 用于在事件总线上发布下载相关的信息通知，
/// 如镜像源切换、下载状态变更等。
///
/// 示例：
/// ```dart
/// eventBus.publish(DownloadInfoEvent(message: '正在切换镜像源...'));
/// ```
class DownloadInfoEvent extends Event {
  /// 信息消息内容
  final String message;

  /// 构造函数
  ///
  /// 参数：
  /// - [message] 要发布的信息消息
  DownloadInfoEvent({required this.message});
}

class _Semaphore {
  int _permits;

  _Semaphore(this._permits);

  Future<void> acquire() async {
    while (_permits <= 0) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _permits--;
  }

  void release() {
    _permits++;
  }
}