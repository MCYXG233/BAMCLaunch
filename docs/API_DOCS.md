# BAMCLauncher API文档和架构设计

## 一、项目概述

BAMCLauncher是一个基于Flutter开发的跨平台Minecraft启动器，采用分层架构和模块化设计，实现了高内聚低耦合的系统架构。

### 核心特性

- **跨平台支持**：支持Windows、macOS、Linux三大桌面平台
- **模块化设计**：所有功能模块通过统一接口抽象，完全解耦
- **全栈自研**：核心能力完全自研，确保代码可控性和鲁棒性
- **高扩展性**：新增功能仅需实现对应接口，无需修改上层代码

## 二、系统架构

### 分层架构

```
┌─────────────────────────────────────────────────┐
│  UI层（自研BAMC UI Kit）                        │
├─────────────────────────────────────────────────┤
│  业务层（模块化功能单元）                        │
├─────────────────────────────────────────────────┤
│  核心适配层（统一接口抽象）                      │
├─────────────────────────────────────────────────┤
│  原生桥接层（平台专属实现）                      │
└─────────────────────────────────────────────────┘
```

### 模块关系图

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Platform      │◄───►│    Account      │◄───►│    Version      │
│  Adapter        │     │   Manager       │     │    Manager      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
          ▲                        ▲                        ▲
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Download      │◄───►│    Game         │◄───►│    Content      │
│   Engine        │     │   Launcher      │     │    Manager      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
          ▲                        ▲                        ▲
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Modpack       │◄───►│    Server       │◄───►│    Config       │
│   Manager       │     │   Manager       │     │    Manager      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
          ▲                        ▲                        ▲
          │                        │                        │
          └────────────────────────┴────────────────────────┘
                                      │
                                      ▼
                              ┌─────────────────┐
                              │    Logger       │
                              └─────────────────┘
```

## 三、核心接口定义

### 1. 平台适配接口 (IPlatformAdapter)

```dart
abstract class IPlatformAdapter {
  // 目录路径
  String get appDataDirectory;
  String get cacheDirectory;
  String get configDirectory;
  String get logsDirectory;
  String get gameDirectory;
  
  // Java相关
  List<String> get javaPaths;
  Future<String?> findJava();
  
  // 文件操作
  Future<bool> isDirectory(String path);
  Future<bool> isFile(String path);
  Future<void> createDirectory(String path);
  Future<void> delete(String path, {bool recursive = false});
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<List<String>> listFiles(String directory);
  Future<List<String>> listDirectories(String directory);
  
