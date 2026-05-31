import 'dart:convert';

/// 垃圾回收器类型
enum GarbageCollector {
  g1gc,
  zgc,
  shenandoah,
  parallel,
  serial,
  auto,
}

/// 文件验证策略
enum FileValidatePolicy {
  disable,
  full,
  normal,
}

/// 启动器可见性
enum LauncherVisibility {
  startHidden,
  runningHidden,
  always,
}

/// 进程优先级
enum ProcessPriority {
  low,
  belowNormal,
  normal,
  aboveNormal,
  high,
}

/// 内存信息
class MemoryInfo {
  final int total;
  final int used;
  final int suggestedMaxAlloc;

  MemoryInfo({
    required this.total,
    required this.used,
    required this.suggestedMaxAlloc,
  });

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'used': used,
      'suggestedMaxAlloc': suggestedMaxAlloc,
    };
  }

  factory MemoryInfo.fromJson(Map<String, dynamic> json) {
    return MemoryInfo(
      total: json['total'] as int,
      used: json['used'] as int,
      suggestedMaxAlloc: json['suggestedMaxAlloc'] as int,
    );
  }
}

/// 分辨率配置
class Resolution {
  final int width;
  final int height;
  final bool fullscreen;

  Resolution({
    required this.width,
    required this.height,
    this.fullscreen = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'fullscreen': fullscreen,
    };
  }

  factory Resolution.fromJson(Map<String, dynamic> json) {
    return Resolution(
      width: json['width'] as int? ?? 854,
      height: json['height'] as int? ?? 480,
      fullscreen: json['fullscreen'] as bool? ?? false,
    );
  }

  Resolution copyWith({
    int? width,
    int? height,
    bool? fullscreen,
  }) {
    return Resolution(
      width: width ?? this.width,
      height: height ?? this.height,
      fullscreen: fullscreen ?? this.fullscreen,
    );
  }
}

/// Java配置
class JavaConfig {
  final bool auto;
  final String execPath;

  JavaConfig({
    this.auto = true,
    this.execPath = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'auto': auto,
      'execPath': execPath,
    };
  }

  factory JavaConfig.fromJson(Map<String, dynamic> json) {
    return JavaConfig(
      auto: json['auto'] as bool? ?? true,
      execPath: json['execPath'] as String? ?? '',
    );
  }

  JavaConfig copyWith({
    bool? auto,
    String? execPath,
  }) {
    return JavaConfig(
      auto: auto ?? this.auto,
      execPath: execPath ?? this.execPath,
    );
  }
}

/// 游戏窗口配置
class GameWindowConfig {
  final Resolution resolution;
  final String customTitle;
  final String customInfo;

  GameWindowConfig({
    required this.resolution,
    this.customTitle = '',
    this.customInfo = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'resolution': resolution.toJson(),
      'customTitle': customTitle,
      'customInfo': customInfo,
    };
  }

  factory GameWindowConfig.fromJson(Map<String, dynamic> json) {
    return GameWindowConfig(
      resolution: json['resolution'] != null
          ? Resolution.fromJson(json['resolution'] as Map<String, dynamic>)
          : Resolution(width: 854, height: 480),
      customTitle: json['customTitle'] as String? ?? '',
      customInfo: json['customInfo'] as String? ?? '',
    );
  }

  GameWindowConfig copyWith({
    Resolution? resolution,
    String? customTitle,
    String? customInfo,
  }) {
    return GameWindowConfig(
      resolution: resolution ?? this.resolution,
      customTitle: customTitle ?? this.customTitle,
      customInfo: customInfo ?? this.customInfo,
    );
  }
}

/// 性能配置
class PerformanceConfig {
  final bool autoMemAllocation;
  final int maxMemAllocation;
  final ProcessPriority processPriority;

  PerformanceConfig({
    this.autoMemAllocation = true,
    this.maxMemAllocation = 1024,
    this.processPriority = ProcessPriority.normal,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoMemAllocation': autoMemAllocation,
      'maxMemAllocation': maxMemAllocation,
      'processPriority': processPriority.name,
    };
  }

  factory PerformanceConfig.fromJson(Map<String, dynamic> json) {
    return PerformanceConfig(
      autoMemAllocation: json['autoMemAllocation'] as bool? ?? true,
      maxMemAllocation: json['maxMemAllocation'] as int? ?? 1024,
      processPriority: _parseProcessPriority(json['processPriority'] as String?),
    );
  }

  static ProcessPriority _parseProcessPriority(String? value) {
    if (value == null) return ProcessPriority.normal;
    return ProcessPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProcessPriority.normal,
    );
  }

  PerformanceConfig copyWith({
    bool? autoMemAllocation,
    int? maxMemAllocation,
    ProcessPriority? processPriority,
  }) {
    return PerformanceConfig(
      autoMemAllocation: autoMemAllocation ?? this.autoMemAllocation,
      maxMemAllocation: maxMemAllocation ?? this.maxMemAllocation,
      processPriority: processPriority ?? this.processPriority,
    );
  }
}

/// 游戏服务器配置
class GameServerConfig {
  final bool autoJoin;
  final String serverAddress;
  final int serverPort;

  GameServerConfig({
    this.autoJoin = false,
    this.serverAddress = '',
    this.serverPort = 25565,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoJoin': autoJoin,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
    };
  }

  factory GameServerConfig.fromJson(Map<String, dynamic> json) {
    return GameServerConfig(
      autoJoin: json['autoJoin'] as bool? ?? false,
      serverAddress: json['serverAddress'] as String? ?? '',
      serverPort: json['serverPort'] as int? ?? 25565,
    );
  }

