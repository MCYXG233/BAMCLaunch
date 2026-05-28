/// 配置键定义
/// 预定义所有配置项的键名，避免硬编码字符串
class ConfigKeys {
  /// 通用配置类
  static const String theme = 'theme';
  static const String themeMode = 'themeMode';
  static const String language = 'language';
  static const String autoUpdate = 'autoUpdate';
  static const String firstLaunch = 'firstLaunch';
  static const String windowWidth = 'windowWidth';
  static const String windowHeight = 'windowHeight';
  static const String enableSplashAnimation = 'enableSplashAnimation';
  static const String enableSoundEffects = 'enableSoundEffects';
  static const String launchAtStartup = 'launchAtStartup';
  static const String minimizeToTray = 'minimizeToTray';
  static const String closeToTray = 'closeToTray';

  /// 下载配置类
  static const String downloadPath = 'downloadPath';
  static const String concurrentDownloads = 'concurrentDownloads';
  static const String maxRetries = 'maxRetries';
  static const String downloadSource = 'downloadSource';
  static const String mirrorSourceIndex = 'mirrorSourceIndex';
  static const String autoSwitchMirror = 'autoSwitchMirror';
  static const String useProxy = 'useProxy';
  static const String proxyAddress = 'proxyAddress';
  static const String proxyPort = 'proxyPort';

  /// 游戏配置类
  static const String defaultVersion = 'defaultVersion';
  static const String javaPath = 'javaPath';
  static const String memory = 'memory';
  static const String memoryAllocation = 'memoryAllocation';
  static const String gameDirectory = 'gameDirectory';
  static const String jvmArguments = 'jvmArguments';
  static const String gameArguments = 'gameArguments';
  static const String fullscreen = 'fullscreen';
  static const String resolutionWidth = 'resolutionWidth';
  static const String resolutionHeight = 'resolutionHeight';

  /// 账户配置类
  static const String selectedAccount = 'selectedAccount';
  static const String accounts = 'accounts';

  /// 外置登录配置
  static const String authlibPath = 'authlibPath';
  static const String authlibServers = 'authlibServers';
  static const String authlibSelectedServer = 'authlibSelectedServer';
  static const String authlibAccounts = 'authlibAccounts';

  /// 加密相关配置前缀
  static const String encryptedPrefix = 'encrypted_';

  /// 版本相关配置
  static const String installedVersions = 'installedVersions';
  static const String selectedVersion = 'selectedVersion';

  /// 游戏启动配置
  static const String launchMemory = 'launchMemory';
  static const String launchJvmArgs = 'launchJvmArgs';
  static const String launchGameArgs = 'launchGameArgs';
  static const String launchFullscreen = 'launchFullscreen';
  static const String launchWidth = 'launchWidth';
  static const String launchHeight = 'launchHeight';
  static const String launchServerAddress = 'launchServerAddress';
  static const String launchServerPort = 'launchServerPort';

  /// 资源中心配置
  static const String resourceCenterSource = 'resourceCenterSource';
  static const String resourceCenterDefaultType = 'resourceCenterDefaultType';
  static const String resourceCenterSortBy = 'resourceCenterSortBy';
  static const String resourceCenterGameVersion = 'resourceCenterGameVersion';
  static const String resourceCenterModLoader = 'resourceCenterModLoader';
  static const String resourceCenterEnableCache = 'resourceCenterEnableCache';
  static const String resourceCenterCacheDuration = 'resourceCenterCacheDuration';
  static const String resourceCenterShowInstalledOnly = 'resourceCenterShowInstalledOnly';
  static const String resourceCenterAutoUpdateResources = 'resourceCenterAutoUpdateResources';

  static const String gameWindowSize = 'gameWindowSize';
  static const String autoRetryDownload = 'autoRetryDownload';
  static const String proxyHost = 'proxyHost';

  /// 启动器窗口配置
  static const String launcherVisibility = 'launcherVisibility';
  static const String fileValidatePolicy = 'fileValidatePolicy';
  static const String gcStrategy = 'gcStrategy';
}
