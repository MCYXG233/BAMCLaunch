import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../core/logger.dart';
import '../config/config_manager.dart';
import '../core/error_codes.dart';

/// 版本信息
class ReleaseInfo {
  final String version;
  final String? name;
  final String? body;
  final String? downloadUrl;
  final DateTime? publishedAt;
  final bool? isPreRelease;

  ReleaseInfo({
    required this.version,
    this.name,
    this.body,
    this.downloadUrl,
    this.publishedAt,
    this.isPreRelease,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      version: json['tag_name'] ?? '',
      name: json['name'],
      body: json['body'],
      downloadUrl: (json['assets'] as List<dynamic>?)
          ?.firstWhere(
            (asset) =>
                (asset['name'] as String).endsWith('.exe') ||
                (asset['name'] as String).endsWith('.zip'),
            orElse: () => null,
          )?['browser_download_url'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      isPreRelease: json['prerelease'] ?? false,
    );
  }
}

/// 更新管理器
class UpdateManager {
  static UpdateManager? _instance;
  static UpdateManager get instance => _instance ??= UpdateManager._internal();

  final Logger _logger = Logger('UpdateManager');
  final ConfigManager _config = ConfigManager.instance;

  static const String defaultOwner = 'BAMCLaunch';
  static const String defaultRepoName = 'BAMCLaunch';
  static const String defaultRepo = '$defaultOwner/$defaultRepoName';
  static const Duration checkInterval = Duration(hours: 24);

  UpdateManager._internal();

  /// 最后检查时间
  DateTime? _lastCheckedAt;

  /// 最新版本信息
  ReleaseInfo? _latestRelease;

  /// 是否正在检查更新
  bool _isChecking = false;

  /// 更新检查流
  final StreamController<ReleaseInfo?> _updateStream =
      StreamController.broadcast();

  Stream<ReleaseInfo?> get updateStream => _updateStream.stream;

  /// 初始化
  Future<void> initialize() async {
    _logger.info('Initializing UpdateManager...');

    final lastChecked = _config.getString('update_last_checked');
    if (lastChecked != null) {
      try {
        _lastCheckedAt = DateTime.parse(lastChecked);
      } catch (e) {
        _logger.warning('Failed to parse last checked time', e);
      }
    }

    _logger.info('UpdateManager initialized');
  }

  /// 检查更新
  Future<ReleaseInfo?> checkForUpdates({
    bool force = false,
    String? repo,
  }) async {
    if (_isChecking) {
      _logger.warning('Update check already in progress');
      return _latestRelease;
    }

    final repoToCheck = repo ?? _config.getString('update_repo') ?? defaultRepo;
    _logger.info('Checking for updates from $repoToCheck...');

    // 检查是否需要检查（24小时间隔）
    if (!force && _lastCheckedAt != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckedAt!);
      if (timeSinceLastCheck < checkInterval) {
        _logger.info('Skipping update check (last checked ${_lastCheckedAt})');
        return _latestRelease;
      }
    }

    _isChecking = true;

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$repoToCheck/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BAMCLauncher',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _latestRelease = ReleaseInfo.fromJson(data);

        // 保存最后检查时间
        _lastCheckedAt = DateTime.now();
        await _config.setString(
          'update_last_checked',
          _lastCheckedAt!.toIso8601String(),
        );

