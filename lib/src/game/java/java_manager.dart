/// Java管理器模块
///
/// 该模块负责管理系统中安装的Java运行环境，包括：
/// - 自动检测系统中已安装的Java版本
/// - 验证Java安装的有效性
/// - 根据游戏版本推荐合适的Java版本
/// - 管理用户选择的Java配置
///
/// 使用示例：
/// ```dart
/// final javaManager = JavaManager.instance;
/// final installations = await javaManager.findJavaInstallations();
/// final recommended = await javaManager.getRecommendedJava();
/// ```
library;

import 'dart:async';
import 'dart:io';
import '../../config/config_keys.dart';
import '../../config/config_manager.dart';
import '../../core/logger.dart';
import '../../core/error_codes.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import 'models.dart';

/// Java管理器接口
///
/// 定义了Java检测、选择、验证等核心功能的抽象接口。
/// 该接口允许在不同平台上实现不同的Java检测逻辑，
/// 同时保持统一的API契约。
///
/// 主要职责：
/// - 查找系统中已安装的Java环境
/// - 获取推荐的Java版本
/// - 管理用户选择的Java配置
/// - 验证Java安装的有效性
/// - 获取Java安装的详细信息
///
/// 使用示例：
/// ```dart
/// IJavaManager manager = JavaManager.instance;
/// final installations = await manager.findJavaInstallations();
/// ```
abstract class IJavaManager {
  /// 查找系统中的所有Java安装
  ///
  /// 扫描系统中已安装的Java运行环境，包括：
  /// - 系统环境变量JAVA_HOME指向的Java
  /// - 系统PATH中的Java
  /// - 常见安装目录中的Java（如Windows注册表、macOS的/Library等）
  /// - 用户配置的额外Java路径
  ///
  /// 返回值：
  /// - [List<JavaInstallation>] 找到的Java安装列表，按主版本号降序排列
  /// - 如果未找到任何Java安装，返回空列表
  ///
  /// 异常：
  /// - 该方法捕获所有异常，不会向外抛出
  ///
  /// 示例：
  /// ```dart
  /// final installations = await manager.findJavaInstallations();
  /// for (final java in installations) {
  ///   print('Java ${java.version} at ${java.path}');
  /// }
  /// ```
  Future<List<JavaInstallation>> findJavaInstallations();

  /// 获取推荐的Java版本
  ///
  /// 根据以下优先级选择最合适的Java版本：
  /// 1. 兼容的64位版本（优先）
  /// 2. 兼容的32位版本
  /// 3. 推荐范围内的最高版本
  /// 4. 找到的第一个Java安装
  ///
  /// 返回值：
  /// - [JavaInstallation] 推荐的Java安装信息
  /// - 如果未找到任何Java安装，返回null
  ///
  /// 示例：
  /// ```dart
  /// final recommended = await manager.getRecommendedJava();
  /// if (recommended != null) {
  ///   print('推荐使用: Java ${recommended.version}');
  /// }
  /// ```
  Future<JavaInstallation?> getRecommendedJava();

  /// 获取当前用户选中的Java
  ///
  /// 从配置中读取用户选择的Java路径，并验证其有效性。
  /// 如果用户未选择或选择的Java无效，则自动选择推荐的Java版本。
  ///
  /// 返回值：
  /// - [JavaInstallation] 当前选中的Java安装信息
  /// - 如果未找到有效的Java安装，返回null
  ///
  /// 示例：
  /// ```dart
  /// final selected = await manager.getSelectedJava();
  /// if (selected != null) {
  ///   print('当前使用: ${selected.path}');
  /// }
  /// ```
  Future<JavaInstallation?> getSelectedJava();

  /// 选择指定的Java作为默认Java
  ///
  /// 将指定的Java路径保存到配置中，并发布选择变更事件。
  /// 在保存之前会验证Java路径的有效性。
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 异常：
  /// - [Exception] 如果Java路径无效，抛出异常
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   await manager.selectJava('/path/to/java');
  ///   print('Java选择成功');
  /// } catch (e) {
  ///   print('Java选择失败: $e');
  /// }
  /// ```
  Future<void> selectJava(String javaPath);

