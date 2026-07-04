import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../config/config_keys.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../di/service_locator.dart';
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
///
/// 定义了游戏版本管理的核心操作，包括版本列表获取、安装、卸载等功能。
/// 该接口提供了版本管理的抽象层，便于测试和不同实现的替换。
///
/// 主要功能：
/// - 获取可用游戏版本列表
/// - 安装指定版本
/// - 卸载已安装版本
/// - 检查版本安装状态
/// - 监控安装进度
/// - 修复版本文件
///
/// 使用示例：
/// ```dart
/// final versionManager = VersionManager();
/// final versions = await versionManager.fetchVersionList();
/// await versionManager.installVersion('1.20.4');
/// ```
abstract class IVersionManager {
  /// 获取游戏版本列表
  ///
  /// 从远程服务器（BMCLAPI）获取所有可用的 Minecraft 游戏版本列表。
  /// 返回的列表包含正式版、快照版和远古版本等信息。
  ///
  /// 返回值：
  /// - `Future<List<GameVersion>>`: 游戏版本列表，每个元素包含版本ID、类型、发布时间等信息
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 网络请求失败或数据解析错误时抛出
  ///
  /// 使用示例：
  /// ```dart
  /// final versions = await versionManager.fetchVersionList();
  /// for (final v in versions) {
  ///   print('${v.id} - ${v.type}');
  /// }
  /// ```
  Future<List<GameVersion>> fetchVersionList();

  /// 安装指定版本
  ///
  /// 下载并安装指定版本的游戏文件，包括：
  /// - 版本 JSON 配置文件
  /// - 客户端 JAR 文件
  /// - 依赖库文件
  /// - 资源文件（材质、音效等）
  ///
  /// 参数：
  /// - `versionId` (String): 要安装的版本ID，如 "1.20.4"、"23w43a" 等
  ///
  /// 返回值：
  /// - `Future<void>`: 安装完成的 Future
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在、下载失败或文件写入错误时抛出
  ///
  /// 使用示例：
  /// ```dart
  /// try {
  ///   await versionManager.installVersion('1.20.4');
  ///   print('安装成功');
  /// } catch (e) {
  ///   print('安装失败: $e');
  /// }
  /// ```
  Future<void> installVersion(String versionId);

  /// 获取已安装版本列表
  ///
  /// 从本地配置中读取已成功安装的版本ID列表。
  ///
  /// 返回值：
  /// - `Future<List<String>>`: 已安装版本ID列表
  ///
  /// 使用示例：
  /// ```dart
  /// final installed = await versionManager.getInstalledVersions();
  /// print('已安装 ${installed.length} 个版本');
  /// ```
  Future<List<String>> getInstalledVersions();

  /// 卸载指定版本
  ///
  /// 删除指定版本的所有本地文件，包括：
  /// - 版本目录及其下所有文件
  /// - 从已安装列表中移除该版本记录
  ///
  /// 参数：
  /// - `versionId` (String): 要卸载的版本ID
  ///
  /// 返回值：
  /// - `Future<void>`: 卸载完成的 Future
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 文件删除失败时抛出
  ///
  /// 使用示例：
  /// ```dart
  /// await versionManager.uninstallVersion('1.19.2');
  /// ```
  Future<void> uninstallVersion(String versionId);

  /// 检查版本是否已安装
  ///
  /// 验证指定版本是否已正确安装，检查内容包括：
  /// - 版本是否在已安装列表中
  /// - 版本目录是否存在
  ///
  /// 参数：
  /// - `versionId` (String): 要检查的版本ID
  ///
  /// 返回值：
  /// - `Future<bool>`: 如果版本已安装返回 `true`，否则返回 `false`
  ///
  /// 使用示例：
  /// ```dart
  /// if (await versionManager.isVersionInstalled('1.20.4')) {
  ///   print('版本已安装');
  /// }
  /// ```
  Future<bool> isVersionInstalled(String versionId);

