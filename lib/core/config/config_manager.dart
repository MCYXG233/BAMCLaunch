import 'dart:convert';
import 'dart:io';
import '../platform/i_platform_adapter.dart';
import 'i_config_manager.dart';
import 'aes_encryption.dart';
import 'models/global_config.dart';

/// 配置管理器实现类
/// 负责配置的读写、加密、备份与恢复等操作
class ConfigManager implements IConfigManager {
  /// 平台适配器
  final IPlatformAdapter _platformAdapter;
  /// 配置文件名
  final String _configFileName = 'config.json';
  /// 备份文件名
  final String _backupFileName = 'config_backup.json';
  /// 备份目录名
  final String _backupDirectoryName = 'backups';
  /// 加密密钥
  String? _encryptionKey;

  /// 构造函数
  /// [_platformAdapter]: 平台适配器实例
  ConfigManager(this._platformAdapter);

  /// 获取配置文件路径
  Future<String> get _configFilePath async {
    final configDir = _platformAdapter.configDirectory;
    return '$configDir${Platform.pathSeparator}$_configFileName';
  }

  /// 获取备份文件路径
  Future<String> get _backupFilePath async {
    final configDir = _platformAdapter.configDirectory;
    return '$configDir${Platform.pathSeparator}$_backupFileName';
  }

  /// 获取备份目录路径
  Future<String> get _backupDirectoryPath async {
    final configDir = _platformAdapter.configDirectory;
    return '$configDir${Platform.pathSeparator}$_backupDirectoryName';
  }

  /// 获取加密密钥
  /// 基于用户名和主机名生成唯一密钥
  Future<String> _getEncryptionKey() async {
    if (_encryptionKey == null) {
      final username = await _platformAdapter.getUsername();
      final hostname = await _platformAdapter.getHostname();
      _encryptionKey = '${username}_${hostname}_bamclauncher_secret_key';
    }
    return _encryptionKey!;
  }

