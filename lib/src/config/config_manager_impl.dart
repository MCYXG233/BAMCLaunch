import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'config_manager.dart';
import 'config_keys.dart';
import 'config_models.dart';
import 'crypto_util.dart';
import 'package:flutter/foundation.dart';

import '../core/logger.dart';

/// 配置管理器实现类
/// 使用JSON格式存储配置，支持加密存储敏感信息
class ConfigManagerImpl implements IConfigManager {
  static ConfigManagerImpl? _instance;
  final IPlatformAdapter _platformAdapter;

  final Map<String, dynamic> _config = {};
  final StreamController<String> _configChangesController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _autoSave = true;
  File? _configFile;
  
  /// 缓存的完整配置对象
  LauncherConfig? _cachedConfig;

  /// 获取单例实例
  factory ConfigManagerImpl() {
    _instance ??= ConfigManagerImpl._internal();
    return _instance!;
  }

  /// 私有构造函数
  ConfigManagerImpl._internal()
    : _platformAdapter = PlatformAdapterFactory.instance;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final supportDir = await _platformAdapter.getApplicationSupportDirectory();
    final configDir = Directory(path.join(supportDir, 'config'));

    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    _configFile = File(path.join(configDir.path, 'settings.json'));

    if (await _configFile!.exists()) {
      await load();
    }

