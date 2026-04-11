abstract class IConfigManager {
  // 基础配置操作
  Future<void> saveConfig(String key, dynamic value, {bool encrypt = false});
  Future<dynamic> loadConfig(String key, {bool decrypt = false});
  Future<void> removeConfig(String key);
  Future<bool> containsKey(String key);
  Future<Map<String, dynamic>> getAllConfigs();
  Future<void> clearAllConfigs();

  // 全局配置操作
  Future<void> saveGlobalConfig(dynamic config);
  Future<dynamic> loadGlobalConfig();
  Future<bool> validateConfig(dynamic config);
  Future<void> resetToDefaults();

  // 配置迁移与升级
  Future<void> migrateConfig();
  Future<String> getCurrentConfigVersion();
  Future<void> updateConfigVersion(String version);

  // 备份与恢复
  Future<void> backupConfig();
  Future<bool> restoreConfig(String backupPath);
  Future<List<String>> getBackupFiles();
  Future<void> createAutoBackup();
  Future<void> cleanOldBackups(int keepCount);

  // 配置验证
  Future<bool> isConfigValid();
  Future<void> repairConfig();
}