import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../core/logger.dart';
import '../config/config_manager.dart';
import '../core/error_codes.dart';

/// 版本发布信息类
///
/// 用于存储从 GitHub API 获取的版本发布信息，包括版本号、发布名称、
/// 更新说明、下载链接、发布时间和是否为预发布版本等。
class ReleaseInfo {
  /// 版本号（从 GitHub release 的 tag_name 解析）
  final String version;

  /// 发布名称（可选）
  final String? name;

  /// 更新说明/发布日志（可选）
  final String? body;

  /// 下载链接（优先选择 .exe 或 .zip 格式的资源）
  final String? downloadUrl;

  /// 发布时间（ISO 8601 格式）
  final DateTime? publishedAt;

  /// 是否为预发布版本
  final bool? isPreRelease;

  /// 创建版本信息实例
  ///
  /// [version] 版本号，必填
  /// [name] 发布名称，可选
  /// [body] 更新说明，可选
  /// [downloadUrl] 下载链接，可选
  /// [publishedAt] 发布时间，可选
  /// [isPreRelease] 是否为预发布版本，可选
  ReleaseInfo({
    required this.version,
    this.name,
    this.body,
    this.downloadUrl,
    this.publishedAt,
    this.isPreRelease,
  });

  /// 从 JSON 数据创建版本信息实例
  ///
  /// 解析 GitHub API 返回的 release JSON 数据，提取版本信息。
  /// 下载链接会优先查找 .exe 或 .zip 格式的资源文件。
  ///
  /// [json] GitHub API 返回的 release JSON 对象
  /// 返回解析后的 [ReleaseInfo] 实例
  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      // 从 tag_name 字段获取版本号
      version: json['tag_name'] ?? '',
      // 发布名称
      name: json['name'],
      // 发布说明内容
      body: json['body'],
      // 从 assets 数组中查找第一个 .exe 或 .zip 文件的下载链接
      downloadUrl: (json['assets'] as List<dynamic>?)
          ?.firstWhere(
            (asset) =>
                (asset['name'] as String).endsWith('.exe') ||
                (asset['name'] as String).endsWith('.zip'),
            orElse: () => null,
          )?['browser_download_url'],
      // 解析 ISO 8601 格式的发布时间
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      // 是否为预发布版本
      isPreRelease: json['prerelease'] ?? false,
    );
  }
}

/// 更新管理器
///
/// 负责应用程序的自动更新功能，包括：
/// - 检查 GitHub 仓库的最新版本
/// - 下载更新文件
/// - 安装更新（支持 .exe 和 .zip 格式）
/// - 版本比较
/// - 更新状态通知
///
/// 使用单例模式，通过 [instance] 获取全局实例。
class UpdateManager {
  /// 单例实例
  static UpdateManager? _instance;

  /// 获取单例实例
  ///
  /// 如果实例不存在则创建新实例。
  static UpdateManager get instance => _instance ??= UpdateManager._internal();

  /// 日志记录器
  final Logger _logger = Logger('UpdateManager');

  /// 配置管理器实例
  final ConfigManager _config = ConfigManager.instance;

  /// GitHub 仓库所有者名称
  static const String defaultOwner = 'BAMCLaunch';

  /// GitHub 仓库名称
  static const String defaultRepoName = 'BAMCLaunch';

  /// 默认的 GitHub 仓库路径（格式：owner/repo）
  static const String defaultRepo = '$defaultOwner/$defaultRepoName';

  /// 版本检查间隔（24小时）
  static const Duration checkInterval = Duration(hours: 24);

  /// 私有构造函数（单例模式）
  UpdateManager._internal();

  /// 最后检查更新的时间
  ///
  /// 用于控制检查频率，避免过于频繁的 API 请求。
  DateTime? _lastCheckedAt;

  /// 最新版本信息缓存
  ///
  /// 缓存最近一次检查获取到的版本信息，避免重复请求。
  ReleaseInfo? _latestRelease;

  /// 是否正在检查更新的标志
  ///
  /// 防止并发检查，确保同一时间只有一个检查任务在运行。
  bool _isChecking = false;

  /// 更新检查结果流控制器
  ///
  /// 用于广播版本检查结果，支持多个监听者。
  final StreamController<ReleaseInfo?> _updateStream =
      StreamController.broadcast();

