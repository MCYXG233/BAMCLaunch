import '../resource_center/index.dart';
import '../download/index.dart';

/// 事件基类
///
/// 所有自定义事件都应该继承此类
abstract class Event {
  /// 事件发生的时间戳
  final DateTime timestamp;

  Event() : timestamp = DateTime.now();
}

/// 日志事件
///
/// 用于记录系统日志信息
class LogEvent extends Event {
  /// 日志级别
  final LogLevel level;

  /// 日志消息
  final String message;

  /// 可选的错误信息
  final Object? error;

  /// 可选的堆栈跟踪
  final StackTrace? stackTrace;

  LogEvent({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

/// 日志级别枚举
enum LogLevel {
  /// 调试信息
  debug,

  /// 一般信息
  info,

  /// 警告信息
  warn,

  /// 错误信息
  error,
}

/// 任务相关事件基类
abstract class TaskEvent extends Event {
  /// 任务ID
  final String taskId;

  TaskEvent({required this.taskId});
}

/// 任务开始事件
class TaskStartedEvent extends TaskEvent {
  TaskStartedEvent({required super.taskId});
}

/// 任务完成事件
class TaskCompletedEvent extends TaskEvent {
  /// 任务执行结果（可选）
  final dynamic result;

  TaskCompletedEvent({required super.taskId, this.result});
}

/// 任务失败事件
class TaskFailedEvent extends TaskEvent {
  /// 错误信息
  final Object error;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  TaskFailedEvent({
    required super.taskId,
    required this.error,
    this.stackTrace,
  });
}

/// 任务进度更新事件
class TaskProgressEvent extends TaskEvent {
  /// 进度值（0.0 - 1.0）
  final double progress;

  /// 进度描述
  final String? description;

  TaskProgressEvent({
    required super.taskId,
    required this.progress,
    this.description,
  });
}

/// 配置变更事件
class ConfigChangedEvent extends Event {
  /// 配置键
  final String key;

  /// 新值
  final dynamic newValue;

  /// 旧值
  final dynamic oldValue;

  ConfigChangedEvent({
    required this.key,
    required this.newValue,
    this.oldValue,
  });
}

/// 账户相关事件基类
abstract class AccountEvent extends Event {}

/// 账户添加事件
class AccountAddedEvent extends AccountEvent {
  /// 新增的账户
  final String accountId;

  AccountAddedEvent({required this.accountId});
}

/// 账户更新事件
class AccountUpdatedEvent extends AccountEvent {
  /// 更新的账户ID
  final String accountId;

  AccountUpdatedEvent({required this.accountId});
}

/// 账户删除事件
class AccountDeletedEvent extends AccountEvent {
  /// 删除的账户ID
  final String accountId;

  AccountDeletedEvent({required this.accountId});
}

/// 选中账户变更事件
class SelectedAccountChangedEvent extends AccountEvent {
  /// 新选中的账户ID，可为空表示取消选中
  final String? newAccountId;

  /// 旧选中的账户ID，可为空表示之前未选中
  final String? oldAccountId;

  SelectedAccountChangedEvent({this.newAccountId, this.oldAccountId});
}

/// 下载相关事件基类
abstract class DownloadEvent extends Event {
  /// 任务ID
  final String taskId;

  DownloadEvent({required this.taskId});
}

/// 下载开始事件
class DownloadStartedEvent extends DownloadEvent {
  /// 文件URL
  final String url;

  /// 保存路径
  final String savePath;

  DownloadStartedEvent({
    required super.taskId,
    required this.url,
    required this.savePath,
  });
}

/// 下载完成事件
class DownloadCompletedEvent extends DownloadEvent {
  /// 文件URL
  final String url;

  /// 保存路径
  final String savePath;

  DownloadCompletedEvent({
    required super.taskId,
    required this.url,
    required this.savePath,
  });
}

/// 下载失败事件
class DownloadFailedEvent extends DownloadEvent {
  /// 文件URL
  final String url;

  /// 保存路径
  final String savePath;

  /// 错误信息
  final Object error;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  DownloadFailedEvent({
    required super.taskId,
    required this.url,
    required this.savePath,
    required this.error,
    this.stackTrace,
  });
}

/// 下载取消事件
class DownloadCancelledEvent extends DownloadEvent {
  DownloadCancelledEvent({required super.taskId});
}

/// 版本相关事件基类
abstract class VersionEvent extends Event {}

/// 版本列表获取事件
class VersionListFetchedEvent extends VersionEvent {
  /// 版本列表
  final List<String> versions;

  VersionListFetchedEvent({required this.versions});
}

/// 版本安装开始事件
class VersionInstallStartedEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  VersionInstallStartedEvent({required this.versionId});
}

/// 版本安装进度事件
class VersionInstallProgressEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  /// 进度（0.0 - 1.0）
  final double progress;

  /// 阶段
  final String stage;

  VersionInstallProgressEvent({
    required this.versionId,
    required this.progress,
    required this.stage,
  });
}

/// 版本安装完成事件
class VersionInstallCompletedEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  VersionInstallCompletedEvent({required this.versionId});
}

