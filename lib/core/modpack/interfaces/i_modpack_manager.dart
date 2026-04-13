import '../models/modpack_models.dart';

abstract class IModpackManager {
  // 导入整合包
  Future<Modpack> importModpack(String filePath);

  // 导出整合包
  Future<String> exportModpack(String modpackId, String destination);

  // 安装整合包
  Future<ModpackInstallationResult> installModpack(String modpackId, String gameVersion);

  // 卸载整合包
  Future<bool> uninstallModpack(String modpackId);

  // 获取整合包列表
  Future<List<Modpack>> getModpacks();

  // 获取整合包详情
  Future<Modpack?> getModpack(String modpackId);

  // 更新整合包
  Future<Modpack> updateModpack(String modpackId);

  // 备份整合包
  Future<String> backupModpack(String modpackId, String destination);

  // 恢复整合包
  Future<Modpack> restoreModpack(String backupPath);

  // 获取整合包的模组列表
  Future<List<Mod>> getModpackMods(String modpackId);

  // 向整合包添加模组
  Future<bool> addModToModpack(String modpackId, String modId, String version);

  // 从整合包移除模组
  Future<bool> removeModFromModpack(String modpackId, String modId);

  // 更新整合包中的模组
  Future<bool> updateModInModpack(String modpackId, String modId, String version);
}
