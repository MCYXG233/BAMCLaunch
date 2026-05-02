import '../app_event.dart';

/// 版本列表刷新事件
class VersionsRefreshedEvent extends AppEvent {
  final List<String> versionIds;

  VersionsRefreshedEvent({required this.versionIds});
}

/// 版本安装开始事件
class VersionInstallStartedEvent extends AppEvent {
  final String versionId;

  VersionInstallStartedEvent({required this.versionId});
}

/// 版本安装完成事件
class VersionInstallCompletedEvent extends AppEvent {
  final String versionId;

  VersionInstallCompletedEvent({required this.versionId});
}

/// 版本安装失败事件
class VersionInstallFailedEvent extends AppEvent {
  final String versionId;
  final String error;

  VersionInstallFailedEvent({
    required this.versionId,
    required this.error,
  });
}

/// 版本删除事件
class VersionDeletedEvent extends AppEvent {
  final String versionId;

  VersionDeletedEvent({required this.versionId});
}

/// 模组加载器安装事件
class ModLoaderInstallEvent extends AppEvent {
  final String versionId;
  final String loaderType;
  final String loaderVersion;

  ModLoaderInstallEvent({
    required this.versionId,
    required this.loaderType,
    required this.loaderVersion,
  });
}