  GameServerConfig copyWith({
    bool? autoJoin,
    String? serverAddress,
    int? serverPort,
  }) {
    return GameServerConfig(
      autoJoin: autoJoin ?? this.autoJoin,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
    );
  }
}

/// JVM配置
class JVMConfig {
  final GarbageCollector garbageCollector;
  final int javaPermanentGenerationSpace;
  final String environmentVariable;
  final String args;

  JVMConfig({
    this.garbageCollector = GarbageCollector.auto,
    this.javaPermanentGenerationSpace = 128,
    this.environmentVariable = '',
    this.args = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'garbageCollector': garbageCollector.name,
      'javaPermanentGenerationSpace': javaPermanentGenerationSpace,
      'environmentVariable': environmentVariable,
      'args': args,
    };
  }

  factory JVMConfig.fromJson(Map<String, dynamic> json) {
    return JVMConfig(
      garbageCollector: _parseGC(json['garbageCollector'] as String?),
      javaPermanentGenerationSpace: json['javaPermanentGenerationSpace'] as int? ?? 128,
      environmentVariable: json['environmentVariable'] as String? ?? '',
      args: json['args'] as String? ?? '',
    );
  }

  static GarbageCollector _parseGC(String? value) {
    if (value == null) return GarbageCollector.auto;
    return GarbageCollector.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GarbageCollector.auto,
    );
  }

  JVMConfig copyWith({
    GarbageCollector? garbageCollector,
    int? javaPermanentGenerationSpace,
    String? environmentVariable,
    String? args,
  }) {
    return JVMConfig(
      garbageCollector: garbageCollector ?? this.garbageCollector,
      javaPermanentGenerationSpace: javaPermanentGenerationSpace ?? this.javaPermanentGenerationSpace,
      environmentVariable: environmentVariable ?? this.environmentVariable,
      args: args ?? this.args,
    );
  }
}

/// 自定义命令配置
class CustomCommands {
  final String minecraftArgument;
  final String precallCommand;
  final String wrapperLauncher;
  final String postExitCommand;

  CustomCommands({
    this.minecraftArgument = '',
    this.precallCommand = '',
    this.wrapperLauncher = '',
    this.postExitCommand = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'minecraftArgument': minecraftArgument,
      'precallCommand': precallCommand,
      'wrapperLauncher': wrapperLauncher,
      'postExitCommand': postExitCommand,
    };
  }

  factory CustomCommands.fromJson(Map<String, dynamic> json) {
    return CustomCommands(
      minecraftArgument: json['minecraftArgument'] as String? ?? '',
      precallCommand: json['precallCommand'] as String? ?? '',
      wrapperLauncher: json['wrapperLauncher'] as String? ?? '',
      postExitCommand: json['postExitCommand'] as String? ?? '',
    );
  }

  CustomCommands copyWith({
    String? minecraftArgument,
    String? precallCommand,
    String? wrapperLauncher,
    String? postExitCommand,
  }) {
    return CustomCommands(
      minecraftArgument: minecraftArgument ?? this.minecraftArgument,
      precallCommand: precallCommand ?? this.precallCommand,
      wrapperLauncher: wrapperLauncher ?? this.wrapperLauncher,
      postExitCommand: postExitCommand ?? this.postExitCommand,
    );
  }
}

/// 游戏兼容配置
class GameWorkaroundConfig {
  final bool noJvmArgs;
  final FileValidatePolicy fileValidatePolicy;
  final bool dontCheckJvmValidity;
  final bool dontPatchNatives;
  final bool useLwjglUnsafeAgent;
  final bool useNativeGlfw;
  final bool useNativeOpenal;

  GameWorkaroundConfig({
    this.noJvmArgs = false,
    this.fileValidatePolicy = FileValidatePolicy.normal,
    this.dontCheckJvmValidity = false,
    this.dontPatchNatives = false,
    this.useLwjglUnsafeAgent = true,
    this.useNativeGlfw = false,
    this.useNativeOpenal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'noJvmArgs': noJvmArgs,
      'fileValidatePolicy': fileValidatePolicy.name,
      'dontCheckJvmValidity': dontCheckJvmValidity,
      'dontPatchNatives': dontPatchNatives,
      'useLwjglUnsafeAgent': useLwjglUnsafeAgent,
      'useNativeGlfw': useNativeGlfw,
      'useNativeOpenal': useNativeOpenal,
    };
  }

  factory GameWorkaroundConfig.fromJson(Map<String, dynamic> json) {
    return GameWorkaroundConfig(
      noJvmArgs: json['noJvmArgs'] as bool? ?? false,
      fileValidatePolicy: _parseFileValidatePolicy(json['fileValidatePolicy'] as String?),
      dontCheckJvmValidity: json['dontCheckJvmValidity'] as bool? ?? false,
      dontPatchNatives: json['dontPatchNatives'] as bool? ?? false,
      useLwjglUnsafeAgent: json['useLwjglUnsafeAgent'] as bool? ?? true,
      useNativeGlfw: json['useNativeGlfw'] as bool? ?? false,
      useNativeOpenal: json['useNativeOpenal'] as bool? ?? false,
    );
  }

  static FileValidatePolicy _parseFileValidatePolicy(String? value) {
    if (value == null) return FileValidatePolicy.normal;
    return FileValidatePolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FileValidatePolicy.normal,
    );
  }

  GameWorkaroundConfig copyWith({
    bool? noJvmArgs,
    FileValidatePolicy? fileValidatePolicy,
    bool? dontCheckJvmValidity,
    bool? dontPatchNatives,
    bool? useLwjglUnsafeAgent,
    bool? useNativeGlfw,
    bool? useNativeOpenal,
  }) {
    return GameWorkaroundConfig(
      noJvmArgs: noJvmArgs ?? this.noJvmArgs,
      fileValidatePolicy: fileValidatePolicy ?? this.fileValidatePolicy,
      dontCheckJvmValidity: dontCheckJvmValidity ?? this.dontCheckJvmValidity,
      dontPatchNatives: dontPatchNatives ?? this.dontPatchNatives,
      useLwjglUnsafeAgent: useLwjglUnsafeAgent ?? this.useLwjglUnsafeAgent,
      useNativeGlfw: useNativeGlfw ?? this.useNativeGlfw,
      useNativeOpenal: useNativeOpenal ?? this.useNativeOpenal,
    );
  }
}