  // 进程管理
  Future<Process> startProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});
  Future<int> runProcess(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment});
  Future<bool> killProcess(int pid);
  Future<bool> isProcessRunning(int pid);
  
  // 系统信息
  String getPlatformName();
  String getPlatformVersion();
  Future<bool> setAutoStartup(bool enabled);
  Future<bool> isAutoStartupEnabled();
  Future<String> getUsername();
  Future<String> getHostname();
  Future<String?> getEnvironmentVariable(String name);
  Future<void> setEnvironmentVariable(String name, String value);
  Future<String> getExecutablePath();
  Future<bool> isElevated();
}
```

### 2. 账户认证接口 (IAuthenticator)

```dart
abstract class IAuthenticator {
  Future<Account> login(Map<String, dynamic> credentials);
  Future<Account> refresh(Account account);
  Future<MinecraftProfile> getProfile(Account account);
  Future<void> logout(Account account);
  bool canRefresh(Account account);
  AccountType get accountType;
}
```

### 3. 版本管理接口 (IVersionManager)

```dart
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
  
  // 模组加载器相关
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
```

### 4. 下载引擎接口 (IDownloadEngine)

```dart
abstract class IDownloadEngine {
  Future<void> downloadFile(
    String url,
    String savePath, {
    List<IDownloadSource>? sources,
    String? checksum,
    String? checksumType,
    int maxRetries = 3,
    int chunkSize = 1024 * 1024,
    int maxThreads = 4,
    Function(double)? onProgress,
    Function(String)? onError,
  });
  Future<bool> verifyFile(String filePath, String checksum, String checksumType);
  void cancelDownload(String url);
  bool isDownloading(String url);
  double getProgress(String url);
}
```

### 5. 游戏启动接口 (IGameLauncher)

```dart
abstract class IGameLauncher {
  Future<JavaDetectionResult> detectJava();
  Future<String> optimizeJvmParameters(String gameVersion, int memoryMb);
  Future<Process> launchGame(GameLaunchConfig config);
  Stream<String> getGameOutput();
  Stream<ProcessSignal> getProcessSignals();
  Future<void> killProcess();
  bool get isProcessRunning;
}
```

### 6. 内容管理接口 (IContentManager)

```dart
abstract class IContentManager {
  Future<SearchResult> searchContent(SearchQuery query);
  Future<ContentInstallResult> installContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  });
  Future<ContentInstallResult> updateContent({
    required ContentItem item,
    required String versionId,
    Function(double)? onProgress,
  });
  Future<void> uninstallContent(String contentId, ContentType type);
  Future<List<ContentItem>> getInstalledContent(ContentType type);
  Future<List<ContentItem>> checkForUpdates(ContentType type);
  Future<List<ConflictInfo>> checkConflicts(ContentItem item);
  Future<DependencyInfo> checkDependencies(ContentItem item);
  Future<List<ContentDependency>> resolveDependencies(List<ContentDependency> dependencies);
  Future<void> installDependencies(List<ContentDependency> dependencies);
  Future<ContentItem> getContentDetails(String contentId, ContentSource source);
  Future<List<ContentItem>> getPopularContent(ContentType type, {int limit = 10});
  Future<List<ContentItem>> getFeaturedContent(ContentType type, {int limit = 10});
  Future<void> refreshContentCache();
  Future<bool> isContentInstalled(String contentId, ContentType type);
  Future<String?> getInstalledVersion(String contentId, ContentType type);
  Future<void> validateContentIntegrity(String contentId, ContentType type);
}
```

### 7. 整合包管理接口 (IModpackManager)

```dart
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
```

### 8. 服务器管理接口 (IServerManager)

```dart
abstract class IServerManager {
  Future<List<ServerInfo>> getServerList();
  Future<void> addServer(ServerInfo server);
  Future<void> updateServer(ServerInfo server);
  Future<void> deleteServer(String serverId);
  Future<ServerStatus> getServerStatus(String address, int port);
  Future<void> connectToServer(String serverId);
  Future<void> startLanServer(String worldName, int port);
  Future<void> stopLanServer();
  bool get isLanServerRunning;
  Future<void> refreshServerList();
  Future<void> importServerList(String filePath);
  Future<void> exportServerList(String filePath);
}
```

### 9. 配置管理接口 (IConfigManager)

```dart
abstract class IConfigManager {
  Future<T?> get<T>(String key, {T? defaultValue});
  Future<void> set<T>(String key, T value);
  Future<void> remove(String key);
  Future<bool> contains(String key);
  Future<void> clear();
  Future<void> save();
  Future<void> load();
  Future<void> resetToDefaults();
  Future<void> backupConfig(String backupPath);
  Future<void> restoreConfig(String backupPath);
}
```

### 10. 日志接口 (ILogger)

```dart
abstract class ILogger {
  void debug(String message, {Map<String, dynamic>? context});
  void info(String message, {Map<String, dynamic>? context});
  void warning(String message, {Map<String, dynamic>? context});
  void error(String message, {dynamic error, StackTrace? stackTrace});
  void fatal(String message, {dynamic error, StackTrace? stackTrace});
  void setLogLevel(LogLevel level);
  LogLevel getLogLevel();
  Future<void> flush();
  Future<void> close();
}
```

## 四、技术栈说明

### 核心技术

- **Flutter 3.22+**：跨平台UI框架，桌面端支持成熟
- **Dart SDK 3.0+**：利用空安全、模式匹配等特性
- **window_manager**：窗口管理、托盘、标题栏自定义
- **crypto**：哈希校验、AES加密
- **archive**：压缩包解压/打包
- **sqflite_common_ffi**：本地元数据存储
- **xml**：XML配置解析

### 架构特点

1. **接口抽象**：所有模块通过统一接口对外提供能力
2. **依赖注入**：通过工厂模式创建具体实现
3. **事件驱动**：使用全局事件总线实现模块间通信
4. **异步处理**：耗时操作放入独立Isolate执行
5. **错误处理**：全局异常捕获，分级错误处理

## 五、模块实现说明

### 平台适配模块

- **WindowsPlatformAdapter**：Windows平台实现
- **MacOSPlatformAdapter**：macOS平台实现  
- **LinuxPlatformAdapter**：Linux平台实现
- **PlatformAdapterFactory**：根据运行平台创建对应适配器

### 账户认证模块

- **MicrosoftAuthenticator**：微软OAuth2登录实现
- **OfflineAuthenticator**：离线账户实现
- **AccountManager**：账户管理，支持多账户切换

### 版本管理模块

- **VersionManager**：版本下载、安装、管理
- **支持的加载器**：Forge、Fabric、Quilt、NeoForge、LiteLoader

### 下载引擎模块

- **DownloadEngine**：多线程分块下载引擎
- **DownloadSource**：下载源管理，支持多镜像源切换
- **支持的镜像源**：官方、BMCLAPI、MCBBS等

### 游戏启动模块

- **GameLauncher**：游戏启动核心逻辑
- **Java检测**：自动检测系统Java环境
- **JVM参数优化**：根据游戏版本和内存自动优化

## 六、扩展开发指南

### 添加新功能模块

1. 定义模块接口（如 `INewFeature`）
2. 实现具体类（如 `NewFeatureImpl`）
3. 在工厂类中注册实现
4. 在业务层使用接口

### 添加新平台支持

1. 实现 `IPlatformAdapter` 接口
2. 在 `PlatformAdapterFactory` 中添加平台判断逻辑
3. 处理平台特定的路径和系统调用

### 添加新的认证方式

1. 实现 `IAuthenticator` 接口
2. 在 `AccountManager` 中注册新的认证器
3. 更新账户模型和UI界面

## 七、性能优化建议

1. **内存管理**：使用流处理大文件，图片懒加载
2. **UI优化**：使用const构造函数，列表懒加载
3. **异步处理**：耗时操作放入独立Isolate
4. **缓存策略**：合理使用内存缓存和磁盘缓存
5. **网络优化**：实现请求合并、重试机制

## 八、安全注意事项

1. **敏感信息加密**：账户令牌使用AES-256加密存储
2. **HTTPS通信**：所有网络请求使用HTTPS
3. **权限最小化**：仅申请必要的系统权限
4. **输入验证**：所有用户输入进行严格验证
5. **日志脱敏**：确保日志中不包含敏感信息