  /// 验证Java路径是否有效
  ///
  /// 检查指定的Java路径是否存在且能够正常执行。
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 返回值：
  /// - [bool] true表示Java有效，false表示无效
  ///
  /// 示例：
  /// ```dart
  /// final isValid = await manager.validateJava('/path/to/java');
  /// if (isValid) {
  ///   print('Java路径有效');
  /// }
  /// ```
  Future<bool> validateJava(String javaPath);

  /// 获取指定Java的详细信息
  ///
  /// 执行java -version命令并解析输出，获取Java的版本、位数、发行商等信息。
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 返回值：
  /// - [JavaInstallation] Java安装的详细信息
  /// - 如果Java不存在或无法执行，返回null
  ///
  /// 示例：
  /// ```dart
  /// final info = await manager.getJavaInfo('/path/to/java');
  /// if (info != null) {
  ///   print('版本: ${info.version}, 64位: ${info.is64Bit}');
  /// }
  /// ```
  Future<JavaInstallation?> getJavaInfo(String javaPath);
}

/// Java管理器实现类（单例模式）
///
/// 提供Java环境管理的具体实现，包括：
/// - 自动检测系统中安装的Java版本
/// - 智能推荐适合的Java版本
/// - 缓存机制提高性能
/// - 事件发布通知变更
///
/// 该类使用单例模式，确保全局只有一个Java管理器实例。
///
/// 使用示例：
/// ```dart
/// // 获取单例实例
/// final javaManager = JavaManager.instance;
///
/// // 或使用工厂构造函数
/// final javaManager = JavaManager();
///
/// // 查找Java安装
/// final installations = await javaManager.findJavaInstallations();
///
/// // 获取适合特定游戏版本的Java
/// final java = await javaManager.getJavaForGameVersion('1.20.4');
/// ```
class JavaManager implements IJavaManager {
  /// 单例实例
  static JavaManager? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例，如果实例不存在则创建。
  ///
  /// 返回值：
  /// - [JavaManager] Java管理器的单例实例
  factory JavaManager() {
    return _instance ??= JavaManager._internal();
  }

  /// 内部构造函数（私有）
  ///
  /// 用于创建单例实例，外部无法直接调用。
  JavaManager._internal();

  /// 获取单例实例的静态方法
  ///
  /// 提供更直观的单例访问方式。
  ///
  /// 返回值：
  /// - [JavaManager] Java管理器的单例实例
  static JavaManager get instance => _instance ??= JavaManager._internal();

  /// 重置单例实例
  ///
  /// 仅用于测试目的，清除当前的单例实例，
  /// 允许在测试中创建新的实例。
  ///
  /// 注意：生产代码中不应使用此方法。
  static void reset() {
    _instance = null;
  }

  /// 平台适配器
  ///
  /// 用于执行平台相关的操作，如查找Java安装路径。
  /// 根据当前操作系统自动选择合适的适配器实现。
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器
  ///
  /// 用于读取和保存用户配置，包括用户选择的Java路径和额外的Java搜索路径。
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线
  ///
  /// 用于发布Java相关的变更事件，如Java安装列表变更、选中Java变更等。
  /// 允许其他组件订阅这些事件并做出响应。
  final EventBus _eventBus = EventBus();

  /// 日志记录器
  ///
  /// 用于记录Java管理器的操作日志，包括调试信息、警告和错误。
  final Logger _logger = Logger('JavaManager');

  /// 缓存的Java安装列表
  ///
  /// 存储最近一次查找的Java安装列表，避免重复执行耗时的检测操作。
  /// 当缓存过期或被清除时，需要重新查找。
  List<JavaInstallation>? _cachedInstallations;

  /// 缓存有效期
  ///
  /// 缓存的过期时间，默认为5分钟。
  /// 超过此时间后，缓存将被视为无效，需要重新查找。
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 缓存最后更新时间
  ///
  /// 记录缓存最后一次更新的时间，用于判断缓存是否过期。
  DateTime? _lastCacheUpdate;

