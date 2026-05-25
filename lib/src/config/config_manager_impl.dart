import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../platform/platform_adapter.dart';
import '../platform/platform_adapter_factory.dart';
import 'config_manager.dart';
import 'config_keys.dart';
import 'crypto_util.dart';

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
      await _configFile!.writeAsString(jsonString);
    } catch (e) {
      print('Failed to save config: $e');
    }
  }

  @override
  Future<void> load() async {
    if (_configFile == null || !await _configFile!.exists()) return;

    try {
      final jsonString = await _configFile!.readAsString();
      final Map<String, dynamic> loaded = jsonDecode(jsonString);

      _config.clear();
      _config.addAll(loaded);

      for (final key in loaded.keys) {
        _configChangesController.add(key);
      }
    } catch (e) {
      print('Failed to load config: $e');
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
}
