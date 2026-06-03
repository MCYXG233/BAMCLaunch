import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../core/logger.dart';
import '../instance/instance_manager.dart';
import '../instance/models.dart';
import 'mod_info.dart';
import 'mod_scanner.dart';

/// 模组管理器
///
/// 负责管理 Minecraft 实例的模组，提供模组的查询、启用/禁用、删除等功能。
/// 该类采用单例模式，确保全局只有一个模组管理器实例。
///
/// ## 主要职责
/// - 扫描并获取指定实例的模组列表
/// - 切换模组的启用/禁用状态
/// - 删除模组文件
/// - 打开模组文件夹
///
/// ## 使用示例
/// ```dart
/// final modManager = ModManager.instance;
///
/// // 获取模组列表
/// final mods = await modManager.getMods('instance-id');
///
/// // 切换模组状态
/// await modManager.toggleMod(mods.first);
///
/// // 删除模组
/// await modManager.deleteMod(mods.first);
/// ```
///
/// ## 注意事项
/// - 模组启用状态通过文件扩展名 `.disabled` 来标识
/// - 所有操作都会记录日志，便于问题排查
class ModManager {
  /// 单例实例
  ///
  /// 使用懒加载方式初始化，首次访问时创建实例。
  static ModManager? _instance;

  /// 工厂构造函数
  ///
  /// 返回单例实例，如果实例不存在则创建。
  /// 这确保了全局只有一个 ModManager 实例。
  factory ModManager() {
    _instance ??= ModManager._internal();
    return _instance!;
  }

  /// 私有内部构造函数
  ///
  /// 用于单例模式的内部初始化，外部无法直接调用。
  ModManager._internal();

  /// 获取单例实例的静态 getter
  ///
  /// 提供更直观的单例访问方式，等同于 `ModManager()`。
  ///
  /// 示例：
  /// ```dart
  /// final manager = ModManager.instance;
  /// ```
  static ModManager get instance => _instance ??= ModManager._internal();

  /// 日志记录器
  ///
  /// 用于记录模组管理过程中的信息、警告和错误。
  final Logger _logger = Logger('ModManager');

  /// 实例管理器
  ///
  /// 用于获取实例的路径信息和目录配置。
  final InstanceManager _instanceManager = InstanceManager.instance;

  /// 模组扫描器
  ///
  /// 用于扫描指定目录下的模组文件并解析模组信息。
  final ModScanner _scanner = ModScanner();

  /// 获取指定实例的根路径
  ///
  /// 根据实例 ID 查找实例配置，并返回该实例在文件系统中的完整路径。
  ///
  /// ## 参数
  /// - [instanceId] 实例的唯一标识符
  ///
  /// ## 返回值
  /// 返回实例的完整文件系统路径，格式为：`{目录路径}/instances/{实例ID}`
  ///
  /// ## 异常
  /// - [ArgumentError] 当指定的实例 ID 不存在时抛出
  /// - [ArgumentError] 当实例关联的目录配置不存在时抛出
  ///
  /// ## 示例
  /// ```dart
  /// final path = await _getInstancePath('my-instance');
  /// // 返回类似: C:\Games\Minecraft\instances\my-instance
  /// ```
  Future<String> _getInstancePath(String instanceId) async {
    // 确保实例管理器已初始化
    if (!_instanceManager.isInitialized) {
      await _instanceManager.initialize();
    }

    // 查找指定 ID 的实例配置
    final instance = _instanceManager.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    // 查找实例所属的目录配置
    final directory = _instanceManager.directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found for instance: $instanceId'),
    );