/// 高级配置
class AdvancedConfig {
  final CustomCommands customCommands;
  final JVMConfig jvm;
  final GameWorkaroundConfig workaround;
  final bool enabled;

  AdvancedConfig({
    required this.customCommands,
    required this.jvm,
    required this.workaround,
    this.enabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'customCommands': customCommands.toJson(),
      'jvm': jvm.toJson(),
      'workaround': workaround.toJson(),
      'enabled': enabled,
    };
  }

  factory AdvancedConfig.fromJson(Map<String, dynamic> json) {
    return AdvancedConfig(
      customCommands: json['customCommands'] != null
          ? CustomCommands.fromJson(json['customCommands'] as Map<String, dynamic>)
          : CustomCommands(),
      jvm: json['jvm'] != null
          ? JVMConfig.fromJson(json['jvm'] as Map<String, dynamic>)
          : JVMConfig(),
      workaround: json['workaround'] != null
          ? GameWorkaroundConfig.fromJson(json['workaround'] as Map<String, dynamic>)
          : GameWorkaroundConfig(),
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  AdvancedConfig copyWith({
    CustomCommands? customCommands,
    JVMConfig? jvm,
    GameWorkaroundConfig? workaround,
    bool? enabled,
  }) {
    return AdvancedConfig(
      customCommands: customCommands ?? this.customCommands,
      jvm: jvm ?? this.jvm,
      workaround: workaround ?? this.workaround,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// 游戏配置
class GameConfig {
  final JavaConfig gameJava;
  final GameWindowConfig gameWindow;
  final PerformanceConfig performance;
  final GameServerConfig gameServer;
  final bool versionIsolation;
  final LauncherVisibility launcherVisibility;
  final bool displayGameLog;
  final AdvancedConfig advanced;

  GameConfig({
    required this.gameJava,
    required this.gameWindow,
    required this.performance,
    required this.gameServer,
    this.versionIsolation = true,
    this.launcherVisibility = LauncherVisibility.always,
    this.displayGameLog = true,
    required this.advanced,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameJava': gameJava.toJson(),
      'gameWindow': gameWindow.toJson(),
      'performance': performance.toJson(),
      'gameServer': gameServer.toJson(),
      'versionIsolation': versionIsolation,
      'launcherVisibility': launcherVisibility.name,
      'displayGameLog': displayGameLog,
      'advanced': advanced.toJson(),
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      gameJava: json['gameJava'] != null
          ? JavaConfig.fromJson(json['gameJava'] as Map<String, dynamic>)
          : JavaConfig(),
      gameWindow: json['gameWindow'] != null
          ? GameWindowConfig.fromJson(json['gameWindow'] as Map<String, dynamic>)
          : GameWindowConfig(resolution: Resolution(width: 854, height: 480)),
      performance: json['performance'] != null
          ? PerformanceConfig.fromJson(json['performance'] as Map<String, dynamic>)
          : PerformanceConfig(),
      gameServer: json['gameServer'] != null
          ? GameServerConfig.fromJson(json['gameServer'] as Map<String, dynamic>)
          : GameServerConfig(),
      versionIsolation: json['versionIsolation'] as bool? ?? true,
      launcherVisibility: _parseLauncherVisibility(json['launcherVisibility'] as String?),
      displayGameLog: json['displayGameLog'] as bool? ?? true,
      advanced: json['advanced'] != null
          ? AdvancedConfig.fromJson(json['advanced'] as Map<String, dynamic>)
          : AdvancedConfig(
              customCommands: CustomCommands(),
              jvm: JVMConfig(),
              workaround: GameWorkaroundConfig(),
            ),
    );
  }

  static LauncherVisibility _parseLauncherVisibility(String? value) {
    if (value == null) return LauncherVisibility.always;
    return LauncherVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LauncherVisibility.always,
    );
  }

  GameConfig copyWith({
    JavaConfig? gameJava,
    GameWindowConfig? gameWindow,
    PerformanceConfig? performance,
    GameServerConfig? gameServer,
    bool? versionIsolation,
    LauncherVisibility? launcherVisibility,
    bool? displayGameLog,
    AdvancedConfig? advanced,
  }) {
    return GameConfig(
      gameJava: gameJava ?? this.gameJava,
      gameWindow: gameWindow ?? this.gameWindow,
      performance: performance ?? this.performance,
      gameServer: gameServer ?? this.gameServer,
      versionIsolation: versionIsolation ?? this.versionIsolation,
      launcherVisibility: launcherVisibility ?? this.launcherVisibility,
      displayGameLog: displayGameLog ?? this.displayGameLog,
      advanced: advanced ?? this.advanced,
    );
  }
}

/// 主题配置
class ThemeConfig {
  final String primaryColor;
  final String colorMode;
  final bool useLiquidGlassDesign;
  final String headNavStyle;

  ThemeConfig({
    this.primaryColor = 'blue',
    this.colorMode = 'light',
    this.useLiquidGlassDesign = true,
    this.headNavStyle = 'adaptive',
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'colorMode': colorMode,
      'useLiquidGlassDesign': useLiquidGlassDesign,
      'headNavStyle': headNavStyle,
    };
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColor: json['primaryColor'] as String? ?? 'blue',
      colorMode: json['colorMode'] as String? ?? 'light',
      useLiquidGlassDesign: json['useLiquidGlassDesign'] as bool? ?? true,
      headNavStyle: json['headNavStyle'] as String? ?? 'adaptive',
    );
  }

  ThemeConfig copyWith({
    String? primaryColor,
    String? colorMode,
    bool? useLiquidGlassDesign,
    String? headNavStyle,
  }) {
    return ThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      colorMode: colorMode ?? this.colorMode,
      useLiquidGlassDesign: useLiquidGlassDesign ?? this.useLiquidGlassDesign,
      headNavStyle: headNavStyle ?? this.headNavStyle,
    );
  }
}

/// 字体配置
class FontConfig {
  final String fontFamily;
  final int fontSize;

  FontConfig({
    this.fontFamily = '%built-in',
    this.fontSize = 100,
  });

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
    };
  }

