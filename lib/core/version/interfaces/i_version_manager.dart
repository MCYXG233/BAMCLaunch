import '../models/version_models.dart';
import '../models/loader_models.dart';

abstract class IVersionManager {
  Future<VersionManifest> getVersionManifest({bool forceRefresh = false});

  Future<List<Version>> getInstalledVersions();

  Future<Version> getVersionInfo(String versionId);

  Future<void> installVersion(String versionId, Function(double) onProgress);

  Future<void> uninstallVersion(String versionId);

  Future<bool> checkVersionIntegrity(String versionId);

  Future<void> repairVersion(String versionId);

  Future<Version> createCustomVersion({
    required String id,
    required String name,
    required String inheritsFrom,
    Map<String, dynamic>? customData,
  });

  Future<void> updateVersionStatus(String versionId, VersionStatus status);

  Future<List<VersionEntry>> searchVersions(String query);

  Future<void> downloadVersionAssets(String versionId, Function(double) onProgress);

  Future<List<LoaderVersion>> getLoaderVersions(
    LoaderType loaderType,
    String mcVersion,
  );

  Future<LoaderInstallResult> installLoader({
    required LoaderType loaderType,
    required String mcVersion,
    required String loaderVersion,
    Function(double)? onProgress,
    Function(LoaderInstallStatus)? onStatusChanged,
  });

  Future<LoaderCompatibilityInfo> checkLoaderCompatibility(
    LoaderType loaderType,
    String mcVersion,
    String loaderVersion,
  );

  Future<void> uninstallLoader(String versionId);

  Future<List<Version>> getInstalledLoaders();
}