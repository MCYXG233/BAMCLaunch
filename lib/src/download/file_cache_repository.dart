import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';

/// 文件下载缓存仓库
/// 
/// 以 SHA1 为索引缓存已下载的文件，多实例共享。
/// 参考 HMCL 的 DefaultCacheRepository 设计。
class FileCacheRepository {
  static FileCacheRepository? _instance;
  static FileCacheRepository get instance => _instance ??= FileCacheRepository._();
  
  FileCacheRepository._();
  
  final Logger _logger = Logger('FileCacheRepository');
  final Map<String, String> _index = {};  // sha1 -> cacheFilePath
  String? _cacheDir;
  bool _initialized = false;
  
  /// 初始化缓存仓库
  Future<void> initialize(String baseDir) async {
    if (_initialized) return;
    _cacheDir = path.join(baseDir, 'cache');
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await _loadIndex();
    _initialized = true;
    _logger.info('FileCacheRepository initialized: ${_index.length} cached files');
  }
  
  /// 检查缓存中是否有指定哈希的文件
  Future<bool> hasFile(String sha1) async {
    final cachePath = _index[sha1.toLowerCase()];
    if (cachePath == null) return false;
    return File(cachePath).exists();
  }
  
  /// 获取缓存文件
  Future<File?> getCachedFile(String sha1) async {
    final cachePath = _index[sha1.toLowerCase()];
    if (cachePath == null) return null;
    final file = File(cachePath);
    if (await file.exists()) return file;
    _index.remove(sha1.toLowerCase());
    return null;
  }
  
  /// 将文件加入缓存
  Future<void> cacheFile(File sourceFile, String sha1) async {
    if (_cacheDir == null) return;
    final cachePath = path.join(_cacheDir!, sha1.toLowerCase());
    try {
      await sourceFile.copy(cachePath);
      _index[sha1.toLowerCase()] = cachePath;
      await _saveIndex();
    } catch (e) {
      _logger.warn('Failed to cache file: $e');
    }
  }
  
  /// 缓存目录中的文件数量
  int get cachedFileCount => _index.length;
  
  Future<void> _loadIndex() async {
    final indexFile = File(path.join(_cacheDir!, 'index.json'));
    if (!await indexFile.exists()) return;
    try {
      final data = json.decode(await indexFile.readAsString()) as Map<String, dynamic>;
      for (final entry in data.entries) {
        _index[entry.key] = entry.value as String;
      }
    } catch (e) {
      _logger.warn('Failed to load cache index: $e');
    }
  }
  
  Future<void> _saveIndex() async {
    if (_cacheDir == null) return;
    final indexFile = File(path.join(_cacheDir!, 'index.json'));
    try {
      await indexFile.writeAsString(json.encode(_index));
    } catch (e) {
      _logger.warn('Failed to save cache index: $e');
    }
  }
}