        _logger.info('Latest release: ${_latestRelease?.version}');
        _updateStream.add(_latestRelease);
        return _latestRelease;
      } else {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'Failed to check updates: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to check for updates', e, stackTrace);
      if (e is AppException) rethrow;
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: e.toString(),
      );
    } finally {
      _isChecking = false;
    }
  }

  /// 比较版本（返回值：<0表示当前版本旧，0表示相等，>0表示当前版本新）
  int compareVersions(String currentVersion, String newVersion) {
    // 移除v前缀
    final current = currentVersion.replaceFirst('v', '');
    final latest = newVersion.replaceFirst('v', '');

    final currentParts = current.split('.').map(int.tryParse).toList();
    final latestParts = latest.split('.').map(int.tryParse).toList();

    for (int i = 0; i < currentParts.length || i < latestParts.length; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] ?? 0 : 0;
      final latestPart = i < latestParts.length ? latestParts[i] ?? 0 : 0;

      if (currentPart != latestPart) {
        return currentPart - latestPart;
      }
    }

    return 0;
  }

  /// 检查是否有新版本可用
  bool hasUpdate(String currentVersion) {
    if (_latestRelease == null) return false;
    return compareVersions(currentVersion, _latestRelease!.version) < 0;
  }

  /// 下载更新
  Future<File> downloadUpdate({
    String? downloadUrl,
    Function(double)? onProgress,
  }) async {
    if (_latestRelease == null && downloadUrl == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No release info available',
      );
    }

    final url = downloadUrl ?? _latestRelease?.downloadUrl;
    if (url == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No download URL found',
      );
    }

    _logger.info('Downloading update from $url...');

    // 确定下载路径
    final tempDir = Directory.systemTemp;
    final fileName = path.basename(url);
    final filePath = path.join(tempDir.path, 'bamclaunch_update', fileName);

    // 创建目录
    final fileDir = Directory(path.dirname(filePath));
    if (!await fileDir.exists()) {
      await fileDir.create(recursive: true);
    }

    // 下载文件
    final file = File(filePath);
    final request = await http.Client().get(Uri.parse(url));

    await file.writeAsBytes(request.bodyBytes);

    _logger.info('Update downloaded: $filePath');
    return file;
  }

  Future<void> installUpdate(File updateFile) async {
    _logger.info('Installing update: ${updateFile.path}');

    final currentExe = File(Platform.resolvedExecutable);
    final backupPath = '${currentExe.path}.bak';
    File? backupFile;

    try {
      if (Platform.isWindows) {
        if (updateFile.path.endsWith('.exe')) {
          backupFile = await _createBackup(currentExe, backupPath);
          await _replaceExecutable(updateFile, currentExe);
        } else if (updateFile.path.endsWith('.zip')) {
          backupFile = await _createBackup(currentExe, backupPath);
          await _installFromZip(updateFile, currentExe);
        } else {
          throw AppException.fromCode(
            ErrorCodes.unknown,
            detail: 'Unsupported update format: ${updateFile.path}',
          );
        }
      } else if (Platform.isMacOS) {
        // TODO: macOS update installation
        throw AppException.fromCode(
          ErrorCodes.unknown,
          detail: 'macOS updates not implemented yet',
        );
      } else if (Platform.isLinux) {
        // TODO: Linux update installation
        throw AppException.fromCode(
          ErrorCodes.unknown,
          detail: 'Linux updates not implemented yet',
        );
      }

      _logger.info('Update installation completed');
    } catch (e, stackTrace) {
      _logger.error('Failed to install update', e, stackTrace);
      if (backupFile != null) {
        await _restoreFromBackup(backupFile, currentExe);
      }
      rethrow;
    }
  }

  Future<File> _createBackup(File currentExe, String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      await currentExe.copy(backupPath);
      _logger.info('Backup created: $backupPath');
      return backupFile;
    } catch (e, stackTrace) {
      _logger.error('Failed to create backup', e, stackTrace);
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'Failed to create backup: $e',
      );
    }
  }

  Future<void> _restoreFromBackup(File backupFile, File targetExe) async {
    try {
      _logger.warning('Restoring from backup: ${backupFile.path}');
      if (await backupFile.exists()) {
        if (await targetExe.exists()) {
          await targetExe.delete();
        }
        await backupFile.copy(targetExe.path);
        _logger.info('Restored from backup successfully');
      } else {
        _logger.error('Backup file not found: ${backupFile.path}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to restore from backup', e, stackTrace);
    }
  }

  Future<void> _replaceExecutable(File source, File target) async {
    try {
      if (await target.exists()) {
        await target.delete();
      }
      await source.copy(target.path);
      _logger.info('Executable replaced: ${target.path}');
    } catch (e, stackTrace) {
      _logger.error('Failed to replace executable', e, stackTrace);
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'Failed to replace executable: $e',
      );
    }
  }

  Future<void> _installFromZip(File zipFile, File currentExe) async {
    _logger.info('Extracting ZIP update: ${zipFile.path}');

    final bytes = await zipFile.readAsBytes();
    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    final exeFileName = path.basename(currentExe.path);
    archive.ArchiveFile? newExeFile;

    for (final file in zipArchive.files) {
      if (!file.isFile) continue;
      final fileName = path.basename(file.name);
      if (fileName == exeFileName) {
        newExeFile = file;
        break;
      }
    }

    if (newExeFile == null) {
      for (final file in zipArchive.files) {
        if (!file.isFile) continue;
        if (file.name.endsWith('.exe')) {
          newExeFile = file;
          break;
        }
      }
    }

    if (newExeFile == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No executable found in ZIP archive',
      );
    }

    final tempExtractDir = Directory(
      path.join(Directory.systemTemp.path, 'bamclaunch_update', 'extract'),
    );
    if (await tempExtractDir.exists()) {
      await tempExtractDir.delete(recursive: true);
    }
    await tempExtractDir.create(recursive: true);

    final extractedExePath = path.join(
      tempExtractDir.path,
      path.basename(newExeFile.name),
    );
    final extractedFile = File(extractedExePath);
    await extractedFile.writeAsBytes(newExeFile.content as List<int>);

    _logger.info('Extracted executable: $extractedExePath');

    await _replaceExecutable(extractedFile, currentExe);

    try {
      await tempExtractDir.delete(recursive: true);
    } catch (e) {
      _logger.warning('Failed to clean up temp extract directory', e);
    }
  }

  /// 清理临时文件
  Future<void> cleanup() async {
    try {
      final tempDir = Directory(path.join(Directory.systemTemp.path, 'bamclaunch_update'));
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        _logger.info('Cleaned up update temp directory');
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to cleanup temp directory', e, stackTrace);
    }
  }

  /// 关闭
  Future<void> dispose() async {
    await _updateStream.close();
  }
}
