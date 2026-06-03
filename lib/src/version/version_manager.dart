import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../config/config_keys.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../download/download_engine.dart';
import '../event/event.dart';
import '../event/event_bus.dart';
import '../game/launcher/game_file_validator.dart';
import '../game/launcher/models.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../task/task_context.dart';
import 'install_version_task.dart';
import 'models.dart';

/// 版本管理器接口
abstract class IVersionManager {
  /// 获取版本列表
  Future<List<GameVersion>> fetchVersionList();

  /// 安装版本
  Future<void> installVersion(String versionId);

  /// 获取已安装版本
  Future<List<String>> getInstalledVersions();

  /// 卸载版本
  Future<void> uninstallVersion(String versionId);

  /// 检查版本是否已安装
  Future<bool> isVersionInstalled(String versionId);

  /// 安装进度流
  Stream<VersionInstallProgress> get installProgressStream;

  /// 取消安装
  Future<void> cancelInstall();

  /// 获取版本JSON
  Future<VersionJson> fetchVersionJson(String versionId);

  /// 获取版本目录路径
  Future<String> getVersionDir(String versionId);

  /// 获取游戏目录
  Future<String> getGameDir();

  /// 补全版本文件
  Future<List<InvalidFile>> repairVersionFiles(String versionId);
}

/// 版本管理器实现（单例）
class VersionManager implements IVersionManager {
  static VersionManager? _instance;

  factory VersionManager() {
    return _instance ??= VersionManager._internal();
  }

  VersionManager._internal();

  /// 获取单例实例
  static VersionManager get instance =>
      _instance ??= VersionManager._internal();

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// BMCLAPI 版本清单地址
  static const String _versionManifestUrl =
      'https://bmclapi2.bangbang93.com/mc/game/version_manifest.json';

  /// 平台适配器
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线
  final EventBus _eventBus = EventBus();

  /// 下载引擎
  final IDownloadEngine _downloadEngine = DownloadEngine();

  /// 日志记录器
  final Logger _logger = Logger('VersionManager');

  /// 安装进度流控制器
  final StreamController<VersionInstallProgress> _installProgressController =
      StreamController<VersionInstallProgress>.broadcast();

  /// 当前安装任务
  InstallVersionTask? _currentInstallTask;

  /// 当前任务上下文
  TaskContext? _currentTaskContext;

  /// 缓存的版本清单
  VersionManifest? _cachedVersionManifest;

  /// 缓存过期时间
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 缓存最后更新时间
  DateTime? _lastCacheUpdate;

  @override
  Stream<VersionInstallProgress> get installProgressStream =>
      _installProgressController.stream;