    // 拼接并返回实例的完整路径
    return path.join(directory.path, 'instances', instanceId);
  }

  /// 获取指定实例的模组列表
  ///
  /// 扫描指定实例的 mods 目录，返回所有模组的信息列表。
  /// 包括已启用和已禁用的模组。
  ///
  /// ## 参数
  /// - [instanceId] 实例的唯一标识符
  ///
  /// ## 返回值
  /// 返回模组信息列表 [List<ModInfo>]。如果发生错误，返回空列表。
  ///
  /// ## 异常
  /// 该方法会捕获所有异常并返回空列表，不会向上抛出异常。
  /// 错误信息会记录到日志中。
  ///
  /// ## 示例
  /// ```dart
  /// final mods = await modManager.getMods('my-instance');
  /// for (final mod in mods) {
  ///   print('${mod.name} - ${mod.isEnabled ? "已启用" : "已禁用"}');
  /// }
  /// ```
  Future<List<ModInfo>> getMods(String instanceId) async {
    try {
      // 获取实例路径
      final instancePath = await _getInstancePath(instanceId);
      // 扫描该路径下的模组
      return await _scanner.scanMods(instancePath);
    } catch (e, stackTrace) {
      // 记录错误日志，返回空列表以避免中断调用流程
      _logger.error('Failed to get mods for instance: $instanceId', e, stackTrace);
      return [];
    }
  }

  /// 切换模组的启用/禁用状态
  ///
  /// 通过重命名模组文件来切换其状态：
  /// - 启用 → 禁用：添加 `.disabled` 后缀
  /// - 禁用 → 启用：移除 `.disabled` 后缀
  ///
  /// ## 参数
  /// - [mod] 要切换状态的模组信息对象
  ///
  /// ## 返回值
  /// 无返回值（[Future<void>]）
  ///
  /// ## 异常
  /// - [FileSystemException] 当模组文件不存在时抛出
  /// - [FileSystemException] 当文件操作失败时抛出（如权限不足）
  /// - 其他可能的 IO 异常
  ///
  /// ## 示例
  /// ```dart
  /// final mods = await modManager.getMods('my-instance');
  /// final disabledMod = mods.firstWhere((m) => !m.isEnabled);
  /// await modManager.toggleMod(disabledMod); // 启用该模组
  /// ```
  ///
  /// ## 注意
  /// 该方法会修改文件系统中的文件名，操作不可逆（除非再次调用）。
  Future<void> toggleMod(ModInfo mod) async {
    try {
      // 获取模组文件对象
      final file = File(mod.filePath);

      // 检查文件是否存在
      if (!await file.exists()) {
        throw FileSystemException('模组文件不存在', mod.filePath);
      }

      if (mod.isEnabled) {
        // 模组当前已启用，需要禁用：添加 .disabled 后缀
        final newPath = '${mod.filePath}.disabled';
        await file.rename(newPath);
        _logger.info('Disabled mod: ${mod.name}');
      } else {
        // 模组当前已禁用，需要启用：移除 .disabled 后缀
        final originalPath = mod.filePath.replaceAll('.disabled', '');
        await file.rename(originalPath);
        _logger.info('Enabled mod: ${mod.name}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to toggle mod: ${mod.name}', e, stackTrace);
      rethrow;
    }
  }

  /// 删除模组
  ///
  /// 从文件系统中永久删除指定的模组文件。
  /// 此操作不可逆，请谨慎使用。
  ///
  /// ## 参数
  /// - [mod] 要删除的模组信息对象
  ///
  /// ## 返回值
  /// 无返回值（[Future<void>]）
  ///
  /// ## 异常
  /// - 文件删除失败时可能抛出 IO 异常
  /// - 权限不足时可能抛出 [FileSystemException]
  ///
  /// ## 示例
  /// ```dart
  /// final mods = await modManager.getMods('my-instance');
  /// final modToDelete = mods.firstWhere((m) => m.name == 'unwanted-mod');
  /// await modManager.deleteMod(modToDelete);
  /// ```
  ///
  /// ## 注意
  /// - 如果文件不存在，方法会静默返回，不会抛出异常
  /// - 删除操作不可逆，建议在调用前进行用户确认
  Future<void> deleteMod(ModInfo mod) async {
    try {
      final file = File(mod.filePath);

      // 仅在文件存在时执行删除
      if (await file.exists()) {
        await file.delete();
        _logger.info('Deleted mod: ${mod.name} (${mod.fileName})');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to delete mod: ${mod.name}', e, stackTrace);
      rethrow;
    }
  }

  /// 打开模组文件夹
  ///
  /// 在系统文件管理器中打开指定实例的 mods 文件夹。
  /// 如果文件夹不存在，会自动创建。
  ///
  /// ## 参数
  /// - [instancePath] 实例的根路径
  ///
  /// ## 返回值
  /// 无返回值（[Future<void>]）
  ///
  /// ## 异常
  /// - 打开文件夹失败时可能抛出异常
  /// - 创建文件夹失败时可能抛出 [FileSystemException]
  ///
  /// ## 示例
  /// ```dart
  /// final instancePath = await _getInstancePath('my-instance');
  /// await modManager.openModsFolder(instancePath);
  /// ```
  ///
  /// ## 实现细节
  /// 方法会依次尝试以下方式打开文件夹：
  /// 1. 使用 `url_launcher` 的 `launchUrl` 方法
  /// 2. 如果失败，使用系统命令 `explorer`（Windows）
  ///
  /// 注意：当前实现中 `canLaunchUrl` 的判断逻辑可能存在问题，
  /// 应该是 `if (await canLaunchUrl(uri))` 而非 `if (!await canLaunchUrl(uri))`。
  Future<void> openModsFolder(String instancePath) async {
    try {
      // 构建 mods 文件夹路径
      final modsDir = Directory(path.join(instancePath, 'mods'));

      // 如果文件夹不存在，则创建
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }

      // 将路径转换为 URI
      final uri = Uri.directory(modsDir.path);

      // 尝试使用 url_launcher 打开文件夹
      // 注意：这里的逻辑可能有误，应该是 if (await canLaunchUrl(uri))
      if (!await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // 备用方案：使用系统命令打开文件夹（Windows）
        await Process.run('explorer', [modsDir.path]);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to open mods folder', e, stackTrace);
      rethrow;
    }
  }
}