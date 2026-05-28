import 'dart:io';
import 'package:path/path.dart' as path;
import '../../config/config_keys.dart';
import '../../config/config_manager.dart';
import '../../core/logger.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import 'models.dart';

/// Java管理器接口
/// 定义了Java检测、选择、验证等功能
abstract class IJavaManager {
  /// 查找系统中的Java安装
  Future<List<JavaInstallation>> findJavaInstallations();

  /// 获取推荐的Java版本
  Future<JavaInstallation?> getRecommendedJava();

  /// 获取当前选中的Java
  Future<JavaInstallation?> getSelectedJava();

  /// 选择Java
  Future<void> selectJava(String javaPath);

  /// 验证Java是否有效
  Future<bool> validateJava(String javaPath);

  /// 获取Java信息
  Future<JavaInstallation?> getJavaInfo(String javaPath);
}

/// Java管理器实现（单例）
class JavaManager implements IJavaManager {
  static JavaManager? _instance;

  factory JavaManager() {
    return _instance ??= JavaManager._internal();
  }

  JavaManager._internal();

  /// 获取单例实例
  static JavaManager get instance => _instance ??= JavaManager._internal();

  /// 重置单例（仅用于测试）
  static void reset() {
    _instance = null;
  }

  /// 平台适配器
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线
  final EventBus _eventBus = EventBus();

  /// 日志记录器
  final Logger _logger = Logger('JavaManager');

  /// 缓存的Java安装列表
  List<JavaInstallation>? _cachedInstallations;

  /// 缓存过期时间
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 缓存最后更新时间
  DateTime? _lastCacheUpdate;

  @override
  Future<List<JavaInstallation>> findJavaInstallations() async {
    try {
      // 检查缓存是否有效
      if (_cachedInstallations != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        _logger.debug('Using cached Java installations');
        return _cachedInstallations!;
      }

      _logger.info('Searching for Java installations...');

      final javaPaths = await _platformAdapter.findJavaInstallations();
      final List<JavaInstallation> installations = [];

      for (final javaPath in javaPaths) {
        final javaInfo = await getJavaInfo(javaPath);
        if (javaInfo != null) {
          installations.add(javaInfo);
        }
      }

      // 去重（按路径）
      final uniquePaths = <String>{};
      final uniqueInstallations = <JavaInstallation>[];
      for (final installation in installations) {
        if (!uniquePaths.contains(installation.path)) {
          uniquePaths.add(installation.path);
          uniqueInstallations.add(installation);
        }
      }

      // 按主版本号降序排序
      uniqueInstallations.sort(
        (a, b) => b.majorVersion.compareTo(a.majorVersion),
      );

      _cachedInstallations = uniqueInstallations;
      _lastCacheUpdate = DateTime.now();

      _eventBus.publish(
        JavaInstallationsChangedEvent(
          installations: uniqueInstallations.map((i) => i.path).toList(),
        ),
      );

      _logger.info('Found ${uniqueInstallations.length} Java installations');
      return uniqueInstallations;
    } catch (e, stackTrace) {
      _logger.error('Failed to find Java installations', e, stackTrace);
      return [];
    }
  }

