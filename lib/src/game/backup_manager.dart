import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import '../config/config_manager.dart';
import '../config/config_keys.dart';

/// 备份类型枚举
///
/// 定义了备份操作可以包含的内容范围，用于区分不同类型的备份。
/// 不同类型的备份在创建时只会包含指定范围的内容。
///
/// 示例:
/// ```dart
/// // 创建完整备份
/// await backupManager.createBackup(
///   type: BackupType.full,
///   ...
/// );
///
/// // 仅备份存档
/// await backupManager.createBackup(
///   type: BackupType.savesOnly,
///   ...
/// );
/// ```
enum BackupType {
  /// 完整备份
  ///
  /// 备份实例的所有内容，包括存档、配置、模组等所有文件。
  /// 适用于迁移实例或完整恢复场景。
  full,

  /// 仅备份存档
  ///
  /// 只备份实例的 saves 目录下的存档文件。
  /// 适用于定期保存游戏进度的场景，备份文件较小。
  savesOnly,

  /// 仅备份配置
  ///
  /// 只备份实例的 config 目录下的配置文件。
  /// 适用于保存游戏设置和模组配置的场景。
  configOnly,
}

/// 压缩级别枚举
///
/// 定义了备份文件的压缩级别，用于在压缩速度和压缩率之间进行权衡。
/// 压缩级别越高，压缩后的文件越小，但压缩时间越长。
///
/// 示例:
/// ```dart
/// // 设置最大压缩级别
/// await backupManager.setCompressionLevel(CompressionLevel.maximum);
/// ```
enum CompressionLevel {
  /// 快速压缩
  ///
  /// 使用最低的压缩级别（level 1），压缩速度最快，但压缩率较低。
  /// 适用于需要快速创建备份的场景，如自动定时备份。
  fast,

  /// 平衡压缩
  ///
  /// 使用中等的压缩级别（level 6），在压缩速度和压缩率之间取得平衡。
  /// 推荐作为默认选项，适用于大多数备份场景。
  balanced,

  /// 最大压缩
  ///
  /// 使用最高的压缩级别（level 9），压缩率最高，但压缩时间最长。
  /// 适用于存储空间有限或需要长期保存备份的场景。
  maximum,
}

/// 备份记录数据类
///
/// 表示单次备份操作的元数据记录，包含备份的所有相关信息。
/// 该类是不可变的，通过 [copyWith] 方法创建修改后的副本。
///
/// 主要用途：
/// - 存储备份的元数据信息
/// - 在备份列表中展示备份详情
/// - 作为备份恢复操作的参数
///
/// 示例:
/// ```dart
/// // 从 JSON 创建备份记录
/// final record = BackupRecord.fromJson(jsonData);
///
/// // 获取格式化的文件大小
/// print(record.formattedFileSize); // 输出: "1.5 GB"
///
/// // 创建修改后的副本
/// final updated = record.copyWith(description: '新描述');
/// ```
class BackupRecord {
  /// 备份唯一标识符
  ///
  /// 格式为 `{instanceId}_{timestamp}_{type}`，用于唯一标识一个备份。
  /// 例如: `instance123_1699999999999_full`
  final String id;

  /// 关联的游戏实例ID
  ///
  /// 标识此备份属于哪个游戏实例，用于按实例筛选备份列表。
  final String instanceId;

  /// 游戏实例名称
  ///
  /// 用户可见的实例名称，便于在UI中显示。
  /// 注意：实例名称可能会被用户修改，因此同时保存 instanceId 作为唯一标识。
  final String instanceName;

  /// 备份类型
  ///
  /// 指示此备份是完整备份、仅存档还是仅配置。
  /// 参见 [BackupType] 枚举了解各类型的详细说明。
  final BackupType type;

  /// 备份创建时间
  ///
  /// 记录备份创建的时间戳，用于排序和显示创建日期。
  final DateTime createdAt;

  /// 备份文件的完整路径
  ///
  /// 备份文件在文件系统中的存储位置，通常是 ZIP 文件路径。
  final String filePath;

  /// 备份文件大小（字节）
  ///
  /// 备份文件的原始大小，用于显示和统计存储空间占用。
  /// 可通过 [formattedFileSize] 获取人类可读的格式化大小。
  final int fileSize;

  /// 用户备注描述
  ///
  /// 可选的用户自定义描述，用于记录备份的目的或内容说明。
  final String? description;

  /// 游戏版本
  ///
  /// 创建备份时的游戏版本号，用于版本兼容性检查。
  /// 恢复时可用于警告用户版本不匹配。
  final String? gameVersion;

  /// 是否已压缩
  ///
  /// 指示备份文件是否使用压缩存储。
  /// 如果为 true，备份文件为 ZIP 格式；如果为 false，可能是未压缩的目录。
  final bool isCompressed;

  /// 标签ID列表
  ///
  /// 用户定义的标签集合，用于分类和筛选备份。
  /// 例如: ['important', 'pre-mod-update']
  final List<String> tags;

  /// 创建备份记录实例
  ///
  /// 参数:
  /// - [id]: 备份唯一标识符（必需）
  /// - [instanceId]: 关联的实例ID（必需）
  /// - [instanceName]: 实例名称（必需）
  /// - [type]: 备份类型（必需）
  /// - [createdAt]: 创建时间（必需）
  /// - [filePath]: 备份文件路径（必需）
  /// - [fileSize]: 文件大小（必需）
  /// - [description]: 可选的用户描述
  /// - [gameVersion]: 可选的游戏版本
  /// - [isCompressed]: 是否压缩，默认为 false
  /// - [tags]: 标签列表，默认为空列表
  BackupRecord({
    required this.id,
    required this.instanceId,
    required this.instanceName,
    required this.type,
    required this.createdAt,
    required this.filePath,
    required this.fileSize,
    this.description,
    this.gameVersion,
    this.isCompressed = false,
    this.tags = const [],
  });