  factory FontConfig.fromJson(Map<String, dynamic> json) {
    return FontConfig(
      fontFamily: json['fontFamily'] as String? ?? '%built-in',
      fontSize: json['fontSize'] as int? ?? 100,
    );
  }

  FontConfig copyWith({
    String? fontFamily,
    int? fontSize,
  }) {
    return FontConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// 外观背景配置
class AppearanceBackgroundConfig {
  final String choice;
  final bool randomCustom;
  final bool autoDarken;

  AppearanceBackgroundConfig({
    this.choice = '%built-in:Florwyn',
    this.randomCustom = false,
    this.autoDarken = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'choice': choice,
      'randomCustom': randomCustom,
      'autoDarken': autoDarken,
    };
  }

  factory AppearanceBackgroundConfig.fromJson(Map<String, dynamic> json) {
    return AppearanceBackgroundConfig(
      choice: json['choice'] as String? ?? '%built-in:Florwyn',
      randomCustom: json['randomCustom'] as bool? ?? false,
      autoDarken: json['autoDarken'] as bool? ?? false,
    );
  }

  AppearanceBackgroundConfig copyWith({
    String? choice,
    bool? randomCustom,
    bool? autoDarken,
  }) {
    return AppearanceBackgroundConfig(
      choice: choice ?? this.choice,
      randomCustom: randomCustom ?? this.randomCustom,
      autoDarken: autoDarken ?? this.autoDarken,
    );
  }
}

/// 辅助功能配置
class AccessibilityConfig {
  final bool invertColors;
  final bool enhanceContrast;

  AccessibilityConfig({
    this.invertColors = false,
    this.enhanceContrast = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'invertColors': invertColors,
      'enhanceContrast': enhanceContrast,
    };
  }

  factory AccessibilityConfig.fromJson(Map<String, dynamic> json) {
    return AccessibilityConfig(
      invertColors: json['invertColors'] as bool? ?? false,
      enhanceContrast: json['enhanceContrast'] as bool? ?? false,
    );
  }

  AccessibilityConfig copyWith({
    bool? invertColors,
    bool? enhanceContrast,
  }) {
    return AccessibilityConfig(
      invertColors: invertColors ?? this.invertColors,
      enhanceContrast: enhanceContrast ?? this.enhanceContrast,
    );
  }
}

/// 外观配置
class AppearanceConfig {
  final ThemeConfig theme;
  final FontConfig font;
  final AppearanceBackgroundConfig background;
  final AccessibilityConfig accessibility;

  AppearanceConfig({
    required this.theme,
    required this.font,
    required this.background,
    required this.accessibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.toJson(),
      'font': font.toJson(),
      'background': background.toJson(),
      'accessibility': accessibility.toJson(),
    };
  }

  factory AppearanceConfig.fromJson(Map<String, dynamic> json) {
    return AppearanceConfig(
      theme: json['theme'] != null
          ? ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>)
          : ThemeConfig(),
      font: json['font'] != null
          ? FontConfig.fromJson(json['font'] as Map<String, dynamic>)
          : FontConfig(),
      background: json['background'] != null
          ? AppearanceBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : AppearanceBackgroundConfig(),
      accessibility: json['accessibility'] != null
          ? AccessibilityConfig.fromJson(json['accessibility'] as Map<String, dynamic>)
          : AccessibilityConfig(),
    );
  }

  AppearanceConfig copyWith({
    ThemeConfig? theme,
    FontConfig? font,
    AppearanceBackgroundConfig? background,
    AccessibilityConfig? accessibility,
  }) {
    return AppearanceConfig(
      theme: theme ?? this.theme,
      font: font ?? this.font,
      background: background ?? this.background,
      accessibility: accessibility ?? this.accessibility,
    );
  }
}

/// 源配置
class SourceConfig {
  final String strategy;

  SourceConfig({
    this.strategy = 'auto',
  });

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy,
    };
  }

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      strategy: json['strategy'] as String? ?? 'auto',
    );
  }

  SourceConfig copyWith({
    String? strategy,
  }) {
    return SourceConfig(
      strategy: strategy ?? this.strategy,
    );
  }
}

/// 传输配置
class TransmissionConfig {
  final bool autoConcurrent;
  final int concurrentCount;
  final bool enableSpeedLimit;
  final int speedLimitValue;

  TransmissionConfig({
    this.autoConcurrent = true,
    this.concurrentCount = 64,
    this.enableSpeedLimit = false,
    this.speedLimitValue = 1024,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoConcurrent': autoConcurrent,
      'concurrentCount': concurrentCount,
      'enableSpeedLimit': enableSpeedLimit,
      'speedLimitValue': speedLimitValue,
    };
  }

