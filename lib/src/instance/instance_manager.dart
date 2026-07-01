import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart' as archive;
import 'package:path/path.dart' as path;
import 'models.dart';
import '../config/config_manager.dart';
import '../core/logger.dart';

/// 实例管理器
/// 
/// 该类是一个单例类，负责管理 Minecraft 游戏的目录、实例和资源。
/// 主要职责包括：
/// - 管理游戏目录（GameDirectory）的增删改查
/// - 管理游戏实例（GameInstance）的增删改查
/// - 管理实例资源的导入导出
/// - 自动检测系统中的 Minecraft 安装目录
/// - 维护当前选中的目录和实例状态
/// 
/// 使用方式：
/// ```dart
/// // 获取单例实例
/// final manager = InstanceManager.instance;
/// 
/// // 初始化管理器
/// await manager.initialize();
/// 
/// // 创建新目录
/// final directory = await manager.createDirectory(
///   name: '我的游戏目录',
///   path: '/path/to/minecraft',
/// );
/// 
/// // 创建新实例
/// final instance = await manager.createInstance(
///   name: '我的实例',
///   directoryId: directory.id,
///   version: '1.20.1',
/// );
/// ```
/// 
/// 注意：
/// - 使用前必须调用 [initialize] 方法进行初始化
/// - 所有修改操作都会自动保存到配置文件
/// - 该类是单例模式，全局只有一个实例
class InstanceManager {
  /// 单例实例
  static InstanceManager? _instance;
  
  /// 配置文件中存储实例列表的键名
  static const String _instancesKey = 'instances';
  
  /// 配置文件中存储目录列表的键名
  static const String _directoriesKey = 'directories';
  
  /// 配置文件中存储选中目录ID的键名
  static const String _selectedDirectoryKey = 'selectedDirectory';
  
  /// 配置文件中存储选中实例ID的键名
  static const String _selectedInstanceKey = 'selectedInstance';

  /// 日志记录器，用于记录操作日志和错误信息
  final Logger _logger = Logger('InstanceManager');
  
  /// 配置管理器，用于持久化存储数据
  final ConfigManager _config = ConfigManager.instance;

  /// 游戏目录列表
  List<GameDirectory> _directories = [];
  
  /// 游戏实例列表
  List<GameInstance> _instances = [];
  
  /// 当前选中的目录ID
  String? _selectedDirectoryId;
  
  /// 当前选中的实例ID
  String? _selectedInstanceId;
  
  /// 标记管理器是否已初始化
  bool _isInitialized = false;

  /// 标记管理器是否正在初始化中（防止并发初始化）
  bool _isInitializing = false;

  /// 私有构造函数（单例模式）
  InstanceManager._internal();

  /// 工厂构造函数，返回单例实例
  /// 
  /// 如果实例不存在则创建，否则返回已存在的实例
  factory InstanceManager() {
    _instance ??= InstanceManager._internal();
    return _instance!;
  }

  /// 获取单例实例的静态方法
  /// 
  /// 这是访问 [InstanceManager] 实例的推荐方式
  static InstanceManager get instance => InstanceManager();

  /// 管理器是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 获取所有游戏目录（不可修改的列表）
  List<GameDirectory> get directories => List.unmodifiable(_directories);
  
  /// 获取所有游戏实例（不可修改的列表）
  List<GameInstance> get instances => List.unmodifiable(_instances);
  
  /// 获取当前选中的目录ID
  String? get selectedDirectoryId => _selectedDirectoryId;
  
  /// 获取当前选中的实例ID
  String? get selectedInstanceId => _selectedInstanceId;

  /// 获取当前选中的目录
  /// 
  /// 返回值：
  /// - 如果有选中的目录ID，返回对应的目录对象
  /// - 如果选中的目录ID不存在但有其他目录，返回第一个目录
  /// - 如果没有任何目录，返回 null
  /// 
  /// 异常：
  /// - [StateError]：当选中的目录ID无效且目录列表为空时抛出
  GameDirectory? get selectedDirectory {
    if (_selectedDirectoryId == null) return _directories.isNotEmpty ? _directories.first : null;
    try {
      return _directories.firstWhere((d) => d.id == _selectedDirectoryId);
    } catch (_) {
      return _directories.isNotEmpty ? _directories.first : null;
    }
  }

  /// 获取当前选中的实例
  /// 
  /// 返回值：
  /// - 如果有选中的实例ID，返回对应的实例对象
  /// - 如果选中的实例ID不存在但有其他实例，返回第一个实例
  /// - 如果没有任何实例，返回 null
  /// 
  /// 异常：
  /// - [StateError]：当选中的实例ID无效且实例列表为空时抛出
  GameInstance? get selectedInstance {
    if (_selectedInstanceId == null) return _instances.isNotEmpty ? _instances.first : null;
    try {
      return _instances.firstWhere((i) => i.id == _selectedInstanceId);
    } catch (_) {
      return _instances.isNotEmpty ? _instances.first : null;
    }
  }

  /// 获取指定目录下的所有实例
  /// 
  /// 参数：
  /// - [directoryId]：目录ID
  /// 
  /// 返回值：
  /// - 返回该目录下的所有实例列表
  /// 
  /// 使用示例：
  /// ```dart
  /// final instances = manager.getDirectoryInstances(directoryId);
  /// for (final instance in instances) {
  ///   print(instance.name);
  /// }
  /// ```
  List<GameInstance> getDirectoryInstances(String directoryId) {
    return _instances.where((i) => i.directoryId == directoryId).toList();
  }

  /// 初始化管理器
  /// 
  /// 该方法必须在使用管理器之前调用。它会：
  /// 1. 从配置文件加载已保存的目录列表
  /// 2. 从配置文件加载已保存的实例列表
  /// 3. 加载上次选中的目录和实例ID
  /// 4. 自动检测系统中常见的 Minecraft 安装目录
  /// 
  /// 如果已经初始化过，则直接返回，不会重复初始化。
  /// 
  /// 异常：
  /// - 如果初始化过程中发生错误，会重新抛出异常
  /// 
  /// 使用示例：
  /// ```dart
  /// final manager = InstanceManager.instance;
  /// await manager.initialize();
  /// // 现在可以安全地使用管理器
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // 等待正在进行的初始化完成
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      _logger.info('Initializing InstanceManager...');