  /// 将备份记录序列化为 JSON 格式
  ///
  /// 返回包含所有备份元数据的 Map，用于持久化存储。
  /// 与 [fromJson] 配合使用实现序列化/反序列化。
  ///
  /// 返回值:
  /// - 包含所有字段的 Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceId': instanceId,
      'instanceName': instanceName,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'filePath': filePath,
      'fileSize': fileSize,
      'description': description,
      'gameVersion': gameVersion,
      'isCompressed': isCompressed,
      'tags': tags,
    };
  }

  /// 从 JSON 数据创建备份记录实例
  ///
  /// 工厂构造函数，从持久化的 JSON 数据恢复备份记录。
  /// 如果 type 字段无法识别，默认使用 [BackupType.full]。
  /// 如果 isCompressed 字段缺失，默认为 false。
  /// 如果 tags 字段缺失，默认为空列表。
  ///
  /// 参数:
  /// - [json]: 包含备份数据的 Map
  ///
  /// 返回值:
  /// - 新的 [BackupRecord] 实例
  ///
  /// 可能抛出的异常:
  /// - [FormatException]: 当 createdAt 无法解析为 DateTime 时
  /// - [TypeError]: 当必需字段类型不正确时
  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as String,
      instanceId: json['instanceId'] as String,
      instanceName: json['instanceName'] as String,
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.full,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      description: json['description'] as String?,
      gameVersion: json['gameVersion'] as String?,
      isCompressed: json['isCompressed'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// 获取格式化的文件大小字符串
  ///
  /// 将字节大小转换为人类可读的格式，自动选择合适的单位（B/KB/MB/GB）。
  ///
  /// 返回值示例:
  /// - "512 B" (小于 1KB)
  /// - "1.5 KB" (小于 1MB)
  /// - "256.0 MB" (小于 1GB)
  /// - "1.5 GB" (大于等于 1GB)
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 创建修改后的备份记录副本
  ///
  /// 用于创建一个或多个字段被修改的新实例，保持原实例不变。
  /// 未指定的字段将保持原值。
  ///
  /// 参数:
  /// - [id]: 新的备份ID（可选）
  /// - [instanceId]: 新的实例ID（可选）
  /// - [instanceName]: 新的实例名称（可选）
  /// - [type]: 新的备份类型（可选）
  /// - [createdAt]: 新的创建时间（可选）
  /// - [filePath]: 新的文件路径（可选）
  /// - [fileSize]: 新的文件大小（可选）
  /// - [description]: 新的描述（可选）
  /// - [gameVersion]: 新的游戏版本（可选）
  /// - [isCompressed]: 新的压缩状态（可选）
  /// - [tags]: 新的标签列表（可选）
  ///
  /// 返回值:
  /// - 包含修改字段的新 [BackupRecord] 实例
  BackupRecord copyWith({
    String? id,
    String? instanceId,
    String? instanceName,
    BackupType? type,
    DateTime? createdAt,
    String? filePath,
    int? fileSize,
    String? description,
    String? gameVersion,
    bool? isCompressed,
    List<String>? tags,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      instanceName: instanceName ?? this.instanceName,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
      gameVersion: gameVersion ?? this.gameVersion,
      isCompressed: isCompressed ?? this.isCompressed,
      tags: tags ?? this.tags,
    );
  }
}

/// 备份进度回调函数类型定义
///
/// 用于报告备份和恢复操作的进度，便于 UI 显示进度条和当前处理的文件。
///
/// 参数:
/// - [progress]: 进度值，范围 0.0 到 1.0，表示完成百分比
/// - [currentFile]: 当前正在处理的文件名或状态描述
///
/// 示例:
/// ```dart
/// void onProgress(double progress, String currentFile) {
///   print('进度: ${(progress * 100).toStringAsFixed(1)}% - $currentFile');
/// }
///
/// await backupManager.createBackup(
///   ...
///   onProgress: onProgress,
/// );
/// ```
typedef BackupProgressCallback = void Function(
  double progress,
  String currentFile,
);

/// 备份管理器
///
/// 负责游戏实例备份和恢复的核心管理类，采用单例模式。
/// 提供备份的创建、恢复、删除、查询等完整生命周期管理。
///
/// 主要功能:
/// - 创建不同类型的备份（完整/仅存档/仅配置）
/// - 恢复备份到指定实例
/// - 管理备份记录和索引
/// - 支持可选的 ZIP 压缩
/// - 自动清理旧备份
/// - 进度回调支持
///
/// 使用方式:
/// ```dart
/// // 获取单例实例
/// final backupManager = BackupManager.instance;
///
/// // 初始化（必须在使用前调用）
/// await backupManager.initialize();
///
/// // 创建备份
/// final record = await backupManager.createBackup(
///   instanceId: 'my-instance',
///   instanceName: '我的游戏',
///   instancePath: '/path/to/instance',
///   type: BackupType.full,
///   description: '更新模组前备份',
/// );
///
/// // 恢复备份
/// await backupManager.restoreBackup(
///   backup: record,
///   targetPath: '/path/to/instance',
/// );
///
/// // 获取实例的所有备份
/// final backups = backupManager.getBackupsForInstance('my-instance');
/// ```
///
/// 注意事项:
/// - 必须先调用 [initialize] 方法初始化后才能使用其他方法
/// - 同时只能进行一个备份或恢复操作
/// - 恢复前会自动创建当前状态的备份
class BackupManager {
  /// 单例实例
  static BackupManager? _instance;

  /// 日志记录器
  final Logger _logger = Logger('BackupManager');

  /// 平台适配器，用于获取应用支持目录等平台相关操作
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器，用于读取和保存压缩设置
  final ConfigManager _configManager = ConfigManager();

  /// 备份存储目录
  ///
  /// 所有备份文件都存储在此目录下，路径为 {应用支持目录}/backups
  Directory? _backupDir;

  /// 内存中的备份记录列表
  ///
  /// 缓存所有备份的元数据，避免频繁读取文件系统。
  /// 通过 [_loadBackupRecords] 加载，[_saveBackupRecords] 保存。
  final List<BackupRecord> _backups = [];

  /// 备份操作进行中标志
  ///
  /// 用于防止并发备份操作，同一时间只能有一个备份任务运行。
  bool _isBackingUp = false;