  /// 获取更新检查结果流
  ///
  /// 订阅此流可以监听版本检查结果。
  Stream<ReleaseInfo?> get updateStream => _updateStream.stream;

  /// 初始化更新管理器
  ///
  /// 从配置中恢复上次检查时间，用于控制检查频率。
  /// 应在应用启动时调用此方法。
  Future<void> initialize() async {
    _logger.info('Initializing UpdateManager...');

    // 从配置中读取上次检查时间
    final lastChecked = _config.getString('update_last_checked');
    if (lastChecked != null) {
      try {
        _lastCheckedAt = DateTime.parse(lastChecked);
      } catch (e) {
        // 解析失败时记录警告，但不影响初始化
        _logger.warning('Failed to parse last checked time', e);
      }
    }

    _logger.info('UpdateManager initialized');
  }

  /// 检查更新
  ///
  /// 从指定的 GitHub 仓库获取最新版本信息。
  ///
  /// [force] 是否强制检查，忽略 24 小时间隔限制
  /// [repo] 要检查的仓库路径（格式：owner/repo），为空则使用配置或默认值
  ///
  /// 返回最新版本信息 [ReleaseInfo]，如果检查失败或跳过则返回 null。
  ///
  /// 抛出 [AppException] 当网络请求失败或其他错误发生时。
  Future<ReleaseInfo?> checkForUpdates({
    bool force = false,
    String? repo,
  }) async {
    // 防止并发检查
    if (_isChecking) {
      _logger.warning('Update check already in progress');
      return _latestRelease;
    }

    // 确定要检查的仓库：参数 > 配置 > 默认值
    final repoToCheck = repo ?? _config.getString('update_repo') ?? defaultRepo;
    _logger.info('Checking for updates from $repoToCheck...');

    // 检查是否需要检查（24小时间隔）
    // 如果不是强制检查，且上次检查时间存在，则判断是否超过间隔
    if (!force && _lastCheckedAt != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckedAt!);
      if (timeSinceLastCheck < checkInterval) {
        // 未超过间隔时间，跳过检查
        _logger.info('Skipping update check (last checked ${_lastCheckedAt})');
        return _latestRelease;
      }
    }

    // 设置检查中标志
    _isChecking = true;

