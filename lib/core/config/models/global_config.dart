class GlobalConfig {
  // 配置版本
  final String version;

  // 基本配置
  final BasicConfig basic;

  // 游戏配置
  final GameConfig game;

  // 下载配置
  final DownloadConfig download;

  // 账户配置
  final AccountConfig account;

  // UI配置
  final UiConfig ui;

  // 内容管理配置
  final ContentConfig content;

  GlobalConfig({
    required this.version,
    required this.basic,
    required this.game,
    required this.download,
    required this.account,
    required this.ui,
    required this.content,
  });

  factory GlobalConfig.defaultConfig() {
    return GlobalConfig(
      version: '1.0.0',
      basic: BasicConfig.defaultConfig(),
      game: GameConfig.defaultConfig(),
      download: DownloadConfig.defaultConfig(),
      account: AccountConfig.defaultConfig(),
      ui: UiConfig.defaultConfig(),
      content: ContentConfig.defaultConfig(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'basic': basic.toJson(),
      'game': game.toJson(),
      'download': download.toJson(),
      'account': account.toJson(),
      'ui': ui.toJson(),
      'content': content.toJson(),
    };
  }

  factory GlobalConfig.fromJson(Map<String, dynamic> json) {
    return GlobalConfig(
      version: json['version'] ?? '1.0.0',
      basic: BasicConfig.fromJson(json['basic'] ?? {}),
      game: GameConfig.fromJson(json['game'] ?? {}),
      download: DownloadConfig.fromJson(json['download'] ?? {}),
      account: AccountConfig.fromJson(json['account'] ?? {}),
      ui: UiConfig.fromJson(json['ui'] ?? {}),
      content: ContentConfig.fromJson(json['content'] ?? {}),
    );
  }
}

class BasicConfig {
  final String launcherVersion;
  final String language;
  final bool autoUpdate;
  final bool checkUpdateOnStartup;
  final String theme;
  final bool enableLogging;
  final String logLevel;

  BasicConfig({
    required this.launcherVersion,
    required this.language,
    required this.autoUpdate,
    required this.checkUpdateOnStartup,
    required this.theme,
    required this.enableLogging,
    required this.logLevel,
  });

  factory BasicConfig.defaultConfig() {
    return BasicConfig(
      launcherVersion: '1.0.0',
      language: 'zh_CN',
      autoUpdate: true,
      checkUpdateOnStartup: true,
      theme: 'default',
      enableLogging: true,
      logLevel: 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'launcherVersion': launcherVersion,
      'language': language,
      'autoUpdate': autoUpdate,
      'checkUpdateOnStartup': checkUpdateOnStartup,
      'theme': theme,
      'enableLogging': enableLogging,
      'logLevel': logLevel,
    };
  }

  factory BasicConfig.fromJson(Map<String, dynamic> json) {
    return BasicConfig(
      launcherVersion: json['launcherVersion'] ?? '1.0.0',
      language: json['language'] ?? 'zh_CN',
      autoUpdate: json['autoUpdate'] ?? true,
      checkUpdateOnStartup: json['checkUpdateOnStartup'] ?? true,
      theme: json['theme'] ?? 'default',
      enableLogging: json['enableLogging'] ?? true,
      logLevel: json['logLevel'] ?? 'info',
    );
  }
}

class GameConfig {
  final String javaPath;
  final int maxMemory;
  final int minMemory;
  final List<String> jvmArguments;
  final List<String> gameArguments;
  final bool enableFullscreen;
  final int windowWidth;
  final int windowHeight;
  final bool enableVsync;
  final bool enableMipmap;
  final String gameDirectory;

  GameConfig({
    required this.javaPath,
    required this.maxMemory,
    required this.minMemory,
    required this.jvmArguments,
    required this.gameArguments,
    required this.enableFullscreen,
    required this.windowWidth,
    required this.windowHeight,
    required this.enableVsync,
    required this.enableMipmap,
    required this.gameDirectory,
  });

  factory GameConfig.defaultConfig() {
    return GameConfig(
      javaPath: '',
      maxMemory: 2048,
      minMemory: 512,
      jvmArguments: [
        '-XX:+UseG1GC',
        '-XX:G1NewSizePercent=20',
        '-XX:G1ReservePercent=20',
        '-XX:MaxGCPauseMillis=50',
        '-XX:G1HeapRegionSize=32M',
      ],
      gameArguments: [],
      enableFullscreen: false,
      windowWidth: 854,
      windowHeight: 480,
      enableVsync: true,
      enableMipmap: true,
      gameDirectory: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'javaPath': javaPath,
      'maxMemory': maxMemory,
      'minMemory': minMemory,
      'jvmArguments': jvmArguments,
      'gameArguments': gameArguments,
      'enableFullscreen': enableFullscreen,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'enableVsync': enableVsync,
      'enableMipmap': enableMipmap,
      'gameDirectory': gameDirectory,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      javaPath: json['javaPath'] ?? '',
      maxMemory: json['maxMemory'] ?? 2048,
      minMemory: json['minMemory'] ?? 512,
      jvmArguments: List<String>.from(json['jvmArguments'] ?? []),
      gameArguments: List<String>.from(json['gameArguments'] ?? []),
      enableFullscreen: json['enableFullscreen'] ?? false,
      windowWidth: json['windowWidth'] ?? 854,
      windowHeight: json['windowHeight'] ?? 480,
      enableVsync: json['enableVsync'] ?? true,
      enableMipmap: json['enableMipmap'] ?? true,
      gameDirectory: json['gameDirectory'] ?? '',
    );
  }
}

class DownloadConfig {
  final String downloadSource;
  final int downloadThreads;
  final int downloadSpeedLimit;
  final bool enableProxy;
  final String proxyHost;
  final int proxyPort;
  final String proxyType;
  final bool enableBreakpointResume;
  final int retryCount;
  final int retryDelay;

  DownloadConfig({
    required this.downloadSource,
    required this.downloadThreads,
    required this.downloadSpeedLimit,
    required this.enableProxy,
    required this.proxyHost,
    required this.proxyPort,
    required this.proxyType,
    required this.enableBreakpointResume,
    required this.retryCount,
    required this.retryDelay,
  });

  factory DownloadConfig.defaultConfig() {
    return DownloadConfig(
      downloadSource: 'bmclapi',
      downloadThreads: 8,
      downloadSpeedLimit: 0, // 0表示不限速
      enableProxy: false,
      proxyHost: '127.0.0.1',
      proxyPort: 7890,
      proxyType: 'http',
      enableBreakpointResume: true,
      retryCount: 3,
      retryDelay: 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadSource': downloadSource,
      'downloadThreads': downloadThreads,
      'downloadSpeedLimit': downloadSpeedLimit,
      'enableProxy': enableProxy,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
      'proxyType': proxyType,
      'enableBreakpointResume': enableBreakpointResume,
      'retryCount': retryCount,
      'retryDelay': retryDelay,
    };
  }

  factory DownloadConfig.fromJson(Map<String, dynamic> json) {
    return DownloadConfig(
      downloadSource: json['downloadSource'] ?? 'bmclapi',
      downloadThreads: json['downloadThreads'] ?? 8,
      downloadSpeedLimit: json['downloadSpeedLimit'] ?? 0,
      enableProxy: json['enableProxy'] ?? false,
      proxyHost: json['proxyHost'] ?? '127.0.0.1',
      proxyPort: json['proxyPort'] ?? 7890,
      proxyType: json['proxyType'] ?? 'http',
      enableBreakpointResume: json['enableBreakpointResume'] ?? true,
      retryCount: json['retryCount'] ?? 3,
      retryDelay: json['retryDelay'] ?? 1000,
    );
  }
}

class AccountConfig {
  final String defaultAccountId;
  final bool autoLogin;
  final bool rememberPassword;
  final bool enableAuthlibInjector;
  final String authlibInjectorUrl;
  final bool enableSkinUpload;

  AccountConfig({
    required this.defaultAccountId,
    required this.autoLogin,
    required this.rememberPassword,
    required this.enableAuthlibInjector,
    required this.authlibInjectorUrl,
    required this.enableSkinUpload,
  });

  factory AccountConfig.defaultConfig() {
    return AccountConfig(
      defaultAccountId: '',
      autoLogin: false,
      rememberPassword: false,
      enableAuthlibInjector: false,
      authlibInjectorUrl: '',
      enableSkinUpload: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultAccountId': defaultAccountId,
      'autoLogin': autoLogin,
      'rememberPassword': rememberPassword,
      'enableAuthlibInjector': enableAuthlibInjector,
      'authlibInjectorUrl': authlibInjectorUrl,
      'enableSkinUpload': enableSkinUpload,
    };
  }

  factory AccountConfig.fromJson(Map<String, dynamic> json) {
    return AccountConfig(
      defaultAccountId: json['defaultAccountId'] ?? '',
      autoLogin: json['autoLogin'] ?? false,
      rememberPassword: json['rememberPassword'] ?? false,
      enableAuthlibInjector: json['enableAuthlibInjector'] ?? false,
      authlibInjectorUrl: json['authlibInjectorUrl'] ?? '',
      enableSkinUpload: json['enableSkinUpload'] ?? true,
    );
  }
}

class UiConfig {
  final bool enableCustomTitleBar;
  final bool enableTransparentWindow;
  final bool enableBlurEffect;
  final bool enableAnimation;
  final bool enableSound;
  final bool enableNotifications;
  final String sidebarWidth;
  final bool autoHideSidebar;
  final bool enableDarkMode;

  UiConfig({
    required this.enableCustomTitleBar,
    required this.enableTransparentWindow,
    required this.enableBlurEffect,
    required this.enableAnimation,
    required this.enableSound,
    required this.enableNotifications,
    required this.sidebarWidth,
    required this.autoHideSidebar,
    required this.enableDarkMode,
  });

  factory UiConfig.defaultConfig() {
    return UiConfig(
      enableCustomTitleBar: true,
      enableTransparentWindow: false,
      enableBlurEffect: true,
      enableAnimation: true,
      enableSound: true,
      enableNotifications: true,
      sidebarWidth: '200px',
      autoHideSidebar: false,
      enableDarkMode: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableCustomTitleBar': enableCustomTitleBar,
      'enableTransparentWindow': enableTransparentWindow,
      'enableBlurEffect': enableBlurEffect,
      'enableAnimation': enableAnimation,
      'enableSound': enableSound,
      'enableNotifications': enableNotifications,
      'sidebarWidth': sidebarWidth,
      'autoHideSidebar': autoHideSidebar,
      'enableDarkMode': enableDarkMode,
    };
  }

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      enableCustomTitleBar: json['enableCustomTitleBar'] ?? true,
      enableTransparentWindow: json['enableTransparentWindow'] ?? false,
      enableBlurEffect: json['enableBlurEffect'] ?? true,
      enableAnimation: json['enableAnimation'] ?? true,
      enableSound: json['enableSound'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      sidebarWidth: json['sidebarWidth'] ?? '200px',
      autoHideSidebar: json['autoHideSidebar'] ?? false,
      enableDarkMode: json['enableDarkMode'] ?? false,
    );
  }
}