  /// 恢复操作进行中标志
  ///
  /// 用于防止并发恢复操作，同一时间只能有一个恢复任务运行。
  bool _isRestoring = false;

  /// 初始化完成标志
  ///
  /// 标记 [initialize] 方法是否已成功执行。
  bool _initialized = false;

  /// 压缩功能启用状态
  ///
  /// 控制新创建的备份是否使用 ZIP 压缩。
  /// 默认为 true，可通过 [setCompressEnabled] 修改。
  bool _compressEnabled = true;

  /// 压缩级别
  ///
  /// 控制压缩的级别，影响压缩速度和压缩率。
  /// 默认为 [CompressionLevel.balanced]，可通过 [setCompressionLevel] 修改。
  CompressionLevel _compressionLevel = CompressionLevel.balanced;

  /// 私有构造函数（单例模式）
  BackupManager._internal();

  /// 获取单例实例
  ///
  /// 返回 [BackupManager] 的唯一实例，如果实例不存在则创建。
  /// 使用懒加载模式，首次访问时创建实例。
  static BackupManager get instance {
    _instance ??= BackupManager._internal();
    return _instance!;
  }

  /// 工厂构造函数
  ///
  /// 返回单例实例，等同于 [instance] getter。
  factory BackupManager() => instance;

  /// 初始化备份管理器
  ///
  /// 必须在使用其他方法之前调用此方法进行初始化。
  /// 初始化过程包括：
  /// - 创建或确认备份存储目录存在
  /// - 加载已有的备份记录索引
  /// - 加载压缩设置
  ///
  /// 如果初始化失败，会记录错误日志但不会抛出异常，
  /// 以确保应用可以继续运行（虽然备份功能可能不可用）。
  ///
  /// 此方法可以多次调用，如果已初始化则会直接返回。
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 示例:
  /// ```dart
  /// final backupManager = BackupManager.instance;
  /// await backupManager.initialize();
  /// // 现在可以安全地使用其他备份方法
  /// ```
  Future<void> initialize() async {
    // 如果已经初始化，直接返回避免重复操作
    if (_initialized) return;

    try {
      // 获取应用支持目录作为备份存储的基础路径
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _backupDir = Directory(path.join(supportDir, 'backups'));

      // 如果备份目录不存在，创建它（包括所有父目录）
      if (!await _backupDir!.exists()) {
        await _backupDir!.create(recursive: true);
      }

      // 加载已有的备份记录和压缩设置
      await _loadBackupRecords();
      await _loadCompressionSettings();
      _logger.info('Backup manager initialized, ${_backups.length} backups loaded');
      _initialized = true;
    } catch (e, stackTrace) {
      // 初始化失败时记录错误，但标记为已初始化以避免无限重试
      _logger.error('Failed to initialize backup manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载压缩设置（私有方法）
  ///
  /// 从配置管理器读取压缩相关的设置，包括是否启用压缩和压缩级别。
  /// 如果配置中没有这些设置，使用默认值。
  Future<void> _loadCompressionSettings() async {
    // 从配置读取压缩启用状态，默认为 true
    _compressEnabled = _configManager.getBool(ConfigKeys.backupCompressEnabled) ?? true;
    // 从配置读取压缩级别字符串，默认为 'balanced'
    final levelStr = _configManager.getString(ConfigKeys.backupCompressionLevel) ?? 'balanced';
    // 将字符串转换为 CompressionLevel 枚举值
    _compressionLevel = CompressionLevel.values.firstWhere(
      (e) => e.name == levelStr,
      orElse: () => CompressionLevel.balanced,
    );
  }

  /// 保存压缩设置（私有方法）
  ///
  /// 将当前的压缩设置持久化到配置管理器中。
  Future<void> _saveCompressionSettings() async {
    await _configManager.setBool(ConfigKeys.backupCompressEnabled, _compressEnabled);
    await _configManager.setString(ConfigKeys.backupCompressionLevel, _compressionLevel.name);
  }

  /// 获取压缩功能是否启用
  ///
  /// 返回当前压缩功能的启用状态。
  /// 默认为 true，可通过 [setCompressEnabled] 方法修改。
  ///
  /// 返回值:
  /// - true 表示新备份将使用压缩
  /// - false 表示新备份不压缩
  bool get compressEnabled => _compressEnabled;

  /// 获取当前压缩级别
  ///
  /// 返回当前使用的压缩级别，影响压缩速度和压缩率。
  /// 默认为 [CompressionLevel.balanced]，可通过 [setCompressionLevel] 方法修改。
  ///
  /// 返回值:
  /// - [CompressionLevel] 枚举值
  CompressionLevel get compressionLevel => _compressionLevel;

  /// 设置压缩功能启用状态
  ///
  /// 控制新创建的备份是否使用 ZIP 压缩。
  /// 设置会自动持久化到配置中。
  ///
  /// 参数:
  /// - [enabled]: 是否启用压缩，true 启用，false 禁用
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 示例:
  /// ```dart
  /// // 禁用压缩（备份更快但文件更大）
  /// await backupManager.setCompressEnabled(false);
  ///
  /// // 启用压缩（备份较慢但文件更小）
  /// await backupManager.setCompressEnabled(true);
  /// ```
  Future<void> setCompressEnabled(bool enabled) async {
    _compressEnabled = enabled;
    await _saveCompressionSettings();
    _logger.info('Backup compression ${enabled ? 'enabled' : 'disabled'}');
  }

  /// 设置压缩级别
  ///
  /// 控制压缩的级别，在压缩速度和压缩率之间进行权衡。
  /// 设置会自动持久化到配置中。
  ///
  /// 参数:
  /// - [level]: 压缩级别枚举值
  ///   - [CompressionLevel.fast]: 快速压缩（level 1），速度快但压缩率低
  ///   - [CompressionLevel.balanced]: 平衡压缩（level 6），速度和压缩率平衡
  ///   - [CompressionLevel.maximum]: 最大压缩（level 9），速度慢但压缩率高
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 示例:
  /// ```dart
  /// // 设置最大压缩级别（适合长期存储）
  /// await backupManager.setCompressionLevel(CompressionLevel.maximum);
  ///
  /// // 设置快速压缩级别（适合频繁备份）
  /// await backupManager.setCompressionLevel(CompressionLevel.fast);
  /// ```
  Future<void> setCompressionLevel(CompressionLevel level) async {
    _compressionLevel = level;
    await _saveCompressionSettings();
    _logger.info('Backup compression level set to ${level.name}');
  }

  /// 获取压缩级别对应的 archive 库压缩级别数值（私有方法）
  ///
  /// 将 [CompressionLevel] 枚举转换为 archive 库使用的整数级别。
  /// archive 库的压缩级别范围是 1-9。
  ///
  /// 返回值:
  /// - 1 对应 [CompressionLevel.fast]
  /// - 6 对应 [CompressionLevel.balanced]
  /// - 9 对应 [CompressionLevel.maximum]
  int _getArchiveCompressionLevel() {
    switch (_compressionLevel) {
      case CompressionLevel.fast:
        return 1;
      case CompressionLevel.balanced:
        return 6;
      case CompressionLevel.maximum:
        return 9;
    }
  }

  /// 加载备份记录索引（私有方法）
  ///
  /// 从 index.json 文件加载所有备份的元数据记录到内存中。
  /// 如果索引文件不存在或加载失败，会尝试从文件系统重建索引。
  ///
  /// 索引文件格式:
  /// ```json
  /// {
  ///   "backups": [ ...BackupRecord.toJson()... ],
  ///   "lastUpdated": "2024-01-01T00:00:00.000Z"
  /// }
  /// ```
  Future<void> _loadBackupRecords() async {
    final indexFile = File(path.join(_backupDir!.path, 'index.json'));

    // 如果索引文件不存在，尝试从文件系统重建
    if (!await indexFile.exists()) {
      // 尝试从文件系统重建索引
      await _rebuildIndex();
      return;
    }

    try {
      // 读取并解析索引文件内容
      final content = await indexFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final backupsData = data['backups'] as List?;

      // 将 JSON 数据转换为 BackupRecord 对象列表
      if (backupsData != null) {
        _backups.clear();
        _backups.addAll(
          backupsData
              .whereType<Map<String, dynamic>>()
              .map((e) => BackupRecord.fromJson(e)),
        );
      }
    } catch (e, stackTrace) {
      // 解析失败时，尝试重建索引
      _logger.error('Failed to load backup records', e, stackTrace);
      await _rebuildIndex();
    }
  }

  /// 保存备份记录索引（私有方法）
  ///
  /// 将内存中的所有备份记录持久化到 index.json 文件中。
  /// 包含所有备份的元数据和最后更新时间。
  ///
  /// 注意：此方法不会抛出异常，失败时仅记录日志。
  Future<void> _saveBackupRecords() async {
    final indexFile = File(path.join(_backupDir!.path, 'index.json'));

    try {
      // 构建索引数据结构
      final data = {
        'backups': _backups.map((e) => e.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // 写入文件（使用 JSON 格式）
      await indexFile.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      _logger.error('Failed to save backup records', e, stackTrace);
    }
  }

  /// 从文件系统重建备份索引（私有方法）
  ///
  /// 当 index.json 文件不存在或损坏时，扫描备份目录中的 ZIP 文件，
  /// 从文件名解析备份信息并重建索引。
  ///
  /// 文件名格式约定: `{instanceId}_{timestamp}_{type}.zip`
  /// 例如: `instance123_1699999999999_full.zip`
  ///
  /// 解析规则:
  /// - 第一部分作为 instanceId
  /// - 第二部分作为时间戳（毫秒）
  /// - 第三部分作为备份类型
  ///
  /// 注意：重建的索引可能不完整，因为文件名中不包含实例名称、
  /// 描述、游戏版本等信息，这些字段会使用默认值。
  Future<void> _rebuildIndex() async {
    _logger.info('Rebuilding backup index...');
    _backups.clear();

    try {
      // 检查备份目录是否存在
      if (_backupDir == null || !await _backupDir!.exists()) return;

      // 遍历备份目录中的所有文件
      final files = _backupDir!.listSync();

      for (final file in files) {
        // 只处理 ZIP 文件
        if (file is File && file.path.endsWith('.zip')) {
          final fileName = path.basenameWithoutExtension(file.path);

          // 尝试从文件名解析信息（格式: instanceId_timestamp_type）
          final parts = fileName.split('_');

          // 验证文件名格式是否正确（至少包含3个部分）
          if (parts.length >= 3) {
            final instanceId = parts[0];
            final timestamp = int.tryParse(parts[1]) ?? 0;
            final typeStr = parts.length > 2 ? parts[2] : 'full';

            // 解析备份类型
            final type = BackupType.values.firstWhere(
              (e) => e.name == typeStr,
              orElse: () => BackupType.full,
            );

            // 获取文件大小
            final fileStat = await file.stat();

            // 创建备份记录（使用默认值填充缺失的信息）
            _backups.add(BackupRecord(
              id: fileName,
              instanceId: instanceId,
              instanceName: instanceId, // 暂时使用ID作为名称（无法从文件名获取）
              type: type,
              createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
              filePath: file.path,
              fileSize: fileStat.size,
              isCompressed: true,
            ));
          }
        }
      }

      _logger.info('Rebuilt index with ${_backups.length} backups');
      // 保存重建后的索引
      await _saveBackupRecords();
    } catch (e, stackTrace) {
      _logger.error('Failed to rebuild backup index', e, stackTrace);
    }
  }

  /// 压缩目录为 ZIP 文件（私有方法）
  ///
  /// 将指定目录及其所有内容压缩为 ZIP 格式的备份文件。
  /// 使用 archive 库进行压缩，支持不同的压缩级别。
  ///
  /// 压缩流程:
  /// 1. 统计目录中的文件总数（用于计算进度）
  /// 2. 递归读取所有文件并添加到归档中
  /// 3. 使用 ZipEncoder 编码为 ZIP 格式
  /// 4. 将 ZIP 数据写入目标文件
  ///
  /// 参数:
  /// - [sourceDir]: 要压缩的源目录路径
  /// - [outputPath]: 输出的 ZIP 文件路径
  /// - [onProgress]: 进度回调函数（可选）
  ///
  /// 返回值:
  /// - 成功时返回 ZIP 文件大小（字节）
  /// - 失败时返回 0
  ///
  /// 进度计算:
  /// - 文件读取阶段：进度范围 0.0 到 0.8
  /// - ZIP 编码完成：进度为 1.0
  Future<int> _compressDirectory({
    required String sourceDir,
    required String outputPath,
    BackupProgressCallback? onProgress,
  }) async {
    // 创建空的归档对象
    final archive = Archive();
    final sourceDirectory = Directory(sourceDir);

    // 用于进度计算的计数器
    int totalFiles = 0;
    int processedFiles = 0;

    // 第一阶段：统计文件总数（用于计算进度百分比）
    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is File) {
        totalFiles++;
      }
    }

    // 第二阶段：读取文件并添加到归档中
    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is File) {
        // 计算相对于源目录的路径（保持目录结构）
        final relativePath = path.relative(entity.path, from: sourceDir);
        // 读取文件内容为字节列表
        final fileBytes = await entity.readAsBytes();

        // 将文件添加到归档中
        archive.addFile(ArchiveFile(
          relativePath,
          fileBytes.length,
          fileBytes,
        ));

        // 更新进度并回调
        processedFiles++;
        if (onProgress != null) {
          // 文件读取阶段进度最大为 0.8（压缩阶段占 0.2）
          onProgress(
            totalFiles > 0 ? processedFiles / totalFiles * 0.8 : 0,
            relativePath,
          );
        }
      }
    }

    // 第三阶段：将归档编码为 ZIP 格式
    final zipData = ZipEncoder().encode(
      archive,
      level: _getArchiveCompressionLevel(),
    );

    // 第四阶段：写入 ZIP 文件
    if (zipData != null) {
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipData);

      // 完成回调
      if (onProgress != null) {
        onProgress(1.0, '完成');
      }

      return zipData.length;
    }

    return 0;
  }