  /// 查找系统中的所有Java安装
  ///
  /// 该方法会：
  /// 1. 检查缓存是否有效，如果有效则直接返回缓存结果
  /// 2. 通过平台适配器查找系统中的Java安装
  /// 3. 合并用户配置的额外Java路径
  /// 4. 验证每个Java路径并获取详细信息
  /// 5. 去重并按版本号排序
  /// 6. 更新缓存并发布变更事件
  ///
  /// 返回值：
  /// - [List<JavaInstallation>] 找到的Java安装列表，按主版本号降序排列
  /// - 如果发生错误或未找到任何Java安装，返回空列表
  ///
  /// 异常：
  /// - 该方法捕获所有异常，不会向外抛出
  @override
  Future<List<JavaInstallation>> findJavaInstallations() async {
    try {
      // 检查缓存是否有效
      // 如果缓存存在且未过期，直接返回缓存结果以提高性能
      if (_cachedInstallations != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        _logger.debug('Using cached Java installations');
        return _cachedInstallations!;
      }

      _logger.info('Searching for Java installations...');

      // 通过平台适配器查找系统中的Java安装路径
      // 平台适配器会根据不同操作系统使用不同的检测方法
      final javaPaths = await _platformAdapter.findJavaInstallations();
      final List<JavaInstallation> installations = [];

      // 添加用户配置的额外 Java 路径
      // 用户可以在配置中手动添加Java路径，这些路径会被合并到检测结果中
      final extraPaths = _configManager.getExtraJavaPaths();
      final allPaths = [...javaPaths, ...extraPaths];

      // 遍历所有路径，获取每个Java的详细信息
      for (final javaPath in allPaths) {
        // 跳过重复的路径，避免重复检测
        if (installations.any((i) => i.path == javaPath)) {
          continue;
        }
        // 获取Java信息，如果无效则跳过
        final javaInfo = await getJavaInfo(javaPath);
        if (javaInfo != null) {
          installations.add(javaInfo);
        }
      }

      // 去重（按路径）
      // 使用Set来确保路径的唯一性，避免重复的Java安装
      final uniquePaths = <String>{};
      final uniqueInstallations = <JavaInstallation>[];
      for (final installation in installations) {
        if (!uniquePaths.contains(installation.path)) {
          uniquePaths.add(installation.path);
          uniqueInstallations.add(installation);
        }
      }

      // 按主版本号降序排序
      // 这样最新的Java版本会排在前面，方便用户选择
      uniqueInstallations.sort(
        (a, b) => b.majorVersion.compareTo(a.majorVersion),
      );

      // 更新缓存
      _cachedInstallations = uniqueInstallations;
      _lastCacheUpdate = DateTime.now();

      // 发布Java安装列表变更事件
      // 订阅者可以监听此事件来更新UI或执行其他操作
      _eventBus.publish(
        JavaInstallationsChangedEvent(
          installations: uniqueInstallations.map((i) => i.path).toList(),
        ),
      );

      _logger.info('Found ${uniqueInstallations.length} Java installations');
      return uniqueInstallations;
    } catch (e, stackTrace) {
      // 捕获所有异常，记录日志并返回空列表
      _logger.error('Failed to find Java installations', e, stackTrace);
      return [];
    }
  }

  /// 获取推荐的Java版本
  ///
  /// 根据以下优先级选择最合适的Java版本：
  /// 1. 兼容的64位版本（优先选择，性能更好）
  /// 2. 兼容的32位版本（备选）
  /// 3. 推荐范围内的最高版本（版本号在8-21之间）
  /// 4. 找到的第一个Java安装（最后的回退选项）
  ///
  /// 兼容版本定义：Java 8, 11, 17, 21（这些是Minecraft官方支持的版本）
  ///
  /// 返回值：
  /// - [JavaInstallation] 推荐的Java安装信息
  /// - 如果未找到任何Java安装，返回null
  ///
  /// 异常：
  /// - 该方法捕获所有异常，不会向外抛出
  @override
  Future<JavaInstallation?> getRecommendedJava() async {
    try {
      final installations = await findJavaInstallations();

      // 如果没有找到任何Java安装，返回null
      if (installations.isEmpty) {
        return null;
      }

      // 优先选择兼容的64位版本
      // 64位Java可以分配更多内存，对Minecraft运行更有利
      JavaInstallation? bestMatch;
      for (final installation in installations) {
        if (JavaVersion.isCompatible(installation.majorVersion) &&
            installation.is64Bit) {
          bestMatch = installation;
          break;
        }
      }

      // 如果没有找到兼容的64位版本，尝试找兼容的32位版本
      // 32位Java虽然内存受限，但仍然可以运行Minecraft
      if (bestMatch == null) {
        for (final installation in installations) {
          if (JavaVersion.isCompatible(installation.majorVersion)) {
            bestMatch = installation;
            break;
          }
        }
      }

      // 如果还是没有找到兼容版本，查找推荐范围内的最高版本
      // 推荐范围是Java 8-21，这些版本基本都能运行Minecraft
      if (bestMatch == null) {
        for (final installation in installations) {
          if (JavaVersion.isRecommended(installation.majorVersion)) {
            bestMatch = installation;
            break;
          }
        }
      }

      // 最后选择找到的第一个Java安装作为回退选项
      // 因为列表已按版本号降序排序，所以会选择最高版本
      bestMatch ??= installations.first;

      _logger.info(
        'Recommended Java: ${bestMatch.version} at ${bestMatch.path}',
      );
      return bestMatch;
    } catch (e, stackTrace) {
      _logger.error('Failed to get recommended Java', e, stackTrace);
      return null;
    }
  }