    try {
      // 调用 GitHub API 获取最新版本信息
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$repoToCheck/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BAMCLauncher',
        },
      );

      if (response.statusCode == 200) {
        // 解析 JSON 响应
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _latestRelease = ReleaseInfo.fromJson(data);

        // 保存最后检查时间到配置
        _lastCheckedAt = DateTime.now();
        await _config.setString(
          'update_last_checked',
          _lastCheckedAt!.toIso8601String(),
        );

        _logger.info('Latest release: ${_latestRelease?.version}');
        // 通过流广播检查结果
        _updateStream.add(_latestRelease);
        return _latestRelease;
      } else {
        // HTTP 状态码非 200，抛出网络错误
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'Failed to check updates: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to check for updates', e, stackTrace);
      // 如果已经是 AppException 则直接重新抛出
      if (e is AppException) rethrow;
      // 其他错误包装为 AppException
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: e.toString(),
      );
    } finally {
      // 无论成功或失败，都重置检查标志
      _isChecking = false;
    }
  }

  /// 比较两个版本号
  ///
  /// 使用语义化版本比较规则，逐段比较版本号。
  ///
  /// [currentVersion] 当前版本号
  /// [newVersion] 新版本号
  ///
  /// 返回值：
  /// - 小于 0：当前版本比新版本旧
  /// - 等于 0：两个版本相同
  /// - 大于 0：当前版本比新版本新
  int compareVersions(String currentVersion, String newVersion) {
    // 移除版本号前的 'v' 前缀（如果有）
    final current = currentVersion.replaceFirst('v', '');
    final latest = newVersion.replaceFirst('v', '');

    // 按点号分割版本号，并转换为整数
    final currentParts = current.split('.').map(int.tryParse).toList();
    final latestParts = latest.split('.').map(int.tryParse).toList();

    // 逐段比较版本号
    for (int i = 0; i < currentParts.length || i < latestParts.length; i++) {
      // 处理版本段不存在或解析失败的情况，默认为 0
      final currentPart = i < currentParts.length ? currentParts[i] ?? 0 : 0;
      final latestPart = i < latestParts.length ? latestParts[i] ?? 0 : 0;

      // 如果当前段不相等，返回差值
      if (currentPart != latestPart) {
        return currentPart - latestPart;
      }
    }

    // 所有段都相等，版本相同
    return 0;
  }

  /// 检查是否有新版本可用
  ///
  /// 比较当前版本与缓存中的最新版本。
  ///
  /// [currentVersion] 当前应用程序版本号
  ///
  /// 返回 true 如果有新版本可用，否则返回 false。
  /// 如果尚未检查过更新（_latestRelease 为 null），返回 false。
  bool hasUpdate(String currentVersion) {
    if (_latestRelease == null) return false;
    // 比较版本：如果当前版本比最新版本旧，则有更新
    return compareVersions(currentVersion, _latestRelease!.version) < 0;
  }

  /// 下载更新文件
  ///
  /// 从指定 URL 或最新版本的下载链接下载更新文件。
  ///
  /// [downloadUrl] 下载链接，为空则使用最新版本的下载链接
  /// [onProgress] 下载进度回调函数，参数为进度百分比（0.0 - 1.0）
  ///
  /// 返回下载完成的文件对象。
  ///
  /// 抛出 [AppException] 当没有可用的下载链接或下载失败时。
  Future<File> downloadUpdate({
    String? downloadUrl,
    Function(double)? onProgress,
  }) async {
    // 检查是否有可用的版本信息和下载链接
    if (_latestRelease == null && downloadUrl == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No release info available',
      );
    }

    // 确定下载 URL：参数 > 最新版本缓存
    final url = downloadUrl ?? _latestRelease?.downloadUrl;
    if (url == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No download URL found',
      );
    }

    _logger.info('Downloading update from $url...');

    // 确定下载路径：使用系统临时目录下的子目录
    final tempDir = Directory.systemTemp;
    final fileName = path.basename(url);
    final filePath = path.join(tempDir.path, 'bamclaunch_update', fileName);

    // 创建下载目录（如果不存在）
    final fileDir = Directory(path.dirname(filePath));
    if (!await fileDir.exists()) {
      await fileDir.create(recursive: true);
    }

    // 下载文件
    final file = File(filePath);
    final request = await http.Client().get(Uri.parse(url));

    // 将下载内容写入文件
    await file.writeAsBytes(request.bodyBytes);

    _logger.info('Update downloaded: $filePath');
    return file;
  }

  /// 安装更新
  ///
  /// 根据更新文件类型和操作系统执行更新安装。
  /// 目前支持 Windows 平台的 .exe 和 .zip 格式更新。
  ///
  /// [updateFile] 下载的更新文件
  ///
  /// 抛出 [AppException] 当安装失败或不支持的平台/格式时。
  Future<void> installUpdate(File updateFile) async {
    _logger.info('Installing update: ${updateFile.path}');

    // 获取当前可执行文件路径
    final currentExe = File(Platform.resolvedExecutable);
    final backupPath = '${currentExe.path}.bak';
    File? backupFile;

    try {
      if (Platform.isWindows) {
        // Windows 平台更新逻辑
        if (updateFile.path.endsWith('.exe')) {
          // 直接替换可执行文件
          backupFile = await _createBackup(currentExe, backupPath);
          await _replaceExecutable(updateFile, currentExe);
        } else if (updateFile.path.endsWith('.zip')) {
          // 从 ZIP 压缩包中提取并替换
          backupFile = await _createBackup(currentExe, backupPath);
          await _installFromZip(updateFile, currentExe);
        } else {
          // 不支持的更新格式
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
      // 安装失败时尝试从备份恢复
      if (backupFile != null) {
        await _restoreFromBackup(backupFile, currentExe);
      }
      rethrow;
    }
  }

  /// 创建当前可执行文件的备份
  ///
  /// 在更新前备份当前可执行文件，以便在更新失败时恢复。
  ///
  /// [currentExe] 当前可执行文件
  /// [backupPath] 备份文件路径
  ///
  /// 返回备份文件对象。
  ///
  /// 抛出 [AppException] 当备份失败时。
  Future<File> _createBackup(File currentExe, String backupPath) async {
    try {
      final backupFile = File(backupPath);
      // 如果备份文件已存在，先删除
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      // 复制当前可执行文件到备份路径
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

  /// 从备份恢复可执行文件
  ///
  /// 当更新安装失败时，使用备份文件恢复原始可执行文件。
  ///
  /// [backupFile] 备份文件
  /// [targetExe] 目标可执行文件路径
  Future<void> _restoreFromBackup(File backupFile, File targetExe) async {
    try {
      _logger.warning('Restoring from backup: ${backupFile.path}');
      if (await backupFile.exists()) {
        // 删除损坏的目标文件
        if (await targetExe.exists()) {
          await targetExe.delete();
        }
        // 从备份恢复
        await backupFile.copy(targetExe.path);
        _logger.info('Restored from backup successfully');
      } else {
        _logger.error('Backup file not found: ${backupFile.path}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to restore from backup', e, stackTrace);
    }
  }

  /// 替换可执行文件
  ///
  /// 使用新的可执行文件替换当前可执行文件。
  ///
  /// [source] 源文件（新版本）
  /// [target] 目标文件（当前版本）
  ///
  /// 抛出 [AppException] 当替换失败时。
  Future<void> _replaceExecutable(File source, File target) async {
    try {
      // 删除目标文件（如果存在）
      if (await target.exists()) {
        await target.delete();
      }
      // 复制源文件到目标位置
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

  /// 从 ZIP 压缩包安装更新
  ///
  /// 解压 ZIP 文件，查找可执行文件，然后替换当前可执行文件。
  ///
  /// [zipFile] ZIP 压缩包文件
  /// [currentExe] 当前可执行文件
  ///
  /// 抛出 [AppException] 当 ZIP 中找不到可执行文件或安装失败时。
  Future<void> _installFromZip(File zipFile, File currentExe) async {
    _logger.info('Extracting ZIP update: ${zipFile.path}');

    // 读取 ZIP 文件内容
    final bytes = await zipFile.readAsBytes();
    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    // 获取当前可执行文件名，用于在 ZIP 中查找同名文件
    final exeFileName = path.basename(currentExe.path);
    archive.ArchiveFile? newExeFile;

    // 首先尝试查找与当前可执行文件同名的文件
    for (final file in zipArchive.files) {
      if (!file.isFile) continue;
      final fileName = path.basename(file.name);
      if (fileName == exeFileName) {
        newExeFile = file;
        break;
      }
    }

    // 如果没找到同名文件，则查找任意 .exe 文件
    if (newExeFile == null) {
      for (final file in zipArchive.files) {
        if (!file.isFile) continue;
        if (file.name.endsWith('.exe')) {
          newExeFile = file;
          break;
        }
      }
    }

    // 如果仍然没找到可执行文件，抛出异常
    if (newExeFile == null) {
      throw AppException.fromCode(
        ErrorCodes.unknown,
        detail: 'No executable found in ZIP archive',
      );
    }

    // 创建临时解压目录
    final tempExtractDir = Directory(
      path.join(Directory.systemTemp.path, 'bamclaunch_update', 'extract'),
    );
    // 如果目录已存在，先删除
    if (await tempExtractDir.exists()) {
      await tempExtractDir.delete(recursive: true);
    }
    await tempExtractDir.create(recursive: true);

    // 解压可执行文件到临时目录
    final extractedExePath = path.join(
      tempExtractDir.path,
      path.basename(newExeFile.name),
    );
    final extractedFile = File(extractedExePath);
    await extractedFile.writeAsBytes(newExeFile.content as List<int>);

    _logger.info('Extracted executable: $extractedExePath');

    // 替换当前可执行文件
    await _replaceExecutable(extractedFile, currentExe);

    // 清理临时解压目录
    try {
      await tempExtractDir.delete(recursive: true);
    } catch (e) {
      _logger.warning('Failed to clean up temp extract directory', e);
    }
  }

  /// 清理临时文件
  ///
  /// 删除更新过程中创建的临时文件和目录。
  /// 应在更新完成后或应用启动时调用。
  Future<void> cleanup() async {
    try {
      // 删除更新临时目录
      final tempDir = Directory(path.join(Directory.systemTemp.path, 'bamclaunch_update'));
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        _logger.info('Cleaned up update temp directory');
      }
    } catch (e, stackTrace) {
      // 清理失败不影响应用运行，仅记录警告
      _logger.warning('Failed to cleanup temp directory', e, stackTrace);
    }
  }

  /// 关闭更新管理器
  ///
  /// 释放资源，关闭更新流控制器。
  /// 应在应用退出时调用。
  Future<void> dispose() async {
    await _updateStream.close();
  }
}