  factory TransmissionConfig.fromJson(Map<String, dynamic> json) {
    return TransmissionConfig(
      autoConcurrent: json['autoConcurrent'] as bool? ?? true,
      concurrentCount: json['concurrentCount'] as int? ?? 64,
      enableSpeedLimit: json['enableSpeedLimit'] as bool? ?? false,
      speedLimitValue: json['speedLimitValue'] as int? ?? 1024,
    );
  }

  TransmissionConfig copyWith({
    bool? autoConcurrent,
    int? concurrentCount,
    bool? enableSpeedLimit,
    int? speedLimitValue,
  }) {
    return TransmissionConfig(
      autoConcurrent: autoConcurrent ?? this.autoConcurrent,
      concurrentCount: concurrentCount ?? this.concurrentCount,
      enableSpeedLimit: enableSpeedLimit ?? this.enableSpeedLimit,
      speedLimitValue: speedLimitValue ?? this.speedLimitValue,
    );
  }
}

/// 缓存配置
class CacheConfig {
  final String directory;

  CacheConfig({
    required this.directory,
  });

  Map<String, dynamic> toJson() {
    return {
      'directory': directory,
    };
  }

  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      directory: json['directory'] as String? ?? '',
    );
  }

  CacheConfig copyWith({
    String? directory,
  }) {
    return CacheConfig(
      directory: directory ?? this.directory,
    );
  }
}

/// 代理类型
enum ProxyType {
  http,
  socks,
}

/// 代理配置
class ProxyConfig {
  final bool enabled;
  final ProxyType selectedType;
  final String host;
  final int port;

  ProxyConfig({
    this.enabled = false,
    this.selectedType = ProxyType.http,
    this.host = '',
    this.port = 8080,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'selectedType': selectedType.name,
      'host': host,
      'port': port,
    };
  }

  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      enabled: json['enabled'] as bool? ?? false,
      selectedType: _parseProxyType(json['selectedType'] as String?),
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 8080,
    );
  }

  static ProxyType _parseProxyType(String? value) {
    if (value == null) return ProxyType.http;
    return ProxyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProxyType.http,
    );
  }

  ProxyConfig copyWith({
    bool? enabled,
    ProxyType? selectedType,
    String? host,
    int? port,
  }) {
    return ProxyConfig(
      enabled: enabled ?? this.enabled,
      selectedType: selectedType ?? this.selectedType,
      host: host ?? this.host,
      port: port ?? this.port,
    );
  }
}

/// 下载配置
class DownloadConfig {
  final SourceConfig source;
  final TransmissionConfig transmission;
  final CacheConfig cache;
  final ProxyConfig proxy;

  DownloadConfig({
    required this.source,
    required this.transmission,
    required this.cache,
    required this.proxy,
  });

  Map<String, dynamic> toJson() {
    return {
      'source': source.toJson(),
      'transmission': transmission.toJson(),
      'cache': cache.toJson(),
      'proxy': proxy.toJson(),
    };
  }

  factory DownloadConfig.fromJson(Map<String, dynamic> json) {
    return DownloadConfig(
      source: json['source'] != null
          ? SourceConfig.fromJson(json['source'] as Map<String, dynamic>)
          : SourceConfig(),
      transmission: json['transmission'] != null
          ? TransmissionConfig.fromJson(json['transmission'] as Map<String, dynamic>)
          : TransmissionConfig(),
      cache: json['cache'] != null
          ? CacheConfig.fromJson(json['cache'] as Map<String, dynamic>)
          : CacheConfig(directory: ''),
      proxy: json['proxy'] != null
          ? ProxyConfig.fromJson(json['proxy'] as Map<String, dynamic>)
          : ProxyConfig(),
    );
  }

  DownloadConfig copyWith({
    SourceConfig? source,
    TransmissionConfig? transmission,
    CacheConfig? cache,
    ProxyConfig? proxy,
  }) {
    return DownloadConfig(
      source: source ?? this.source,
      transmission: transmission ?? this.transmission,
      cache: cache ?? this.cache,
      proxy: proxy ?? this.proxy,
    );
  }
}

/// 通用设置
class GeneralSettings {
  final String language;

  GeneralSettings({
    this.language = 'zh-CN',
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
    };
  }

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      language: json['language'] as String? ?? 'zh-CN',
    );
  }

  GeneralSettings copyWith({
    String? language,
  }) {
    return GeneralSettings(
      language: language ?? this.language,
    );
  }
}

/// 功能配置
class FunctionalityConfig {
  final String discoverPage;
  final String instancesNavType;
  final bool launchPageQuickSwitch;
  final bool autoDownloadJava;
  final bool resourceTranslation;
  final bool translatedFilenamePrefix;
  final bool skipFirstScreenOptions;

  FunctionalityConfig({
    this.discoverPage = 'on',
    this.instancesNavType = 'instance',
    this.launchPageQuickSwitch = true,
    this.autoDownloadJava = true,
    this.resourceTranslation = true,
    this.translatedFilenamePrefix = true,
    this.skipFirstScreenOptions = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'discoverPage': discoverPage,
      'instancesNavType': instancesNavType,
      'launchPageQuickSwitch': launchPageQuickSwitch,
      'autoDownloadJava': autoDownloadJava,
      'resourceTranslation': resourceTranslation,
      'translatedFilenamePrefix': translatedFilenamePrefix,
      'skipFirstScreenOptions': skipFirstScreenOptions,
    };
  }

