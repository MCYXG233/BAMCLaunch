import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../core/logger.dart';
import '../di/service_locator.dart';
import '../platform/platform_adapter_factory.dart';

/// Adoptium API 响应模型
class AdoptiumRelease {
  final String version;
  final String downloadUrl;
  final String fileName;
  final String architecture;
  final String os;
  final String javatype;
  final String link;

  AdoptiumRelease({
    required this.version,
    required this.downloadUrl,
    required this.fileName,
    required this.architecture,
    required this.os,
    required this.javatype,
    required this.link,
  });

  factory AdoptiumRelease.fromJson(Map<String, dynamic> json) {
    return AdoptiumRelease(
      version: json['version'] ?? '',
      downloadUrl: json['binary']['link'] ?? '',
      fileName: json['binary']['name'] ?? '',
      architecture: json['binary']['architecture'] ?? '',
      os: json['binary']['os'] ?? '',
      javatype: json['binary']['image_type'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

/// Java 下载服务
class JavaDownloadService {
  static JavaDownloadService? _instance;
  static JavaDownloadService get instance =>
      ServiceLocator.instance.tryGet<JavaDownloadService>() ??
      (_instance ??= JavaDownloadService._());
  JavaDownloadService._();

  final Logger _logger = Logger('JavaDownloadService');
  final NetworkClient _networkClient = NetworkClient();

  /// Adoptium API 基础 URL
  static const String _adoptiumApiBase = 'https://api.adoptium.net/v3';

  /// 获取指定版本的可用 Java 列表
  Future<List<AdoptiumRelease>> getAvailableJava({
    required int majorVersion,
    required String architecture,
    String os = 'windows',
    String imageType = 'jdk',
  }) async {
    try {
      final url = '$_adoptiumApiBase/assets/featured'
          '?architecture=$architecture'
          '&image_type=$imageType'
          '&os=$os'
          '&project=jdk'
          '&release=latest'
          '&vendor=eclipse';

      _logger.info('Fetching Java $majorVersion from Adoptium...');

      final response = await _networkClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // 过滤出指定主版本的 Java
        final filtered = data.where((item) {
          final version = item['version'] as String?;
          if (version == null) return false;
          // 检查版本号是否匹配（例如 "17.0.2+12" 中的 17）
          final major = int.tryParse(version.split('.').first.split('+').first.split('-').first);
          return major == majorVersion;
        }).toList();

        return filtered.map((item) => AdoptiumRelease.fromJson(item)).toList();
      } else {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'HTTP ${response.statusCode}',
          retryable: true,
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch Java list', e, stackTrace);
      rethrow;
    }
  }

  /// 获取推荐下载链接
  Future<AdoptiumRelease?> getRecommendedDownload({
    required int majorVersion,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // 优先选择 x64 架构
      final releases = await getAvailableJava(
        majorVersion: majorVersion,
        architecture: 'x64',
        os: 'windows',
        imageType: 'jdk',
      );

      if (releases.isEmpty) {
        _logger.warning('No Java $majorVersion found, trying x86...');
        // 如果没有 x64，尝试 x86
        final x86Releases = await getAvailableJava(
          majorVersion: majorVersion,
          architecture: 'x86',
          os: 'windows',
          imageType: 'jdk',
        );
        if (x86Releases.isNotEmpty) {
          return x86Releases.first;
        }
      } else {
        return releases.first;
      }

      // 如果还是没有，尝试查找最新版本
      _logger.warning('No exact match for Java $majorVersion, finding latest...');
      final latestReleases = await getAvailableJava(
        majorVersion: majorVersion,
        architecture: 'x64',
        os: 'windows',
        imageType: 'jdk',
      );

      return latestReleases.isNotEmpty ? latestReleases.first : null;
    } catch (e) {
      _logger.error('Failed to get recommended download', e);
      return null;
    }
  }

  /// 下载并安装 Java
  Future<String> downloadAndInstallJava({
    required int majorVersion,
    required String destinationPath,
    void Function(int received, int total)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    try {
      onStatus?.call('正在获取下载链接...');

      final release = await getRecommendedDownload(
        majorVersion: majorVersion,
      );

      if (release == null || release.downloadUrl.isEmpty) {
        throw AppException.fromCode(
          ErrorCodes.networkDownloadFailed,
          detail: '无法获取 Java $majorVersion 的下载链接',
        );
      }

      _logger.info('Downloading Java from: ${release.downloadUrl}');

      onStatus?.call('正在下载 Java $majorVersion...');

      // 创建下载目录
      final downloadDir = Directory(destinationPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 下载文件
      final fileName = release.fileName;
      final filePath = path.join(destinationPath, fileName);

      await _networkClient.downloadFile(
        release.downloadUrl,
        filePath,
        onProgress: onProgress,
      );

      _logger.info('Download completed: $filePath');

      onStatus?.call('正在解压 Java...');

      // 解压文件
      await _extractJava(filePath, destinationPath);

      // 清理 zip 文件
      final zipFile = File(filePath);
      if (await zipFile.exists()) {
        await zipFile.delete();
        _logger.info('Cleaned up zip file: $filePath');
      }

      // 查找解压后的 java.exe 路径
      final javaPath = await _findJavaExecutable(destinationPath);

      if (javaPath == null) {
        throw AppException.fromCode(
          ErrorCodes.gameJavaNotFound,
          detail: 'Java 解压后未找到 java.exe',
        );
      }

      _logger.info('Java installed at: $javaPath');
      onStatus?.call('Java 安装完成!');

      return javaPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to download and install Java', e, stackTrace);
      rethrow;
    }
  }

  /// 解压 Java
  Future<void> _extractJava(String zipPath, String destinationPath) async {
    try {
      _logger.info('Extracting Java to: $destinationPath');

      // 使用系统解压命令
      if (Platform.isWindows) {
        // Windows: 使用 PowerShell 的 Expand-Archive
        final result = await Process.run(
          'powershell',
          [
            '-Command',
            'Expand-Archive',
            '-Path',
            zipPath,
            '-DestinationPath',
            destinationPath,
            '-Force',
          ],
        );

        if (result.exitCode != 0) {
          throw AppException.fromCode(
            ErrorCodes.fileArchiveError,
            detail: result.stderr.toString(),
            originalError: result.stderr,
          );
        }
      } else {
        // 其他平台: 尝试使用 unzip
        final result = await Process.run(
          'unzip',
          ['-o', zipPath, '-d', destinationPath],
        );

        if (result.exitCode != 0) {
          throw AppException.fromCode(
            ErrorCodes.fileArchiveError,
            detail: result.stderr.toString(),
            originalError: result.stderr,
          );
        }
      }

      _logger.info('Java extracted successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to extract Java', e, stackTrace);
      rethrow;
    }
  }

  /// 查找 java.exe 路径
  Future<String?> _findJavaExecutable(String basePath) async {
    try {
      final dir = Directory(basePath);

      // 递归查找 java.exe
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path).toLowerCase();
          if (fileName == 'java.exe') {
            _logger.info('Found java.exe at: ${entity.path}');
            return entity.path;
          }
        }
      }

      _logger.warning('java.exe not found in: $basePath');
      return null;
    } catch (e, stackTrace) {
      _logger.error('Failed to find java.exe', e, stackTrace);
      return null;
    }
  }

  /// 验证下载的 Java
  Future<bool> validateJava(String javaPath) async {
    try {
      final file = File(javaPath);
      if (!await file.exists()) {
        return false;
      }

      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
