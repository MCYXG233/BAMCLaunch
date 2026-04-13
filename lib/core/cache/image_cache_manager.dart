import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ImageCacheManager {
  static ImageCacheManager? _instance;
  final Map<String, _CachedImage> _memoryCache = {};
  final Map<String, Completer<ImageProvider>> _pendingRequests = {};
  final Directory? _cacheDirectory;
  final int _maxMemoryCacheSize;
  final Duration _cacheExpiration;

  factory ImageCacheManager({
    Directory? cacheDirectory,
    int maxMemoryCacheSize = 100,
    Duration cacheExpiration = const Duration(days: 7),
  }) {
    _instance ??= ImageCacheManager._internal(
      cacheDirectory: cacheDirectory,
      maxMemoryCacheSize: maxMemoryCacheSize,
      cacheExpiration: cacheExpiration,
    );
    return _instance!;
  }

  ImageCacheManager._internal({
    Directory? cacheDirectory,
    required int maxMemoryCacheSize,
    required Duration cacheExpiration,
  }) : _cacheDirectory = cacheDirectory,
       _maxMemoryCacheSize = maxMemoryCacheSize,
       _cacheExpiration = cacheExpiration;

  Future<void> initialize() async {
    if (_cacheDirectory != null && !await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    await _cleanExpiredCache();
  }

  Future<ImageProvider> getImage(
    String url, {
    String? cacheKey,
    Duration? expiration,
  }) async {
    final key = cacheKey ?? url;

    // 检查内存缓存
    if (_memoryCache.containsKey(key)) {
      final cachedImage = _memoryCache[key]!;
      if (!_isExpired(cachedImage.timestamp, expiration)) {
        return cachedImage.provider;
      } else {
        _memoryCache.remove(key);
      }
    }

    // 检查是否有正在进行的请求
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future;
    }

    // 创建新的请求
    final completer = Completer<ImageProvider>();
    _pendingRequests[key] = completer;

    try {
      ImageProvider provider;

      // 检查磁盘缓存
      if (_cacheDirectory != null) {
        final file = _getCacheFile(key);
        if (await file.exists()) {
          final fileStat = await file.stat();
          if (!_isExpired(
            fileStat.modified.millisecondsSinceEpoch,
            expiration,
          )) {
            provider = FileImage(file);
            _addToMemoryCache(key, provider);
            completer.complete(provider);
            _pendingRequests.remove(key);
            return provider;
          } else {
            await file.delete();
          }
        }
      }

      // 从网络加载
      provider = NetworkImage(url);
      _addToMemoryCache(key, provider);

      // 缓存到磁盘
      if (_cacheDirectory != null) {
        await _cacheToDisk(key, url);
      }

      completer.complete(provider);
    } catch (e) {
      completer.completeError(e);
    } finally {
      _pendingRequests.remove(key);
    }

    return completer.future;
  }

  Future<void> _cacheToDisk(String key, String url) async {
    try {
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 30);
      
      final request = await httpClient.getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close()
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final file = _getCacheFile(key);
        await file.parent.create(recursive: true);
        
        // 使用流式写入，避免一次性加载到内存
        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.close();
      }
    } catch (_) {
      // 忽略缓存失败
    }
  }

  void _addToMemoryCache(String key, ImageProvider provider) {
    // 限制内存缓存大小
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = _CachedImage(
      provider: provider,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool _isExpired(int timestamp, Duration? customExpiration) {
    final expiration = customExpiration ?? _cacheExpiration;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp > expiration.inMilliseconds;
  }

  File _getCacheFile(String key) {
    final fileName = Uri.encodeComponent(key).replaceAll('%', '_');
    return File('${_cacheDirectory!.path}/$fileName');
  }

  Future<void> _cleanExpiredCache() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (_isExpired(stat.modified.millisecondsSinceEpoch, null)) {
            await file.delete();
          }
        }
      }
    } catch (_) {
      // 忽略清理失败
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    // 强制触发GC
    if (kDebugMode) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  Future<void> clearDiskCache() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (_) {
      // 忽略清理失败
    }
  }

  int get memoryCacheSize => _memoryCache.length;

  void dispose() {
    clearMemoryCache();
    _memoryCache.clear();
    _pendingRequests.clear();
  }
}

class _CachedImage {
  final ImageProvider provider;
  final int timestamp;

  _CachedImage({required this.provider, required this.timestamp});
}

class CachedImage extends StatelessWidget {
  final String url;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? cacheExpiration;

  const CachedImage({
    super.key,
    required this.url,
    this.cacheKey,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.cacheExpiration,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: ImageCacheManager().getImage(
        url,
        cacheKey: cacheKey,
        expiration: cacheExpiration,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? const SizedBox();
        }

        if (snapshot.hasError) {
          return errorWidget ?? const SizedBox();
        }

        return Image(
          image: snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const SizedBox();
          },
        );
      },
    );
  }
}