  /// 加载所有配置
  /// 返回配置映射
  Future<Map<String, dynamic>> _loadAllConfigs() async {
    final configPath = await _configFilePath;
    final configDir = Directory(_platformAdapter.configDirectory);

    // 确保配置目录存在
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    if (!(await _platformAdapter.isFile(configPath))) {
      return {};
    }

    try {
      final content = await _platformAdapter.readFile(configPath);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// 保存所有配置
  /// [configs]: 配置映射
  Future<void> _saveAllConfigs(Map<String, dynamic> configs) async {
    final configPath = await _configFilePath;
    final configDir = Directory(_platformAdapter.configDirectory);

    // 确保配置目录存在
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    final content = jsonEncode(configs);
    await _platformAdapter.writeFile(configPath, content);
  }

  // 基础配置操作
  /// 保存配置
  /// [key]: 配置键
  /// [value]: 配置值
  /// [encrypt]: 是否加密
  @override
  Future<void> saveConfig(String key, dynamic value,
      {bool encrypt = false}) async {
    final configs = await _loadAllConfigs();

    if (encrypt) {
      final encryptionKey = await _getEncryptionKey();
      final jsonValue = jsonEncode(value);
      final encryptedValue = AesEncryption.encrypt(jsonValue, encryptionKey);
      configs[key] = {'encrypted': true, 'value': encryptedValue};
    } else {
      configs[key] = {'encrypted': false, 'value': value};
    }

    await _saveAllConfigs(configs);
  }

  /// 加载配置
  /// [key]: 配置键
  /// [decrypt]: 是否解密
  /// 返回配置值
  @override
  Future<dynamic> loadConfig(String key, {bool decrypt = false}) async {
    final configs = await _loadAllConfigs();
    final config = configs[key];

    if (config == null) {
      return null;
    }

    if (config['encrypted'] == true && decrypt) {
      final encryptionKey = await _getEncryptionKey();
      final encryptedValue = config['value'] as String;
      final decryptedValue =
          AesEncryption.decrypt(encryptedValue, encryptionKey);
      return jsonDecode(decryptedValue);
    }

    return config['value'];
  }

  /// 删除配置
  /// [key]: 配置键
  @override
  Future<void> removeConfig(String key) async {
    final configs = await _loadAllConfigs();
    configs.remove(key);
    await _saveAllConfigs(configs);
  }

  /// 检查配置是否存在
  /// [key]: 配置键
  /// 返回是否存在
  @override
  Future<bool> containsKey(String key) async {
    final configs = await _loadAllConfigs();
    return configs.containsKey(key);
  }

  /// 获取所有配置
  /// 返回配置映射，加密配置显示为<encrypted>
  @override
  Future<Map<String, dynamic>> getAllConfigs() async {
    final configs = await _loadAllConfigs();
    final result = <String, dynamic>{};

    configs.forEach((key, value) {
      if (value['encrypted'] == true) {
        result[key] = '<encrypted>';
      } else {
        result[key] = value['value'];
      }
    });

    return result;
  }

  /// 清除所有配置
  @override
  Future<void> clearAllConfigs() async {
    await _saveAllConfigs({});
  }

  // 全局配置操作
  /// 保存全局配置
  /// [config]: 全局配置对象或映射
  @override
  Future<void> saveGlobalConfig(dynamic config) async {
    if (config is GlobalConfig) {
      await saveConfig('global_config', config.toJson());
    } else if (config is Map<String, dynamic>) {
      await saveConfig('global_config', config);
    }
  }

  /// 加载全局配置
  /// 返回全局配置对象
  @override
  Future<dynamic> loadGlobalConfig() async {
    final config = await loadConfig('global_config');
    if (config is Map<String, dynamic>) {
      return GlobalConfig.fromJson(config);
    }
    return null;
  }

  /// 验证配置
  /// [config]: 配置对象或映射
  /// 返回是否有效
  @override
  Future<bool> validateConfig(dynamic config) async {
    try {
      if (config is GlobalConfig) {
        // 验证全局配置结构
        return true;
      } else if (config is Map<String, dynamic>) {
        // 验证配置映射结构
        return config.containsKey('version') &&
            config.containsKey('basic') &&
            config.containsKey('game') &&
            config.containsKey('download') &&
            config.containsKey('account') &&
            config.containsKey('ui') &&
            config.containsKey('content');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 重置为默认配置
  @override
  Future<void> resetToDefaults() async {
    final defaultConfig = GlobalConfig.defaultConfig();
    await saveGlobalConfig(defaultConfig);
    await updateConfigVersion(defaultConfig.version);
  }

  // 配置迁移与升级
  /// 迁移配置
  /// 根据当前版本进行配置迁移
  @override
  Future<void> migrateConfig() async {
    final currentVersion = await getCurrentConfigVersion();
    
    // 根据当前版本进行迁移
    if (currentVersion.isEmpty) {
      // 首次安装，使用默认配置
      await resetToDefaults();
    } else if (currentVersion == '1.0.0') {
      // 从1.0.0版本迁移到新版本的逻辑
      // TODO: 实现具体的迁移逻辑
    }
    // 可以添加更多版本迁移逻辑
  }

  /// 获取当前配置版本
  /// 返回配置版本字符串
  @override
  Future<String> getCurrentConfigVersion() async {
    final config = await loadGlobalConfig();
    if (config is GlobalConfig) {
      return config.version;
    }
    return '';
  }

  /// 更新配置版本
  /// [version]: 新的版本号
  @override
  Future<void> updateConfigVersion(String version) async {
    final config = await loadGlobalConfig();
    if (config is GlobalConfig) {
      final updatedConfig = GlobalConfig(
        version: version,
        basic: config.basic,
        game: config.game,
        download: config.download,
        account: config.account,
        ui: config.ui,
        content: config.content,
      );
      await saveGlobalConfig(updatedConfig);
    }
  }

  // 备份与恢复
  /// 备份配置
  @override
  Future<void> backupConfig() async {
    final configPath = await _configFilePath;
    final backupPath = await _backupFilePath;

    if (await _platformAdapter.isFile(configPath)) {
      final content = await _platformAdapter.readFile(configPath);
      await _platformAdapter.writeFile(backupPath, content);
    }
  }

  /// 恢复配置
  /// [backupPath]: 备份文件路径
  /// 返回是否恢复成功
  @override
  Future<bool> restoreConfig(String backupPath) async {
    if (!(await _platformAdapter.isFile(backupPath))) {
      return false;
    }

    try {
      final content = await _platformAdapter.readFile(backupPath);
      final configPath = await _configFilePath;
      await _platformAdapter.writeFile(configPath, content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取备份文件列表
  /// 返回备份文件路径列表
  @override
  Future<List<String>> getBackupFiles() async {
    final backupDir = await _backupDirectoryPath;
    final directory = Directory(backupDir);
    
    if (!await directory.exists()) {
      return [];
    }

    try {
      final files = await _platformAdapter.listFiles(backupDir);
      return files.where((file) => file.endsWith('.json')).toList();
    } catch (e) {
      return [];
    }
  }

  /// 创建自动备份
  @override
  Future<void> createAutoBackup() async {
    final backupDir = await _backupDirectoryPath;
    final directory = Directory(backupDir);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFileName = 'config_backup_$timestamp.json';
    final backupPath = '$backupDir${Platform.pathSeparator}$backupFileName';
    final configPath = await _configFilePath;

    if (await _platformAdapter.isFile(configPath)) {
      final content = await _platformAdapter.readFile(configPath);
      await _platformAdapter.writeFile(backupPath, content);
    }

    // 清理旧备份，保留最近的5个
    await cleanOldBackups(5);
  }

  /// 清理旧备份
  /// [keepCount]: 保留的备份数量
  @override
  Future<void> cleanOldBackups(int keepCount) async {
    final backupDir = await _backupDirectoryPath;
    final directory = Directory(backupDir);
    
    if (!await directory.exists()) {
      return;
    }

    try {
      final files = await _platformAdapter.listFiles(backupDir);
      if (files.length <= keepCount) {
        return;
      }

      // 按文件名排序（时间戳）
      files.sort((a, b) {
        final aTime = int.parse(a.split('_').last.split('.').first);
        final bTime = int.parse(b.split('_').last.split('.').first);
        return bTime.compareTo(aTime); // 降序排列
      });

      // 删除超出保留数量的备份
      for (var i = keepCount; i < files.length; i++) {
        final filePath = '$backupDir${Platform.pathSeparator}${files[i]}';
        try {
          await File(filePath).delete();
        } catch (e) {
          // 忽略删除错误
        }
      }
    } catch (e) {
      // 忽略清理错误
    }
  }

  // 配置验证
  /// 检查配置是否有效
  /// 返回是否有效
  @override
  Future<bool> isConfigValid() async {
    try {
      final config = await loadGlobalConfig();
      return await validateConfig(config);
    } catch (e) {
      return false;
    }
  }

  /// 修复配置
  /// 如果配置无效，创建备份并重置为默认配置
  @override
  Future<void> repairConfig() async {
    try {
      final isValid = await isConfigValid();
      if (!isValid) {
        // 创建备份
        await createAutoBackup();
        // 重置为默认配置
        await resetToDefaults();
      }
    } catch (e) {
      // 如果修复失败，使用默认配置
      await resetToDefaults();
    }
  }
}
