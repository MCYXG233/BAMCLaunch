import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart' as archive_lib;
import '../../core/logger.dart';
import '../../core/network_client.dart';
import '../../di/service_locator.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import 'models.dart';

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
    return ServiceLocator.instance.tryGet<JavaDownloader>() ??
        (_instance ??= JavaDownloader._internal());
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

  /// 获取可用的Java版本列表
  ///
  /// 从 Adoptium API 获取可用的 Java 版本。
  Future<List<JavaRelease>> getAvailableReleases() async {
    try {
      final data = await NetworkClient().getJson(
        'https://api.adoptium.net/v3/info/available_releases',
      );
      final available = data['available_lts_releases'] as List<dynamic>? ??
          data['available_releases'] as List<dynamic>? ??
          [];
      return available.map((v) {
        final version = v.toString();
        return JavaRelease(
          version: version,
          vendor: 'Eclipse Temurin',
        );
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch available Java releases', e, stackTrace);
      // 回退到常用版本列表
      return [
        JavaRelease(version: '21', vendor: 'Eclipse Temurin'),
        JavaRelease(version: '17', vendor: 'Eclipse Temurin'),
        JavaRelease(version: '8', vendor: 'Eclipse Temurin'),
      ];
    }
  }

  /// 根据游戏版本推荐Java版本
  Future<JavaRelease?> getRecommendedJava(String gameVersion) async {
    final recommendedVersions = JavaVersion.getRecommendedForGameVersion(gameVersion);
    final available = await getAvailableReleases();

    // 按优先级遍历推荐的 Java 主版本号，查找匹配的可用版本
    for (final reqVersion in recommendedVersions) {
      final match = available.where(
        (r) => int.tryParse(r.version) == reqVersion,
      );
      if (match.isNotEmpty) {
        return match.first;
      }
    }

    // 未找到精确匹配，返回最高版本
    return available.isNotEmpty ? available.first : null;
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

      // 确保目录存在
      if (_downloadDir == null || _installDir == null) {
        await initialize();
      }

      // 从 Adoptium API 获取下载信息
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.downloading,
        progress: 0,
        message: '正在获取下载信息...',
      ));

      final apiUrl = 'https://api.adoptium.net/v3/assets/latest/${release.version}/hotspot'
          '?os=${_getOsName()}&architecture=${_getArchitecture()}'
          '&image_type=jre&vendor=eclipse';

      final data = await NetworkClient().getJson(apiUrl) as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('Adoptium API returned empty result for Java ${release.version}');
      }

      final binary = data[0]['binary'] as Map<String, dynamic>;
      final package = binary['package'] as Map<String, dynamic>;
      final downloadUrl = package['link'] as String;
      final fileName = package['name'] as String;

      // 下载文件
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.downloading,
        progress: 0.1,
        message: '正在下载 $fileName...',
      ));

      final zipPath = path.join(_downloadDir!.path, fileName);
      await NetworkClient().downloadFile(
        downloadUrl,
        zipPath,
        onProgress: (downloaded, total) {
          if (total > 0) {
            final progress = downloaded / total;
            _emitProgress(JavaDownloadProgress(
              status: JavaInstallStatus.downloading,
              progress: 0.1 + progress * 0.7,
              message: '下载中... ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB',
            ));
          }
        },
      );

      // 解压文件
      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.extracting,
        progress: 0.8,
        message: '正在解压...',
      ));

      final extractDir = path.join(_installDir!.path, 'java-${release.version}');
      await _extractArchive(zipPath, extractDir);

      // 删除下载的压缩包
      try {
        await File(zipPath).delete();
      } catch (_) {}

      // 查找 java 可执行文件路径
      final javaExePath = getJavaExecutable(extractDir);
      if (javaExePath == null) {
        throw Exception('Java executable not found in extracted directory');
      }

      _emitProgress(JavaDownloadProgress(
        status: JavaInstallStatus.completed,
        progress: 1.0,
        message: 'Java ${release.version} 安装成功！',
      ));

      _logger.info('Java ${release.version} installed at $extractDir');
      return extractDir;
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

  /// 获取当前操作系统名称（用于 Adoptium API）
  String _getOsName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'mac';
    return 'linux';
  }

  /// 获取当前架构名称（用于 Adoptium API）
  String _getArchitecture() {
    // 常见架构映射
    final arch = Platform.version;
    if (arch.contains('arm64') || arch.contains('aarch64')) return 'aarch64';
    return 'x64';
  }

  /// 解压归档文件（支持 .zip 和 .tar.gz）
  Future<void> _extractArchive(String archivePath, String targetDir) async {
    final file = File(archivePath);
    final bytes = await file.readAsBytes();

    if (archivePath.endsWith('.zip')) {
      // 解压 ZIP 文件
      final zipArchive = archive_lib.ZipDecoder().decodeBytes(bytes);
      for (final entry in zipArchive) {
        final entryPath = path.join(targetDir, entry.name);
        if (entry.isFile) {
          final outFile = File(entryPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(entry.content as List<int>);
        } else {
          await Directory(entryPath).create(recursive: true);
        }
      }
    } else if (archivePath.endsWith('.tar.gz') || archivePath.endsWith('.tgz')) {
      // 解压 tar.gz 文件
      final gzDecoded = archive_lib.GZipDecoder().decodeBytes(bytes);
      final tarArchive = archive_lib.TarDecoder().decodeBytes(gzDecoded);
      for (final entry in tarArchive) {
        final entryPath = path.join(targetDir, entry.name);
        if (entry.isFile) {
          final outFile = File(entryPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(entry.content as List<int>);
        } else {
          await Directory(entryPath).create(recursive: true);
        }
      }
    } else {
      throw Exception('Unsupported archive format: $archivePath');
    }
  }

  /// 检查是否已经安装
  Future<String?> _checkExistingInstallation(JavaRelease release) async {
    final installPath = path.join(_installDir!.path, 'java-${release.version}');

    // 检查 java 可执行文件是否存在
    final javaExe = getJavaExecutable(installPath);
    if (javaExe != null) {
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
        final dirName = path.basename(dir.path);
        // 检查目录名是否符合 java-{version} 格式
        if (dirName.startsWith('java-')) {
          final version = dirName.substring(5);
          // 检查 java 可执行文件是否存在
          final javaExe = getJavaExecutable(dir.path);
          if (javaExe != null) {
            installed.add(JavaRelease(
              version: version,
              vendor: 'Eclipse Temurin',
            ));
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