  factory FunctionalityConfig.fromJson(Map<String, dynamic> json) {
    return FunctionalityConfig(
      discoverPage: json['discoverPage'] as String? ?? 'on',
      instancesNavType: json['instancesNavType'] as String? ?? 'instance',
      launchPageQuickSwitch: json['launchPageQuickSwitch'] as bool? ?? true,
      autoDownloadJava: json['autoDownloadJava'] as bool? ?? true,
      resourceTranslation: json['resourceTranslation'] as bool? ?? true,
      translatedFilenamePrefix: json['translatedFilenamePrefix'] as bool? ?? true,
      skipFirstScreenOptions: json['skipFirstScreenOptions'] as bool? ?? true,
    );
  }

  FunctionalityConfig copyWith({
    String? discoverPage,
    String? instancesNavType,
    bool? launchPageQuickSwitch,
    bool? autoDownloadJava,
    bool? resourceTranslation,
    bool? translatedFilenamePrefix,
    bool? skipFirstScreenOptions,
  }) {
    return FunctionalityConfig(
      discoverPage: discoverPage ?? this.discoverPage,
      instancesNavType: instancesNavType ?? this.instancesNavType,
      launchPageQuickSwitch: launchPageQuickSwitch ?? this.launchPageQuickSwitch,
      autoDownloadJava: autoDownloadJava ?? this.autoDownloadJava,
      resourceTranslation: resourceTranslation ?? this.resourceTranslation,
      translatedFilenamePrefix: translatedFilenamePrefix ?? this.translatedFilenamePrefix,
      skipFirstScreenOptions: skipFirstScreenOptions ?? this.skipFirstScreenOptions,
    );
  }
}

/// 通用高级配置
class GeneralConfigAdvanced {
  final bool autoPurgeLauncherLogs;

  GeneralConfigAdvanced({
    this.autoPurgeLauncherLogs = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoPurgeLauncherLogs': autoPurgeLauncherLogs,
    };
  }

  factory GeneralConfigAdvanced.fromJson(Map<String, dynamic> json) {
    return GeneralConfigAdvanced(
      autoPurgeLauncherLogs: json['autoPurgeLauncherLogs'] as bool? ?? true,
    );
  }

  GeneralConfigAdvanced copyWith({
    bool? autoPurgeLauncherLogs,
  }) {
    return GeneralConfigAdvanced(
      autoPurgeLauncherLogs: autoPurgeLauncherLogs ?? this.autoPurgeLauncherLogs,
    );
  }
}

/// 通用配置
class GeneralConfig {
  final GeneralSettings general;
  final FunctionalityConfig functionality;
  final GeneralConfigAdvanced advanced;

  GeneralConfig({
    required this.general,
    required this.functionality,
    required this.advanced,
  });

  Map<String, dynamic> toJson() {
    return {
      'general': general.toJson(),
      'functionality': functionality.toJson(),
      'advanced': advanced.toJson(),
    };
  }

  factory GeneralConfig.fromJson(Map<String, dynamic> json) {
    return GeneralConfig(
      general: json['general'] != null
          ? GeneralSettings.fromJson(json['general'] as Map<String, dynamic>)
          : GeneralSettings(),
      functionality: json['functionality'] != null
          ? FunctionalityConfig.fromJson(json['functionality'] as Map<String, dynamic>)
          : FunctionalityConfig(),
      advanced: json['advanced'] != null
          ? GeneralConfigAdvanced.fromJson(json['advanced'] as Map<String, dynamic>)
          : GeneralConfigAdvanced(),
    );
  }

  GeneralConfig copyWith({
    GeneralSettings? general,
    FunctionalityConfig? functionality,
    GeneralConfigAdvanced? advanced,
  }) {
    return GeneralConfig(
      general: general ?? this.general,
      functionality: functionality ?? this.functionality,
      advanced: advanced ?? this.advanced,
    );
  }
}

/// 启动器 MCP 服务器配置
class LauncherMcpServerConfig {
  final bool enabled;
  final int port;

  LauncherMcpServerConfig({
    this.enabled = true,
    this.port = 18970,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'port': port,
    };
  }

  factory LauncherMcpServerConfig.fromJson(Map<String, dynamic> json) {
    return LauncherMcpServerConfig(
      enabled: json['enabled'] as bool? ?? true,
      port: json['port'] as int? ?? 18970,
    );
  }

  LauncherMcpServerConfig copyWith({
    bool? enabled,
    int? port,
  }) {
    return LauncherMcpServerConfig(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
    );
  }
}

/// MCP 服务器配置
class McpServerConfig {
  final LauncherMcpServerConfig launcher;

  McpServerConfig({
    required this.launcher,
  });

  Map<String, dynamic> toJson() {
    return {
      'launcher': launcher.toJson(),
    };
  }

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    return McpServerConfig(
      launcher: json['launcher'] != null
          ? LauncherMcpServerConfig.fromJson(json['launcher'] as Map<String, dynamic>)
          : LauncherMcpServerConfig(),
    );
  }

  McpServerConfig copyWith({
    LauncherMcpServerConfig? launcher,
  }) {
    return McpServerConfig(
      launcher: launcher ?? this.launcher,
    );
  }
}

/// 智能配置
class IntelligenceConfig {
  final McpServerConfig mcpServer;

  IntelligenceConfig({
    required this.mcpServer,
  });

  Map<String, dynamic> toJson() {
    return {
      'mcpServer': mcpServer.toJson(),
    };
  }

  factory IntelligenceConfig.fromJson(Map<String, dynamic> json) {
    return IntelligenceConfig(
      mcpServer: json['mcpServer'] != null
          ? McpServerConfig.fromJson(json['mcpServer'] as Map<String, dynamic>)
          : McpServerConfig(launcher: LauncherMcpServerConfig()),
    );
  }

  IntelligenceConfig copyWith({
    McpServerConfig? mcpServer,
  }) {
    return IntelligenceConfig(
      mcpServer: mcpServer ?? this.mcpServer,
    );
  }
}