  /// 安装进度流
  ///
  /// 提供版本安装过程中的实时进度更新，可用于显示安装进度条。
  ///
  /// 返回值：
  /// - `Stream<VersionInstallProgress>`: 安装进度事件流，包含当前阶段、进度百分比等信息
  ///
  /// 使用示例：
  /// ```dart
  /// versionManager.installProgressStream.listen((progress) {
  ///   print('${progress.stage}: ${progress.progress}%');
  /// });
  /// ```
  Stream<VersionInstallProgress> get installProgressStream;

  /// 取消当前安装任务
  ///
  /// 中断正在进行的版本安装任务，清理已下载的部分文件。
  /// 如果没有正在进行的安装任务，则此方法不执行任何操作。
  ///
  /// 返回值：
  /// - `Future<void>`: 取消操作的 Future
  ///
  /// 使用示例：
  /// ```dart
  /// // 用户点击取消按钮时调用
  /// await versionManager.cancelInstall();
  /// ```
  Future<void> cancelInstall();

  /// 获取版本JSON配置
  ///
  /// 从远程服务器获取指定版本的详细JSON配置信息，包含：
  /// - 主类信息
  /// - 库依赖列表
  /// - 启动参数模板
  /// - 资源索引信息
  ///
  /// 参数：
  /// - `versionId` (String): 要获取配置的版本ID
  ///
  /// 返回值：
  /// - `Future<VersionJson>`: 版本JSON配置对象
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在或网络请求失败时抛出
  ///
  /// 使用示例：
  /// ```dart
  /// final versionJson = await versionManager.fetchVersionJson('1.20.4');
  /// print('主类: ${versionJson.mainClass}');
  /// ```
  Future<VersionJson> fetchVersionJson(String versionId);

  /// 获取版本目录路径
  ///
  /// 返回指定版本的本地存储目录的绝对路径。
  /// 目录结构通常为：`{游戏目录}/versions/{versionId}/`
  ///
  /// 参数：
  /// - `versionId` (String): 版本ID
  ///
  /// 返回值：
  /// - `Future<String>`: 版本目录的绝对路径
  ///
  /// 使用示例：
  /// ```dart
  /// final versionDir = await versionManager.getVersionDir('1.20.4');
  /// print('版本目录: $versionDir');
  /// ```
  Future<String> getVersionDir(String versionId);

  /// 获取游戏目录
  ///
  /// 返回游戏的主存储目录路径。如果用户配置了自定义目录则返回自定义路径，
  /// 否则返回平台默认的游戏目录。
  ///
  /// 返回值：
  /// - `Future<String>`: 游戏目录的绝对路径
  ///
  /// 使用示例：
  /// ```dart
  /// final gameDir = await versionManager.getGameDir();
  /// print('游戏目录: $gameDir');
  /// ```
  Future<String> getGameDir();

  /// 补全/修复版本文件
  ///
  /// 验证指定版本的所有文件完整性，并重新下载损坏或缺失的文件。
  /// 包括客户端JAR、库文件、资源文件等。
  ///
  /// 参数：
  /// - `versionId` (String): 要修复的版本ID
  ///
  /// 返回值：
  /// - `Future<List<InvalidFile>>`: 修复的无效文件列表，如果所有文件都有效则返回空列表
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在或下载失败时抛出
  ///
  /// 使用示例：
  /// ```dart
  /// final invalidFiles = await versionManager.repairVersionFiles('1.20.4');
  /// if (invalidFiles.isEmpty) {
  ///   print('所有文件完整');
  /// } else {
  ///   print('已修复 ${invalidFiles.length} 个文件');
  /// }
  /// ```
  Future<List<InvalidFile>> repairVersionFiles(String versionId);
}

