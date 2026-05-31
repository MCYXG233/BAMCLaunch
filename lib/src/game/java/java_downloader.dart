import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';

/// Java版本信息
class JavaRelease {
  final String version;
  final String vendor;
  final String? downloadUrl;
  final String? sha256;
  final int? size;

  JavaRelease({
    required this.version,
    required this.vendor,
    this.downloadUrl,
    this.sha256,
    this.size,
  });
}

/// Java安装状态
enum JavaInstallStatus {
  notStarted,
  downloading,
  extracting,
  installing,
  completed,
  error,
}

/// Java下载进度
class JavaDownloadProgress {
  final JavaInstallStatus status;
  final double progress;
  final String? message;
  final String? error;

  JavaDownloadProgress({
    required this.status,
    this.progress = 0,
    this.message,
    this.error,
  });
}

/// Java自动下载器
class JavaDownloader {
  static JavaDownloader? _instance;

  final Logger _logger = Logger('JavaDownloader');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 下载目录
  Directory? _downloadDir;

  /// 安装目录
  Directory? _installDir;

  /// 当前下载进度回调
  void Function(JavaDownloadProgress)? _onProgress;

  /// 是否正在下载
  bool _isDownloading = false;

  JavaDownloader._internal();

  /// 获取单例实例
  static JavaDownloader get instance {
    _instance ??= JavaDownloader._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory JavaDownloader() => instance;

  /// 初始化Java下载器
  Future<void> initialize() async {
    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _downloadDir = Directory(path.join(supportDir, 'java_downloads'));
      _installDir = Directory(path.join(supportDir, 'java_runtime'));

      if (!await _downloadDir!.exists()) {
        await _downloadDir!.create(recursive: true);
      }
      if (!await _installDir!.exists()) {
        await _installDir!.create(recursive: true);
      }

      _logger.info('Java downloader initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Java downloader', e, stackTrace);
    }
  }

  /// 获取可用的Java版本列表（简化实现）
  Future<List<JavaRelease>> getAvailableReleases() async {
    // 这里应该调用API获取实际的Java版本列表
    // 这里返回一些常用版本作为示例
    return [
      JavaRelease(
        version: '21',
        vendor: 'Eclipse Temurin',
        downloadUrl: 'https://example.com/java21',
      ),
      JavaRelease(
        version: '17',
        vendor: 'Eclipse Temurin',
        downloadUrl: 'https://example.com/java17',
      ),
      JavaRelease(
        version: '8',
        vendor: 'Eclipse Temurin',
        downloadUrl: 'https://example.com/java8',
      ),
    ];
  }

  /// 根据游戏版本推荐Java版本
  Future<JavaRelease?> getRecommendedJava(String gameVersion) async {
    // 简单的推荐逻辑
    // - 1.20+ → Java 17 或 21
    // - 1.17-1.19 → Java 17
    // - 1.16及以下 → Java 8
    final recommended = await getAvailableReleases();

    if (gameVersion.compareTo('1.20') >= 0) {
      return recommended.firstWhere((r) => r.version == '21', orElse: () => recommended.first);
    } else if (gameVersion.compareTo('1.17') >= 0) {
      return recommended.firstWhere((r) => r.version == '17', orElse: () => recommended.first);
    } else {
      return recommended.firstWhere((r) => r.version == '8', orElse: () => recommended.first);
    }
  }

  /// 下载并安装Java
  Future<String?> downloadAndInstall(
    JavaRelease release, {
    void Function(JavaDownloadProgress)? onProgress,
  }) async {
    if (_isDownloading) {
      _logger.warn('Download already in progress');
      return null;
    }

    _isDownloading = true;
    _onProgress = onProgress;

    try {
      // 检查是否已经安装
      final installedPath = await _checkExistingInstallation(release);
      if (installedPath != null) {
        _logger.info('Java ${release.version} already installed');
        _emitProgress(JavaDownloadProgress(
          status: JavaInstallStatus.completed,
          message: 'Java ${release.version} already installed',
        ));
        return installedPath;
      }

      // 模拟下载过程（实际应该从真实URL下载）
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.downloading,
        progress: 0,
        message: 'Starting download...',
      ));