  @override
  Future<List<GameVersion>> fetchVersionList() async {
    try {
      // 检查缓存是否有效
      if (_cachedVersionManifest != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        _logger.debug('Using cached version manifest');
        return _cachedVersionManifest!.versions;
      }

      _logger.info('Fetching version manifest from BMCLAPI');

      final networkClient = NetworkClient();
      final response = await networkClient.get(
        _versionManifestUrl,
        headers: NetworkClient.bmclapiHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch version manifest: ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedVersionManifest = VersionManifest.fromJson(json);
      _lastCacheUpdate = DateTime.now();

      _eventBus.publish(
        VersionListFetchedEvent(
          versions: _cachedVersionManifest!.versions.map((v) => v.id).toList(),
        ),
      );

      _logger.info(
        'Successfully fetched ${_cachedVersionManifest!.versions.length} versions',
      );
      return _cachedVersionManifest!.versions;
    } catch (e) {
      _logger.error('Failed to fetch version list', e);
      rethrow;
    }
  }

  @override
  Future<VersionJson> fetchVersionJson(String versionId) async {
    try {
      final versions = await fetchVersionList();
      final version = versions.firstWhere(
        (v) => v.id == versionId,
        orElse: () => throw Exception('Version $versionId not found'),
      );

      _logger.info('Fetching version JSON for $versionId');
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        version.url,
        headers: NetworkClient.bmclapiHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch version JSON: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VersionJson.fromJson(json);
    } catch (e) {
      _logger.error('Failed to fetch version JSON for $versionId', e);
      rethrow;
    }
  }

  @override
  Future<void> installVersion(String versionId) async {
    try {
      // 检查是否已安装
      if (await isVersionInstalled(versionId)) {
        _logger.warning('Version $versionId is already installed');
        return;
      }

      // 获取版本信息
      final versionJson = await fetchVersionJson(versionId);

      // 创建任务上下文
      _currentTaskContext = TaskContext();

      // 创建安装任务
      _currentInstallTask = InstallVersionTask(
        versionId: versionId,
        versionJson: versionJson,
        versionManager: this,
        platformAdapter: _platformAdapter,
        downloadEngine: _downloadEngine,
        configManager: _configManager,
        eventBus: _eventBus,
        progressController: _installProgressController,
      );

      // 运行任务
      await _currentInstallTask!.run(_currentTaskContext);

      // 添加到已安装版本列表
      await _addInstalledVersion(versionId);

      _logger.info('Successfully installed version $versionId');
    } catch (e) {
      _logger.error('Failed to install version $versionId', e);
      rethrow;
    } finally {
      _currentInstallTask = null;
      _currentTaskContext = null;
    }
  }

  @override
  Future<void> cancelInstall() async {
    if (_currentTaskContext != null) {
      _logger.info('Cancelling install task');
      _currentTaskContext!.cancel();
    }
  }

  @override
  Future<List<String>> getInstalledVersions() async {
    final installedVersions =
        _configManager.get<List<dynamic>>(ConfigKeys.installedVersions) ?? [];
    return List<String>.from(installedVersions);
  }

  @override
  Future<void> uninstallVersion(String versionId) async {
    try {
      if (!await isVersionInstalled(versionId)) {
        _logger.warning('Version $versionId is not installed');
        return;
      }

      // 删除版本目录
      final versionDir = await getVersionDir(versionId);
      final dir = Directory(versionDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _logger.info('Deleted version directory: $versionDir');
      }

      // 从已安装列表中移除
      await _removeInstalledVersion(versionId);

      _eventBus.publish(VersionUninstalledEvent(versionId: versionId));
      _logger.info('Successfully uninstalled version $versionId');
    } catch (e) {
      _logger.error('Failed to uninstall version $versionId', e);
      rethrow;
    }
  }

  @override
  Future<bool> isVersionInstalled(String versionId) async {
    final installedVersions = await getInstalledVersions();
    if (!installedVersions.contains(versionId)) {
      return false;
    }

    // 检查版本目录是否存在
    final versionDir = await getVersionDir(versionId);
    return Directory(versionDir).exists();
  }

  @override
  Future<String> getVersionDir(String versionId) async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'versions', versionId);
  }

  @override
  Future<String> getGameDir() async {
    final customDir = _configManager.get<String>(ConfigKeys.gameDirectory);
    if (customDir != null && customDir.isNotEmpty) {
      return customDir;
    }
    return await _platformAdapter.getDefaultGameDirectory();
  }

  /// 添加版本到已安装列表
  Future<void> _addInstalledVersion(String versionId) async {
    final versions = await getInstalledVersions();
    if (!versions.contains(versionId)) {
      versions.add(versionId);
      await _configManager.set<List<String>>(
        ConfigKeys.installedVersions,
        versions,
      );
      _eventBus.publish(InstalledVersionsChangedEvent(versions: versions));
    }
  }

  /// 从已安装列表中移除版本
  Future<void> _removeInstalledVersion(String versionId) async {
    final versions = await getInstalledVersions();
    versions.remove(versionId);
    await _configManager.set<List<String>>(
      ConfigKeys.installedVersions,
      versions,
    );
    _eventBus.publish(InstalledVersionsChangedEvent(versions: versions));
  }

  /// 获取资源目录
  Future<String> getAssetsDir() async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'assets');
  }

  /// 获取库目录
  Future<String> getLibrariesDir() async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'libraries');
  }

  @override
  Future<List<InvalidFile>> repairVersionFiles(String versionId) async {
    _logger.info('Repairing files for version $versionId');
    
    final versionJson = await fetchVersionJson(versionId);
    final gameDir = await getGameDir();
    final invalidFiles = await GameFileValidator.instance.validateAll(
      versionJson, 
      gameDir, 
      FileValidatePolicy.full,
    );
    
    if (invalidFiles.isEmpty) {
      _logger.info('All files are valid, no repair needed');
      return [];
    }
    
    _logger.info('Found ${invalidFiles.length} invalid files, starting repair');
    for (final file in invalidFiles) {
      if (file.url != null) {
        await _downloadEngine.download(file.url!, file.path);
      }
    }
    
    _logger.info('Repair completed for version $versionId');
    return invalidFiles;
  }

  /// 检查库文件是否需要下载
  bool shouldDownloadLibrary(Library library) {
    if (library.rules == null || library.rules!.isEmpty) {
      return true;
    }

    bool allowed = true;
    for (final rule in library.rules!) {
      final matches = _ruleMatches(rule);
      if (rule.action == 'allow') {
        allowed = matches;
      } else if (rule.action == 'disallow') {
        allowed = !matches;
      }
    }

    return allowed;
  }

  /// 检查规则是否匹配当前平台
  bool _ruleMatches(Rule rule) {
    if (rule.os == null) {
      return true;
    }

    if (rule.os!.name != null) {
      final osName = rule.os!.name!;
      if (_platformAdapter.isWindows && osName != 'windows') return false;
      if (_platformAdapter.isMacOS && osName != 'osx') return false;
      if (_platformAdapter.isLinux && osName != 'linux') return false;
    }

    // 忽略架构和版本检查，简化实现
    return true;
  }

  /// 获取原生库分类器
  String? getNativeClassifier(Library library) {
    if (library.natives == null) return null;

    String osKey;
    if (_platformAdapter.isWindows) {
      osKey = 'windows';
    } else if (_platformAdapter.isMacOS) {
      osKey = 'osx';
    } else if (_platformAdapter.isLinux) {
      osKey = 'linux';
    } else {
      return null;
    }

    return library.natives![osKey];
  }

  /// 销毁管理器
  void dispose() {
    _installProgressController.close();
  }
}