    _initialized = true;
  }

  @override
  T? get<T>(String key, {T? defaultValue}) {
    final value = _config[key];
    if (value == null) return defaultValue;

    if (value is T) return value;

    try {
      if (T == int) return int.tryParse(value.toString()) as T?;
      if (T == double) return double.tryParse(value.toString()) as T?;
      if (T == bool) {
        final lower = value.toString().toLowerCase();
        return (lower == 'true' || lower == '1') as T?;
      }
    } catch (e) {
      return defaultValue;
    }

    return defaultValue;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    final oldValue = _config[key];
    if (oldValue == value) return;

    _config[key] = value;
    _configChangesController.add(key);

    if (_autoSave) {
      await save();
    }
  }

  @override
  Future<void> setEncrypted(String key, String value) async {
    final encryptedKey = '${ConfigKeys.encryptedPrefix}$key';
    final encryptedValue = CryptoUtil.encryptString(value);
    await set(encryptedKey, encryptedValue);
  }

  @override
  Future<String?> getEncrypted(String key) async {
    final encryptedKey = '${ConfigKeys.encryptedPrefix}$key';
    final encryptedValue = get<String>(encryptedKey);
    if (encryptedValue == null) return null;
    return CryptoUtil.decryptString(encryptedValue);
  }

  @override
  Future<void> remove(String key) async {
    if (_config.containsKey(key)) {
      _config.remove(key);
      _configChangesController.add(key);

      if (_autoSave) {
        await save();
      }
    }
  }

  @override
  Future<void> clear() async {
    final keys = List<String>.from(_config.keys);
    _config.clear();

    for (final key in keys) {
      _configChangesController.add(key);
    }

    if (_autoSave) {
      await save();
    }
  }

  @override
  Future<void> save() async {
    if (_configFile == null) return;

    try {
      final jsonString = jsonEncode(_config);
      final tempFile = File('${_configFile!.path}.tmp');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await tempFile.writeAsString(jsonString);

      if (await _configFile!.exists()) {
        await _configFile!.delete();
      }
      await tempFile.rename(_configFile!.path);
    } catch (e) {
      debugPrint('[ConfigManager] Failed to save config: $e');
    }
  }

  @override
  Future<void> load() async {
    if (_configFile == null || !await _configFile!.exists()) return;

    try {
      final jsonString = await _configFile!.readAsString();
      if (jsonString.trim().isEmpty) {
        debugPrint('[ConfigManager] Config file is empty, using defaults');
        return;
      }

      final Map<String, dynamic> loaded = jsonDecode(jsonString);
      _config.clear();
      _config.addAll(loaded);

      for (final key in loaded.keys) {
        _configChangesController.add(key);
      }
    } on FormatException catch (e) {
      final backupPath =
          '${_configFile!.path}.corrupted.${DateTime.now().millisecondsSinceEpoch}';
      try {
        await _configFile!.rename(backupPath);
        debugPrint(
            '[ConfigManager] Config file corrupted, backed up to $backupPath');
      } catch (_) {
        debugPrint('[ConfigManager] Failed to backup corrupted config');
      }
      debugPrint(
          '[ConfigManager] Using default config due to corruption: $e');
    } catch (e) {
      debugPrint('[ConfigManager] Failed to load config: $e');
    }
  }

  @override
  Stream<String> get configChanges => _configChangesController.stream;

  @override
  String? getString(String key, {String? defaultValue}) =>
      get<String>(key, defaultValue: defaultValue);

  @override
  Future<void> setString(String key, String value) => set(key, value);

  @override
  int? getInt(String key, {int? defaultValue}) =>
      get<int>(key, defaultValue: defaultValue);

  @override
  Future<void> setInt(String key, int value) => set(key, value);

  @override
  bool? getBool(String key, {bool? defaultValue}) =>
      get<bool>(key, defaultValue: defaultValue);

  @override
  Future<void> setBool(String key, bool value) => set(key, value);

  /// 设置是否自动保存
  /// [enabled] 是否启用自动保存
  void setAutoSave(bool enabled) {
    _autoSave = enabled;
  }

  /// 获取当前配置的副本
  Map<String, dynamic> getAll() {
    return Map<String, dynamic>.from(_config);
  }

  /// 关闭资源
  void dispose() {
    _configChangesController.close();
  }

  /// 获取完整的启动器配置
  LauncherConfig getLauncherConfig() {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }
    try {
      final configData = _config[ConfigKeys.launcherConfig];
      if (configData != null && configData is Map<String, dynamic>) {
        _cachedConfig = LauncherConfig.fromJson(configData);
        return _cachedConfig!;
      }
    } catch (e, st) {
      Logger.instance.error('解析启动器配置失败，使用默认配置', e, st);
    }
    return LauncherConfig.defaultConfig();
  }

  /// 保存完整的启动器配置
  Future<void> setLauncherConfig(LauncherConfig config) async {
    _cachedConfig = config;
    await set(ConfigKeys.launcherConfig, config.toJson());
  }

  /// 批量更新配置
  Future<void> updateConfig(Map<String, dynamic> updates) async {
    for (final entry in updates.entries) {
      _config[entry.key] = entry.value;
    }
    for (final key in updates.keys) {
      _configChangesController.add(key);
    }
    if (_autoSave) {
      await save();
    }
  }

  /// 增加运行计数
  Future<int> incrementRunCount() async {
    final current = getInt(ConfigKeys.runCount) ?? 0;
    final newCount = current + 1;
    await setInt(ConfigKeys.runCount, newCount);
    return newCount;
  }

  /// 获取额外的 Java 路径列表
  List<String> getExtraJavaPaths() {
    final paths = _config[ConfigKeys.extraJavaPaths];
    if (paths is List) {
      return paths.whereType<String>().toList();
    }
    return [];
  }

  /// 添加额外的 Java 路径
  Future<void> addExtraJavaPath(String path) async {
    final paths = getExtraJavaPaths();
    if (!paths.contains(path)) {
      paths.add(path);
      await set(ConfigKeys.extraJavaPaths, paths);
    }
  }

  /// 移除额外的 Java 路径
  Future<void> removeExtraJavaPath(String path) async {
    final paths = getExtraJavaPaths();
    if (paths.remove(path)) {
      await set(ConfigKeys.extraJavaPaths, paths);
    }
  }

  /// 获取被抑制的对话框列表
  List<String> getSuppressedDialogs() {
    final dialogs = _config[ConfigKeys.suppressedDialogs];
    if (dialogs is List) {
      return dialogs.whereType<String>().toList();
    }
    return [];
  }

  /// 抑制对话框
  Future<void> suppressDialog(String dialogId) async {
    final dialogs = getSuppressedDialogs();
    if (!dialogs.contains(dialogId)) {
      dialogs.add(dialogId);
      await set(ConfigKeys.suppressedDialogs, dialogs);
    }
  }

  /// 检查对话框是否被抑制
  bool isDialogSuppressed(String dialogId) {
    return getSuppressedDialogs().contains(dialogId);
  }

  /// 获取本地游戏目录列表
  List<GameDirectory> getLocalGameDirectories() {
    final dirs = _config[ConfigKeys.localGameDirectories];
    if (dirs is List) {
      return dirs
          .whereType<Map<String, dynamic>>()
          .map((e) => GameDirectory.fromJson(e))
          .toList();
    }
    return [];
  }

  /// 添加本地游戏目录
  Future<void> addLocalGameDirectory(GameDirectory dir) async {
    final dirs = getLocalGameDirectories();
    final existingIndex = dirs.indexWhere((d) => d.dir == dir.dir);
    if (existingIndex >= 0) {
      dirs[existingIndex] = dir;
    } else {
      dirs.add(dir);
    }
    await set(ConfigKeys.localGameDirectories, dirs.map((d) => d.toJson()).toList());
  }

  /// 移除本地游戏目录
  Future<void> removeLocalGameDirectory(String dirPath) async {
    final dirs = getLocalGameDirectories();
    dirs.removeWhere((d) => d.dir == dirPath);
    await set(ConfigKeys.localGameDirectories, dirs.map((d) => d.toJson()).toList());
  }
}