  /// 根据游戏版本获取推荐的Java安装
  ///
  /// 根据Minecraft版本选择最适合的Java版本。
  /// 不同版本的Minecraft对Java版本有不同的要求：
  /// - 1.16及以下: 推荐Java 8，兼容Java 11
  /// - 1.17-1.18: 推荐Java 17，兼容Java 8
  /// - 1.19-1.20.4: 推荐Java 17
  /// - 1.20.5+: 推荐Java 21，兼容Java 17
  ///
  /// 参数：
  /// - [gameVersion] Minecraft游戏版本号，如 "1.20.4"
  ///
  /// 返回值：
  /// - [JavaInstallation] 推荐的Java安装信息
  /// - 如果未找到合适的Java，返回null
  ///
  /// 示例：
  /// ```dart
  /// final java = await javaManager.getJavaForGameVersion('1.20.4');
  /// print('推荐使用: Java ${java?.version}');
  /// ```
  Future<JavaInstallation?> getJavaForGameVersion(String gameVersion) async {
    try {
      final installations = await findJavaInstallations();

      // 如果没有找到任何Java安装，记录警告并返回null
      if (installations.isEmpty) {
        _logger.warn('No Java installations found');
        return null;
      }

      // 获取该游戏版本推荐的Java版本列表
      // 返回的列表按优先级排序，第一个是最推荐的版本
      final requiredJavaVersions = JavaVersion.getRecommendedForGameVersion(gameVersion);

      _logger.debug('Game version $gameVersion requires Java versions: $requiredJavaVersions');

      // 按优先级遍历推荐的Java版本，查找匹配的安装
      for (final requiredVersion in requiredJavaVersions) {
        // 优先查找64位的匹配版本
        final match64 = installations.firstWhere(
          (inst) => inst.majorVersion == requiredVersion && inst.is64Bit,
          orElse: () => installations.firstWhere(
            // 如果没有64位版本，查找任意位数的匹配版本
            (inst) => inst.majorVersion == requiredVersion,
            orElse: () => installations.first,
          ),
        );
        // 检查是否找到了匹配的版本
        if (match64.majorVersion == requiredVersion) {
          _logger.info(
            'Found matching Java ${match64.version} for game $gameVersion at ${match64.path}',
          );
          return match64;
        }
      }

      // 如果没有找到精确匹配的版本，使用通用推荐的Java版本
      final fallback = await getRecommendedJava();
      _logger.warn(
        'No exact Java match for game $gameVersion, using fallback: ${fallback?.version}',
      );
      return fallback;
    } catch (e, stackTrace) {
      _logger.error('Failed to get Java for game version $gameVersion', e, stackTrace);
      // 发生异常时，回退到通用推荐的Java版本
      return await getRecommendedJava();
    }
  }

  /// 检查Java版本是否与游戏版本兼容
  ///
  /// 判断指定的Java版本是否能够运行指定的游戏版本。
  ///
  /// 参数：
  /// - [javaVersion] Java版本字符串，如 "1.8.0_301" 或 "17.0.4"
  /// - [gameVersion] Minecraft游戏版本号，如 "1.20.4"
  ///
  /// 返回值：
  /// - [bool] true表示兼容，false表示不兼容
  ///
  /// 示例：
  /// ```dart
  /// final isCompatible = javaManager.isJavaCompatibleWithGame('17.0.4', '1.20.4');
  /// print('兼容性: $isCompatible');
  /// ```
  bool isJavaCompatibleWithGame(String javaVersion, String gameVersion) {
    // 解析Java主版本号
    final javaMajor = JavaVersion.parseMajorVersion(javaVersion);
    // 获取游戏推荐的Java版本列表
    final requiredVersions = JavaVersion.getRecommendedForGameVersion(gameVersion);
    // 检查Java版本是否在推荐列表中，或者是已知的兼容版本
    return requiredVersions.contains(javaMajor) ||
           JavaVersion.isCompatible(javaMajor);
  }

