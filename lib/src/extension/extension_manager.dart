import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../config/config_manager.dart';
import '../core/logger.dart';

/// 扩展状态
enum ExtensionStatus {
  loaded,
  enabled,
  disabled,
  error,
}

/// 扩展信息
class ExtensionInfo {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final String? authorUrl;
  final String? homepage;
  final String? license;
  final List<String> dependencies;
  final List<String> permissions;
  final String entryPoint;
  final String? icon;
  final ExtensionStatus status;
  final String? error;
  final DateTime installedAt;
  final DateTime? updatedAt;

  ExtensionInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.authorUrl,
    this.homepage,
    this.license,
    this.dependencies = const [],
    this.permissions = const [],
    required this.entryPoint,
    this.icon,
    this.status = ExtensionStatus.disabled,
    this.error,
    required this.installedAt,
    this.updatedAt,
  });

  ExtensionInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? author,
    String? authorUrl,
    String? homepage,
    String? license,
    List<String>? dependencies,
    List<String>? permissions,
    String? entryPoint,
    String? icon,
    ExtensionStatus? status,
    String? error,
    DateTime? installedAt,
    DateTime? updatedAt,
  }) {
    return ExtensionInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      author: author ?? this.author,
      authorUrl: authorUrl ?? this.authorUrl,
      homepage: homepage ?? this.homepage,
      license: license ?? this.license,
      dependencies: dependencies ?? this.dependencies,
      permissions: permissions ?? this.permissions,
      entryPoint: entryPoint ?? this.entryPoint,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      error: error ?? this.error,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      'authorUrl': authorUrl,
      'homepage': homepage,
      'license': license,
      'dependencies': dependencies,
      'permissions': permissions,
      'entryPoint': entryPoint,
      'icon': icon,
      'status': status.name,
      'error': error,
      'installedAt': installedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExtensionInfo.fromJson(Map<String, dynamic> json) {
    return ExtensionInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      authorUrl: json['authorUrl'] as String?,
      homepage: json['homepage'] as String?,
      license: json['license'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      entryPoint: json['entryPoint'] as String,
      icon: json['icon'] as String?,
      status: ExtensionStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => ExtensionStatus.disabled,
      ),
      error: json['error'] as String?,
      installedAt: DateTime.parse(json['installedAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

/// 扩展元数据文件
class ExtensionManifest {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final String? authorUrl;
  final String? homepage;
  final String? license;
  final List<String> dependencies;
  final List<String> permissions;
  final String entryPoint;
  final String? icon;

  ExtensionManifest({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    this.authorUrl,
    this.homepage,
    this.license,
    this.dependencies = const [],
    this.permissions = const [],
    required this.entryPoint,
    this.icon,
  });

  factory ExtensionManifest.fromJson(Map<String, dynamic> json) {
    return ExtensionManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      authorUrl: json['authorUrl'] as String?,
      homepage: json['homepage'] as String?,
      license: json['license'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      entryPoint: json['entryPoint'] as String,
      icon: json['icon'] as String?,
    );
  }
}

/// 扩展管理器
class ExtensionManager {
  static ExtensionManager? _instance;

  factory ExtensionManager() {
    _instance ??= ExtensionManager._internal();
    return _instance!;
  }

  ExtensionManager._internal();

  static ExtensionManager get instance => _instance ??= ExtensionManager._internal();

  final Logger _logger = Logger('ExtensionManager');
  final ConfigManager _configManager = ConfigManager.instance;

  static const String _extensionsKey = 'extensions';
  static const String _enabledExtensionsKey = 'enabled_extensions';

  final List<ExtensionInfo> _extensions = [];
  final Map<String, dynamic> _loadedExtensions = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<ExtensionInfo> get extensions => List.unmodifiable(_extensions);

  /// 初始化扩展管理器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.info('Initializing ExtensionManager...');

      await _loadExtensions();
      await _loadEnabledExtensions();

      _initialized = true;
      _logger.info('ExtensionManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize ExtensionManager', e, stackTrace);
      rethrow;
    }
  }

  /// 加载扩展列表
  Future<void> _loadExtensions() async {
    try {
      final raw = _configManager.get<List<dynamic>>(_extensionsKey);
      if (raw != null) {
        _extensions.clear();
        _extensions.addAll(raw.map((e) => ExtensionInfo.fromJson(e as Map<String, dynamic>)));
      } else {
        _extensions.clear();
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load extensions', e, stackTrace);
      _extensions.clear();
    }
  }

  /// 加载已启用的扩展
  Future<void> _loadEnabledExtensions() async {
    try {
      final enabledIds = _configManager.get<List<dynamic>>(_enabledExtensionsKey);
      if (enabledIds != null) {
        for (final id in enabledIds) {
          final index = _extensions.indexWhere((e) => e.id == id);
          if (index != -1) {
            _extensions[index] = _extensions[index].copyWith(status: ExtensionStatus.enabled);
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load enabled extensions', e, stackTrace);
    }
  }

  /// 保存扩展数据
  Future<void> save() async {
    try {
      await _configManager.set<List<dynamic>>(_extensionsKey, _extensions.map((e) => e.toJson()).toList());

      final enabledIds = _extensions
          .where((e) => e.status == ExtensionStatus.enabled)
          .map((e) => e.id)
          .toList();
      await _configManager.set<List<dynamic>>(_enabledExtensionsKey, enabledIds);

      await _configManager.save();
      _logger.info('Extension data saved successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to save extension data', e, stackTrace);
      rethrow;
    }
  }

  /// 安装扩展
  Future<ExtensionInfo> installExtension(String extensionPath) async {
    final directory = Directory(extensionPath);
    if (!directory.existsSync()) {
      throw ArgumentError('Extension directory does not exist: $extensionPath');
    }

    final manifestFile = File(path.join(extensionPath, 'manifest.json'));
    if (!manifestFile.existsSync()) {
      throw ArgumentError('Manifest file not found: ${manifestFile.path}');
    }

    final manifestContent = await manifestFile.readAsString();
    final manifest = ExtensionManifest.fromJson(json.decode(manifestContent) as Map<String, dynamic>);

    final extensionInfo = ExtensionInfo(
      id: manifest.id,
      name: manifest.name,
      description: manifest.description,
      version: manifest.version,
      author: manifest.author,
      authorUrl: manifest.authorUrl,
      homepage: manifest.homepage,
      license: manifest.license,
      dependencies: manifest.dependencies,
      permissions: manifest.permissions,
      entryPoint: path.join(extensionPath, manifest.entryPoint),
      icon: manifest.icon != null ? path.join(extensionPath, manifest.icon!) : null,
      status: ExtensionStatus.disabled,
      installedAt: DateTime.now(),
    );

    _extensions.add(extensionInfo);
    await save();

    _logger.info('Installed extension: ${manifest.name}');
    return extensionInfo;
  }

  /// 卸载扩展
  Future<void> uninstallExtension(String extensionId) async {
    final index = _extensions.indexWhere((e) => e.id == extensionId);
    if (index == -1) {
      throw ArgumentError('Extension not found: $extensionId');
    }

    final extension = _extensions[index];

    if (extension.status == ExtensionStatus.enabled) {
      await disableExtension(extensionId);
    }

    if (_loadedExtensions.containsKey(extensionId)) {
      _loadedExtensions.remove(extensionId);
    }

    _extensions.removeAt(index);
    await save();

    _logger.info('Uninstalled extension: ${extension.name}');
  }

  /// 启用扩展
  Future<void> enableExtension(String extensionId) async {
    final index = _extensions.indexWhere((e) => e.id == extensionId);
    if (index == -1) {
      throw ArgumentError('Extension not found: $extensionId');
    }

    final extension = _extensions[index];

    try {
      await _loadExtension(extension);
      _extensions[index] = extension.copyWith(status: ExtensionStatus.enabled);
      await save();

      _logger.info('Enabled extension: ${extension.name}');
    } catch (e, stackTrace) {
      _logger.error('Failed to enable extension ${extension.name}', e, stackTrace);
      _extensions[index] = extension.copyWith(
        status: ExtensionStatus.error,
        error: e.toString(),
      );
      await save();
      rethrow;
    }
  }

  /// 禁用扩展
  Future<void> disableExtension(String extensionId) async {
    final index = _extensions.indexWhere((e) => e.id == extensionId);
    if (index == -1) {
      throw ArgumentError('Extension not found: $extensionId');
    }

    final extension = _extensions[index];

    if (_loadedExtensions.containsKey(extensionId)) {
      await _unloadExtension(extensionId);
    }

    _extensions[index] = extension.copyWith(status: ExtensionStatus.disabled, error: null);
    await save();

    _logger.info('Disabled extension: ${extension.name}');
  }

  /// 加载扩展
  Future<void> _loadExtension(ExtensionInfo extension) async {
    try {
      _logger.info('Loading extension: ${extension.name}');

      _loadedExtensions[extension.id] = {
        'info': extension,
        'loaded': true,
      };

      _logger.info('Extension loaded: ${extension.name}');
    } catch (e, stackTrace) {
      _logger.error('Failed to load extension ${extension.name}', e, stackTrace);
      throw e;
    }
  }

  /// 卸载扩展
  Future<void> _unloadExtension(String extensionId) async {
    try {
      _loadedExtensions.remove(extensionId);
      _logger.info('Extension unloaded: $extensionId');
    } catch (e, stackTrace) {
      _logger.error('Failed to unload extension $extensionId', e, stackTrace);
    }
  }

  /// 获取扩展信息
  ExtensionInfo? getExtension(String extensionId) {
    return _extensions.firstWhere(
      (e) => e.id == extensionId,
      orElse: () => throw StateError('Extension not found'),
    );
  }

  /// 检查扩展是否已启用
  bool isExtensionEnabled(String extensionId) {
    final extension = _extensions.firstWhere(
      (e) => e.id == extensionId,
      orElse: () => throw StateError('Extension not found'),
    );
    return extension.status == ExtensionStatus.enabled;
  }

  /// 获取已启用的扩展
  List<ExtensionInfo> getEnabledExtensions() {
    return _extensions.where((e) => e.status == ExtensionStatus.enabled).toList();
  }

  /// 获取有错误的扩展
  List<ExtensionInfo> getErroredExtensions() {
    return _extensions.where((e) => e.status == ExtensionStatus.error).toList();
  }

  /// 批量安装扩展
  Future<List<ExtensionInfo>> batchInstallExtensions(List<String> paths) async {
    final results = <ExtensionInfo>[];
    for (final path in paths) {
      try {
        final extension = await installExtension(path);
        results.add(extension);
      } catch (e) {
        _logger.error('Failed to install extension from $path', e);
      }
    }
    return results;
  }

  /// 获取扩展的公共API
  dynamic getExtensionApi(String extensionId) {
    return _loadedExtensions[extensionId];
  }
}

