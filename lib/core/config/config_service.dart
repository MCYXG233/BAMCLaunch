import 'i_config_manager.dart';
import 'models/global_config.dart';

class ConfigService {
  final IConfigManager _configManager;
  GlobalConfig? _cachedConfig;

  ConfigService(this._configManager);

  // 初始化配置
  Future<void> initialize() async {
    // 验证配置有效性
    final isValid = await _configManager.isConfigValid();
    if (!isValid) {
      await _configManager.repairConfig();
    }
    
    // 加载配置
    await loadConfig();
  }

  // 加载配置到缓存
  Future<void> loadConfig() async {
    _cachedConfig = await _configManager.loadGlobalConfig() as GlobalConfig?;
    if (_cachedConfig == null) {
      _cachedConfig = GlobalConfig.defaultConfig();
      await _configManager.saveGlobalConfig(_cachedConfig!);
    }
  }

  // 获取当前配置
  GlobalConfig get config {
    return _cachedConfig ?? GlobalConfig.defaultConfig();
  }

  // 保存配置
  Future<void> saveConfig() async {
    if (_cachedConfig != null) {
      await _configManager.saveGlobalConfig(_cachedConfig!);
    }
  }

  // 重置为默认配置
  Future<void> resetToDefaults() async {
    await _configManager.resetToDefaults();
    await loadConfig();
  }

  // 验证配置
  Future<bool> validate() async {
    return await _configManager.validateConfig(_cachedConfig);
  }

  // 修复配置
  Future<void> repair() async {
    await _configManager.repairConfig();
    await loadConfig();
  }

  // 创建备份
  Future<void> createBackup() async {
    await _configManager.createAutoBackup();
  }

  // 获取备份文件列表
  Future<List<String>> getBackups() async {
    return await _configManager.getBackupFiles();
  }

  // 从备份恢复
  Future<bool> restoreFromBackup(String backupPath) async {
    final success = await _configManager.restoreConfig(backupPath);
    if (success) {
      await loadConfig();
    }
    return success;
  }

  // 基本配置访问器
  BasicConfig get basic => config.basic;
  
  Future<void> updateBasic(BasicConfig Function(BasicConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: updater(config.basic),
      game: config.game,
      download: config.download,
      account: config.account,
      ui: config.ui,
      content: config.content,
    );
    await saveConfig();
  }

  // 游戏配置访问器
  GameConfig get game => config.game;
  
  Future<void> updateGame(GameConfig Function(GameConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: config.basic,
      game: updater(config.game),
      download: config.download,
      account: config.account,
      ui: config.ui,
      content: config.content,
    );
    await saveConfig();
  }

  // 下载配置访问器
  DownloadConfig get download => config.download;
  
  Future<void> updateDownload(DownloadConfig Function(DownloadConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: config.basic,
      game: config.game,
      download: updater(config.download),
      account: config.account,
      ui: config.ui,
      content: config.content,
    );
    await saveConfig();
  }

  // 账户配置访问器
  AccountConfig get account => config.account;
  
  Future<void> updateAccount(AccountConfig Function(AccountConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: config.basic,
      game: config.game,
      download: config.download,
      account: updater(config.account),
      ui: config.ui,
      content: config.content,
    );
    await saveConfig();
  }

  // UI配置访问器
  UiConfig get ui => config.ui;
  
  Future<void> updateUi(UiConfig Function(UiConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: config.basic,
      game: config.game,
      download: config.download,
      account: config.account,
      ui: updater(config.ui),
      content: config.content,
    );
    await saveConfig();
  }

  // 内容配置访问器
  ContentConfig get content => config.content;
  
  Future<void> updateContent(ContentConfig Function(ContentConfig) updater) async {
    _cachedConfig = GlobalConfig(
      version: config.version,
      basic: config.basic,
      game: config.game,
      download: config.download,
      account: config.account,
      ui: config.ui,
      content: updater(config.content),
    );
    await saveConfig();
  }

  // 便捷方法：更新单个配置项
  Future<void> updateLanguage(String language) async {
    await updateBasic((basic) => BasicConfig(
          launcherVersion: basic.launcherVersion,
          language: language,
          autoUpdate: basic.autoUpdate,
          checkUpdateOnStartup: basic.checkUpdateOnStartup,
          theme: basic.theme,
          enableLogging: basic.enableLogging,
          logLevel: basic.logLevel,
        ));
  }

  Future<void> updateMemorySettings(int maxMemory, int minMemory) async {
    await updateGame((game) => GameConfig(
          javaPath: game.javaPath,
          maxMemory: maxMemory,
          minMemory: minMemory,
          jvmArguments: game.jvmArguments,
          gameArguments: game.gameArguments,
          enableFullscreen: game.enableFullscreen,
          windowWidth: game.windowWidth,
          windowHeight: game.windowHeight,
          enableVsync: game.enableVsync,
          enableMipmap: game.enableMipmap,
          gameDirectory: game.gameDirectory,
        ));
  }

  Future<void> updateDownloadSource(String source) async {
    await updateDownload((download) => DownloadConfig(
          downloadSource: source,
          downloadThreads: download.downloadThreads,
          downloadSpeedLimit: download.downloadSpeedLimit,
          enableProxy: download.enableProxy,
          proxyHost: download.proxyHost,
          proxyPort: download.proxyPort,
          proxyType: download.proxyType,
          enableBreakpointResume: download.enableBreakpointResume,
          retryCount: download.retryCount,
          retryDelay: download.retryDelay,
        ));
  }

  Future<void> updateDefaultAccount(String accountId) async {
    await updateAccount((account) => AccountConfig(
          defaultAccountId: accountId,
          autoLogin: account.autoLogin,
          rememberPassword: account.rememberPassword,
          enableAuthlibInjector: account.enableAuthlibInjector,
          authlibInjectorUrl: account.authlibInjectorUrl,
          enableSkinUpload: account.enableSkinUpload,
        ));
  }

  Future<void> updateTheme(String theme) async {
    await updateBasic((basic) => BasicConfig(
          launcherVersion: basic.launcherVersion,
          language: basic.language,
          autoUpdate: basic.autoUpdate,
          checkUpdateOnStartup: basic.checkUpdateOnStartup,
          theme: theme,
          enableLogging: basic.enableLogging,
          logLevel: basic.logLevel,
        ));
  }

  Future<void> updateWindowSize(int width, int height) async {
    await updateGame((game) => GameConfig(
          javaPath: game.javaPath,
          maxMemory: game.maxMemory,
          minMemory: game.minMemory,
          jvmArguments: game.jvmArguments,
          gameArguments: game.gameArguments,
          enableFullscreen: game.enableFullscreen,
          windowWidth: width,
          windowHeight: height,
          enableVsync: game.enableVsync,
          enableMipmap: game.enableMipmap,
          gameDirectory: game.gameDirectory,
        ));
  }
}