  @override
  Future<JavaInstallation?> getRecommendedJava() async {
    try {
      final installations = await findJavaInstallations();

      if (installations.isEmpty) {
        return null;
      }

      // 优先选择兼容的64位版本
      JavaInstallation? bestMatch;
      for (final installation in installations) {
        if (JavaVersion.isCompatible(installation.majorVersion) &&
            installation.is64Bit) {
          bestMatch = installation;
          break;
        }
      }

      // 如果没有找到兼容的64位版本，尝试找兼容的32位
      if (bestMatch == null) {
        for (final installation in installations) {
          if (JavaVersion.isCompatible(installation.majorVersion)) {
            bestMatch = installation;
            break;
          }
        }
      }

      // 如果还是没有，找推荐范围内的最高版本
      if (bestMatch == null) {
        for (final installation in installations) {
          if (JavaVersion.isRecommended(installation.majorVersion)) {
            bestMatch = installation;
            break;
          }
        }
      }

      // 最后选择找到的第一个
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

  Future<JavaInstallation?> getJavaForGameVersion(String gameVersion) async {
    try {
      final installations = await findJavaInstallations();

      if (installations.isEmpty) {
        _logger.warn('No Java installations found');
        return null;
      }

      final requiredJavaVersions = JavaVersion.getRecommendedForGameVersion(gameVersion);

      _logger.debug('Game version $gameVersion requires Java versions: $requiredJavaVersions');

      for (final requiredVersion in requiredJavaVersions) {
        final match64 = installations.firstWhere(
          (inst) => inst.majorVersion == requiredVersion && inst.is64Bit,
          orElse: () => installations.firstWhere(
            (inst) => inst.majorVersion == requiredVersion,
            orElse: () => installations.first,
          ),
        );
        if (match64.majorVersion == requiredVersion) {
          _logger.info(
            'Found matching Java ${match64.version} for game $gameVersion at ${match64.path}',
          );
          return match64;
        }
      }

      final fallback = await getRecommendedJava();
      _logger.warn(
        'No exact Java match for game $gameVersion, using fallback: ${fallback?.version}',
      );
      return fallback;
    } catch (e, stackTrace) {
      _logger.error('Failed to get Java for game version $gameVersion', e, stackTrace);
      return await getRecommendedJava();
    }
  }

  bool isJavaCompatibleWithGame(String javaVersion, String gameVersion) {
    final javaMajor = JavaVersion.parseMajorVersion(javaVersion);
    final requiredVersions = JavaVersion.getRecommendedForGameVersion(gameVersion);
    return requiredVersions.contains(javaMajor) ||
           JavaVersion.isCompatible(javaMajor);
  }

  @override
  Future<JavaInstallation?> getSelectedJava() async {
    try {
      final javaPath = _configManager.getString(ConfigKeys.javaPath);

      if (javaPath != null && javaPath.isNotEmpty) {
        final javaInfo = await getJavaInfo(javaPath);
        if (javaInfo != null) {
          _logger.info('Selected Java: ${javaInfo.version} at $javaPath');
          return javaInfo;
        }
      }

      // 如果没有选中或选中的Java无效，使用推荐的Java
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

  @override
  Future<void> selectJava(String javaPath) async {
    try {
      final oldPath = _configManager.getString(ConfigKeys.javaPath);

      if (!await validateJava(javaPath)) {
        throw Exception('Invalid Java path: $javaPath');
      }

      await _configManager.setString(ConfigKeys.javaPath, javaPath);

      _eventBus.publish(
        SelectedJavaChangedEvent(newJavaPath: javaPath, oldJavaPath: oldPath),
      );

      _logger.info('Selected Java: $javaPath');
    } catch (e, stackTrace) {
      _logger.error('Failed to select Java', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> validateJava(String javaPath) async {
    try {
      final javaInfo = await getJavaInfo(javaPath);
      return javaInfo != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<JavaInstallation?> getJavaInfo(String javaPath) async {
    try {
      final file = File(javaPath);
      if (!await file.exists()) {
        _logger.debug('Java file not found: $javaPath');
        return null;
      }

      // 运行 java -version 获取版本信息
      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      // java -version 输出到 stderr
      final output = (result.stderr as String?) ?? '';

      if (result.exitCode != 0) {
        _logger.debug('Java execution failed: $output');
        return null;
      }

      // 解析版本信息
      String? versionString;
      String? vendor;
      bool is64Bit = false;

      final lines = output.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();

        // 解析版本号
        if (trimmedLine.contains('version')) {
          final versionMatch = RegExp(r'"([^"]+)"').firstMatch(trimmedLine);
          if (versionMatch != null) {
            versionString = versionMatch.group(1);
          }
        }

        // 解析发行商
        if (trimmedLine.contains('Runtime Environment')) {
          final vendorMatch = RegExp(r'([A-Za-z]+)').firstMatch(trimmedLine);
          if (vendorMatch != null) {
            vendor = vendorMatch.group(1);
          }
        }

        // 检测64位
        if (trimmedLine.contains('64-Bit') ||
            trimmedLine.contains('amd64') ||
            trimmedLine.contains('x86_64')) {
          is64Bit = true;
        }
      }

      if (versionString == null) {
        _logger.debug('Could not parse Java version from: $output');
        return null;
      }

      final majorVersion = JavaVersion.parseMajorVersion(versionString);

      final installation = JavaInstallation(
        path: javaPath,
        version: versionString,
        majorVersion: majorVersion,
        is64Bit: is64Bit,
        vendor: vendor,
      );

      _logger.debug('Java info: $installation');
      return installation;
    } catch (e, stackTrace) {
      _logger.debug('Failed to get Java info for $javaPath: $e');
      return null;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedInstallations = null;
    _lastCacheUpdate = null;
  }
}