/// 扩展配置
class ExtensionConfig {
  final List<String> enabled;
  final Map<String, dynamic> homeWidgetState;

  ExtensionConfig({
    this.enabled = const [],
    this.homeWidgetState = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'homeWidgetState': homeWidgetState,
    };
  }

  factory ExtensionConfig.fromJson(Map<String, dynamic> json) {
    return ExtensionConfig(
      enabled: (json['enabled'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      homeWidgetState: (json['homeWidgetState'] as Map<String, dynamic>?) ?? {},
    );
  }

  ExtensionConfig copyWith({
    List<String>? enabled,
    Map<String, dynamic>? homeWidgetState,
  }) {
    return ExtensionConfig(
      enabled: enabled ?? this.enabled,
      homeWidgetState: homeWidgetState ?? this.homeWidgetState,
    );
  }
}

/// 基本信息配置
class BasicInfo {
  final String launcherVersion;
  final String platform;
  final String arch;
  final String osType;
  final String platformVersion;
  final String exeSha256;
  final bool isPortable;
  final bool isExePathAvailable;
  final bool isChinaMainlandIp;
  final bool allowFullLoginFeature;

  BasicInfo({
    this.launcherVersion = 'dev',
    this.platform = '',
    this.arch = '',
    this.osType = '',
    this.platformVersion = '',
    this.exeSha256 = '',
    this.isPortable = false,
    this.isExePathAvailable = true,
    this.isChinaMainlandIp = false,
    this.allowFullLoginFeature = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'launcherVersion': launcherVersion,
      'platform': platform,
      'arch': arch,
      'osType': osType,
      'platformVersion': platformVersion,
      'exeSha256': exeSha256,
      'isPortable': isPortable,
      'isExePathAvailable': isExePathAvailable,
      'isChinaMainlandIp': isChinaMainlandIp,
      'allowFullLoginFeature': allowFullLoginFeature,
    };
  }

  factory BasicInfo.fromJson(Map<String, dynamic> json) {
    return BasicInfo(
      launcherVersion: json['launcherVersion'] as String? ?? 'dev',
      platform: json['platform'] as String? ?? '',
      arch: json['arch'] as String? ?? '',
      osType: json['osType'] as String? ?? '',
      platformVersion: json['platformVersion'] as String? ?? '',
      exeSha256: json['exeSha256'] as String? ?? '',
      isPortable: json['isPortable'] as bool? ?? false,
      isExePathAvailable: json['isExePathAvailable'] as bool? ?? true,
      isChinaMainlandIp: json['isChinaMainlandIp'] as bool? ?? false,
      allowFullLoginFeature: json['allowFullLoginFeature'] as bool? ?? false,
    );
  }

  BasicInfo copyWith({
    String? launcherVersion,
    String? platform,
    String? arch,
    String? osType,
    String? platformVersion,
    String? exeSha256,
    bool? isPortable,
    bool? isExePathAvailable,
    bool? isChinaMainlandIp,
    bool? allowFullLoginFeature,
  }) {
    return BasicInfo(
      launcherVersion: launcherVersion ?? this.launcherVersion,
      platform: platform ?? this.platform,
      arch: arch ?? this.arch,
      osType: osType ?? this.osType,
      platformVersion: platformVersion ?? this.platformVersion,
      exeSha256: exeSha256 ?? this.exeSha256,
      isPortable: isPortable ?? this.isPortable,
      isExePathAvailable: isExePathAvailable ?? this.isExePathAvailable,
      isChinaMainlandIp: isChinaMainlandIp ?? this.isChinaMainlandIp,
      allowFullLoginFeature: allowFullLoginFeature ?? this.allowFullLoginFeature,
    );
  }
}

/// 游戏目录
class GameDirectory {
  final String dir;
  final String name;

  GameDirectory({
    required this.dir,
    this.name = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'dir': dir,
      'name': name,
    };
  }

  factory GameDirectory.fromJson(Map<String, dynamic> json) {
    return GameDirectory(
      dir: json['dir'] as String,
      name: json['name'] as String? ?? '',
    );
  }

  GameDirectory copyWith({
    String? dir,
    String? name,
  }) {
    return GameDirectory(
      dir: dir ?? this.dir,
      name: name ?? this.name,
    );
  }
}

/// 启动器配置主类
class LauncherConfig {
  final BasicInfo basicInfo;
  final bool mocked;
  final int runCount;
  final bool lastRunExitedNormally;
  final AppearanceConfig appearance;
  final DownloadConfig download;
  final GeneralConfig general;
  final IntelligenceConfig intelligence;
  final ExtensionConfig extension;
  final GameConfig globalGameConfig;
  final List<GameDirectory> localGameDirectories;
  final List<String> extraJavaPaths;
  final List<String> suppressedDialogs;

  LauncherConfig({
    required this.basicInfo,
    this.mocked = false,
    this.runCount = 0,
    this.lastRunExitedNormally = true,
    required this.appearance,
    required this.download,
    required this.general,
    required this.intelligence,
    required this.extension,
    required this.globalGameConfig,
    this.localGameDirectories = const [],
    this.extraJavaPaths = const [],
    this.suppressedDialogs = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'basicInfo': basicInfo.toJson(),
      'mocked': mocked,
      'runCount': runCount,
      'lastRunExitedNormally': lastRunExitedNormally,
      'appearance': appearance.toJson(),
      'download': download.toJson(),
      'general': general.toJson(),
      'intelligence': intelligence.toJson(),
      'extension': extension.toJson(),
      'globalGameConfig': globalGameConfig.toJson(),
      'localGameDirectories': localGameDirectories.map((e) => e.toJson()).toList(),
      'extraJavaPaths': extraJavaPaths,
      'suppressedDialogs': suppressedDialogs,
    };
  }

  factory LauncherConfig.fromJson(Map<String, dynamic> json) {
    return LauncherConfig(
      basicInfo: json['basicInfo'] != null
          ? BasicInfo.fromJson(json['basicInfo'] as Map<String, dynamic>)
          : BasicInfo(),
      mocked: json['mocked'] as bool? ?? false,
      runCount: json['runCount'] as int? ?? 0,
      lastRunExitedNormally: json['lastRunExitedNormally'] as bool? ?? true,
      appearance: json['appearance'] != null
          ? AppearanceConfig.fromJson(json['appearance'] as Map<String, dynamic>)
          : AppearanceConfig(
              theme: ThemeConfig(),
              font: FontConfig(),
              background: AppearanceBackgroundConfig(),
              accessibility: AccessibilityConfig(),
            ),
      download: json['download'] != null
          ? DownloadConfig.fromJson(json['download'] as Map<String, dynamic>)
          : DownloadConfig(
              source: SourceConfig(),
              transmission: TransmissionConfig(),
              cache: CacheConfig(directory: ''),
              proxy: ProxyConfig(),
            ),
      general: json['general'] != null
          ? GeneralConfig.fromJson(json['general'] as Map<String, dynamic>)
          : GeneralConfig(
              general: GeneralSettings(),
              functionality: FunctionalityConfig(),
              advanced: GeneralConfigAdvanced(),
            ),
      intelligence: json['intelligence'] != null
          ? IntelligenceConfig.fromJson(json['intelligence'] as Map<String, dynamic>)
          : IntelligenceConfig(mcpServer: McpServerConfig(launcher: LauncherMcpServerConfig())),
      extension: json['extension'] != null
          ? ExtensionConfig.fromJson(json['extension'] as Map<String, dynamic>)
          : ExtensionConfig(),
      globalGameConfig: json['globalGameConfig'] != null
          ? GameConfig.fromJson(json['globalGameConfig'] as Map<String, dynamic>)
          : GameConfig(
              gameJava: JavaConfig(),
              gameWindow: GameWindowConfig(resolution: Resolution(width: 854, height: 480)),
              performance: PerformanceConfig(),
              gameServer: GameServerConfig(),
              advanced: AdvancedConfig(
                customCommands: CustomCommands(),
                jvm: JVMConfig(),
                workaround: GameWorkaroundConfig(),
              ),
            ),
      localGameDirectories: (json['localGameDirectories'] as List<dynamic>?)
              ?.map((e) => GameDirectory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraJavaPaths: (json['extraJavaPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suppressedDialogs: (json['suppressedDialogs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 获取默认配置
  static LauncherConfig defaultConfig() {
    return LauncherConfig(
      basicInfo: BasicInfo(),
      appearance: AppearanceConfig(
        theme: ThemeConfig(),
        font: FontConfig(),
        background: AppearanceBackgroundConfig(),
        accessibility: AccessibilityConfig(),
      ),
      download: DownloadConfig(
        source: SourceConfig(),
        transmission: TransmissionConfig(),
        cache: CacheConfig(directory: ''),
        proxy: ProxyConfig(),
      ),
      general: GeneralConfig(
        general: GeneralSettings(),
        functionality: FunctionalityConfig(),
        advanced: GeneralConfigAdvanced(),
      ),
      intelligence: IntelligenceConfig(
        mcpServer: McpServerConfig(launcher: LauncherMcpServerConfig()),
      ),
      extension: ExtensionConfig(),
      globalGameConfig: GameConfig(
        gameJava: JavaConfig(),
        gameWindow: GameWindowConfig(resolution: Resolution(width: 854, height: 480)),
        performance: PerformanceConfig(),
        gameServer: GameServerConfig(),
        advanced: AdvancedConfig(
          customCommands: CustomCommands(),
          jvm: JVMConfig(),
          workaround: GameWorkaroundConfig(),
        ),
      ),
    );
  }

  /// 创建部分更新副本
  LauncherConfig copyWith({
    BasicInfo? basicInfo,
    bool? mocked,
    int? runCount,
    bool? lastRunExitedNormally,
    AppearanceConfig? appearance,
    DownloadConfig? download,
    GeneralConfig? general,
    IntelligenceConfig? intelligence,
    ExtensionConfig? extension,
    GameConfig? globalGameConfig,
    List<GameDirectory>? localGameDirectories,
    List<String>? extraJavaPaths,
    List<String>? suppressedDialogs,
  }) {
    return LauncherConfig(
      basicInfo: basicInfo ?? this.basicInfo,
      mocked: mocked ?? this.mocked,
      runCount: runCount ?? this.runCount,
      lastRunExitedNormally: lastRunExitedNormally ?? this.lastRunExitedNormally,
      appearance: appearance ?? this.appearance,
      download: download ?? this.download,
      general: general ?? this.general,
      intelligence: intelligence ?? this.intelligence,
      extension: extension ?? this.extension,
      globalGameConfig: globalGameConfig ?? this.globalGameConfig,
      localGameDirectories: localGameDirectories ?? this.localGameDirectories,
      extraJavaPaths: extraJavaPaths ?? this.extraJavaPaths,
      suppressedDialogs: suppressedDialogs ?? this.suppressedDialogs,
    );
  }

  /// 从当前配置创建新配置，保留某些字段
  LauncherConfig replaceWithPreserved(LauncherConfig newConfig, List<String> preservedFields) {
    final Map<String, dynamic> currentJson = toJson();
    final Map<String, dynamic> newJson = newConfig.toJson();

    for (final field in preservedFields) {
      if (currentJson.containsKey(field)) {
        newJson[field] = currentJson[field];
      }
    }

    return LauncherConfig.fromJson(newJson);
  }
}