/// 版本管理器实现类（单例模式）
///
/// 负责管理 Minecraft 游戏版本的核心类，实现了 [IVersionManager] 接口。
/// 提供版本列表获取、安装、卸载、验证等完整功能。
///
/// 设计模式：
/// - 单例模式：确保全局只有一个版本管理器实例，避免资源浪费和状态不一致
/// - 事件驱动：通过事件总线发布版本相关事件，支持松耦合的组件通信
///
/// 主要职责：
/// 1. 版本清单管理：从 BMCLAPI 获取并缓存版本列表
/// 2. 版本安装：协调下载引擎完成版本文件的下载和安装
/// 3. 版本卸载：清理版本文件和配置
/// 4. 文件验证：检查并修复损坏的版本文件
///
/// 使用示例：
/// ```dart
/// final versionManager = VersionManager.instance;
/// // 或
/// final versionManager = VersionManager();
/// ```
///
/// 注意事项：
/// - 该类使用单例模式，多次构造返回同一实例
/// - 使用完毕后应调用 [dispose] 方法释放资源
/// - 安装过程可通过 [installProgressStream] 监听进度
class VersionManager implements IVersionManager {
  /// 单例实例
  static VersionManager? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例，如果实例不存在则创建新实例。
  /// 这确保了全局只有一个 VersionManager 实例。
  factory VersionManager() {
    return _instance ??= VersionManager._internal();
  }

  /// 私有内部构造函数
  ///
  /// 外部无法直接调用，只能通过工厂构造函数获取实例。
  VersionManager._internal();

  /// 获取单例实例
  ///
  /// 提供静态访问点，等同于 `VersionManager()` 工厂构造函数。
  static VersionManager get instance =>
      ServiceLocator.instance.tryGet<VersionManager>() ??
      (_instance ??= VersionManager._internal());

  /// 重置单例（仅用于测试）
  ///
  /// 清除当前的单例实例，下次访问时会创建新实例。
  /// 此方法主要用于单元测试中重置测试环境。
  ///
  /// 注意：生产代码中不应调用此方法。
  static void reset() {
    _instance = null;
  }

  /// BMCLAPI 版本清单地址
  ///
  /// BMCLAPI 是国内 Minecraft 镜像源，提供更快的下载速度。
  /// 该地址返回所有可用游戏版本的清单信息。
  static const String _versionManifestUrl =
      'https://bmclapi2.bangbang93.com/mc/game/version_manifest.json';

  /// 平台适配器
  ///
  /// 用于获取平台相关信息，如操作系统类型、默认游戏目录等。
  /// 通过工厂自动创建适合当前平台的适配器实现。
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器
  ///
  /// 用于读写用户配置，包括游戏目录、已安装版本列表等持久化数据。
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线
  ///
  /// 用于发布版本相关事件，如版本列表获取完成、版本安装/卸载等。
  /// 支持发布-订阅模式，实现组件间的松耦合通信。
  final EventBus _eventBus = EventBus();

  /// 下载引擎
  ///
  /// 负责实际的文件下载工作，支持断点续传、并发下载等特性。
  final IDownloadEngine _downloadEngine = DownloadEngine();

  /// 日志记录器
  ///
  /// 用于记录版本管理过程中的调试信息、警告和错误。
  final Logger _logger = Logger('VersionManager');

  /// 安装进度流控制器
  ///
  /// 广播模式的流控制器，允许多个监听者同时接收安装进度更新。
  /// 在安装过程中通过此控制器发送进度事件。
  final StreamController<VersionInstallProgress> _installProgressController =
      StreamController<VersionInstallProgress>.broadcast();

  /// 当前安装任务
  ///
  /// 保存正在执行的安装任务实例，用于取消操作和状态管理。
  /// 任务完成后会被置为 null。
  InstallVersionTask? _currentInstallTask;

  /// 当前任务上下文
  ///
  /// 用于控制任务的执行状态，支持取消操作。
  /// 与 [_currentInstallTask] 配合使用。
  TaskContext? _currentTaskContext;

  /// 缓存的版本清单
  ///
  /// 存储从远程获取的版本清单数据，避免频繁网络请求。
  /// 通过 [_cacheDuration] 控制缓存有效期。
  VersionManifest? _cachedVersionManifest;

  /// 缓存过期时间
  ///
  /// 版本清单缓存的有效时长，默认为1小时。
  /// 超过此时间后需要重新获取最新数据。
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 缓存最后更新时间
  ///
  /// 记录版本清单缓存的时间戳，用于判断缓存是否过期。
  DateTime? _lastCacheUpdate;