  /// 获取当前用户选中的Java
  ///
  /// 从配置中读取用户选择的Java路径，并验证其有效性。
  /// 如果用户未选择或选择的Java无效，则自动选择推荐的Java版本并保存到配置。
  ///
  /// 返回值：
  /// - [JavaInstallation] 当前选中的Java安装信息
  /// - 如果未找到有效的Java安装，返回null
  ///
  /// 异常：
  /// - 该方法捕获所有异常，不会向外抛出
  @override
  Future<JavaInstallation?> getSelectedJava() async {
    try {
      // 从配置中读取用户选择的Java路径
      final javaPath = _configManager.getString(ConfigKeys.javaPath);

      // 如果配置中有Java路径，尝试验证并获取信息
      if (javaPath != null && javaPath.isNotEmpty) {
        final javaInfo = await getJavaInfo(javaPath);
        if (javaInfo != null) {
          _logger.info('Selected Java: ${javaInfo.version} at $javaPath');
          return javaInfo;
        }
      }

      // 如果没有选中或选中的Java无效，使用推荐的Java
      // 并自动保存到配置中
      _logger.info('No valid Java selected, using recommended');
      final recommended = await getRecommendedJava();
      if (recommended != null) {
        await selectJava(recommended.path);
      }
      return recommended;
    } catch (e, stackTrace) {
      _logger.error('Failed to get selected Java', e, stackTrace);
      return null;
    }
  }

  /// 选择指定的Java作为默认Java
  ///
  /// 将指定的Java路径保存到配置中，并发布选择变更事件。
  /// 在保存之前会验证Java路径的有效性。
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 异常：
  /// - [Exception] 如果Java路径无效，抛出异常
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   await javaManager.selectJava('/usr/bin/java');
  ///   print('Java选择成功');
  /// } catch (e) {
  ///   print('Java选择失败: $e');
  /// }
  /// ```
  @override
  Future<void> selectJava(String javaPath) async {
    try {
      // 获取旧的Java路径，用于事件通知
      final oldPath = _configManager.getString(ConfigKeys.javaPath);

      // 验证Java路径的有效性
      // 如果Java路径无效，抛出异常
      if (!await validateJava(javaPath)) {
        throw AppException.fromCode(
          ErrorCodes.gameJavaInvalidPath,
          detail: javaPath,
        );
      }

      // 保存新的Java路径到配置
      await _configManager.setString(ConfigKeys.javaPath, javaPath);

      // 发布Java选择变更事件
      // 订阅者可以监听此事件来更新UI或执行其他操作
      _eventBus.publish(
        SelectedJavaChangedEvent(newJavaPath: javaPath, oldJavaPath: oldPath),
      );

      _logger.info('Selected Java: $javaPath');
    } catch (e, stackTrace) {
      _logger.error('Failed to select Java', e, stackTrace);
      // 重新抛出异常，让调用者处理
      rethrow;
    }
  }