class ContentConfig {
  final String defaultModSource;
  final String defaultResourcePackSource;
  final String defaultShaderPackSource;
  final bool enableAutoUpdateContent;
  final bool enableConflictDetection;
  final bool enableDependencyCheck;
  final String modInstallDirectory;
  final String resourcePackDirectory;
  final String shaderPackDirectory;

  ContentConfig({
    required this.defaultModSource,
    required this.defaultResourcePackSource,
    required this.defaultShaderPackSource,
    required this.enableAutoUpdateContent,
    required this.enableConflictDetection,
    required this.enableDependencyCheck,
    required this.modInstallDirectory,
    required this.resourcePackDirectory,
    required this.shaderPackDirectory,
  });

  factory ContentConfig.defaultConfig() {
    return ContentConfig(
      defaultModSource: 'modrinth',
      defaultResourcePackSource: 'modrinth',
      defaultShaderPackSource: 'modrinth',
      enableAutoUpdateContent: false,
      enableConflictDetection: true,
      enableDependencyCheck: true,
      modInstallDirectory: '',
      resourcePackDirectory: '',
      shaderPackDirectory: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultModSource': defaultModSource,
      'defaultResourcePackSource': defaultResourcePackSource,
      'defaultShaderPackSource': defaultShaderPackSource,
      'enableAutoUpdateContent': enableAutoUpdateContent,
      'enableConflictDetection': enableConflictDetection,
      'enableDependencyCheck': enableDependencyCheck,
      'modInstallDirectory': modInstallDirectory,
      'resourcePackDirectory': resourcePackDirectory,
      'shaderPackDirectory': shaderPackDirectory,
    };
  }

  factory ContentConfig.fromJson(Map<String, dynamic> json) {
    return ContentConfig(
      defaultModSource: json['defaultModSource'] ?? 'modrinth',
      defaultResourcePackSource:
          json['defaultResourcePackSource'] ?? 'modrinth',
      defaultShaderPackSource: json['defaultShaderPackSource'] ?? 'modrinth',
      enableAutoUpdateContent: json['enableAutoUpdateContent'] ?? false,
      enableConflictDetection: json['enableConflictDetection'] ?? true,
      enableDependencyCheck: json['enableDependencyCheck'] ?? true,
      modInstallDirectory: json['modInstallDirectory'] ?? '',
      resourcePackDirectory: json['resourcePackDirectory'] ?? '',
      shaderPackDirectory: json['shaderPackDirectory'] ?? '',
    );
  }
}