/// 版本安装失败事件
class VersionInstallFailedEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  /// 错误信息
  final Object error;

  VersionInstallFailedEvent({required this.versionId, required this.error});
}

/// 版本安装取消事件
class VersionInstallCancelledEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  VersionInstallCancelledEvent({required this.versionId});
}

/// 版本卸载事件
class VersionUninstalledEvent extends VersionEvent {
  /// 版本ID
  final String versionId;

  VersionUninstalledEvent({required this.versionId});
}

/// 已安装版本列表变化事件
class InstalledVersionsChangedEvent extends VersionEvent {
  /// 已安装版本列表
  final List<String> versions;

  InstalledVersionsChangedEvent({required this.versions});
}

/// Java相关事件基类
abstract class JavaEvent extends Event {}

/// Java安装列表变化事件
class JavaInstallationsChangedEvent extends JavaEvent {
  /// Java安装列表
  final List<String> installations;

  JavaInstallationsChangedEvent({required this.installations});
}

/// 选中的Java变化事件
class SelectedJavaChangedEvent extends JavaEvent {
  /// 新选中的Java路径
  final String? newJavaPath;

  /// 旧选中的Java路径
  final String? oldJavaPath;

  SelectedJavaChangedEvent({this.newJavaPath, this.oldJavaPath});
}

/// 游戏启动相关事件基类
abstract class GameLaunchEvent extends Event {}

/// 游戏启动事件
class GameLaunchedEvent extends GameLaunchEvent {
  /// 进程ID
  final String processId;

  /// 游戏版本
  final String version;

  /// 账户名
  final String username;

  GameLaunchedEvent({
    required this.processId,
    required this.version,
    required this.username,
  });
}

/// 游戏停止事件
class GameStoppedEvent extends GameLaunchEvent {
  /// 进程ID
  final String processId;

  /// 退出代码
  final int? exitCode;

  GameStoppedEvent({required this.processId, this.exitCode});
}

/// 游戏崩溃事件
class GameCrashedEvent extends GameLaunchEvent {
  /// 进程ID
  final String processId;

  /// 错误信息
  final String? error;

  /// 日志
  final List<String>? logs;

  GameCrashedEvent({required this.processId, this.error, this.logs});
}

/// 游戏就绪事件
class GameReadyEvent extends GameLaunchEvent {
  /// 进程ID
  final String processId;

  /// 游戏版本
  final String version;

  /// 账户名
  final String username;

  GameReadyEvent({
    required this.processId,
    required this.version,
    required this.username,
  });
}

/// 游玩时长记录事件
class PlayTimeRecordedEvent extends GameLaunchEvent {
  /// 游戏版本
  final String version;

  /// 游玩时长
  final Duration playTime;

  PlayTimeRecordedEvent({
    required this.version,
    required this.playTime,
  });
}

/// 实例相关事件基类
abstract class InstanceEvent extends Event {}

/// 实例创建事件
class InstanceCreatedEvent extends InstanceEvent {
  final String instanceId;

  InstanceCreatedEvent({required this.instanceId});
}

/// 实例更新事件
class InstanceUpdatedEvent extends InstanceEvent {
  final String instanceId;

  InstanceUpdatedEvent({required this.instanceId});
}

/// 实例删除事件
class InstanceDeletedEvent extends InstanceEvent {
  final String instanceId;

  InstanceDeletedEvent({required this.instanceId});
}

/// 选中实例变更事件
class SelectedInstanceChangedEvent extends InstanceEvent {
  final String? newInstanceId;
  final String? oldInstanceId;

  SelectedInstanceChangedEvent({this.newInstanceId, this.oldInstanceId});
}

/// 资源中心相关事件基类
abstract class ResourceCenterEvent extends Event {}

/// 搜索资源事件
class SearchResourcesEvent extends ResourceCenterEvent {
  /// 搜索参数
  final SearchParams params;

  SearchResourcesEvent({required this.params});
}

/// 搜索完成事件
class SearchCompletedEvent extends ResourceCenterEvent {
  /// 搜索结果
  final SearchResult result;

  SearchCompletedEvent({required this.result});
}

/// 搜索失败事件
class SearchFailedEvent extends ResourceCenterEvent {
  /// 错误信息
  final Object error;

  SearchFailedEvent({required this.error});
}

/// 获取资源详情事件
class GetResourceEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 资源来源
  final String source;

  GetResourceEvent({required this.resourceId, required this.source});
}

/// 获取资源详情完成事件
class ResourceRetrievedEvent extends ResourceCenterEvent {
  /// 资源详情
  final Resource resource;

  ResourceRetrievedEvent({required this.resource});
}

/// 获取资源版本列表事件
class GetVersionsEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 资源来源
  final String source;

  GetVersionsEvent({required this.resourceId, required this.source});
}

