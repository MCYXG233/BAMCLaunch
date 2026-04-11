import '../models/modpack_models.dart';

abstract class IModpackManager {
  Future<List<Modpack>> getInstalledModpacks();

  Future<ModpackManifest> parseModpack(String filePath);

  Future<ModpackImportResult> importModpack({
    required String filePath,
    Function(ModpackImportProgress)? onProgress,
  });

  Future<ModpackInstallResult> installModpack({
    required Modpack modpack,
    Function(double)? onProgress,
  });

  Future<void> uninstallModpack(String modpackId);

  Future<ModpackExportResult> exportModpack({
    required String modpackId,
    required String exportPath,
    required ModpackFormat format,
    Function(double)? onProgress,
  });

  Future<Modpack> createModpack(ModpackCreateOptions options);

  Future<Modpack> getModpackInfo(String modpackId);

  Future<bool> checkModpackIntegrity(String modpackId);

  Future<void> repairModpack(String modpackId);

  Future<List<Modpack>> searchModpacks(String query);

  Future<void> refreshModpackCache();

  Future<bool> isModpackInstalled(String modpackId);

  Future<void> updateModpackStatus(String modpackId, ModpackStatus status);

  Future<ModpackFormat> detectModpackFormat(String filePath);
}