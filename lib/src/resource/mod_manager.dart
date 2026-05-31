import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'resource_update_checker.dart';

/// Mod状态
enum ModStatus {
  enabled,
  disabled,
  needsUpdate,
  incompatible,
}

/// Mod元数据
class ModMetadata {
  final String id;
  final String name;
  final String version;
  final String? description;
  final List<String>? authors;
  final String? website;
  final List<String>? gameVersions;
  final List<String>? dependencies;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final ModStatus status;
  final String fileName;
  final String filePath;
  final int fileSize;

  ModMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.authors,
    this.website,
    this.gameVersions,
    this.dependencies,
    this.installedAt,
    this.updatedAt,
    this.status = ModStatus.enabled,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'authors': authors,
      'website': website,
      'gameVersions': gameVersions,
      'dependencies': dependencies,
      'installedAt': installedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
    };
  }

  factory ModMetadata.fromJson(Map<String, dynamic> json) {
    return ModMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
      authors: (json['authors'] as List<dynamic>?)?.cast<String>(),
      website: json['website'] as String?,
      gameVersions: (json['gameVersions'] as List<dynamic>?)?.cast<String>(),
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>(),
      installedAt: json['installedAt'] != null
          ? DateTime.parse(json['installedAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: ModStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ModStatus.enabled,
      ),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
    );
  }

  ModMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    List<String>? authors,
    String? website,
    List<String>? gameVersions,
    List<String>? dependencies,
    DateTime? installedAt,
    DateTime? updatedAt,
    ModStatus? status,
    String? fileName,
    String? filePath,
    int? fileSize,
  }) {
    return ModMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      authors: authors ?? this.authors,
      website: website ?? this.website,
      gameVersions: gameVersions ?? this.gameVersions,
      dependencies: dependencies ?? this.dependencies,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

/// Mod管理器
class ModManager {
  static ModManager? _instance;

  final Logger _logger = Logger('ModManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// Mod缓存
  final Map<String, List<ModMetadata>> _modsCache = {};

  /// Mod元数据缓存文件
  File? _metadataFile;

  /// 是否已初始化
  bool _initialized = false;

  ModManager._internal();

  /// 获取单例实例
  static ModManager get instance {
    _instance ??= ModManager._internal();
    return _instance!;
  }

  /// 工厂构造函数
  factory ModManager() => instance;

  /// 初始化Mod管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _metadataFile = File(path.join(supportDir, 'mod_metadata.json'));

      if (await _metadataFile!.exists()) {
        await _loadMetadata();
      }

      _logger.info('Mod manager initialized');
      _initialized = true;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize mod manager', e, stackTrace);
      _initialized = true;
    }
  }

  /// 加载元数据
  Future<void> _loadMetadata() async {
    try {
      final content = await _metadataFile!.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      data.forEach((instanceId, modsData) {
        if (modsData is List) {
          _modsCache[instanceId] = modsData
              .whereType<Map<String, dynamic>>()
              .map((e) => ModMetadata.fromJson(e))
              .toList();
        }
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to load mod metadata', e, stackTrace);
    }
  }

  /// 保存元数据
  Future<void> _saveMetadata() async {
    try {
      final data = <String, dynamic>{};

      _modsCache.forEach((instanceId, mods) {
        data[instanceId] = mods.map((m) => m.toJson()).toList();
      });

      await _metadataFile!.writeAsString(jsonEncode(data));
    } catch (e, stackTrace) {
      _logger.error('Failed to save mod metadata', e, stackTrace);
    }
  }

  /// 扫描实例目录获取所有Mod
  Future<List<ModMetadata>> scanInstanceMods(String instanceId, String instancePath) async {
    final modsDir = Directory(path.join(instancePath, 'mods'));
    final mods = <ModMetadata>[];

    if (!await modsDir.exists()) {
      return mods;
    }

    await for (final file in modsDir.list()) {
      if (file is File &&
          (file.path.endsWith('.jar') ||
              file.path.endsWith('.litemod') ||
              file.path.endsWith('.disabled'))) {
        final mod = await _loadModFromFile(file, instanceId);
        if (mod != null) {
          mods.add(mod);
        }
      }
    }

    // 更新缓存
    _modsCache[instanceId] = mods;
    await _saveMetadata();

    return mods;
  }

  /// 从文件加载Mod
  Future<ModMetadata?> _loadModFromFile(File file, String instanceId) async {
    try {
      final fileName = path.basename(file.path);
      final fileStat = await file.stat();
      final isDisabled = fileName.endsWith('.disabled');

      // 解析文件名
      final cleanName = isDisabled
          ? fileName.substring(0, fileName.length - '.disabled'.length)
          : fileName;

      // 简单解析，实际应该读取jar包中的mod信息
      final nameParts = cleanName.replaceAll('.jar', '').replaceAll('.litemod', '').split('-');

      String name = nameParts.first;
      String version = 'unknown';

      if (nameParts.length > 1) {
        version = nameParts.last;
        if (nameParts.length > 2) {
          name = nameParts.sublist(0, nameParts.length - 1).join('-');
        }
      }

      return ModMetadata(
        id: '${instanceId}_$fileName',
        name: name,
        version: version,
        status: isDisabled ? ModStatus.disabled : ModStatus.enabled,
        fileName: fileName,
        filePath: file.path,
        fileSize: fileStat.size,
        installedAt: fileStat.modified,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load mod from file ${file.path}', e, stackTrace);
      return null;
    }
  }

  /// 获取实例的Mod列表
  List<ModMetadata> getInstanceMods(String instanceId) {
    return _modsCache[instanceId] ?? [];
  }

  /// 启用Mod
  Future<bool> enableMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (!await file.exists()) return false;

      if (mod.status == ModStatus.enabled) return true;

      // 移除 .disabled 后缀
      final newPath = mod.filePath.replaceAll('.disabled', '');
      await file.rename(newPath);

      // 更新元数据
      final updatedMod = mod.copyWith(
        status: ModStatus.enabled,
        filePath: newPath,
        fileName: path.basename(newPath),
      );

      _updateModInCache(updatedMod);
      await _saveMetadata();

      _logger.info('Enabled mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to enable mod', e, stackTrace);
      return false;
    }
  }

  /// 禁用Mod
  Future<bool> disableMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (!await file.exists()) return false;

      if (mod.status == ModStatus.disabled) return true;

      // 添加 .disabled 后缀
      final newPath = '${mod.filePath}.disabled';
      await file.rename(newPath);

      // 更新元数据
      final updatedMod = mod.copyWith(
        status: ModStatus.disabled,
        filePath: newPath,
        fileName: path.basename(newPath),
      );

      _updateModInCache(updatedMod);
      await _saveMetadata();

      _logger.info('Disabled mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to disable mod', e, stackTrace);
      return false;
    }
  }

  /// 删除Mod
  Future<bool> deleteMod(ModMetadata mod) async {
    try {
      final file = File(mod.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 从缓存中移除
      final instanceId = mod.id.split('_').first;
      final mods = _modsCache[instanceId];
      if (mods != null) {
        mods.removeWhere((m) => m.id == mod.id);
      }

      await _saveMetadata();

      _logger.info('Deleted mod: ${mod.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete mod', e, stackTrace);
      return false;
    }
  }

  /// 更新缓存中的Mod
  void _updateModInCache(ModMetadata mod) {
    final instanceId = mod.id.split('_').first;
    final mods = _modsCache[instanceId];
    if (mods != null) {
      final index = mods.indexWhere((m) => m.id == mod.id);
      if (index >= 0) {
        mods[index] = mod;
      }
    }
  }

  /// 批量启用/禁用Mod
  Future<void> toggleMods(List<ModMetadata> mods, bool enable) async {
    for (final mod in mods) {
      if (enable) {
        await enableMod(mod);
      } else {
        await disableMod(mod);
      }
    }
  }

  /// 获取启用的Mod
  List<ModMetadata> getEnabledMods(String instanceId) {
    return getInstanceMods(instanceId)
        .where((m) => m.status == ModStatus.enabled)
        .toList();
  }

  /// 获取禁用的Mod
  List<ModMetadata> getDisabledMods(String instanceId) {
    return getInstanceMods(instanceId)
        .where((m) => m.status == ModStatus.disabled)
        .toList();
  }

  /// 搜索Mod
  List<ModMetadata> searchMods(String instanceId, String query) {
    final lowerQuery = query.toLowerCase();
    return getInstanceMods(instanceId)
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.id.toLowerCase().contains(lowerQuery) ||
            m.fileName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 清空缓存
  void clearCache() {
    _modsCache.clear();
  }
}