  /// 验证Java路径是否有效
  ///
  /// 通过尝试获取Java信息来验证Java路径的有效性。
  /// 如果能够成功获取Java信息，则认为路径有效。
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 返回值：
  /// - [bool] true表示Java路径有效，false表示无效
  ///
  /// 示例：
  /// ```dart
  /// final isValid = await javaManager.validateJava('/usr/bin/java');
  /// if (isValid) {
  ///   print('Java路径有效');
  /// } else {
  ///   print('Java路径无效');
  /// }
  /// ```
  @override
  Future<bool> validateJava(String javaPath) async {
    try {
      final javaInfo = await getJavaInfo(javaPath);
      return javaInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// 获取指定Java的详细信息
  ///
  /// 执行 `java -version` 命令并解析输出，获取Java的版本、位数、发行商等信息。
  ///
  /// 解析逻辑：
  /// 1. 检查文件是否存在
  /// 2. 执行 `java -version` 命令
  /// 3. 解析命令输出（注意：java -version 的输出在 stderr 中）
  /// 4. 提取版本号、发行商、位数信息
  ///
  /// 参数：
  /// - [javaPath] Java可执行文件的完整路径
  ///
  /// 返回值：
  /// - [JavaInstallation] Java安装的详细信息，包含：
  ///   - path: Java可执行文件路径
  ///   - version: 完整版本号字符串
  ///   - majorVersion: 主版本号（如8, 11, 17, 21）
  ///   - is64Bit: 是否为64位版本
  ///   - vendor: 发行商名称（可选）
  /// - 如果Java不存在或无法执行，返回null
  ///
  /// 示例：
  /// ```dart
  /// final info = await javaManager.getJavaInfo('/usr/bin/java');
  /// if (info != null) {
  ///   print('版本: ${info.version}');
  ///   print('主版本: ${info.majorVersion}');
  ///   print('64位: ${info.is64Bit}');
  ///   print('发行商: ${info.vendor}');
  /// }
  /// ```
  @override
  Future<JavaInstallation?> getJavaInfo(String javaPath) async {
    try {
      // 检查文件是否存在
      final file = File(javaPath);
      if (!await file.exists()) {
        _logger.debug('Java file not found: $javaPath');
        return null;
      }

      // 运行 java -version 获取版本信息
      // 注意：java -version 的输出在 stderr 中，而不是 stdout
      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.debug('Java version check timed out: $javaPath');
          throw TimeoutException('Java -version timed out');
        },
      );

      // java -version 输出到 stderr
      // 这是Java的历史遗留问题，版本信息输出到标准错误流
      final output = (result.stderr as String?) ?? '';

      // 检查命令是否执行成功
      if (result.exitCode != 0) {
        _logger.debug('Java execution failed: $output');
        return null;
      }

      // 解析版本信息
      // 从输出中提取版本号、发行商和位数信息
      String? versionString;
      String? vendor;
      bool is64Bit = false;

      final lines = output.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();

        // 解析版本号
        // 版本号通常在包含 "version" 的行中，格式如：java version "1.8.0_301"
        if (trimmedLine.contains('version')) {
          // 使用正则表达式提取引号中的版本号
          final versionMatch = RegExp(r'"([^"]+)"').firstMatch(trimmedLine);
          if (versionMatch != null) {
            versionString = versionMatch.group(1);
          }
        }

        // 解析发行商
        // 发行商信息通常在包含 "Runtime Environment" 的行中
        // 例如：Java(TM) SE Runtime Environment (build 1.8.0_301-b09)
        if (trimmedLine.contains('Runtime Environment')) {
          final vendorMatch = RegExp(r'([A-Za-z]+)').firstMatch(trimmedLine);
          if (vendorMatch != null) {
            vendor = vendorMatch.group(1);
          }
        }

        // 检测64位
        // 64位Java会在输出中包含 "64-Bit", "amd64" 或 "x86_64" 字样
        // 例如：Java HotSpot(TM) 64-Bit Server VM (build 25.301-b09, mixed mode)
        if (trimmedLine.contains('64-Bit') ||
            trimmedLine.contains('amd64') ||
            trimmedLine.contains('x86_64')) {
          is64Bit = true;
        }
      }

      // 如果无法解析版本号，返回null
      if (versionString == null) {
        _logger.debug('Could not parse Java version from: $output');
        return null;
      }

      // 解析主版本号
      // 例如：1.8.0_301 -> 8, 17.0.4 -> 17
      final majorVersion = JavaVersion.parseMajorVersion(versionString);

      // 创建Java安装信息对象
      final installation = JavaInstallation(
        path: javaPath,
        version: versionString,
        majorVersion: majorVersion,
        is64Bit: is64Bit,
        vendor: vendor,
      );

      _logger.debug('Java info: $installation');
      return installation;
    } catch (e) {
      _logger.debug('Failed to get Java info for $javaPath: $e');
      return null;
    }
  }

  /// 清除缓存
  ///
  /// 清除Java安装列表的缓存，强制下次查找时重新检测系统中的Java安装。
  /// 当用户安装或卸载Java后，可以调用此方法来刷新缓存。
  ///
  /// 示例：
  /// ```dart
  /// // 清除缓存
  /// javaManager.clearCache();
  ///
  /// // 重新查找Java安装
  /// final installations = await javaManager.findJavaInstallations();
  /// ```
  void clearCache() {
    _cachedInstallations = null;
    _lastCacheUpdate = null;
  }
}