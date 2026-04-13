import '../models/content_models.dart';

abstract class IContentManager {
  // 搜索模组
  Future<List<Mod>> searchMods({
    required String query,
    String? gameVersion,
    String? modLoader,
    int page = 1,
    int pageSize = 20,
  });

  // 获取模组详情
  Future<Mod> getModDetails(String modId, {String? source});

  // 获取模组文件
  Future<List<ModFile>> getModFiles(String modId, {String? source});

  // 搜索整合包
  Future<List<Modpack>> searchModpacks({
    required String query,
    String? gameVersion,
    int page = 1,
    int pageSize = 20,
  });

  // 获取整合包详情
  Future<Modpack> getModpackDetails(String modpackId, {String? source});

  // 获取整合包文件
  Future<List<ModpackFile>> getModpackFiles(String modpackId, {String? source});

  // 下载模组
  Future<String> downloadMod(String modId, String fileId, String destination, {String? source});

  // 下载整合包
  Future<String> downloadModpack(String modpackId, String fileId, String destination, {String? source});

  // 获取游戏版本列表
  Future<List<GameVersion>> getGameVersions();

  // 获取模组加载器列表
  Future<List<ModLoader>> getModLoaders(String gameVersion);
}