      await _loadDirectories();
      await _loadInstances();
      await _loadSelectedIds();
      
      // 自动检测并添加常见的 Minecraft 目录
      await _autoDetectDirectories();

      _isInitialized = true;
      _logger.info('InstanceManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize InstanceManager', e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 自动检测常见的 Minecraft 目录和实例
  /// 
  /// 该方法会扫描以下路径：
  /// - 用户指定的路径：`E:\TSSForsunshine\Minecraft`
  /// - Windows APPDATA 目录下的 `.minecraft`
  /// - `C:\Minecraft`
  /// - `D:\Minecraft`
  /// 
  /// 对于每个存在的目录：
  /// 1. 检查是否已在目录列表中
  /// 2. 如果不存在，创建新的目录记录
  /// 3. 扫描目录中的 `versions` 文件夹，自动创建实例记录
  /// 
  /// 注意：
  /// - 该方法是私有方法，在初始化时自动调用
  /// - 检测失败不会影响整体初始化流程，只会记录警告日志
  Future<void> _autoDetectDirectories() async {
    try {
      // 候选路径列表
      final List<String> candidatePaths = [
        // 用户指定的路径
        r'E:\TSSForsunshine\Minecraft',
        // Windows 常见的 Minecraft 目录
        path.join(Platform.environment['APPDATA'] ?? '', '.minecraft'),
        // 其他可能的路径
        r'C:\Minecraft',
        r'D:\Minecraft',
      ];

      // 遍历每个候选路径
      for (final candidatePath in candidatePaths) {
        if (candidatePath.isEmpty) continue;
        
        final directory = Directory(candidatePath);
        if (await directory.exists()) {
          // 检查该目录是否已经存在
          final existingDir = _directories.firstWhere(
            (d) => d.path == candidatePath,
            orElse: () => GameDirectory(id: '', name: '', path: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          );
          
          String? dirId;
          
          if (existingDir.id.isEmpty) {
            // 目录不存在，创建新目录
            _logger.info('Detected new Minecraft directory: $candidatePath');
            final name = path.basename(candidatePath);
            final newDir = await createDirectory(name: name, path: candidatePath);
            dirId = newDir.id;
          } else {
            // 目录已存在，使用现有ID
            dirId = existingDir.id;
          }
          
          // 检测目录中的游戏版本并创建实例
          if (dirId != null) {
            await _detectInstancesInDirectory(dirId, candidatePath);
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to auto-detect directories', e);
    }
  }

  /// 在指定目录中检测游戏版本并创建实例
  /// 
  /// 该方法会扫描目录下的 `versions` 文件夹，对于每个版本：
  /// 1. 检查是否存在对应的 JSON 文件（如 `1.20.1.json`）
  /// 2. 如果存在且该版本尚未创建实例，则自动创建实例记录
  /// 
  /// 参数：
  /// - [directoryId]：目录ID
  /// - [directoryPath]：目录的文件系统路径
  /// 
  /// 注意：
  /// - 该方法是私有方法，由 [_autoDetectDirectories] 调用
  /// - 检测失败不会抛出异常，只会记录警告日志
  Future<void> _detectInstancesInDirectory(String directoryId, String directoryPath) async {
    try {
      // 构建 versions 目录路径
      final versionsDir = Directory(path.join(directoryPath, 'versions'));
      if (!await versionsDir.exists()) {
        return;
      }

      // 获取所有版本目录
      final versionDirs = await versionsDir.list().where((entity) => entity is Directory).toList();
      
      // 遍历每个版本目录
      for (final versionDir in versionDirs) {
        final versionName = path.basename(versionDir.path);
        final jsonFile = File(path.join(versionDir.path, '$versionName.json'));
        
        // 检查版本 JSON 文件是否存在
        if (await jsonFile.exists()) {
          // 检查该版本是否已创建为实例
          final exists = _instances.any(
            (i) => i.directoryId == directoryId && i.version == versionName,
          );
          
          // 如果不存在，创建新实例
          if (!exists) {
            _logger.info('Detected Minecraft version: $versionName in $directoryPath');
            await createInstance(
              name: versionName,
              directoryId: directoryId,
              version: versionName,
              description: '自动检测到的 $versionName 版本',
            );
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to detect instances in directory: $directoryPath', e);
    }
  }

  /// 从配置文件加载目录列表
  /// 
  /// 该方法会从配置管理器中读取保存的目录数据，
  /// 并将其反序列化为 [GameDirectory] 对象列表。
  /// 
  /// 如果加载失败，会清空目录列表并记录错误日志。
  Future<void> _loadDirectories() async {
    try {
      final raw = _config.get<List<dynamic>>(_directoriesKey);
      if (raw != null) {
        _directories = raw.map((e) => GameDirectory.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _directories = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load directories', e, stackTrace);
      _directories = [];
    }
  }

  /// 从配置文件加载实例列表
  /// 
  /// 该方法会从配置管理器中读取保存的实例数据，
  /// 并将其反序列化为 [GameInstance] 对象列表。
  /// 
  /// 如果加载失败，会清空实例列表并记录错误日志。
  Future<void> _loadInstances() async {
    try {
      final raw = _config.get<List<dynamic>>(_instancesKey);
      if (raw != null) {
        _instances = raw.map((e) => GameInstance.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _instances = [];
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load instances', e, stackTrace);
      _instances = [];
    }
  }

  /// 从配置文件加载选中的ID
  /// 
  /// 该方法会加载上次选中的目录ID和实例ID。
  /// 如果没有保存的选中ID，但有可用的目录/实例，
  /// 则自动选中第一个。
  Future<void> _loadSelectedIds() async {
    _selectedDirectoryId = _config.getString(_selectedDirectoryKey);
    _selectedInstanceId = _config.getString(_selectedInstanceKey);

    // 如果没有选中的目录但有目录存在，选中第一个
    if (_directories.isNotEmpty && _selectedDirectoryId == null) {
      _selectedDirectoryId = _directories.first.id;
    }

    // 如果没有选中的实例但有实例存在，选中第一个
    if (_instances.isNotEmpty && _selectedInstanceId == null) {
      _selectedInstanceId = _instances.first.id;
    }
  }

  /// 保存所有数据到配置文件
  /// 
  /// 该方法会将当前的目录列表、实例列表、选中的ID等数据
  /// 保存到配置文件中，以便下次启动时恢复状态。
  /// 
  /// 异常：
  /// - 如果保存失败，会重新抛出异常
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.save();
  /// ```
  Future<void> save() async {
    try {
      // 保存目录列表
      await _config.set<List<dynamic>>(_directoriesKey, _directories.map((d) => d.toJson()).toList());
      // 保存实例列表
      await _config.set<List<dynamic>>(_instancesKey, _instances.map((i) => i.toJson()).toList());

      // 保存选中的目录ID
      if (_selectedDirectoryId != null) {
        await _config.setString(_selectedDirectoryKey, _selectedDirectoryId!);
      }

      // 保存选中的实例ID
      if (_selectedInstanceId != null) {
        await _config.setString(_selectedInstanceKey, _selectedInstanceId!);
      }

      await _config.save();
      _logger.info('Instance data saved successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to save instance data', e, stackTrace);
      rethrow;
    }
  }

  /// 创建新的游戏目录
  /// 
  /// 参数：
  /// - [name]：目录名称，用于显示
  /// - [path]：目录的文件系统路径
  /// 
  /// 返回值：
  /// - 返回新创建的 [GameDirectory] 对象
  /// 
  /// 注意：
  /// - 如果这是第一个创建的目录，会自动将其设为选中状态
  /// - 创建后会自动保存到配置文件
  /// 
  /// 使用示例：
  /// ```dart
  /// final directory = await manager.createDirectory(
  ///   name: '我的游戏目录',
  ///   path: 'C:\\Games\\Minecraft',
  /// );
  /// print('创建的目录ID: ${directory.id}');
  /// ```
  Future<GameDirectory> createDirectory({
    required String name,
    required String path,
  }) async {
    // 生成唯一ID
    final id = generateId();
    final now = DateTime.now();
    
    // 创建目录对象
    final directory = GameDirectory(
      id: id,
      name: name,
      path: path,
      createdAt: now,
      updatedAt: now,
    );

    // 添加到列表
    _directories.add(directory);

    // 如果是第一个目录，自动选中
    if (_directories.length == 1) {
      _selectedDirectoryId = id;
    }

    await save();
    _logger.info('Created directory: $name at $path');

    return directory;
  }

  /// 更新游戏目录信息
  /// 
  /// 参数：
  /// - [id]：要更新的目录ID
  /// - [name]：新的目录名称（可选）
  /// - [path]：新的目录路径（可选）
  /// 
  /// 返回值：
  /// - 返回更新后的 [GameDirectory] 对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.updateDirectory(
  ///   id: directoryId,
  ///   name: '新名称',
  /// );
  /// ```
  Future<GameDirectory> updateDirectory({
    required String id,
    String? name,
    String? path,
  }) async {
    // 查找目录索引
    final index = _directories.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Directory not found: $id');
    }

    // 更新目录信息
    final directory = _directories[index].copyWith(
      name: name,
      path: path,
      updatedAt: DateTime.now(),
    );

    _directories[index] = directory;
    await save();
    _logger.info('Updated directory: ${directory.name}');

    return directory;
  }

  /// 删除游戏目录
  /// 
  /// 参数：
  /// - [id]：要删除的目录ID
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  /// 
  /// 注意：
  /// - 删除目录会同时删除该目录下的所有实例
  /// - 如果删除的是当前选中的目录，会自动选中第一个可用目录
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.deleteDirectory(directoryId);
  /// ```
  Future<void> deleteDirectory(String id) async {
    // 查找目录索引
    final index = _directories.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Directory not found: $id');
    }

    final directory = _directories[index];

    // 删除该目录下的所有实例
    _instances.removeWhere((i) => i.directoryId == id);
    // 删除目录
    _directories.removeAt(index);

    // 如果删除的是当前选中的目录，重新选择
    if (_selectedDirectoryId == id) {
      _selectedDirectoryId = _directories.isNotEmpty ? _directories.first.id : null;
      _selectedInstanceId = _instances.isNotEmpty ? _instances.first.id : null;
    }

    await save();
    _logger.info('Deleted directory: ${directory.name}');
  }

  /// 选择游戏目录
  /// 
  /// 参数：
  /// - [id]：要选择的目录ID
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  /// 
  /// 注意：
  /// - 选择目录时，如果当前选中的实例不在该目录下，
  ///   会自动选中该目录下的第一个实例
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.selectDirectory(directoryId);
  /// ```
  Future<void> selectDirectory(String id) async {
    // 验证目录是否存在
    if (!_directories.any((d) => d.id == id)) {
      throw ArgumentError('Directory not found: $id');
    }

    _selectedDirectoryId = id;

    // 检查当前选中的实例是否在该目录下
    final dirInstances = getDirectoryInstances(id);
    if (dirInstances.isNotEmpty && !dirInstances.any((i) => i.id == _selectedInstanceId)) {
      _selectedInstanceId = dirInstances.first.id;
    }

    await save();
    _logger.info('Selected directory: $id');
  }

  /// 创建新的游戏实例
  /// 
  /// 参数：
  /// - [name]：实例名称
  /// - [directoryId]：所属目录ID
  /// - [version]：Minecraft 版本号
  /// - [loader]：模组加载器类型（如 'forge', 'fabric'，可选）
  /// - [loaderVersion]：模组加载器版本（可选）
  /// - [icon]：实例图标路径（可选）
  /// - [description]：实例描述（可选）
  /// - [config]：实例配置（可选，默认为空配置）
  /// - [resources]：实例资源（可选，默认为空资源列表）
  /// 
  /// 返回值：
  /// - 返回新创建的 [GameInstance] 对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的目录ID不存在
  /// 
  /// 注意：
  /// - 创建实例时会自动创建实例所需的所有子目录
  /// - 如果实例属于当前选中的目录且没有选中的实例，会自动选中该实例
  /// 
  /// 使用示例：
  /// ```dart
  /// final instance = await manager.createInstance(
  ///   name: '我的模组实例',
  ///   directoryId: directoryId,
  ///   version: '1.20.1',
  ///   loader: 'fabric',
  ///   loaderVersion: '0.14.21',
  ///   description: '我的 Fabric 模组实例',
  /// );
  /// ```
  Future<GameInstance> createInstance({
    required String name,
    required String directoryId,
    required String version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceConfig? config,
    InstanceResources? resources,
  }) async {
    // 验证目录是否存在
    if (!_directories.any((d) => d.id == directoryId)) {
      throw ArgumentError('Directory not found: $directoryId');
    }

    // 生成唯一ID
    final id = generateId();
    final now = DateTime.now();

    // 创建实例对象
    final instance = GameInstance(
      id: id,
      name: name,
      directoryId: directoryId,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      config: config ?? InstanceConfig(),
      resources: resources ?? InstanceResources(mods: [], resourcePacks: [], shaderPacks: [], worlds: [], screenshots: []),
      createdAt: now,
      updatedAt: now,
    );

    _instances.add(instance);

    // 如果实例属于当前选中的目录且没有选中的实例，自动选中
    if (_selectedDirectoryId == directoryId && _selectedInstanceId == null) {
      _selectedInstanceId = id;
    }

    // 确保实例目录存在
    await ensureInstanceDirectories(id);
    await save();
    _logger.info('Created instance: $name');

    return instance;
  }

  /// 更新游戏实例信息
  /// 
  /// 参数：
  /// - [id]：要更新的实例ID
  /// - [name]：新的实例名称（可选）
  /// - [version]：新的 Minecraft 版本（可选）
  /// - [loader]：新的模组加载器类型（可选）
  /// - [loaderVersion]：新的模组加载器版本（可选）
  /// - [icon]：新的图标路径（可选）
  /// - [description]：新的描述（可选）
  /// - [status]：新的状态（可选）
  /// - [config]：新的配置（可选）
  /// - [resources]：新的资源（可选）
  /// - [lastPlayed]：最后游玩时间（可选）
  /// - [playTimeSeconds]：总游玩时长（秒，可选）
  /// 
  /// 返回值：
  /// - 返回更新后的 [GameInstance] 对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.updateInstance(
  ///   id: instanceId,
  ///   name: '新名称',
  ///   description: '更新后的描述',
  /// );
  /// ```
  Future<GameInstance> updateInstance({
    required String id,
    String? name,
    String? version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceStatus? status,
    InstanceConfig? config,
    InstanceResources? resources,
    DateTime? lastPlayed,
    int? playTimeSeconds,
  }) async {
    // 查找实例索引
    final index = _instances.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Instance not found: $id');
    }

    // 更新实例信息
    final instance = _instances[index].copyWith(
      name: name,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      status: status,
      config: config,
      resources: resources,
      updatedAt: DateTime.now(),
      lastPlayed: lastPlayed,
      playTimeSeconds: playTimeSeconds,
    );

    _instances[index] = instance;
    await save();
    _logger.info('Updated instance: ${instance.name}');

    return instance;
  }

  /// 删除游戏实例
  /// 
  /// 参数：
  /// - [id]：要删除的实例ID
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  /// 
  /// 注意：
  /// - 如果删除的是当前选中的实例，会自动选中同目录下的第一个可用实例
  /// - 该方法只删除实例记录，不会删除实际的文件
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.deleteInstance(instanceId);
  /// ```
  Future<void> deleteInstance(String id) async {
    // 查找实例索引
    final index = _instances.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances[index];
    _instances.removeAt(index);

    // 如果删除的是当前选中的实例，重新选择
    if (_selectedInstanceId == id) {
      final dirInstances = getDirectoryInstances(instance.directoryId);
      _selectedInstanceId = dirInstances.isNotEmpty ? dirInstances.first.id : null;
    }

    await save();
    _logger.info('Deleted instance: ${instance.name}');
  }

  /// 选择游戏实例
  /// 
  /// 参数：
  /// - [id]：要选择的实例ID
  /// 
  /// 异常：
  /// - [ArgumentError]：如果指定的实例ID不存在
  /// 
  /// 注意：
  /// - 选择实例时会自动选中实例所属的目录
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.selectInstance(instanceId);
  /// ```
  Future<void> selectInstance(String id) async {
    // 验证实例是否存在
    if (!_instances.any((i) => i.id == id)) {
      throw ArgumentError('Instance not found: $id');
    }

    final instance = _instances.firstWhere((i) => i.id == id);
    _selectedInstanceId = id;
    // 同时选中实例所属的目录
    _selectedDirectoryId = instance.directoryId;

    await save();
    _logger.info('Selected instance: $id');
  }

  /// 获取实例的根目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回实例的根目录路径（格式：`{目录路径}\instances\{实例ID}`）
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  /// 
  /// 使用示例：
  /// ```dart
  /// final instancePath = manager.getInstancePath(instanceId);
  /// print('实例路径: $instancePath');
  /// ```
  String getInstancePath(String instanceId) {
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );
    final directory = _directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );
    return '${directory.path}\\instances\\${instance.id}';
  }

  /// 获取实例的 mods 目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 mods 目录路径
  String getInstanceModsPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\mods';
  }

  /// 获取实例的 config 目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 config 目录路径
  String getInstanceConfigPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\config';
  }

  /// 获取实例的 saves（存档）目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 saves 目录路径
  String getInstanceSavesPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\saves';
  }

  /// 获取实例的 resourcepacks（资源包）目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 resourcepacks 目录路径
  String getInstanceResourcePacksPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\resourcepacks';
  }

  /// 获取实例的 shaderpacks（光影包）目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 shaderpacks 目录路径
  String getInstanceShaderPacksPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\shaderpacks';
  }

  /// 获取实例的 screenshots（截图）目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 screenshots 目录路径
  String getInstanceScreenshotsPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\screenshots';
  }

  /// 获取实例的 logs（日志）目录路径
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回 logs 目录路径
  String getInstanceLogsPath(String instanceId) {
    return '${getInstancePath(instanceId)}\\logs';
  }

  /// 确保实例的所有必要目录都存在
  /// 
  /// 该方法会创建实例所需的以下目录：
  /// - mods：模组目录
  /// - config：配置文件目录
  /// - saves：存档目录
  /// - resourcepacks：资源包目录
  /// - shaderpacks：光影包目录
  /// - screenshots：截图目录
  /// - logs：日志目录
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在（由 [getInstancePath] 抛出）
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.ensureInstanceDirectories(instanceId);
  /// ```
  Future<void> ensureInstanceDirectories(String instanceId) async {
    final basePath = getInstancePath(instanceId);
    // 定义需要创建的目录列表
    final dirs = [
      '$basePath\\mods',
      '$basePath\\config',
      '$basePath\\saves',
      '$basePath\\resourcepacks',
      '$basePath\\shaderpacks',
      '$basePath\\screenshots',
      '$basePath\\logs',
    ];
    // 逐个创建目录（如果不存在）
    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  /// 添加资源到实例
  /// 
  /// 将资源ID添加到实例的资源列表中。根据资源类型，
  /// 资源ID会被添加到对应的列表中（mods、resourcePacks等）。
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [resourceId]：资源ID
  /// - [type]：资源类型（mod、resourcePack、shaderPack、world、screenshot）
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在
  /// 
  /// 注意：
  /// - 如果资源ID已存在于列表中，不会重复添加
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.addResourceToInstance(
  ///   instanceId,
  ///   'mod-id-123',
  ///   ResourceType.mod,
  /// );
  /// ```
  Future<void> addResourceToInstance(String instanceId, String resourceId, ResourceType type) async {
    // 查找实例索引
    final instanceIndex = _instances.indexWhere((i) => i.id == instanceId);
    if (instanceIndex == -1) {
      throw ArgumentError('Instance not found: $instanceId');
    }

    final instance = _instances[instanceIndex];
    final updatedResources = instance.resources.copyWith();

    // 根据资源类型添加到对应列表
    switch (type) {
      case ResourceType.mod:
        if (!updatedResources.mods.contains(resourceId)) {
          updatedResources.mods.add(resourceId);
        }
        break;
      case ResourceType.resourcePack:
        if (!updatedResources.resourcePacks.contains(resourceId)) {
          updatedResources.resourcePacks.add(resourceId);
        }
        break;
      case ResourceType.shaderPack:
        if (!updatedResources.shaderPacks.contains(resourceId)) {
          updatedResources.shaderPacks.add(resourceId);
        }
        break;
      case ResourceType.world:
        if (!updatedResources.worlds.contains(resourceId)) {
          updatedResources.worlds.add(resourceId);
        }
        break;
      case ResourceType.screenshot:
        if (!updatedResources.screenshots.contains(resourceId)) {
          updatedResources.screenshots.add(resourceId);
        }
        break;
    }

    // 更新实例
    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  /// 从实例移除资源
  /// 
  /// 从实例的资源列表中移除指定的资源ID。
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// - [resourceId]：要移除的资源ID
  /// - [type]：资源类型
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID不存在
  /// 
  /// 注意：
  /// - 如果资源ID不存在于列表中，操作会被忽略
  /// 
  /// 使用示例：
  /// ```dart
  /// await manager.removeResourceFromInstance(
  ///   instanceId,
  ///   'mod-id-123',
  ///   ResourceType.mod,
  /// );
  /// ```
  Future<void> removeResourceFromInstance(String instanceId, String resourceId, ResourceType type) async {
    // 查找实例索引
    final instanceIndex = _instances.indexWhere((i) => i.id == instanceId);
    if (instanceIndex == -1) {
      throw ArgumentError('Instance not found: $instanceId');
    }

    final instance = _instances[instanceIndex];
    final updatedResources = instance.resources.copyWith();

    // 根据资源类型从对应列表移除
    switch (type) {
      case ResourceType.mod:
        updatedResources.mods.remove(resourceId);
        break;
      case ResourceType.resourcePack:
        updatedResources.resourcePacks.remove(resourceId);
        break;
      case ResourceType.shaderPack:
        updatedResources.shaderPacks.remove(resourceId);
        break;
      case ResourceType.world:
        updatedResources.worlds.remove(resourceId);
        break;
      case ResourceType.screenshot:
        updatedResources.screenshots.remove(resourceId);
        break;
    }

    // 更新实例
    final updatedInstance = instance.copyWith(
      resources: updatedResources,
      updatedAt: DateTime.now(),
    );

    _instances[instanceIndex] = updatedInstance;
    await save();
  }

  /// 复制实例
  /// 
  /// 在同一目录下创建实例的副本，可选择是否复制实例文件。
  /// 
  /// 参数：
  /// - [instanceId]：要复制的实例ID
  /// - [newName]：新实例的名称
  /// - [copyFiles]：是否复制实例文件（默认为 true）
  /// - [options]：复制选项，可指定要排除的目录和文件
  /// 
  /// 返回值：
  /// - 返回新创建的 [GameInstance] 对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  /// 
  /// 注意：
  /// - 新实例会有新的ID和创建时间
  /// - 游戏时长和最后游玩时间会被重置
  /// 
  /// 使用示例：
  /// ```dart
  /// final newInstance = await manager.duplicateInstance(
  ///   instanceId,
  ///   '我的实例 - 副本',
  ///   copyFiles: true,
  /// );
  /// ```
  Future<GameInstance> duplicateInstance(
    String instanceId,
    String newName, {
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    // 获取原实例
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    // 获取所属目录
    final directory = _directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );

    // 生成新ID
    final id = generateId();
    final now = DateTime.now();

    // 创建副本（重置ID、名称、时间和统计数据）
    final duplicated = instance.copyWith(
      id: id,
      name: newName,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    _instances.add(duplicated);

    // 复制实例文件
    if (copyFiles) {
      try {
        final sourceDir = Directory(path.join(directory.path, 'instances', instance.id));
        final targetDir = Directory(path.join(directory.path, 'instances', id));

        if (await sourceDir.exists()) {
          await _copyDirectory(sourceDir, targetDir, options: options);
          _logger.info('Copied instance files: ${instance.id} -> $id');
        }

        // 如果指定，复制版本目录
        if (options?.copyVersionDir ?? false) {
          final sourceVersionDir = Directory(path.join(directory.path, 'versions', instance.version));
          final targetVersionDir = Directory(path.join(directory.path, 'versions', instance.version));

          if (await sourceVersionDir.exists()) {
            await _copyDirectory(sourceVersionDir, targetVersionDir, options: options);
            _logger.info('Copied version directory: ${instance.version}');
          }
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to copy instance files', e, stackTrace);
      }
    }

    await save();
    _logger.info('Duplicated instance: $newName');

    return duplicated;
  }

  /// 复制实例到指定目录
  /// 
  /// 将实例复制到另一个游戏目录下。
  /// 
  /// 参数：
  /// - [instanceId]：要复制的实例ID
  /// - [newName]：新实例的名称
  /// - [targetDirectoryId]：目标目录ID
  /// - [copyFiles]：是否复制实例文件（默认为 true）
  /// - [options]：复制选项
  /// 
  /// 返回值：
  /// - 返回新创建的 [GameInstance] 对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID或目标目录ID不存在
  /// 
  /// 使用示例：
  /// ```dart
  /// final newInstance = await manager.duplicateInstanceToDirectory(
  ///   instanceId,
  ///   '我的实例 - 副本',
  ///   targetDirectoryId,
  /// );
  /// ```
  Future<GameInstance> duplicateInstanceToDirectory(
    String instanceId,
    String newName,
    String targetDirectoryId, {
    bool copyFiles = true,
    CopyOptions? options,
  }) async {
    // 获取原实例
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    // 获取目标目录
    final targetDirectory = _directories.firstWhere(
      (d) => d.id == targetDirectoryId,
      orElse: () => throw ArgumentError('Directory not found: $targetDirectoryId'),
    );

    // 生成新ID
    final id = generateId();
    final now = DateTime.now();

    // 创建副本（更新目录ID）
    final duplicated = instance.copyWith(
      id: id,
      name: newName,
      directoryId: targetDirectoryId,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    _instances.add(duplicated);

    // 复制实例文件到目标目录
    if (copyFiles) {
      try {
        final sourceDir = Directory(path.join(
          _directories.firstWhere((d) => d.id == instance.directoryId).path,
          'instances',
          instance.id,
        ));
        final targetDir = Directory(path.join(targetDirectory.path, 'instances', id));

        if (await sourceDir.exists()) {
          await _copyDirectory(sourceDir, targetDir, options: options);
          _logger.info('Copied instance files to new directory: ${instance.id} -> $id');
        }

        // 如果指定，复制版本目录
        if (options?.copyVersionDir ?? false) {
          final sourceVersionDir = Directory(path.join(
            _directories.firstWhere((d) => d.id == instance.directoryId).path,
            'versions',
            instance.version,
          ));
          final targetVersionDir = Directory(path.join(targetDirectory.path, 'versions', instance.version));

          if (await sourceVersionDir.exists()) {
            await _copyDirectory(sourceVersionDir, targetVersionDir, options: options);
          }
        }
      } catch (e, stackTrace) {
        _logger.error('Failed to copy instance files', e, stackTrace);
      }
    }

    await save();
    _logger.info('Duplicated instance: $newName to directory: ${targetDirectory.name}');

    return duplicated;
  }

  /// 计算实例的磁盘占用大小
  /// 
  /// 参数：
  /// - [instanceId]：实例ID
  /// 
  /// 返回值：
  /// - 返回实例目录的总大小（字节）
  /// - 如果实例目录不存在，返回 0
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  /// 
  /// 使用示例：
  /// ```dart
  /// final size = await manager.getInstanceSize(instanceId);
  /// print('实例大小: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  /// ```
  Future<int> getInstanceSize(String instanceId) async {
    // 获取实例和目录
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final directory = _directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );

    // 检查实例目录是否存在
    final instanceDir = Directory(path.join(directory.path, 'instances', instance.id));
    if (!await instanceDir.exists()) {
      return 0;
    }

    // 计算总大小
    int totalSize = 0;
    await for (final entity in instanceDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// 复制目录
  /// 
  /// 递归复制源目录到目标目录，支持排除特定的目录和文件。
  /// 
  /// 参数：
  /// - [source]：源目录
  /// - [target]：目标目录
  /// - [options]：复制选项（可选）
  /// 
  /// 注意：
  /// - 该方法是私有方法，用于实例复制功能
  /// - 如果目标目录不存在，会自动创建
  Future<void> _copyDirectory(
    Directory source,
    Directory target, {
    CopyOptions? options,
  }) async {
    // 创建目标目录（如果不存在）
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    // 遍历源目录
    await for (final entity in source.list()) {
      final targetPath = path.join(target.path, path.basename(entity.path));

      // 处理目录
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        // 检查是否应该排除该目录
        if (options != null && options.excludeDirs.contains(dirName)) {
          continue;
        }
        await _copyDirectory(entity, Directory(targetPath), options: options);
      } 
      // 处理文件
      else if (entity is File) {
        final fileName = path.basename(entity.path);
        // 检查是否应该排除该文件
        if (options != null && options.excludeFiles.contains(fileName)) {
          continue;
        }
        await entity.copy(targetPath);
      }
    }
  }

  /// 生成唯一ID
  /// 
  /// 生成一个32字符的十六进制字符串作为唯一标识符。
  /// 使用加密安全的随机数生成器确保ID的唯一性。
  /// 
  /// 返回值：
  /// - 返回32字符的十六进制字符串（如：'a1b2c3d4e5f6...''）
  /// 
  /// 使用示例：
  /// ```dart
  /// final id = manager.generateId();
  /// print('生成的ID: $id');
  /// ```
  String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 添加实例（用于导入）
  /// 
  /// 直接将一个已构建好的实例对象添加到管理器中。
  /// 通常用于从外部导入实例数据。
  /// 
  /// 参数：
  /// - [instance]：要添加的实例对象
  /// 
  /// 返回值：
  /// - 返回添加的实例对象
  /// 
  /// 注意：
  /// - 该方法会自动创建实例所需的目录
  /// - 实例ID应该已经设置好，不会重新生成
  /// 
  /// 使用示例：
  /// ```dart
  /// final instance = GameInstance(
  ///   id: 'custom-id',
  ///   name: '导入的实例',
  ///   directoryId: directoryId,
  ///   version: '1.20.1',
  ///   // ... 其他属性
  /// );
  /// await manager.addInstance(instance);
  /// ```
  Future<GameInstance> addInstance(GameInstance instance) async {
    _instances.add(instance);
    await ensureInstanceDirectories(instance.id);
    await save();
    _logger.info('Added instance: ${instance.name}');
    return instance;
  }

  /// 导出实例为ZIP文件
  /// 
  /// 将实例及其配置打包成ZIP文件，便于分享或备份。
  /// 
  /// 参数：
  /// - [instanceId]：要导出的实例ID
  /// - [exportPath]：导出文件的路径（ZIP文件路径）
  /// 
  /// 返回值：
  /// - 返回创建的ZIP文件对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果实例ID或所属目录ID不存在
  /// 
  /// 导出内容包括：
  /// - 实例目录下的所有文件（存储在 'instances/' 路径下）
  /// - 实例配置JSON文件（'instance.json'）
  /// 
  /// 使用示例：
  /// ```dart
  /// final zipFile = await manager.exportInstance(
  ///   instanceId,
  ///   'C:\\Exports\\my-instance.zip',
  /// );
  /// print('导出成功: ${zipFile.path}');
  /// ```
  Future<File> exportInstance(String instanceId, String exportPath) async {
    // 获取实例和目录
    final instance = _instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final directory = _directories.firstWhere(
      (d) => d.id == instance.directoryId,
      orElse: () => throw ArgumentError('Directory not found: ${instance.directoryId}'),
    );

    // 创建ZIP文件
    final zipFile = File(exportPath);
    final zipArchive = archive.Archive();
    final encoder = archive.ZipEncoder();

    // 压缩实例文件
    final instanceDir = Directory(path.join(directory.path, 'instances', instanceId));
    if (await instanceDir.exists()) {
      await for (final entity in instanceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: instanceDir.path);
          final bytes = await entity.readAsBytes();
          zipArchive.addFile(archive.ArchiveFile('instances/$relativePath', bytes.length, bytes));
        }
      }
    }

    // 添加实例配置到ZIP
    final configJson = jsonEncode(instance.toJson());
    zipArchive.addFile(archive.ArchiveFile('instance.json', configJson.length, utf8.encode(configJson)));

    // 写入ZIP文件
    final zipBytes = encoder.encode(zipArchive);
    if (zipBytes != null) {
      await zipFile.writeAsBytes(zipBytes);
    }

    _logger.info('Exported instance: $instanceId -> $exportPath');
    return zipFile;
  }

  /// 从ZIP文件导入实例
  /// 
  /// 从ZIP文件中导入实例，该ZIP文件应该是由 [exportInstance] 方法创建的。
  /// 
  /// 参数：
  /// - [zipPath]：ZIP文件的路径
  /// - [directoryId]：目标目录ID
  /// 
  /// 返回值：
  /// - 返回导入的实例对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果目标目录ID不存在，或ZIP文件格式无效
  /// 
  /// ZIP文件要求：
  /// - 必须包含 'instance.json' 文件
  /// - 实例文件应存储在 'instances/' 路径下
  /// 
  /// 使用示例：
  /// ```dart
  /// final instance = await manager.importInstance(
  ///   'C:\\Exports\\my-instance.zip',
  ///   directoryId,
  /// );
  /// print('导入成功: ${instance.name}');
  /// ```
  Future<GameInstance> importInstance(String zipPath, String directoryId) async {
    // 验证目录存在
    if (!_directories.any((d) => d.id == directoryId)) {
      throw ArgumentError('Directory not found: $directoryId');
    }

    final directory = _directories.firstWhere((d) => d.id == directoryId);

    // 读取ZIP文件
    final bytes = await File(zipPath).readAsBytes();
    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    // 查找并解析实例配置
    archive.ArchiveFile? configFile;
    for (final file in zipArchive.files) {
      if (file.name == 'instance.json' && file.isFile) {
        configFile = file;
        break;
      }
    }

    if (configFile == null) {
      throw ArgumentError('Invalid instance package: missing instance.json');
    }

    // 解析配置
    final configJson = utf8.decode(configFile.content as List<int>);
    final config = jsonDecode(configJson) as Map<String, dynamic>;

    // 生成新ID并创建实例
    final id = generateId();
    final now = DateTime.now();

    final instance = GameInstance.fromJson(config).copyWith(
      id: id,
      directoryId: directoryId,
      createdAt: now,
      updatedAt: now,
      lastPlayed: null,
      playTimeSeconds: 0,
    );

    _instances.add(instance);

    // 提取实例文件
    final targetDir = Directory('${directory.path}\\instances\\$id');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 解压文件
    for (final file in zipArchive.files) {
      if (file.name.startsWith('instances/') && file.isFile) {
        final subPath = file.name.substring('instances/'.length);
        final destPath = path.join(targetDir.path, subPath.replaceAll('/', path.separator));

        // 创建目录
        final destDir = Directory(path.dirname(destPath));
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        // 写入文件
        await File(destPath).writeAsBytes(file.content as List<int>);
      }
    }

    await save();
    _logger.info('Imported instance: $id');

    return instance;
  }

  /// 从Mrpack文件导入实例
  /// 
  /// Mrpack 是 Modrinth 平台使用的模组包格式。
  /// 该方法会解析 mrpack 文件并创建对应的实例。
  /// 
  /// 参数：
  /// - [mrpackPath]：mrpack 文件的路径
  /// - [directoryId]：目标目录ID
  /// - [customName]：自定义实例名称（可选，默认使用模组包名称）
  /// 
  /// 返回值：
  /// - 返回导入的实例对象
  /// 
  /// 异常：
  /// - [ArgumentError]：如果目标目录ID不存在，或mrpack文件格式无效
  /// 
  /// Mrpack文件要求：
  /// - 必须包含 'modrinth.index.json' 文件
  /// - 可选的 'overrides/' 目录包含覆盖文件
  /// 
  /// 使用示例：
  /// ```dart
  /// final instance = await manager.importFromMrpack(
  ///   'C:\\Downloads\\modpack.mrpack',
  ///   directoryId,
  ///   customName: '我的模组包',
  /// );
  /// ```
  Future<GameInstance> importFromMrpack(String mrpackPath, String directoryId, {
    String? customName,
  }) async {
    // 验证目录存在
    if (!_directories.any((d) => d.id == directoryId)) {
      throw ArgumentError('Directory not found: $directoryId');
    }

    final directory = _directories.firstWhere((d) => d.id == directoryId);

    // 读取mrpack文件
    final bytes = await File(mrpackPath).readAsBytes();
    final zipArchive = archive.ZipDecoder().decodeBytes(bytes);

    // 查找modrinth.index.json
    archive.ArchiveFile? indexFile;
    for (final file in zipArchive.files) {
      if (file.name == 'modrinth.index.json' && file.isFile) {
        indexFile = file;
        break;
      }
    }

    if (indexFile == null) {
      throw ArgumentError('Invalid mrpack file: missing modrinth.index.json');
    }

    // 解析索引文件
    final indexJson = utf8.decode(indexFile.content as List<int>);
    final indexData = jsonDecode(indexJson) as Map<String, dynamic>;

    // 生成新ID
    final id = generateId();
    final now = DateTime.now();
    final name = customName ?? indexData['name'] as String? ?? 'Modrinth Modpack';

    // 解析依赖获取Minecraft版本
    final dependencies = indexData['dependencies'] as Map<String, dynamic>?;
    final minecraftVersion = dependencies?['minecraft'] as String? ?? '1.20.1';

    // 创建实例
    final instance = GameInstance(
      id: id,
      name: name,
      directoryId: directoryId,
      version: minecraftVersion,
      description: indexData['summary'] as String?,
      config: InstanceConfig(),
      resources: InstanceResources(
        mods: [],
        resourcePacks: [],
        shaderPacks: [],
        worlds: [],
        screenshots: [],
      ),
      createdAt: now,
      updatedAt: now,
    );

    _instances.add(instance);

    // 创建实例目录
    final targetDir = Directory('${directory.path}\\instances\\$id');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 创建overrides目录并提取文件
    final overridesDir = Directory(path.join(targetDir.path, 'overrides'));
    if (!await overridesDir.exists()) {
      await overridesDir.create(recursive: true);
    }

    // 解压overrides目录下的文件
    for (final file in zipArchive.files) {
      if (file.name.startsWith('overrides/') && file.isFile) {
        final subPath = file.name.substring('overrides/'.length);
        final destPath = path.join(targetDir.path, subPath.replaceAll('/', path.separator));

        final destDir = Directory(path.dirname(destPath));
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        await File(destPath).writeAsBytes(file.content as List<int>);
      }
    }

    await save();
    _logger.info('Imported mrpack instance: $id');

    return instance;
  }

  /// 从实例数据创建实例（用于导入后重建实例）
  /// 
  /// 该方法是 [createInstance] 的包装方法，提供更明确的语义。
  /// 主要用于从外部数据源导入实例时重建实例对象。
  /// 
  /// 参数：
  /// - [name]：实例名称
  /// - [directoryId]：所属目录ID
  /// - [version]：Minecraft 版本
  /// - [loader]：模组加载器类型（可选）
  /// - [loaderVersion]：模组加载器版本（可选）
  /// - [icon]：实例图标路径（可选）
  /// - [description]：实例描述（可选）
  /// - [config]：实例配置（可选）
  /// - [resources]：实例资源（可选）
  /// 
  /// 返回值：
  /// - 返回新创建的 [GameInstance] 对象
  /// 
  /// 使用示例：
  /// ```dart
  /// final instance = await manager.createInstanceFromData(
  ///   name: '重建的实例',
  ///   directoryId: directoryId,
  ///   version: '1.20.1',
  ///   loader: 'fabric',
  /// );
  /// ```
  Future<GameInstance> createInstanceFromData({
    required String name,
    required String directoryId,
    required String version,
    String? loader,
    String? loaderVersion,
    String? icon,
    String? description,
    InstanceConfig? config,
    InstanceResources? resources,
  }) async {
    return createInstance(
      name: name,
      directoryId: directoryId,
      version: version,
      loader: loader,
      loaderVersion: loaderVersion,
      icon: icon,
      description: description,
      config: config,
      resources: resources,
    );
  }
}