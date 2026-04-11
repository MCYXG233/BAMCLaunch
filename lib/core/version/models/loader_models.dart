enum LoaderType {
  forge,
  fabric,
  quilt,
  neoForge,
}

enum LoaderInstallStatus {
  pending,
  downloading,
  installing,
  completed,
  failed,
  rolledBack,
}

class LoaderVersion {
  final String version;
  final String mcVersion;
  final String url;
  final String? sha1;
  final int? size;
  final DateTime releaseTime;

  LoaderVersion({
    required this.version,
    required this.mcVersion,
    required this.url,
    this.sha1,
    this.size,
    required this.releaseTime,
  });
}

class LoaderManifest {
  final LoaderType type;
  final List<LoaderVersion> versions;

  LoaderManifest({
    required this.type,
    required this.versions,
  });
}

class LoaderInstallResult {
  final bool success;
  final String versionId;
  final String? errorMessage;
  final LoaderInstallStatus status;

  LoaderInstallResult({
    required this.success,
    required this.versionId,
    this.errorMessage,
    required this.status,
  });
}

class LoaderCompatibilityInfo {
  final bool isCompatible;
  final String? reason;
  final List<String> compatibleLoaderVersions;

  LoaderCompatibilityInfo({
    required this.isCompatible,
    this.reason,
    required this.compatibleLoaderVersions,
  });
}