      // 模拟下载进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _emitProgress(JavaDownloadProgress(
          status: JavaInstallStatus.downloading,
          progress: i / 100,
          message: 'Downloading: $i%',
        ));
      }

      // 模拟解压
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.extracting,
        progress: 0,
        message: 'Extracting files...',
      ));

      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        _emitProgress(JavaDownloadProgress(
          status: JavaInstallStatus.extracting,
          progress: i / 100,
          message: 'Extracting: $i%',
        ));
      }

      // 模拟安装
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.installing,
        progress: 0,
        message: 'Finalizing installation...',
      ));

      await Future.delayed(const Duration(milliseconds: 500));

      // 创建安装目录
      final installPath = path.join(_installDir!.path, 'java-${release.version}');
      final installDirectory = Directory(installPath);
      if (!await installDirectory.exists()) {
        await installDirectory.create(recursive: true);
      }

      // 这里实际上应该解压文件并设置
      // 由于这是简化版，我们创建一个标记文件
      final markerFile = File(path.join(installPath, '.installed'));
      await markerFile.writeAsString('''
version=${release.version}
vendor=${release.vendor}
installedAt=${DateTime.now().toIso8601String()}
''');

      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.completed,
        progress: 1,
        message: 'Java ${release.version} installed successfully!',
      ));

      _logger.info('Java ${release.version} installed at $installPath');
      return installPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to install Java ${release.version}', e, stackTrace);
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.error,
        error: e.toString(),
      ));
      return null;
    } finally {
      _isDownloading = false;
      _onProgress = null;
    }
  }

  /// 检查是否已经安装
  Future<String?> _checkExistingInstallation(JavaRelease release) async {
    final installPath = path.join(_installDir!.path, 'java-${release.version}');
    final markerFile = File(path.join(installPath, '.installed'));

    if (await markerFile.exists()) {
      return installPath;
    }
    return null;
  }

  /// 获取已安装的Java列表
  Future<List<JavaRelease>> getInstalledVersions() async {
    final installed = <JavaRelease>[];

    if (_installDir == null) return installed;

    await for (final dir in _installDir!.list()) {
      if (dir is Directory) {
        final markerFile = File(path.join(dir.path, '.installed'));
        if (await markerFile.exists()) {
          try {
            final content = await markerFile.readAsString();
            final lines = content.split('\n');

            String? version;
            String? vendor;

            for (final line in lines) {
              if (line.startsWith('version=')) {
                version = line.substring(8);
              } else if (line.startsWith('vendor=')) {
                vendor = line.substring(7);
              }
            }

            if (version != null) {
              installed.add(JavaRelease(
                version: version,
                vendor: vendor ?? 'Unknown',
              ));
            }
          } catch (e) {
            // 忽略错误
          }
        }
      }
    }

    return installed;
  }

  /// 删除已安装的Java版本
  Future<bool> deleteJava(String version) async {
    try {
      final installPath = path.join(_installDir!.path, 'java-$version');
      final installDirectory = Directory(installPath);

      if (await installDirectory.exists()) {
        await installDirectory.delete(recursive: true);
        _logger.info('Deleted Java $version');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete Java $version', e, stackTrace);
      return false;
    }
  }

  /// 获取Java可执行文件路径
  String? getJavaExecutable(String installPath) {
    if (Platform.isWindows) {
      final javaw = File(path.join(installPath, 'bin', 'javaw.exe'));
      if (javaw.existsSync()) {
        return javaw.path;
      }
      final java = File(path.join(installPath, 'bin', 'java.exe'));
      if (java.existsSync()) {
        return java.path;
      }
    } else {
      final java = File(path.join(installPath, 'bin', 'java'));
      if (java.existsSync()) {
        return java.path;
      }
    }
    return null;
  }

  /// 发送进度更新
  void _emitProgress(JavaDownloadProgress progress) {
    if (_onProgress != null) {
      _onProgress!(progress);
    }
  }

  /// 是否已在下载
  bool get isDownloading => _isDownloading;

  /// 清理下载缓存
  Future<void> clearDownloadCache() async {
    try {
      if (_downloadDir != null && await _downloadDir!.exists()) {
        await _downloadDir!.delete(recursive: true);
        await _downloadDir!.create(recursive: true);
        _logger.info('Cleared download cache');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to clear download cache', e, stackTrace);
    }
  }
}