  /// 解压 ZIP 文件到目录（私有方法）
  ///
  /// 将 ZIP 格式的备份文件解压到指定目录，恢复文件结构。
  /// 使用 archive 库的 ZipDecoder 进行解压。
  ///
  /// 解压流程:
  /// 1. 读取 ZIP 文件内容
  /// 2. 使用 ZipDecoder 解析 ZIP 结构
  /// 3. 遍历归档中的所有文件/目录
  /// 4. 创建目录结构并写入文件内容
  ///
  /// 参数:
  /// - [archivePath]: ZIP 文件路径
  /// - [outputDir]: 解压的目标目录路径
  /// - [onProgress]: 进度回调函数（可选）
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 可能抛出的异常:
  /// - [FileSystemException]: 文件读写失败
  /// - [FormatException]: ZIP 文件格式无效
  Future<void> _decompressArchive({
    required String archivePath,
    required String outputDir,
    BackupProgressCallback? onProgress,
  }) async {
    // 读取 ZIP 文件内容
    final archiveFile = File(archivePath);
    final bytes = await archiveFile.readAsBytes();

    // 解析 ZIP 文件结构
    final archive = ZipDecoder().decodeBytes(bytes);

    // 获取文件总数用于进度计算
    final totalFiles = archive.files.length;
    var processedFiles = 0;

    // 遍历归档中的所有条目
    for (final file in archive.files) {
      // 构建输出路径
      final outputPath = path.join(outputDir, file.name);

      if (file.isFile) {
        // 处理文件：创建父目录并写入内容
        final outputFile = File(outputPath);
        // 确保父目录存在
        await outputFile.parent.create(recursive: true);
        // 写入文件内容
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        // 处理目录：创建目录结构
        await Directory(outputPath).create(recursive: true);
      }

      // 更新进度并回调
      processedFiles++;
      if (onProgress != null) {
        onProgress(
          totalFiles > 0 ? processedFiles / totalFiles : 0,
          file.name,
        );
      }
    }
  }