  /// 安装进度流
  ///
  /// 提供安装过程的实时进度更新，UI层可订阅此流显示进度条。
  @override
  Stream<VersionInstallProgress> get installProgressStream =>
      _installProgressController.stream;

  /// 获取游戏版本列表
  ///
  /// 从 BMCLAPI 获取所有可用的 Minecraft 版本信息。
  /// 实现了缓存机制，在缓存有效期内直接返回缓存数据。
  ///
  /// 实现细节：
  /// 1. 首先检查缓存是否有效（存在且未过期）
  /// 2. 缓存有效则直接返回缓存数据
  /// 3. 缓存无效则发起网络请求获取最新数据
  /// 4. 解析响应并更新缓存
  /// 5. 发布版本列表获取完成事件
  ///
  /// 返回值：
  /// - `Future<List<GameVersion>>`: 游戏版本列表
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 网络请求失败或数据解析错误
  @override
  Future<List<GameVersion>> fetchVersionList() async {
    try {
      // 检查缓存是否有效：缓存存在、最后更新时间存在、且未超过有效期
      if (_cachedVersionManifest != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        _logger.debug('Using cached version manifest');
        return _cachedVersionManifest!.versions;
      }

      _logger.info('Fetching version manifest from BMCLAPI');

      // 创建网络客户端并发起请求
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        _versionManifestUrl,
        headers: NetworkClient.bmclapiHeaders,
      );

      // 检查响应状态码
      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'Failed to fetch version manifest: ${response.statusCode}',
        );
      }

      // 解析JSON响应并更新缓存
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedVersionManifest = VersionManifest.fromJson(json);
      _lastCacheUpdate = DateTime.now();

      // 发布版本列表获取完成事件，通知其他组件
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

  /// 获取版本JSON配置
  ///
  /// 根据版本ID获取该版本的详细配置信息，包括库依赖、启动参数等。
  ///
  /// 实现流程：
  /// 1. 从版本列表中查找指定版本
  /// 2. 获取版本的下载URL
  /// 3. 下载并解析版本JSON
  ///
  /// 参数：
  /// - `versionId` (String): 要获取配置的版本ID
  ///
  /// 返回值：
  /// - `Future<VersionJson>`: 版本JSON配置对象
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在时抛出 "Version $versionId not found"
  /// - `Exception`: 网络请求失败时抛出
  @override
  Future<VersionJson> fetchVersionJson(String versionId) async {
    try {
      // 从版本列表中查找指定版本
      final versions = await fetchVersionList();
      final version = versions.firstWhere(
        (v) => v.id == versionId,
        orElse: () => throw AppException.fromCode(
          ErrorCodes.gameVersionNotFound,
          detail: versionId,
        ),
      );

      _logger.info('Fetching version JSON for $versionId');
      
      // 下载版本JSON配置
      final networkClient = NetworkClient();
      final response = await networkClient.get(
        version.url,
        headers: NetworkClient.bmclapiHeaders,
      );

      if (response.statusCode != 200) {
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'Failed to fetch version JSON: ${response.statusCode}',
        );
      }

      // 解析JSON响应
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // 解析 inheritsFrom 继承链
      final resolvedJson = await _resolveVersionJson(json);

      return VersionJson.fromJson(resolvedJson);
    } catch (e) {
      _logger.error('Failed to fetch version JSON for $versionId', e);
      rethrow;
    }
  }

  /// 解析版本 JSON 的 inheritsFrom 继承链
  ///
  /// 递归处理 inheritsFrom 字段，将父版本的配置合并到子版本中。
  /// 支持多层继承（如 Forge -> NeoForge -> MC）。
  ///
  /// 合并策略：
  /// - libraries：合并（父版本 + 子版本）
  /// - arguments：合并（子版本覆盖同名参数组）
  /// - mainClass/downloads/assetIndex/其他：子版本覆盖父版本
  Future<Map<String, dynamic>> _resolveVersionJson(
    Map<String, dynamic> json,
  ) async {
    if (!json.containsKey('inheritsFrom')) {
      return json;
    }

    final parentId = json['inheritsFrom'] as String;
    _logger.info('Resolving inheritsFrom: $parentId');

    final parentJson = await _loadVersionJsonById(parentId);
    final resolvedParent = await _resolveVersionJson(parentJson);

    return _mergeVersionJson(resolvedParent, json);
  }

  /// 通过版本 ID 加载版本 JSON
  ///
  /// 优先从本地 versions 目录读取，若不存在则从远程下载。
  Future<Map<String, dynamic>> _loadVersionJsonById(String versionId) async {
    // 尝试从本地文件加载
    final gameDir = await getGameDir();
    final localPath = path.join(
      gameDir,
      'versions',
      versionId,
      '$versionId.json',
    );
    final localFile = File(localPath);
    if (await localFile.exists()) {
      _logger.debug('Loading parent version JSON from local: $localPath');
      final content = await localFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    }

    // 本地不存在，从远程下载
    _logger.info('Parent version JSON not found locally, fetching: $versionId');
    final versions = await fetchVersionList();
    final version = versions.firstWhere(
      (v) => v.id == versionId,
      orElse: () => throw AppException.fromCode(
        ErrorCodes.gameVersionNotFound,
        detail: versionId,
      ),
    );

    final networkClient = NetworkClient();
    final response = await networkClient.get(
      version.url,
      headers: NetworkClient.bmclapiHeaders,
    );

    if (response.statusCode != 200) {
      throw AppException.fromCode(
        ErrorCodes.networkHttpError,
        detail: 'Failed to fetch parent version JSON: ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 合并父子版本 JSON
  ///
  /// - libraries：追加（父 + 子）
  /// - arguments：合并子覆盖父的同名参数组
  /// - 其他字段：子覆盖父
  Map<String, dynamic> _mergeVersionJson(
    Map<String, dynamic> parent,
    Map<String, dynamic> child,
  ) {
    final result = Map<String, dynamic>.from(parent);

    // 合并 libraries（追加）
    if (child.containsKey('libraries')) {
      final parentLibs = parent['libraries'] as List<dynamic>? ?? [];
      final childLibs = child['libraries'] as List<dynamic>? ?? [];
      result['libraries'] = [...parentLibs, ...childLibs];
    }

    // 合并 arguments
    if (child.containsKey('arguments')) {
      final parentArgs = parent['arguments'] as Map<String, dynamic>? ?? {};
      final childArgs = child['arguments'] as Map<String, dynamic>? ?? {};
      result['arguments'] = _mergeArguments(parentArgs, childArgs);
    }

    // 其他字段：子覆盖父（排除 libraries、arguments、inheritsFrom）
    for (final key in child.keys) {
      if (key != 'libraries' && key != 'arguments' && key != 'inheritsFrom') {
        result[key] = child[key];
      }
    }

    return result;
  }

  /// 合并 arguments 对象
  ///
  /// 同名参数组合并（父 + 子），新参数组直接覆盖。
  Map<String, dynamic> _mergeArguments(
    Map<String, dynamic> parent,
    Map<String, dynamic> child,
  ) {
    final result = Map<String, dynamic>.from(parent);
    for (final key in child.keys) {
      if (result.containsKey(key) &&
          result[key] is List &&
          child[key] is List) {
        result[key] = [...(result[key] as List), ...(child[key] as List)];
      } else {
        result[key] = child[key];
      }
    }
    return result;
  }

  /// 安装指定版本
  ///
  /// 执行完整的版本安装流程，包括检查是否已安装、下载配置、下载文件等。
  ///
  /// 实现流程：
  /// 1. 检查版本是否已安装，已安装则直接返回
  /// 2. 获取版本JSON配置
  /// 3. 创建任务上下文（用于支持取消操作）
  /// 4. 创建并执行安装任务
  /// 5. 将版本添加到已安装列表
  /// 6. 清理任务状态
  ///
  /// 参数：
  /// - `versionId` (String): 要安装的版本ID
  ///
  /// 返回值：
  /// - `Future<void>`: 安装完成的 Future
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在、下载失败或文件写入错误
  @override
  Future<void> installVersion(String versionId) async {
    try {
      // 检查是否已安装，避免重复安装
      if (await isVersionInstalled(versionId)) {
        _logger.warning('Version $versionId is already installed');
        return;
      }

      // 获取版本配置信息
      final versionJson = await fetchVersionJson(versionId);

      // 创建任务上下文，用于控制任务执行和取消
      _currentTaskContext = TaskContext();

      // 创建安装任务实例
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

      // 执行安装任务
      await _currentInstallTask!.run(_currentTaskContext);

      // 安装成功，将版本添加到已安装列表
      await _addInstalledVersion(versionId);

      _logger.info('Successfully installed version $versionId');
    } catch (e) {
      _logger.error('Failed to install version $versionId', e);
      rethrow;
    } finally {
      // 无论成功或失败，都清理任务状态
      _currentInstallTask = null;
      _currentTaskContext = null;
    }
  }

  /// 取消当前安装任务
  ///
  /// 中断正在进行的版本安装。通过取消任务上下文来实现。
  /// 如果没有正在进行的安装任务，此方法不执行任何操作。
  ///
  /// 返回值：
  /// - `Future<void>`: 取消操作的 Future
  @override
  Future<void> cancelInstall() async {
    if (_currentTaskContext != null) {
      _logger.info('Cancelling install task');
      _currentTaskContext!.cancel();
    }
  }

  /// 获取已安装版本列表
  ///
  /// 从配置文件中读取已成功安装的版本ID列表。
  ///
  /// 返回值：
  /// - `Future<List<String>>`: 已安装版本ID列表，如果没有则返回空列表
  @override
  Future<List<String>> getInstalledVersions() async {
    final installedVersions =
        _configManager.get<List<dynamic>>(ConfigKeys.installedVersions) ?? [];
    return List<String>.from(installedVersions);
  }

  /// 卸载指定版本
  ///
  /// 删除指定版本的所有本地文件，并从已安装列表中移除。
  ///
  /// 实现流程：
  /// 1. 检查版本是否已安装
  /// 2. 删除版本目录及其所有内容
  /// 3. 从配置中移除版本记录
  /// 4. 发布卸载完成事件
  ///
  /// 参数：
  /// - `versionId` (String): 要卸载的版本ID
  ///
  /// 返回值：
  /// - `Future<void>`: 卸载完成的 Future
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 文件删除失败时抛出
  @override
  Future<void> uninstallVersion(String versionId) async {
    try {
      // 检查版本是否已安装
      if (!await isVersionInstalled(versionId)) {
        _logger.warning('Version $versionId is not installed');
        return;
      }

      // 删除版本目录及其所有内容
      final versionDir = await getVersionDir(versionId);
      final dir = Directory(versionDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _logger.info('Deleted version directory: $versionDir');
      }

      // 从已安装列表中移除该版本
      await _removeInstalledVersion(versionId);

      // 发布版本卸载事件
      _eventBus.publish(VersionUninstalledEvent(versionId: versionId));
      _logger.info('Successfully uninstalled version $versionId');
    } catch (e) {
      _logger.error('Failed to uninstall version $versionId', e);
      rethrow;
    }
  }

  /// 检查版本是否已安装
  ///
  /// 执行双重检查：
  /// 1. 检查版本是否在已安装列表中
  /// 2. 检查版本目录是否实际存在
  ///
  /// 参数：
  /// - `versionId` (String): 要检查的版本ID
  ///
  /// 返回值：
  /// - `Future<bool>`: 版本已安装返回 `true`，否则返回 `false`
  @override
  Future<bool> isVersionInstalled(String versionId) async {
    // 首先检查配置列表
    final installedVersions = await getInstalledVersions();
    if (!installedVersions.contains(versionId)) {
      return false;
    }

    // 进一步验证版本目录是否存在
    final versionDir = await getVersionDir(versionId);
    return Directory(versionDir).exists();
  }

  /// 获取版本目录路径
  ///
  /// 返回指定版本的本地存储目录绝对路径。
  /// 目录结构：`{游戏目录}/versions/{versionId}/`
  ///
  /// 参数：
  /// - `versionId` (String): 版本ID
  ///
  /// 返回值：
  /// - `Future<String>`: 版本目录的绝对路径
  @override
  Future<String> getVersionDir(String versionId) async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'versions', versionId);
  }

  /// 获取游戏目录
  ///
  /// 返回游戏的主存储目录。优先使用用户配置的自定义目录，
  /// 如果未配置则使用平台默认目录。
  ///
  /// 返回值：
  /// - `Future<String>`: 游戏目录的绝对路径
  @override
  Future<String> getGameDir() async {
    // 检查用户是否配置了自定义游戏目录
    final customDir = _configManager.get<String>(ConfigKeys.gameDirectory);
    if (customDir != null && customDir.isNotEmpty) {
      return customDir;
    }
    // 使用平台默认游戏目录
    return await _platformAdapter.getDefaultGameDirectory();
  }

  /// 添加版本到已安装列表
  ///
  /// 将指定版本ID添加到配置的已安装版本列表中。
  /// 如果版本已在列表中则不重复添加。
  /// 添加成功后会发布已安装版本变更事件。
  ///
  /// 参数：
  /// - `versionId` (String): 要添加的版本ID
  ///
  /// 返回值：
  /// - `Future<void>`: 操作完成的 Future
  Future<void> _addInstalledVersion(String versionId) async {
    final versions = await getInstalledVersions();
    // 避免重复添加
    if (!versions.contains(versionId)) {
      versions.add(versionId);
      await _configManager.set<List<String>>(
        ConfigKeys.installedVersions,
        versions,
      );
      // 发布版本变更事件
      _eventBus.publish(InstalledVersionsChangedEvent(versions: versions));
    }
  }

  /// 从已安装列表中移除版本
  ///
  /// 从配置的已安装版本列表中移除指定版本ID。
  /// 移除成功后会发布已安装版本变更事件。
  ///
  /// 参数：
  /// - `versionId` (String): 要移除的版本ID
  ///
  /// 返回值：
  /// - `Future<void>`: 操作完成的 Future
  Future<void> _removeInstalledVersion(String versionId) async {
    final versions = await getInstalledVersions();
    versions.remove(versionId);
    await _configManager.set<List<String>>(
      ConfigKeys.installedVersions,
      versions,
    );
    // 发布版本变更事件
    _eventBus.publish(InstalledVersionsChangedEvent(versions: versions));
  }

  /// 获取资源目录路径
  ///
  /// 返回游戏资源文件的存储目录，包括材质、音效、语言文件等。
  /// 目录结构：`{游戏目录}/assets/`
  ///
  /// 返回值：
  /// - `Future<String>`: 资源目录的绝对路径
  Future<String> getAssetsDir() async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'assets');
  }

  /// 获取库目录路径
  ///
  /// 返回游戏依赖库文件的存储目录。
  /// 目录结构：`{游戏目录}/libraries/`
  ///
  /// 返回值：
  /// - `Future<String>`: 库目录的绝对路径
  Future<String> getLibrariesDir() async {
    final gameDir = await getGameDir();
    return path.join(gameDir, 'libraries');
  }

  /// 修复版本文件
  ///
  /// 验证指定版本的所有文件完整性，并重新下载损坏或缺失的文件。
  /// 包括客户端JAR、库文件、资源文件等。
  ///
  /// 实现流程：
  /// 1. 获取版本JSON配置
  /// 2. 使用文件验证器检查所有文件
  /// 3. 对每个无效文件进行重新下载
  ///
  /// 参数：
  /// - `versionId` (String): 要修复的版本ID
  ///
  /// 返回值：
  /// - `Future<List<InvalidFile>>`: 修复的无效文件列表，空列表表示所有文件完整
  ///
  /// 可能抛出的异常：
  /// - `Exception`: 版本不存在或下载失败
  @override
  Future<List<InvalidFile>> repairVersionFiles(String versionId) async {
    _logger.info('Repairing files for version $versionId');
    
    // 获取版本配置
    final versionJson = await fetchVersionJson(versionId);
    final gameDir = await getGameDir();
    
    // 使用全量验证策略检查所有文件
    final invalidFiles = await GameFileValidator.instance.validateAll(
      versionJson, 
      gameDir, 
      FileValidatePolicy.full,
    );
    
    // 如果没有无效文件，直接返回
    if (invalidFiles.isEmpty) {
      _logger.info('All files are valid, no repair needed');
      return [];
    }
    
    // 逐个下载无效文件进行修复
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
  ///
  /// 根据库文件的规则（rules）判断当前平台是否需要下载该库。
  /// 规则可以指定允许或禁止特定操作系统。
  ///
  /// 判断逻辑：
  /// - 如果没有规则，默认需要下载
  /// - 遍历所有规则，根据 action 和平台匹配结果决定
  /// - "allow" 规则：匹配时允许，不匹配时禁止
  /// - "disallow" 规则：匹配时禁止，不匹配时允许
  ///
  /// 参数：
  /// - `library` (Library): 要检查的库对象
  ///
  /// 返回值：
  /// - `bool`: 需要下载返回 `true`，否则返回 `false`
  bool shouldDownloadLibrary(Library library) {
    // 没有规则限制，所有平台都需要
    if (library.rules == null || library.rules!.isEmpty) {
      return true;
    }

    // 最后一条匹配的规则生效（标准 Minecraft 行为）
    bool? lastMatch;
    for (final rule in library.rules!) {
      if (_ruleMatches(rule)) {
        lastMatch = rule.action == 'allow';
      }
    }

    return lastMatch ?? true; // 无匹配规则时默认允许
  }

  /// 检查规则是否匹配当前平台
  ///
  /// 根据规则中定义的操作系统要求，判断是否与当前运行平台匹配。
  ///
  /// 匹配逻辑：
  /// - 如果规则没有指定操作系统，则匹配所有平台
  /// - 检查规则中的 os.name 是否与当前操作系统匹配
  /// - 目前简化实现，忽略架构和版本检查
  ///
  /// 参数：
  /// - `rule` (Rule): 要检查的规则对象
  ///
  /// 返回值：
  /// - `bool`: 匹配当前平台返回 `true`，否则返回 `false`
  bool _ruleMatches(Rule rule) {
    // 没有操作系统限制，匹配所有平台
    if (rule.os == null) {
      return true;
    }

    // 检查操作系统名称是否匹配
    if (rule.os!.name != null) {
      final osName = rule.os!.name!;
      // 根据当前平台判断是否匹配
      if (_platformAdapter.isWindows && osName != 'windows') return false;
      if (_platformAdapter.isMacOS && osName != 'osx') return false;
      if (_platformAdapter.isLinux && osName != 'linux') return false;
    }

    // 忽略架构和版本检查，简化实现
    return true;
  }

  /// 获取原生库分类器
  ///
  /// 根据当前操作系统获取库文件中定义的原生库分类器。
  /// 原生库（natives）是包含平台特定本地代码的库文件。
  ///
  /// 实现逻辑：
  /// - 检查库是否定义了 natives 映射
  /// - 根据当前操作系统返回对应的分类器
  /// - Windows -> "windows", macOS -> "osx", Linux -> "linux"
  ///
  /// 参数：
  /// - `library` (Library): 要检查的库对象
  ///
  /// 返回值：
  /// - `String?`: 原生库分类器，如 "natives-windows"；如果没有定义则返回 null
  String? getNativeClassifier(Library library) {
    // 检查是否定义了原生库映射
    if (library.natives == null) return null;

    // 根据当前操作系统确定键名
    String osKey;
    if (_platformAdapter.isWindows) {
      osKey = 'windows';
    } else if (_platformAdapter.isMacOS) {
      osKey = 'osx';
    } else if (_platformAdapter.isLinux) {
      osKey = 'linux';
    } else {
      // 不支持的平台
      return null;
    }

    return library.natives![osKey];
  }

  /// 销毁管理器
  ///
  /// 释放资源，关闭流控制器。
  /// 在不再使用版本管理器时应调用此方法。
  ///
  /// 注意：调用此方法后，实例将无法再使用。
  void dispose() {
    _installProgressController.close();
  }
}