/// 获取资源版本列表完成事件
class VersionsRetrievedEvent extends ResourceCenterEvent {
  /// 版本列表
  final List<ResourceVersion> versions;

  VersionsRetrievedEvent({required this.versions});
}

/// 下载资源事件
class DownloadResourceEvent extends ResourceCenterEvent {
  /// 资源
  final Resource resource;

  /// 要下载的版本
  final ResourceVersion version;

  DownloadResourceEvent({required this.resource, required this.version});
}

/// 资源下载开始事件
class ResourceDownloadStartedEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 版本ID
  final String versionId;

  /// 任务ID
  final String taskId;

  ResourceDownloadStartedEvent({
    required this.resourceId,
    required this.versionId,
    required this.taskId,
  });
}

/// 资源下载进度事件
class ResourceDownloadProgressEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 版本ID
  final String versionId;

  /// 进度信息
  final DownloadProgress progress;

  ResourceDownloadProgressEvent({
    required this.resourceId,
    required this.versionId,
    required this.progress,
  });
}

/// 资源下载完成事件
class ResourceDownloadCompletedEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 版本ID
  final String versionId;

  /// 保存路径
  final String savePath;

  ResourceDownloadCompletedEvent({
    required this.resourceId,
    required this.versionId,
    required this.savePath,
  });
}

/// 资源下载失败事件
class ResourceDownloadFailedEvent extends ResourceCenterEvent {
  /// 资源ID
  final String resourceId;

  /// 版本ID
  final String versionId;

  /// 错误信息
  final Object error;

  ResourceDownloadFailedEvent({
    required this.resourceId,
    required this.versionId,
    required this.error,
  });
}

/// 资源安装事件
class ResourceInstalledEvent extends ResourceCenterEvent {
  /// 已安装的资源
  final InstalledResource resource;

  ResourceInstalledEvent({required this.resource});
}

/// 资源卸载事件
class ResourceUninstalledEvent extends ResourceCenterEvent {
  /// 本地资源ID
  final String localId;

  ResourceUninstalledEvent({required this.localId});
}

/// 资源启用/禁用事件
class ResourceToggledEvent extends ResourceCenterEvent {
  /// 本地资源ID
  final String localId;

  /// 是否启用
  final bool enabled;

  ResourceToggledEvent({required this.localId, required this.enabled});
}

/// 认证相关事件基类
abstract class AuthEvent extends Event {}

/// 认证开始事件
class AuthStartedEvent extends AuthEvent {}

/// 认证进度更新事件
class AuthProgressEvent extends AuthEvent {
  /// 当前认证步骤
  final String step;

  AuthProgressEvent({required this.step});
}

/// 认证成功事件
class AuthSuccessEvent extends AuthEvent {
  /// 账户ID
  final String accountId;

  /// 用户名
  final String username;

  AuthSuccessEvent({required this.accountId, required this.username});
}

/// 认证失败事件
class AuthFailedEvent extends AuthEvent {
  /// 错误信息
  final Object error;

  AuthFailedEvent({required this.error});
}

/// 登出事件
class LogoutEvent extends AuthEvent {
  /// 账户ID
  final String? accountId;

  LogoutEvent({this.accountId});
}

/// 令牌刷新开始事件
class TokenRefreshStartedEvent extends AuthEvent {}

/// 令牌刷新成功事件
class TokenRefreshSuccessEvent extends AuthEvent {}

/// 令牌刷新失败事件
class TokenRefreshFailedEvent extends AuthEvent {
  /// 错误信息
  final Object error;

  TokenRefreshFailedEvent({required this.error});
}

/// 加载器相关事件基类
abstract class LoaderEvent extends Event {}

/// 加载器状态变化事件
class LoaderStatusChangedEvent extends LoaderEvent {
  /// 实例ID
  final String instanceId;

  /// 新的加载器状态
  final String newStatus;

  /// 旧的加载器状态
  final String? oldStatus;

  LoaderStatusChangedEvent({
    required this.instanceId,
    required this.newStatus,
    this.oldStatus,
  });
}

/// 加载器安装开始事件
class LoaderInstallStartedEvent extends LoaderEvent {
  /// 实例ID
  final String instanceId;

  /// 加载器类型
  final String loaderType;

  /// 加载器版本
  final String loaderVersion;

  LoaderInstallStartedEvent({
    required this.instanceId,
    required this.loaderType,
    required this.loaderVersion,
  });
}

/// 加载器安装完成事件
class LoaderInstallCompletedEvent extends LoaderEvent {
  /// 实例ID
  final String instanceId;

  /// 加载器类型
  final String loaderType;

  /// 加载器版本
  final String loaderVersion;

  LoaderInstallCompletedEvent({
    required this.instanceId,
    required this.loaderType,
    required this.loaderVersion,
  });
}

/// 加载器安装失败事件
class LoaderInstallFailedEvent extends LoaderEvent {
  /// 实例ID
  final String instanceId;

  /// 错误信息
  final Object error;

  LoaderInstallFailedEvent({
    required this.instanceId,
    required this.error,
  });
}