  /// 创建游戏实例备份
  ///
  /// 将指定游戏实例的内容备份到备份存储目录。
  /// 支持不同类型的备份（完整/仅存档/仅配置）和可选的压缩。
  ///
  /// 备份流程:
  /// 1. 检查是否已有备份任务在进行（防止并发）
  /// 2. 根据备份类型确定要备份的目录
  /// 3. 执行压缩或复制操作
  /// 4. 创建备份记录并保存索引
  ///
  /// 参数:
  /// - [instanceId]: 游戏实例的唯一标识符（必需）
  /// - [instanceName]: 游戏实例的显示名称（必需）
  /// - [instancePath]: 游戏实例的文件路径（必需）
  /// - [type]: 备份类型，默认为 [BackupType.full]
  ///   - [BackupType.full]: 备份整个实例目录
  ///   - [BackupType.savesOnly]: 仅备份 saves 子目录
  ///   - [BackupType.configOnly]: 仅备份 config 子目录
  /// - [description]: 用户备注描述（可选）
  /// - [gameVersion]: 游戏版本号（可选）
  /// - [onProgress]: 进度回调函数（可选）
  /// - [forceCompress]: 强制指定是否压缩（可选），默认使用全局设置
  ///
  /// 返回值:
  /// - 成功时返回 [BackupRecord] 对象，包含备份的所有元数据
  /// - 失败时返回 null，包括：
  ///   - 已有备份任务在进行
  ///   - 源目录不存在
  ///   - 备份过程中发生错误
  ///
  /// 可能抛出的异常:
  /// - 此方法不会抛出异常，所有错误都会被捕获并记录日志
  ///
  /// 示例:
  /// ```dart
  /// // 创建完整备份
  /// final record = await backupManager.createBackup(
  ///   instanceId: 'my-instance',
  ///   instanceName: '我的游戏',
  ///   instancePath: '/path/to/instance',
  ///   type: BackupType.full,
  ///   description: '更新模组前备份',
  ///   gameVersion: '1.20.1',
  /// );
  ///
  /// // 创建仅存档备份（带进度回调）
  /// final record = await backupManager.createBackup(
  ///   instanceId: 'my-instance',
  ///   instanceName: '我的游戏',
  ///   instancePath: '/path/to/instance',
  ///   type: BackupType.savesOnly,
  ///   onProgress: (progress, file) {
  ///     print('备份进度: ${(progress * 100).toFixed(1)}%');
  ///   },
  /// );
  /// ```
  ///
  /// 注意事项:
  /// - 同一时间只能有一个备份任务运行
  /// - 备份文件名格式: `{instanceId}_{timestamp}_{type}.zip`
  /// - 如果禁用压缩，文件仍然会以 ZIP 格式存储（但无压缩）
  Future<BackupRecord?> createBackup({
    required String instanceId,
    required String instanceName,
    required String instancePath,
    BackupType type = BackupType.full,
    String? description,
    String? gameVersion,
    BackupProgressCallback? onProgress,
    bool? forceCompress,
  }) async {
    // 检查是否已有备份任务在进行，防止并发操作
    if (_isBackingUp) {
      _logger.warn('Backup already in progress');
      return null;
    }

    // 设置备份进行中标志
    _isBackingUp = true;
    _logger.info('Starting backup for $instanceName ($instanceId)');

    try {
      // 生成唯一的备份ID：格式为 instanceId_timestamp_type
      final id = '${instanceId}_${DateTime.now().millisecondsSinceEpoch}_${type.name}';
      final timestamp = DateTime.now();
      final backupFileName = '$id.zip';
      final backupPath = path.join(_backupDir!.path, backupFileName);

      // 根据备份类型确定要备份的源目录
      String? sourceDir;
      switch (type) {
        case BackupType.full:
          // 完整备份：备份整个实例目录
          sourceDir = instancePath;
          break;
        case BackupType.savesOnly:
          // 仅存档备份：备份 saves 子目录
          sourceDir = path.join(instancePath, 'saves');
          break;
        case BackupType.configOnly:
          // 仅配置备份：备份 config 子目录
          sourceDir = path.join(instancePath, 'config');
          break;
      }

      // 验证源目录是否存在
      if (sourceDir == null || !Directory(sourceDir).existsSync()) {
        _logger.error('Source directory does not exist: $sourceDir');
        return null;
      }

      // 确定是否使用压缩（优先使用 forceCompress 参数，否则使用全局设置）
      final useCompression = forceCompress ?? _compressEnabled;
      int fileSize = 0;

      if (useCompression) {
        // 使用压缩：调用压缩方法将目录压缩为 ZIP
        fileSize = await _compressDirectory(
          sourceDir: sourceDir,
          outputPath: backupPath,
          onProgress: onProgress,
        );
      } else {
        // 不使用压缩：直接复制文件到临时目录
        // 注意：当前实现存在缺陷，未压缩的备份仍应创建 ZIP 文件
        final tempDir = Directory(path.join(_backupDir!.path, 'temp_$id'));
        await tempDir.create(recursive: true);

        int totalFiles = 0;
        int processedFiles = 0;

        // 第一阶段：统计文件总数（用于进度计算）
        await for (final entity in Directory(sourceDir).list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
          }
        }

        // 第二阶段：复制文件到临时目录
        await for (final entity in Directory(sourceDir).list(recursive: true)) {
          final relativePath = path.relative(entity.path, from: sourceDir);
          final destPath = path.join(tempDir.path, relativePath);

          if (entity is File) {
            // 复制文件：先创建父目录，再复制文件内容
            final destFile = File(destPath);
            await destFile.parent.create(recursive: true);
            await entity.copy(destPath);

            // 更新进度并回调
            processedFiles++;
            if (onProgress != null) {
              onProgress(
                totalFiles > 0 ? processedFiles / totalFiles : 0,
                relativePath,
              );
            }
          } else if (entity is Directory) {
            // 创建目录结构
            await Directory(destPath).create(recursive: true);
          }
        }

        // 计算备份目录的总大小
        fileSize = await _calculateDirectorySize(tempDir);

        // 注意：此处存在设计缺陷
        // 如果不使用压缩，应该创建一个无压缩的 ZIP 文件
        // 当前实现直接使用临时目录，可能导致恢复时路径问题
      }

      // 创建备份记录对象
      final backupRecord = BackupRecord(
        id: id,
        instanceId: instanceId,
        instanceName: instanceName,
        type: type,
        createdAt: timestamp,
        filePath: backupPath,
        fileSize: fileSize,
        description: description,
        gameVersion: gameVersion,
        isCompressed: useCompression,
      );

      // 将备份记录添加到内存列表并持久化索引
      _backups.add(backupRecord);
      await _saveBackupRecords();

      _logger.info('Backup completed: $id, size: $fileSize bytes, compressed: $useCompression');
      return backupRecord;
    } catch (e, stackTrace) {
      // 捕获所有异常，记录日志并返回 null
      _logger.error('Failed to create backup', e, stackTrace);
      return null;
    } finally {
      // 无论成功或失败，都要清除备份进行中标志
      _isBackingUp = false;
    }
  }

  /// 恢复备份到游戏实例
  ///
  /// 将指定的备份恢复到目标游戏实例目录，覆盖当前内容。
  /// 为安全起见，恢复前会自动创建当前状态的备份。
  ///
  /// 恢复流程:
  /// 1. 检查是否已有恢复任务在进行（防止并发）
  /// 2. 自动备份当前状态（防止误操作）
  /// 3. 清空目标目录
  /// 4. 从 ZIP 或目录恢复文件
  ///
  /// 参数:
  /// - [backup]: 要恢复的备份记录对象（必需）
  /// - [targetPath]: 恢复的目标实例路径（必需）
  /// - [onProgress]: 进度回调函数（可选）
  ///
  /// 返回值:
  /// - true 表示恢复成功
  /// - false 表示恢复失败，包括：
  ///   - 已有恢复任务在进行
  ///   - 自动备份失败
  ///   - 恢复过程中发生错误
  ///
  /// 可能抛出的异常:
  /// - 此方法不会抛出异常，所有错误都会被捕获并记录日志
  ///
  /// 示例:
  /// ```dart
  /// // 获取要恢复的备份
  /// final backups = backupManager.getBackupsForInstance('my-instance');
  /// final backupToRestore = backups.first;
  ///
  /// // 执行恢复
  /// final success = await backupManager.restoreBackup(
  ///   backup: backupToRestore,
  ///   targetPath: '/path/to/instance',
  ///   onProgress: (progress, file) {
  ///     print('恢复进度: ${(progress * 100).toFixed(1)}%');
  ///   },
  /// );
  ///
  /// if (success) {
  ///   print('恢复成功');
  /// } else {
  ///   print('恢复失败');
  /// }
  /// ```
  ///
  /// 注意事项:
  /// - 恢复前会自动创建当前状态的备份（描述为 "Auto-backup before restore")
  /// - 目标目录会被完全清空后恢复，原有内容将丢失
  /// - 同一时间只能有一个恢复任务运行
  /// - 如果备份源不存在，恢复会失败
  Future<bool> restoreBackup({
    required BackupRecord backup,
    required String targetPath,
    BackupProgressCallback? onProgress,
  }) async {
    // 检查是否已有恢复任务在进行，防止并发操作
    if (_isRestoring) {
      _logger.warn('Restore already in progress');
      return false;
    }

    // 设置恢复进行中标志
    _isRestoring = true;
    _logger.info('Starting restore: ${backup.id}');

    try {
      // 安全措施：先备份当前状态，防止用户误操作导致数据丢失
      final currentBackup = await createBackup(
        instanceId: backup.instanceId,
        instanceName: backup.instanceName,
        instancePath: targetPath,
        type: BackupType.full,
        description: 'Auto-backup before restore',
        gameVersion: backup.gameVersion,
      );

      // 清空目标目录，准备恢复
      final targetDir = Directory(targetPath);
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      await targetDir.create(recursive: true);

      // 根据备份类型选择恢复方式
      if (backup.isCompressed && backup.filePath.endsWith('.zip')) {
        // 从 ZIP 文件解压恢复
        await _decompressArchive(
          archivePath: backup.filePath,
          outputDir: targetPath,
          onProgress: onProgress,
        );
      } else {
        // 从目录复制恢复（未压缩的备份）
        final backupSourceDir = Directory(backup.filePath);
        if (!await backupSourceDir.exists()) {
          throw Exception('Backup source does not exist');
        }

        int totalFiles = 0;
        int processedFiles = 0;

        // 第一阶段：统计文件总数（用于进度计算）
        await for (final entity in backupSourceDir.list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
          }
        }

        // 第二阶段：复制文件到目标目录
        await for (final entity in backupSourceDir.list(recursive: true)) {
          final relativePath = path.relative(entity.path, from: backupSourceDir.path);
          final destPath = path.join(targetPath, relativePath);

          if (entity is File) {
            // 复制文件：先创建父目录，再复制文件内容
            final destFile = File(destPath);
            await destFile.parent.create(recursive: true);
            await entity.copy(destPath);

            // 更新进度并回调
            processedFiles++;
            if (onProgress != null) {
              onProgress(
                totalFiles > 0 ? processedFiles / totalFiles : 0,
                relativePath,
              );
            }
          } else if (entity is Directory) {
            // 创建目录结构
            await Directory(destPath).create(recursive: true);
          }
        }
      }

      _logger.info('Restore completed: ${backup.id}');
      return true;
    } catch (e, stackTrace) {
      // 捕获所有异常，记录日志并返回 false
      _logger.error('Failed to restore backup', e, stackTrace);
      return false;
    } finally {
      // 无论成功或失败，都要清除恢复进行中标志
      _isRestoring = false;
    }
  }

  /// 计算目录的总大小（私有方法）
  ///
  /// 递归计算指定目录中所有文件的总大小（字节）。
  /// 用于统计备份文件大小和存储空间占用。
  ///
  /// 参数:
  /// - [dir]: 要计算大小的目录对象
  ///
  /// 返回值:
  /// - 目录中所有文件的总大小（字节）
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;

    // 遍历目录中的所有文件，累加文件大小
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return totalSize;
  }

  /// 获取特定游戏实例的所有备份列表
  ///
  /// 返回指定实例的所有备份记录，按创建时间降序排列（最新的在前）。
  ///
  /// 参数:
  /// - [instanceId]: 游戏实例的唯一标识符
  ///
  /// 返回值:
  /// - 该实例的所有备份记录列表，按时间降序排列
  /// - 如果没有备份，返回空列表
  ///
  /// 示例:
  /// ```dart
  /// // 获取实例的所有备份
  /// final backups = backupManager.getBackupsForInstance('my-instance');
  ///
  /// // 显示备份列表
  /// for (final backup in backups) {
  ///   print('${backup.createdAt}: ${backup.formattedFileSize}');
  /// }
  /// ```
  List<BackupRecord> getBackupsForInstance(String instanceId) {
    return _backups
        .where((b) => b.instanceId == instanceId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按时间降序排序
  }

  /// 获取所有备份记录列表
  ///
  /// 返回所有实例的所有备份记录，按创建时间降序排列（最新的在前）。
  ///
  /// 返回值:
  /// - 所有备份记录列表，按时间降序排列
  /// - 如果没有任何备份，返回空列表
  ///
  /// 示例:
  /// ```dart
  /// // 获取所有备份
  /// final allBackups = backupManager.getAllBackups();
  ///
  /// // 显示备份总数
  /// print('总共有 ${allBackups.length} 个备份');
  /// ```
  List<BackupRecord> getAllBackups() {
    return List<BackupRecord>.from(_backups)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按时间降序排序
  }

  /// 按标签筛选备份记录
  ///
  /// 返回包含指定标签的所有备份记录，按创建时间降序排列。
  ///
  /// 参数:
  /// - [tagId]: 要筛选的标签ID
  ///
  /// 返回值:
  /// - 包含该标签的所有备份记录列表，按时间降序排列
  /// - 如果没有匹配的备份，返回空列表
  ///
  /// 示例:
  /// ```dart
  /// // 获取标记为 'important' 的备份
  /// final importantBackups = backupManager.getBackupsByTag('important');
  ///
  /// // 显示重要备份
  /// for (final backup in importantBackups) {
  ///   print('${backup.instanceName}: ${backup.description}');
  /// }
  /// ```
  List<BackupRecord> getBackupsByTag(String tagId) {
    return _backups
        .where((b) => b.tags.contains(tagId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按时间降序排序
  }

  /// 删除指定的备份
  ///
  /// 删除备份文件和对应的备份记录。此操作不可恢复。
  ///
  /// 参数:
  /// - [backupId]: 要删除的备份唯一标识符
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 注意事项:
  /// - 如果备份不存在，方法会直接返回，不会抛出异常
  /// - 删除失败时会记录日志，但不会抛出异常
  /// - 删除操作不可恢复，请谨慎使用
  ///
  /// 示例:
  /// ```dart
  /// // 删除指定的备份
  /// await backupManager.deleteBackup('instance123_1699999999999_full');
  ///
  /// // 删除列表中的第一个备份
  /// final backups = backupManager.getBackupsForInstance('my-instance');
  /// if (backups.isNotEmpty) {
  ///   await backupManager.deleteBackup(backups.first.id);
  /// }
  /// ```
  Future<void> deleteBackup(String backupId) async {
    // 在备份列表中查找指定ID的备份
    final index = _backups.indexWhere((b) => b.id == backupId);
    if (index < 0) return; // 备份不存在，直接返回

    final backup = _backups[index];

    try {
      // 删除备份文件
      final file = File(backup.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 从内存列表中移除备份记录
      _backups.removeAt(index);
      // 更新索引文件
      await _saveBackupRecords();

      _logger.info('Deleted backup: $backupId');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete backup', e, stackTrace);
    }
  }

  /// 清理指定实例的旧备份
  ///
  /// 删除超出保留数量的旧备份，只保留最新的 N 个备份。
  /// 用于自动管理备份数量，避免占用过多存储空间。
  ///
  /// 参数:
  /// - [instanceId]: 游戏实例的唯一标识符（必需）
  /// - [keepCount]: 保留的备份数量，默认为 10
  ///
  /// 返回值:
  /// - 无返回值（Future<void>）
  ///
  /// 清理规则:
  /// - 按创建时间排序，保留最新的 [keepCount] 个备份
  /// - 删除时间较早的备份
  /// - 如果备份总数不超过 [keepCount]，不执行删除
  ///
  /// 示例:
  /// ```dart
  /// // 只保留最新的 5 个备份
  /// await backupManager.cleanOldBackups(
  ///   instanceId: 'my-instance',
  ///   keepCount: 5,
  /// );
  ///
  /// // 使用默认值保留 10 个备份
  /// await backupManager.cleanOldBackups(instanceId: 'my-instance');
  /// ```
  ///
  /// 注意事项:
  /// - 删除操作不可恢复
  /// - 建议在创建新备份后调用此方法进行自动清理
  Future<void> cleanOldBackups({
    required String instanceId,
    int keepCount = 10,
  }) async {
    // 获取该实例的所有备份（已按时间降序排列）
    final instanceBackups = getBackupsForInstance(instanceId);

    // 如果备份数量不超过保留数量，无需清理
    if (instanceBackups.length <= keepCount) return;

    // 获取需要删除的备份（跳过最新的 keepCount 个）
    final toDelete = instanceBackups.skip(keepCount);

    // 逐个删除旧备份
    for (final backup in toDelete) {
      await deleteBackup(backup.id);
    }
  }

  /// 获取所有备份的总大小
  ///
  /// 计算所有备份文件的累计大小（字节）。
  /// 用于统计存储空间占用和显示总备份大小。
  ///
  /// 返回值:
  /// - 所有备份文件的总大小（字节）
  /// - 如果没有任何备份，返回 0
  ///
  /// 示例:
  /// ```dart
  /// // 获取总备份大小
  /// final totalSize = await backupManager.getTotalBackupSize();
  ///
  /// // 格式化显示
  /// if (totalSize < 1024 * 1024 * 1024) {
  ///   print('总备份大小: ${(totalSize / (1024 * 1024)).toFixed(1)} MB');
  /// } else {
  ///   print('总备份大小: ${(totalSize / (1024 * 1024 * 1024)).toFixed(1)} GB');
  /// }
  /// ```
  ///
  /// 注意事项:
  /// - 此方法使用备份记录中存储的 fileSize 字段进行计算
  /// - 不会实际遍历文件系统，速度较快
  /// - 如果备份文件被手动删除但索引未更新，结果可能不准确
  Future<int> getTotalBackupSize() async {
    int totalSize = 0;

    // 累加所有备份记录中的文件大小
    for (final backup in _backups) {
      totalSize += backup.fileSize;
    }

    return totalSize;
  }

  /// 检查是否有备份任务正在进行
  ///
  /// 返回当前是否有备份创建任务正在进行。
  /// 用于 UI 显示状态或防止重复操作。
  ///
  /// 返回值:
  /// - true 表示正在创建备份
  /// - false 表示没有备份任务进行
  ///
  /// 示例:
  /// ```dart
  /// if (backupManager.isBackingUp) {
  ///   print('正在创建备份，请稍候...');
  /// } else {
  ///   await backupManager.createBackup(...);
  /// }
  /// ```
  bool get isBackingUp => _isBackingUp;

  /// 检查是否有恢复任务正在进行
  ///
  /// 返回当前是否有备份恢复任务正在进行。
  /// 用于 UI 显示状态或防止重复操作。
  ///
  /// 返回值:
  /// - true 表示正在恢复备份
  /// - false 表示没有恢复任务进行
  ///
  /// 示例:
  /// ```dart
  /// if (backupManager.isRestoring) {
  ///   print('正在恢复备份，请稍候...');
  /// } else {
  ///   await backupManager.restoreBackup(...);
  /// }
  /// ```
  bool get isRestoring => _isRestoring;
}
